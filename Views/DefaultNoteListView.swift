//import SwiftUI
//import SwiftData
//
//struct NoteListView: View {
//    @Environment(Router.self) private var router
//    @Query private var sessions: [Session]
//    @State private var isTagHidden = false
//    var session: Session? {
//        sessions.sorted { $0.createdAt > $1.createdAt }.first
//    }
//
//    var body: some View {
//        DS.Component.ContentContainer {
//            if let session = session, let currentSubject = session.currentSubject {
//                let tagGroups = currentSubject.tagGroups.sorted { $0.order < $1.order }
//                
//                VStack(spacing: 0) {
//                    paneBar()
//                    
//                    ScrollView(showsIndicators: false) {
//                        LazyVStack(spacing: DS.Spacing.lg, pinnedViews: [.sectionHeaders]) {
//                            if currentSubject.notes.isEmpty {
//                                emptyStateView()
//                            } else if !tagGroups.isEmpty {
//                                ForEach(Array(tagGroups.enumerated()), id: \.element.id) { index, tagGroup in
//                                    Section(header: stickyHeader(session: session, tagGroup: tagGroup, index: index+1)) {
//                                        GroupListView(
//                                            session: session,
//                                            isTagHidden: isTagHidden,
//                                            tagGroup: tagGroup
//                                        )
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.bottom, DS.Spacing.lg)
//                    }.cancelScrollViewDelay()
//                }
//            }
//        }
//    }
//
//    private func stickyHeader(session: Session, tagGroup: TagGroup, index: Int) -> some View {
//        let headerMaxWidth: CGFloat = 360
//        let blockHeight: CGFloat = 33
//        return ZStack(alignment: .top) {
//            Rectangle()  // block elements behind the space above header
//                .foregroundStyle(DS.Color.System.background.primary)
//                .frame(maxWidth: headerMaxWidth)
//                .frame(height: blockHeight)
//            DS.Component.Header(
//                text: tagGroup.name,
//                subtext: "Group \(index)",
//                theme: .palette(tagGroup.color),
//                rating: 2.5,
//                charge: 0.6,
//                matchingRule: tagGroup.matchingRule
//            ) {
//                session.setCurrentReviewingNoteList(to: session.filterNotes(for: tagGroup))
//                session.setCurrentReviewingNoteListIndex(to: 0)
//                router.navigate(to: .noteRoute)
//            }.padding()
//        }
//    }
//
//    private func emptyStateView() -> some View {
//        DS.Component.SummaryView(
//            icon: "mascotWithCard",
//            textView: Text("**No Notes created.**\nAll your notes for this subject will show up here.")
//        )
//    }
//}
//
//extension NoteListView {
//    private func paneBar() -> some View {
//        ZStack {
//            VStack {
//                HStack {
//                    DS.Component.Button(
//                        icon: "cross",
//                        theme: .system(.sapphire),
//                        style: .plain,
//                        size: .compact
//                    ) {
//                        router.navigateBack()
//                    }
//                    Spacer()
//                    DS.Component.Button(
//                        icon: isTagHidden ? "eyeClosed" : "eyeOpened",
//                        theme: .system(.emerald),
//                        style: .plain,
//                        size: .compact
//                    ) {
//                        withAnimation {
//                            isTagHidden = !isTagHidden
//                        }
//                    }
//                    DS.Component.Button(
//                        icon: "rectanglesBoxed",
//                        theme: .palette(.sapphire),
//                        style: .plain,
//                        size: .compact,
//                        preserveIconColor: true
//                    ) {
//                        router.navigate(to: .groupPickerRoute)
//                    }
//                }
//                .padding(.horizontal, DS.Spacing.md)
//                DS.Component.HorizontalDivider()
//            }
//            HStack {
//                Spacer()
//                Text("All Notes")
//                    .font(DS.Typography.bodyLarge)
//                    .foregroundStyle(DS.Color.System.foreground.primary)
//                    .padding(.bottom)
//                Spacer()
//            }
//        }
//    }
//}
//
//struct GroupListView: View {
//    let session: Session
//    let isTagHidden: Bool
//    let tagGroup: TagGroup
//
//    @Environment(\.modelContext) private var modelContext
//    @Environment(Router.self) private var router
//
//    @State private var loadedNotes: [Note] = []
//    @State private var orderedNotes: [Note]? = nil
//    @State private var currentOffset: Int = 0
//    @State private var canLoadMore: Bool = true
//    @State private var isLoading: Bool = false
//
//    private let pageSize = 15
//    private let headerMaxWidth: CGFloat = 360
//
//    var body: some View {
//        VStack(spacing: DS.Spacing.md) {
//            LazyVStack(spacing: DS.Spacing.md) {
//                ForEach(Array(loadedNotes.enumerated()), id: \.element.id) { index, note in
//                    HStack(alignment: .top) {
//                        DS.Component.Tile(
//                            text: note.title.isEmpty
//                                ? "Untitled" : note.title,
//                            subtext: "\(tagGroup.order+1).\(index+1)",
//
//                            tags: isTagHidden ? nil : note.tags,
//                            theme: .palette(tagGroup.color),
//                            rating: 2.0,
//                            charge: 0.6
//                        ) {
//                            session.setCurrentReviewingNoteList(to: session.filterNotes(for: tagGroup))
//                            session.setCurrentReviewingNoteListIndex(to: index)
//                            router.navigate(to: .noteRoute)
//                        }
//                        Spacer()
//                    }
//                    .frame(maxWidth: headerMaxWidth - DS.Spacing.lg)
//                    .onAppear {
//                        if index == loadedNotes.count - 1 {
//                            loadNextBatch()
//                        }
//                    }
//                }
//                
//                if isLoading {
//                    ProgressView()
//                        .padding(.vertical, DS.Spacing.sm)
//                }
//            }
//        }
//        .onAppear {
//            attemptLoad()
//        }
//    }
//
//    private func attemptLoad() {
//        if loadedNotes.isEmpty && canLoadMore {
//            loadNextBatch()
//        }
//    }
//
//    private func loadNextBatch() {
//        guard canLoadMore, !isLoading else { return }
//        isLoading = true
//
//        // 1. Calculate ordered Notes only if not already cached
//        let allNotes: [Note]
//        if let existingNotes = orderedNotes {
//            allNotes = existingNotes
//        } else {
//            let computedNotes = session.filterNotes(for: tagGroup)
//            orderedNotes = computedNotes
//            allNotes = computedNotes
//        }
//
//        guard !allNotes.isEmpty else {
//            completeGroup()
//            return
//        }
//
//        // 2. Slice the cached ordered Notes for the current page
//        let startIndex = currentOffset
//        let endIndex = min(startIndex + pageSize, allNotes.count)
//
//        guard startIndex < allNotes.count else {
//            completeGroup()
//            return
//        }
//
//        let pageNotes = Array(allNotes[startIndex..<endIndex])
//
//        // 3. Append loadedNotes directly
//        loadedNotes.append(contentsOf: pageNotes)
//        currentOffset = endIndex
//
//        if endIndex >= allNotes.count {
//            completeGroup()
//        }
//
//        isLoading = false
//    }
//
//    private func completeGroup() {
//        canLoadMore = false
//        isLoading = false
//    }
//}
