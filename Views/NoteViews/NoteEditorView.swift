import PhotosUI
import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers
import os

struct NoteEditorView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    private var currentEditingNote: Note? {
        if let session = session{
            return session.currentEditingNote
        }
        Log.model.debug("NoteEditor: Session is missing.")
        return nil
    }

    @State private var subjectName: String = ""
    @State var noteState: NoteState = .editable
    @State var isAllBlocksHidden: Bool = true
    @State var isFileImporterPresented: Bool = false
    @State var isConfirmationModalPresented: Bool = false
    #if !targetEnvironment(macCatalyst)
    @State var selectedPhotoItem: PhotosPickerItem? = nil
    #endif
    @State private var localChangeTrigger: Int = 0

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentEditingNote = currentEditingNote {
                ZStack{
                    VStack(spacing: 0) {
                        paneAndToolBar(session: session)
                        NoteRenderer(
                            note: currentEditingNote,
                            isTemporary: false,
                            isReviewing: false,
                            noteState: $noteState,
                            isAllBlocksHidden: $isAllBlocksHidden
                        )
                        .safeAreaInset(edge: .bottom) {
                            if noteState == .editable {
                                editBar(currentEditingNote: currentEditingNote, session: session)
                                    .padding(DS.Spacing.lg)
                                    .transition(
                                        .move(edge: .bottom).combined(
                                            with: .opacity
                                        )
                                    )
                            }
                        }
#if targetEnvironment(macCatalyst)
                        .fileImporter(
                            isPresented: $isFileImporterPresented,
                            allowedContentTypes: [.image],
                            allowsMultipleSelection: false
                        ){result in
                            handleFileImport(result: result, to: currentEditingNote, for: session, in: modelContext)
                        }
#endif
#if !targetEnvironment(macCatalyst)
                        .photosPicker(
                            isPresented: $isFileImporterPresented,
                            selection: $selectedPhotoItem,
                            matching: .images
                        )
                        .onChange(of: selectedPhotoItem, initial: false) { oldValue, newValue in
                            Task {
                                if let newValue = newValue,
                                   let data = try? await newValue.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    
                                    await MainActor.run {
                                        appendNewImageBlock(with: uiImage, to: currentEditingNote, for: session, in: modelContext)
                                    }
                                }
                                
                                await MainActor.run {
                                    selectedPhotoItem = nil
                                }
                            }
                        }
#endif
                    }
                    .task(id: localChangeTrigger) {
                        guard localChangeTrigger > 0 else { return }
                        do {
                            try await Task.sleep(for: .seconds(1.5))
                            save(note: currentEditingNote, for: session, in: modelContext)
                        } catch {
                        }
                    }
                    DS.Component.Modal(
                        isPresented: $isConfirmationModalPresented,
                        height: .height(450)
                    ) {
                        confirmationModalView(currentEditingNote: currentEditingNote, session: session, modelContext: modelContext)
                            .safeAreaPadding(.bottom)
                    }
                }
            } else {
                DS.Component.ErrorView(messages: ["Session is missing."]).onAppear{
                    Log.model.debug("NoteEditor: Session is missing.")
                }
            }
        }
    }
}

