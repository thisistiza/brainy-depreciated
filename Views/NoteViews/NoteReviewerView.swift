import SwiftData
import SwiftUI
import os

struct NoteReviewerView: View {
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
    @State private var noteState: NoteState = .viewable
    @State private var isAllBlocksHidden: Bool = true
    @State private var isPass: Bool? = nil
    @State private var navigationDirection: AxisDirection = .forward

    private func updateReviewState(for note: Note) {
        isPass = session?.isNotePassing(id: note.id)
        isAllBlocksHidden = isPass == nil
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session,
                let currentReviewingNote = currentReviewingNote
            {
                VStack(spacing: 0) {
                    paneBar(session: session)
                    noteContentView()
                    reviewBar(
                        session: session,
                        currentReviewingNote: currentReviewingNote
                    )
                    .background(DS.Color.System.background.primary)
                }
                .task(id: currentReviewingNote) {
                    do {
                        try await Task.sleep(for: .seconds(0.3))
                        updateReviewState(for: currentReviewingNote)
                    } catch {
                    }
                }
                .onChange(of: isPass) {
                    if session.isAllNotesReviewed() {
                        session.scheduleNotesReviewed(in: modelContext)
                        session.resetNotesReviewed()
                        router.navigate(to: .dashboardRoute)
                    }
                }
            } else {
                DS.Component.ErrorView(messages: ["Session is missing."])
                    .onAppear {
                        Log.model.debug("NoteReviewerView: Session is missing.")
                        //TODO
                    }
            }
        }
    }
}

extension NoteReviewerView {
    @ViewBuilder
    private func noteContentView() -> some View {
        if let currentReviewingNote = currentReviewingNote {
            ZStack {
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
                        insertion: .move(
                            edge: navigationDirection == .forward
                                ? .trailing : .leading
                        ).combined(with: .opacity),
                        removal: .move(
                            edge: navigationDirection == .forward
                                ? .leading : .trailing
                        ).combined(with: .opacity)
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            DS.Component.ErrorView(messages: ["Reviewing note is missing."])
                .onAppear {
                    Log.model.debug(
                        "NoteReviewerView: Reviewing note is missing."
                    )
                }
        }
    }

    private func getProgressValue(session: Session) -> CGFloat {
        guard !session.currentReviewingNoteList.isEmpty else { return 0 }
        let count = CGFloat(session.currentReviewingNoteList.count)
        let index = CGFloat(session.currentReviewingNoteListIndex + 1)
        return min(max(index / count, 0.0), 1.0)
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
                DS.Component.ProgressBar(
                    progress: getProgressValue(session: session)
                )
                DS.Component.Button(
                    text: "BACK",
                    theme: .palette(.sapphire),
                    style: .plain,
                    size: .compact
                ) {
                    navigationDirection = .backward
                    withAnimation(.easeInOut) {
                        session.decrementCurrentReviewingNoteListIndex()
                    }
                }
                DS.Component.Button(
                    text: "NEXT",
                    theme: .palette(.sapphire),
                    style: .plain,
                    size: .compact
                ) {
                    navigationDirection = .forward
                    withAnimation(.easeInOut) {
                        session.incrementCurrentReviewingNoteListIndex()
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }

    private func reviewBar(session: Session, currentReviewingNote: Note)
        -> some View
    {
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
                        Log.model.debug("NoteReviewerView: Session is missing.")
                    }
                }
                DS.Component.Button(
                    text: "CHECK",
                    theme: .palette(.sapphire),
                    style: .filled,
                    size: .split,
                    isSelected: isAllBlocksHidden == false
                ) {
                    isPass = nil
                    withAnimation(.easeInOut) {
                        //session.undoLastReview(note: currentReviewingNote)
                        session.updateNotesReviewed(
                            id: currentReviewingNote.id,
                            isPass: isPass
                        )
                        isAllBlocksHidden = !isAllBlocksHidden
                    }
                }
                DS.Component.Button(
                    icon: "crossCircled",
                    theme: .system(.ruby),
                    style: .hollow,
                    size: .compact,
                    preserveIconColor: true,
                    isDisabled: isAllBlocksHidden == true,
                    isSelected: isPass == false,
                ) {
                    if isPass != false {
                        withAnimation(.easeInOut) {
                            isPass = false
                            navigationDirection = .forward
                            // session.schedule(note: currentReviewingNote, isPass: isPass ?? false)
                            session.updateNotesReviewed(
                                id: currentReviewingNote.id,
                                isPass: isPass
                            )
                            session.incrementCurrentReviewingNoteListIndex()
                        }
                    } else {
                        isPass = nil
                        //session.undoLastReview(note: currentReviewingNote)
                        session.updateNotesReviewed(
                            id: currentReviewingNote.id,
                            isPass: isPass
                        )
                    }
                }
                DS.Component.Button(
                    icon: "checkCircled",
                    theme: .system(.emerald),
                    style: .hollow,
                    size: .compact,
                    preserveIconColor: true,
                    isDisabled: isAllBlocksHidden == true,
                    isSelected: isPass == true,
                ) {
                    if isPass != true {
                        withAnimation(.easeInOut) {
                            isPass = true
                            navigationDirection = .forward
                            // session.schedule(note: currentReviewingNote, isPass: isPass ?? true)
                            session.updateNotesReviewed(
                                id: currentReviewingNote.id,
                                isPass: isPass
                            )
                            session.incrementCurrentReviewingNoteListIndex()
                        }
                    } else {
                        isPass = nil
                        //session.undoLastReview(note: currentReviewingNote)
                        session.updateNotesReviewed(
                            id: currentReviewingNote.id,
                            isPass: isPass
                        )
                    }
                }
            }
        }
        .padding(.bottom)
    }
}

extension NoteReviewerView {
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
