import SwiftData
import SwiftUI
import os

struct TagEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    @State private var newTagName: String = ""

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session,
                let currentSubject = session.currentSubject,
                let currentEditingTag = session.currentEditingTag
            {
                VStack(spacing: DS.Spacing.md) {
                    paneBar(session: session, currentSubject: currentSubject, currentEditingTag: currentEditingTag)
                    DS.Component.TextField(
                        text: $newTagName,
                        placeholder: "Enter tag name..."
                    )
                    paletteSelectorView(for: currentEditingTag)
                    Spacer()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onAppear {
                    if let tag = session.currentEditingTag {
                        newTagName = tag.name
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
                    if session.currentEditingTag == nil {
                        messages.append("Current editing tag in session is missing.")
                    }
                    return messages
                }
                DS.Component.ErrorView(messages: messages).onAppear{
                    Log.model.debug("TagEditorView: \(messages)")
                }
            }
        }
    }
}

extension TagEditorView {
    func paneBar(
        session: Session,
        currentSubject: Subject,
        currentEditingTag: Tag,
    ) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        guard !newTagName.isEmpty else{
                            session.setCurrentEditingTag(to: nil)
                            session.delete(tag: currentEditingTag, from: currentSubject, in: modelContext)
                            router.navigateBack()
                            return
                        }
                        session.update(tag: currentEditingTag, for: currentSubject, name: newTagName, in: modelContext)
                        session.setCurrentEditingTag(to: nil)
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: "trash",
                        theme: .palette(.ruby),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true
                    ) {
                        session.setCurrentEditingTag(to: nil)
                        session.delete(tag: currentEditingTag, from: currentSubject, in: modelContext)
                        router.navigateBack()
                    }
                }
                HStack {
                    Spacer()
                    Text("Edit Tag")
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

extension TagEditorView {
    private func paletteSelectorView(for tag: Tag) -> some View {
        return HStack {
            ForEach(DS.Color.Palette.allCases, id: \.self) { palette in
                DS.Component.Button(
                    icon: "tag",
                    theme: .systemWithIconColorAsPalette(palette),
                    style: .hollow,
                    size: .compact,
                    isSelected: palette == tag.color
                ) {
                    tag.color = palette
                }
            }
        }
    }
}
