import SwiftData
import SwiftUI
import os

struct GroupPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentSubject = session.currentSubject{
                VStack(spacing: 0) {
                    let orderedTagGroups = currentSubject.orderedTagGroups
                    paneBar(session: session, currentSubject: currentSubject)
                    if !orderedTagGroups.isEmpty{
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: DS.Spacing.md) {
                                ForEach(Array(orderedTagGroups.sorted { $0.order < $1.order }.enumerated()), id: \.element) { index, tagGroup in
                                    HStack {
                                        DS.Component.Header(
                                            text: tagGroup.name,
                                            subtext: "GROUP \(index+1)",
                                            theme: .palette(tagGroup.color),
                                            matchingRule: tagGroup.matchingRule
                                        ) {
                                            session.setCurrentEditingTagGroup(to: tagGroup)
                                            router.navigate(to: .groupEditorRoute)
                                        }
                                    }
                                }
                            }
                            .cancelScrollViewDelay()
                            .padding()
                        }
                    }
                    else{
                        DS.Component.SummaryView(
                            icon: "mascotWithGroups",
                            textView: Text("""
                            **No groups found.**
                            Notes can be grouped by their tags.
                            Create a new group by pressing \(Image("plus")) on the top right.
                            """)
                        )
                    }
                }
            } else {
                var messages: [String] {
                    var messages: [String] = []
                    guard let session = session else {
                        messages.append("Session is missing.")
                        return messages
                    }
                    if session.currentSubject == nil {
                        messages.append("Current subject in session is missing.")
                    }
                    return messages
                }
                DS.Component.ErrorView(messages: messages).onAppear{
                    Log.model.debug("GroupPickerView: \(messages)")
                }
            }
        }
    }
}

extension GroupPickerView {
    func paneBar(session: Session, currentSubject: Subject) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: "plus",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        let newTagGroup = session.appendTagGroup(named: "", colored: .sapphire, matchingRule: .union, for: currentSubject, in: modelContext)
                        session.setCurrentEditingTagGroup(to: newTagGroup)
                        router.navigate(to: .groupEditorRoute)
                    }
                }
                HStack {
                    Spacer()
                    Text("Groups")
                        .font(DS.Typography.bodyLarge)
                        .foregroundStyle(DS.Color.System.foreground.primary)
                    Spacer()
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }
}
