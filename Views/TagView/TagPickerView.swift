import SwiftData
import SwiftUI
import os

struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentSubject = session.currentSubject, let currentEditingNote = session.currentEditingNote {
                VStack(spacing: 0) {
                    paneBar(session: session, currentEditingNote: currentEditingNote)
                    let orderedTags = currentSubject.tags.sorted { $0.createdAt > $1.createdAt }
                    if !orderedTags.isEmpty{
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: DS.Spacing.md) {
                                ForEach(orderedTags) { tag in
                                    HStack {
                                        let isTagSelected = currentEditingNote.tags.contains(tag)
                                        DS.Component.Button(
                                            icon: "tag",
                                            text: tag.name,
                                            theme: .systemWithIconColorAsPalette(tag.color),
                                            style: .hollow,
                                            size: .fitWithCompact,
                                            alignment: .leading,
                                            isSelected: isTagSelected
                                        ) {
                                            if isTagSelected {
                                                session.delete(tag: tag, from: currentEditingNote, in: modelContext)
                                            } else {
                                                session.appendTag(
                                                    existingTag: tag,
                                                    to: currentEditingNote,
                                                    in: modelContext
                                                )
                                            }
                                        }
                                        
                                        DS.Component.Button(
                                            icon: "slidersMono",
                                            theme: .system(tag.color),
                                            style: .hollow,
                                            size: .compact
                                        ) {
                                            session.setCurrentEditingTag(to: tag)
                                            router.navigate(to: .tagEditorRoute)
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
                            icon: "mascotWithTag",
                            textView: Text("""
                            **No tags created.**
                            Tags help you group your notes by different categories.
                            Create a new tag by pressing \(Image("plus")) on the top right.
                            """)
                        )
                    }
                }
            }
            else{
                var messages: [String] {
                    var messages: [String] = []
                    guard let session = session else {
                        messages.append("Session is missing.")
                        return messages
                    }
                    if session.currentSubject == nil {
                        messages.append("Current subject in session is missing.")
                    }
                    if session.currentEditingTag == nil {
                        messages.append("Current editing tag in session is missing.")
                    }
                    return messages
                }
                DS.Component.ErrorView(messages: messages).onAppear{
                    Log.model.debug("TagPickerView: \(messages)")
                }
            }
        }
    }
}

extension TagPickerView {
    func paneBar(session: Session, currentEditingNote: Note) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        session.setCurrentEditingTag(to: nil)
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: "plus",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        let newTag = session.appendTag(named: "", colored: .sapphire, to: currentEditingNote, in: modelContext)
                        session.setCurrentEditingTag(to: newTag)
                        router.navigate(to: .tagEditorRoute)
                    }
                }
                HStack {
                    Spacer()
                    Text("Tags")
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
