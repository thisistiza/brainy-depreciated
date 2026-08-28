import SwiftUI
import SwiftData
import os

struct NoteListView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) var modelContext
    @Query private var sessions: [Session]
    @State private var isTagHidden = false

    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentSubject = session.currentSubject {
                let tagGroups = currentSubject.tagGroups.sorted { $0.order < $1.order }
                
                VStack(spacing: 0) {
                    paneBar(session: session)
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DS.Spacing.md, pinnedViews: [.sectionHeaders]) {
                            if currentSubject.notes.isEmpty {
                                emptyStateView()
                            } else if !tagGroups.isEmpty {
                                ForEach(Array(tagGroups.enumerated()), id: \.element.id) { index, tagGroup in
                                    let groupNotes = session.filterNotes(for: tagGroup)
                                    Section(header: stickyHeader(session: session, tagGroup: tagGroup, index: index + 1, notes: groupNotes)) {
                                        GroupListView(
                                            session: session,
                                            isTagHidden: isTagHidden,
                                            isReviewable: false,
                                            notes: groupNotes,
                                            tagGroup: tagGroup,
                                            color: tagGroup.color,
                                            isRated: true,
                                            isCharged: true
                                        )
                                    }
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

    private func stickyHeader(session: Session, tagGroup: TagGroup, index: Int, notes: [Note]) -> some View {
        let headerMaxWidth: CGFloat = 360
        let blockHeight: CGFloat = 33

        return ZStack(alignment: .top) {
            let averageMaturity = session.currentReviewingNoteList.averageMaturity
            let averageRetrievalStrength = session.currentReviewingNoteList.averageRetrievalStrength
            Rectangle()
                .foregroundStyle(DS.Color.System.background.primary)
                .frame(maxWidth: headerMaxWidth)
                .frame(height: blockHeight)
            DS.Component.Header(
                text: tagGroup.name,
                subtext: "\(notes.count) Notes",
                theme: .palette(tagGroup.color),
                rating: averageMaturity != 0 ?  averageMaturity : nil,
                charge: averageRetrievalStrength != 0 ? averageRetrievalStrength : nil,
                matchingRule: tagGroup.matchingRule
            ) {
                session.setCurrentReviewingNoteList(to: notes)
                session.setCurrentReviewingNoteListIndex(to: 0)
                router.navigate(to: .noteRoute)
            }
            .padding()
        }
        .padding(.bottom, DS.Spacing.sm)
    }

    private func emptyStateView() -> some View {
        DS.Component.SummaryView(
            icon: "mascotWithCard",
            textView: Text("**No Notes created.**\nAll your notes for this subject will show up here.")
        )
    }
}

extension NoteListView {
    private func paneBar(session: Session) -> some View {
        ZStack {
            VStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact
                    ) {
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
                    DS.Component.Button(
                        icon: "rectanglesBoxed",
                        theme: .palette(.sapphire),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true
                    ) {
                        router.navigate(to: .groupPickerRoute)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                DS.Component.HorizontalDivider()
            }
            HStack {
                Spacer()
                Text("Notes")
                    .font(DS.Typography.bodyLarge)
                    .foregroundStyle(DS.Color.System.foreground.primary)
                    .padding(.bottom)
                Spacer()
            }
        }
    }
}
