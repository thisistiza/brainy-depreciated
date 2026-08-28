import PhotosUI
import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers
import os

struct TemporaryNoteEditorView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    private var currentTemporaryNote: Note? {
        if let session = session{
            if let currentTemporaryNote = session.currentTemporaryNote{
                return currentTemporaryNote
            }
            Log.model.debug("TemporaryNoteEditorView: NoteView: Current temporary note in session is missing.")
            let newNote = session.createTemporaryNote(in: modelContext)
            session.setCurrentTemporaryNote(to: newNote)
            return newNote
        }
        Log.model.debug("TemporaryNoteEditorView: NoteView: Session is missing.")
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
            if let session = session, let currentTemporaryNote = currentTemporaryNote {
                ZStack{
                    VStack(spacing: 0) {
                        paneAndToolBar(session: session)
                        NoteRenderer(
                            note: currentTemporaryNote,
                            isTemporary: true,
                            isReviewing: false,
                            noteState: $noteState,
                            isAllBlocksHidden: $isAllBlocksHidden
                        )
                        .safeAreaInset(edge: .bottom) {
                            if noteState == .editable {
                                editBar(currentTemporaryNote: currentTemporaryNote, session: session)
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
                            handleFileImport(result: result, to: currentTemporaryNote, for: session, in: modelContext)
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
                                        appendNewImageBlock(with: uiImage, to: currentTemporaryNote, for: session, in: modelContext)
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
                            save(note: currentTemporaryNote, for: session, in: modelContext)
                        } catch {
                        }
                    }
                    DS.Component.Modal(
                        isPresented: $isConfirmationModalPresented,
                        height: .height(250)
                    ) {
                        confirmationModalView(currentTemporaryNote: currentTemporaryNote, session: session, modelContext: modelContext)
                            .safeAreaPadding(.bottom)
                    }
                }
            } else {
                DS.Component.ErrorView(messages: ["Session is missing."]).onAppear{
                    Log.model.debug("TemporaryNoteEditorView: NoteView: Session is missing.")
                }
            }
        }
    }
}

extension TemporaryNoteEditorView {
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
                    if let currentTemporaryNote = currentTemporaryNote{
                        save(note: currentTemporaryNote, for: session, in: modelContext)
                    }
                    else{
                        Log.model.debug("TemporaryNoteEditorView: NoteView: Current temporary note failed to save (It is missing).")
                    }
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
                Log.view.debug("TemporaryNoteEditorView: NoteView: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .editable ? .editable : .viewable
            }
            toolBarItem(icon: "slide", palette: .sapphire, isSelected: noteState == .reorderable){
                Log.view.debug("TemporaryNoteEditorView: NoteView: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .reorderable ? .reorderable : .viewable
            }
            toolBarItem(icon: "trash", palette: .ruby, isSelected: noteState == .deletable){
                Log.view.debug("TemporaryNoteEditorView: NoteView: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .deletable ? .deletable : .viewable
            }
            toolBarItem(icon: "loopLeft", palette: .amethyst, isIconColorPreserved: false, isSelected: isConfirmationModalPresented){
                Log.view.debug("TemporaryNoteEditorView: NoteView: Note state is updated to \(noteState.rawValue).")
                hideKeyboard()
                noteState = noteState != .viewable ? .viewable : .viewable
                isConfirmationModalPresented = true
            }
        }
        .padding(.horizontal, DS.Spacing.md)
    }

    private func editBar(currentTemporaryNote: Note, session: Session) -> some View {
        return DS.Component.Bar {
            HStack {
                Spacer()
                editBarItem(icon: "heading") {
                    session.appendBlock(of: .heading, to: currentTemporaryNote, in: modelContext)
                }
                editBarItem(icon: "paragraph") {
                    session.appendBlock(of: .paragraph, to: currentTemporaryNote, in: modelContext)
                }
                editBarItem(icon: "terminal") {
                    session.appendBlock(of: .code, to: currentTemporaryNote, in: modelContext)
                }
                editBarItem(icon: "equation") {
                    session.appendBlock(of: .math, to: currentTemporaryNote, in: modelContext)
                }
                editBarItem(icon: "picture") {
                    hideKeyboard()
                    isFileImporterPresented = true
                }
                editBarItem(icon: "pen") {
                    hideKeyboard()
                    session.appendBlock(of: .annotation, to: currentTemporaryNote, in: modelContext)
                }
                editBarItem(icon: "clipboard", isIconColorPreserved: false) {
                    session.pasteBlockFromClipboard(to: currentTemporaryNote, isTemporary: true, in: modelContext)
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

extension TemporaryNoteEditorView {
    private func confirmationModalView(currentTemporaryNote: Note, session: Session, modelContext: ModelContext) -> some View {
        return DS.Component.ContentContainer {
            VStack(spacing: DS.Spacing.md) {
                Text("Are you sure you want to reset content?")
                    .font(DS.Typography.bodyLarge)
                    .foregroundStyle(DS.Color.System.foreground.primary)
                    .padding(DS.Spacing.md)
                DS.Component.Button(
                    icon: "loop",
                    text: "RESET",
                    theme: .palette(.ruby),
                    style: .hollow
                ) {
                    isConfirmationModalPresented = false
                    let newNote = session.createTemporaryNote(in: modelContext)
                    newNote.subject = nil
                    session.setCurrentTemporaryNote(to: newNote)
                    delete(note: currentTemporaryNote, for: session, in: modelContext)
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
