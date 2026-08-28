import SwiftData
import SwiftUI
import os

struct NoteView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    private var currentReviewingNote: Note? {
        guard let session = session else { return nil }
        let notes = session.currentReviewingNoteList
        let index = session.currentReviewingNoteListIndex
        guard notes.indices.contains(index) else { return nil }
        return notes[index]
    }

    @State private var subjectName: String = ""
    @State var noteState: NoteState = .viewable
    @State var isAllBlocksHidden: Bool = true
    @State var isFileImporterPresented: Bool = false
    @State var isConfirmationModalPresented: Bool = false
    @State private var navigationDirection: AxisDirection = .forward

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentReviewingNote = currentReviewingNote {
                VStack(spacing: 0) {
                    paneBar(session: session)
                    noteContentView()
                    reviewBar(session: session, currentReviewingNote: currentReviewingNote)
                        .background(DS.Color.System.background.primary)
                        .onAppear {
                            isAllBlocksHidden = true
                        }
                }
            } else {
                DS.Component.ErrorView(messages: ["Session is missing."]).onAppear {
                    Log.model.debug("NoteView: Session is missing.")
                        //TODO
                }
            }
        }
    }
}

extension NoteView {
    @ViewBuilder
    private func noteContentView() -> some View {
        if let currentReviewingNote = currentReviewingNote {
            ZStack{
                NoteRenderer(
                    note: currentReviewingNote,
                    isTemporary: false,
                    isReviewing: true,
                    noteState: $noteState,
                    isAllBlocksHidden: $isAllBlocksHidden
                )
                .id(currentReviewingNote.persistentModelID)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            DS.Component.ErrorView(messages: ["Reviewing note is missing."]).onAppear {
                Log.model.debug("NoteView: Reviewing note is missing.")
            }
        }
    }
    private func getProgressValue(session: Session) -> CGFloat{
        let size = CGFloat(session.currentReviewingNoteList.count)
        let index = CGFloat(session.currentReviewingNoteListIndex)
        
        if size <= 0{
            return 0
        }
        return index/size
    }
    private func paneBar(session: Session) -> some View {
        return VStack {
            HStack {
                DS.Component.Button(
                    icon: "cross",
                    theme: .system(.sapphire),
                    style: .plain,
                    size: .compact
                ) {
                    session.setCurrentReviewingNoteList(to: [])
                    hideKeyboard()
                    router.navigateBack()
                }
                Spacer()
                DS.Component.Button(
                    text: "EDIT",
                    theme: .palette(.sapphire),
                    style: .plain,
                    size: .compact
                ) {
                    session.setCurrentEditingNote(to: currentReviewingNote)
                    hideKeyboard()
                    router.navigate(to: .noteEditorRoute)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }

    private func reviewBar(session: Session, currentReviewingNote: Note) -> some View {
        return VStack {
            DS.Component.HorizontalDivider()
            HStack {
                DS.Component.Button(
                    icon: "page",
                    theme: .palette(.iron),
                    style: .filled,
                    size: .compact
                ) {
                    if session != nil {
                        hideKeyboard()
                        router.navigate(to: .temporaryNoteEditorRoute)
                    } else {
                        Log.model.debug("NoteView: Session is missing.")
                    }
                }
                DS.Component.Button(
                    text: "CHECK",
                    theme: .palette(.sapphire),
                    style: .filled,
                    size: .split,
                    isSelected: isAllBlocksHidden == false
                ) {
                    withAnimation(.easeInOut){
                        isAllBlocksHidden = !isAllBlocksHidden
                    }
                }
                DS.Component.Button(
                    icon: "arrowLeft",
                    theme: .palette(.emerald),
                    style: .filled,
                    size: .compact,
                    isDisabled: session.currentReviewingNoteListIndex == 0
                ) {
                    navigationDirection = .backward
                    withAnimation(.easeInOut){
                        session.decrementCurrentReviewingNoteListIndex()
                        isAllBlocksHidden = true
                    }
                }
                DS.Component.Button(
                    icon: "arrowRight",
                    theme: .palette(.emerald),
                    style: .filled,
                    size: .compact,
                    isDisabled: session.currentReviewingNoteListIndex == session.currentReviewingNoteList.count-1
                ) {
                    navigationDirection = .forward
                    withAnimation(.easeInOut){
                        session.incrementCurrentReviewingNoteListIndex()
                        isAllBlocksHidden = true
                    }
                }
            }
        }
        .padding(.bottom)
    }
}

extension NoteView {
    private func editBarItem(
        icon: String,
        isNoteMissing: Bool,
        isKeyboardHidden: Bool = false,
        isIconColorPreserved: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        DS.Component.Button(
            icon: icon,
            theme: .system(.sapphire),
            style: .plain,
            size: .compact,
            preserveIconColor: isIconColorPreserved,
            isDisabled: isNoteMissing
        ) {
            if isKeyboardHidden { hideKeyboard() }
            action()
        }
    }

    private func toolBarItem(
        icon: String,
        palette: DS.Color.Palette,
        selectedNoteState: NoteState? = nil
    ) -> some View {
        DS.Component.Button(
            icon: icon,
            theme: .palette(palette),
            style: .plain,
            size: .compact,
            preserveIconColor: true,
            isSelected: noteState == selectedNoteState
        ) {
            hideKeyboard()
            if let selectedNoteState = selectedNoteState {
                Log.view.debug(
                    "Note state is updated to \(noteState.rawValue)."
                )
                withAnimation(DS.Animation.handleIcon) {
                    noteState =
                        noteState != selectedNoteState
                        ? selectedNoteState : .viewable
                }
            }
        }
    }
}
