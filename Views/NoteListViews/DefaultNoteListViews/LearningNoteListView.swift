import SwiftData
import SwiftUI

struct LearningNoteListView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) var modelContext
    @Query private var sessions: [Session]
    @State private var isTagHidden = true

    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session,
                let currentSubject = session.currentSubject
            {
                let learnNotes = session.filterLearnNotes(from: currentSubject.notes, in: currentSubject)

                VStack(spacing: 0) {
                    paneBar(session: session)
                    ScrollView(showsIndicators: false) {
                        LazyVStack(
                            spacing: DS.Spacing.md,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            if learnNotes.isEmpty {
                                emptyStateView()
                            } else {
                                Section(
                                    header: stickyHeader(
                                        session: session,
                                        notes: learnNotes
                                    )
                                ) {
                                    GroupListView(
                                        session: session,
                                        isTagHidden: isTagHidden,
                                        isReviewable: true,
                                        notes: learnNotes,
                                        tagGroup: nil,
                                        color: .amethyst,
                                        isRated: false,
                                        isCharged: false
                                    )
                                }
                            }
                        }
                        .padding(.bottom, DS.Spacing.lg)
                        .cancelScrollViewDelay()
                    }
                }
            }
        }
    }

    private func stickyHeader(session: Session, notes: [Note]) -> some View {
        let headerMaxWidth: CGFloat = 360
        let blockHeight: CGFloat = 33
        return ZStack(alignment: .top) {
            Rectangle()
                .foregroundStyle(DS.Color.System.background.primary)
                .frame(maxWidth: headerMaxWidth)
                .frame(height: blockHeight)

            DS.Component.Header(
                text: "Learning Notes",
                subtext: "\(notes.count) Notes",
                theme: .palette(.amethyst)
            ) {
                session.setCurrentReviewingNoteList(to: notes)
                session.setCurrentReviewingNoteListIndex(to: 0)
                router.navigate(to: .noteReviewerRoute)
            }
            .padding()
        }
        .padding(.bottom, DS.Spacing.sm)
    }

    private func emptyStateView() -> some View {
        DS.Component.SummaryView(
            icon: "mascotWithCard",
            textView: Text(
                "**No New Notes.**\nYou have caught up on all new notes for this subject."
            )
        )
    }
}

extension LearningNoteListView {
    private func paneBar(session: Session) -> some View {
        ZStack {
            VStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.amethyst),
                        style: .plain,
                        size: .compact
                    ) {
                        session.scheduleNotesReviewed(in: modelContext)
                        session.resetNotesReviewed()
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: isTagHidden ? "eyeClosed" : "eyeOpened",
                        theme: .system(.emerald),
                        style: .plain,
                        size: .compact
                    ) {
                        isTagHidden = !isTagHidden
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                DS.Component.HorizontalDivider()
            }
            HStack {
                Spacer()
                Text("Learning Notes")
                    .font(DS.Typography.bodyLarge)
                    .foregroundStyle(DS.Color.System.foreground.primary)
                    .padding(.bottom)
                Spacer()
            }
        }
    }
}