extension NoteEditorView {
    private func paneAndToolBar(session: Session) -> some View {
        func getModeName() -> String {
            switch noteState {
            case .editable: return "Edit"
            case .hideable: return "Hide"
            case .deletable: return "Delete"
            case .reorderable: return "Reorder"
            case .viewable: return ""
            case .none: return ""
            }
        }
        return VStack {
            HStack {
                DS.Component.Button(
                    icon: "cross",
                    theme: .system(.sapphire),
                    style: .plain,
                    size: .compact
                ) {
                    if let currentEditingNote = currentEditingNote{
                        if !isEmpty(for: currentEditingNote){
                            save(note: currentEditingNote, for: session, in: modelContext)
                        }
                        else{
                            delete(note: currentEditingNote, for: session, in: modelContext)
                            session.setCurrentEditingNote(to: nil)
                            hideKeyboard()
                            if let prev = router.prevRoute(), prev == .noteRoute || prev == .noteReviewerRoute{
                                router.navigateBack(steps: 2)
                            }
                            else{
                                router.navigateBack()
                                return
                            }
                        }
                    }
                    else{
                        Log.model.debug("NoteEditor: Current editing note failed to save (It is missing).")
                    }
                    session.setCurrentEditingNote(to: nil)
                    hideKeyboard()
                    router.navigateBack()
                }
//                Text(getModeName())
//                    .font(DS.Typography.bodyLarge)
//                    .foregroundStyle(DS.Color.System.foreground.primary)
                Spacer()
                toolBar()
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }

    private func toolBar() -> some View {
        return HStack {
            Spacer()
            toolBarItem(icon: "draft", palette: .iron, isSelected: noteState == .editable){
                Log.view.debug("NoteEditor: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .editable ? .editable : .viewable
            }
            toolBarItem(icon: "eyeOpened", palette: .emerald, isSelected: noteState == .hideable){
                Log.view.debug("NoteEditor: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .hideable ? .hideable : .viewable
            }
            toolBarItem(icon: "slide", palette: .sapphire, isSelected: noteState == .reorderable){
                Log.view.debug("NoteEditor: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .reorderable ? .reorderable : .viewable
            }
            toolBarItem(icon: "trash", palette: .ruby, isSelected: noteState == .deletable){
                Log.view.debug("NoteEditor: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .deletable ? .deletable : .viewable
            }
            toolBarItem(icon: "dotsBoxed", palette: .amethyst, isSelected: isConfirmationModalPresented){
                Log.view.debug("NoteEditor: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .viewable ? .viewable : .viewable
                isConfirmationModalPresented = true
            }
        }
        .padding(.horizontal, DS.Spacing.md)
    }

    private func editBar(currentEditingNote: Note, session: Session) -> some View {
        return DS.Component.Bar {
            HStack {
                Spacer()
                editBarItem(icon: "heading") {
                    session.appendBlock(of: .heading, to: currentEditingNote, in: modelContext)
                }
                editBarItem(icon: "paragraph") {
                    session.appendBlock(of: .paragraph, to: currentEditingNote, in: modelContext)
                }
                editBarItem(icon: "terminal") {
                    session.appendBlock(of: .code, to: currentEditingNote, in: modelContext)
                }
                editBarItem(icon: "equation") {
                    session.appendBlock(of: .math, to: currentEditingNote, in: modelContext)
                }
                editBarItem(icon: "picture") {
                    hideKeyboard()
                    isFileImporterPresented = true
                }
                editBarItem(icon: "pen") {
                    hideKeyboard()
                    session.appendBlock(of: .annotation, to: currentEditingNote, in: modelContext)
                }
                editBarItem(icon: "clipboard", isIconColorPreserved: false) {
                    hideKeyboard()
                    session.pasteBlockFromClipboard(to: currentEditingNote, in: modelContext)
                }
#if !targetEnvironment(macCatalyst)
                DS.Component.VerticalDivider()
                editBarItem(icon: "keyboard", isIconColorPreserved: false) {
                    hideKeyboard()
                }
#endif
                Spacer()
            }
        }
        .frame(maxWidth: 360)
    }
}

extension NoteEditorView {
    private func confirmationModalView(currentEditingNote: Note, session: Session, modelContext: ModelContext) -> some View {
        return DS.Component.ContentContainer {
            VStack(spacing: DS.Spacing.md) {
                Text("More Options")
                    .font(DS.Typography.bodyLarge)
                    .foregroundStyle(DS.Color.System.foreground.primary)
                    .padding(DS.Spacing.md)
                DS.Component.Button(
                    icon: "plus",
                    text: "NEW NOTE",
                    theme: .system(.sapphire),
                    style: .hollow
                ) {
                    isConfirmationModalPresented = false
                    update(note: currentEditingNote, for: session, in: modelContext)
                    if let subject = currentEditingNote.subject{
                        let newNote = session.appendNote(to: subject, in: modelContext)
                        session.setCurrentEditingNote(to: newNote)
                    }
                    else{
                        Log.model.debug("NoteEditorView: Current subject in session is missing.")
                    }
                }
                DS.Component.Button(
                    icon: "duplicate",
                    text: "DUPLICATE NOTE",
                    theme: .system(.sapphire),
                    style: .hollow
                ) {
                    isConfirmationModalPresented = false
                    update(note: currentEditingNote, for: session, in: modelContext)
                    copyAndReplace(current: currentEditingNote, for: session, in: modelContext)
                }
                DS.Component.Button(
                    icon: "graduationCap",
                    text: "ADD NOTE TO LEARNING PILE",
                    theme: .system(.sapphire),
                    style: .hollow
                ) {
                    isConfirmationModalPresented = false
                    session.update(note: currentEditingNote, to: .learning, in: modelContext)
                    update(note: currentEditingNote, for: session, in: modelContext)
                }
                DS.Component.Button(
                    icon: "loopLeft",
                    text: "UNDO LAST REVIEW",
                    theme: .system(.sapphire),
                    style: .hollow,
                    preserveIconColor: true
                ) {
                    isConfirmationModalPresented = false
                    session.undoLastReview(note: currentEditingNote)
                    update(note: currentEditingNote, for: session, in: modelContext)
                }
                DS.Component.Button(
                    icon: "trash",
                    text: "DELETE",
                    theme: .palette(.ruby),
                    style: .hollow,
                    preserveIconColor: true
                ) {
                    delete(note: currentEditingNote, for: session, in: modelContext)
                    session.setCurrentEditingNote(to: nil)
                    if let prev = router.prevRoute(), prev == .noteRoute || prev == .noteReviewerRoute{
                        router.navigateBack(steps: 2)
                    }
                    else{
                        router.navigateBack()
                        return
                    }
                }
                DS.Component.Button(
                    text: "CANCEL",
                    theme: .system(.sapphire),
                    style: .hollow
                ) {
                    isConfirmationModalPresented = false
                }
                Spacer()
            }
        }
    }
}
