import SwiftData
import SwiftUI
import os

struct GroupEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    @State var selectedMatchingRule: TagMatchingRule? = nil

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session,
                let currentSubject = session.currentSubject,
                let currentEditingTagGroup = session.currentEditingTagGroup
            {
                VStack(spacing: 0) {
                    paneBar(
                        session: session,
                        currentSubject: currentSubject,
                        currentEditingTagGroup: currentEditingTagGroup
                    )
                    paletteSelectorView(for: currentEditingTagGroup)
                        .padding()
                    let orderedTags = currentSubject.tags.sorted {$0.createdAt > $1.createdAt}
                    let matchingRule = currentEditingTagGroup.matchingRule
                    if !orderedTags.isEmpty {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: DS.Spacing.md) {
                                VStack {
                                    matchingRuleButton(icon: "circleSmall", text: "Every Note", matchingRule: .universal, tagGroup: currentEditingTagGroup)
                                    matchingRuleButton(icon: "vennDiagramComplement", text: "Notes Without Tags", matchingRule: .complement, tagGroup: currentEditingTagGroup)
                                    matchingRuleButton(icon: "vennDiagramUnion", text: "Notes with Any Selected Tag", matchingRule: .union, tagGroup: currentEditingTagGroup)
                                    matchingRuleButton(icon: "vennDiagramIntersection", text: "Notes with Every Selected Tags", matchingRule: .intersection, tagGroup: currentEditingTagGroup)
                                    matchingRuleButton(icon: "vennDiagramSubset", text: "Notes with Only Selected Tags", matchingRule: .subset, tagGroup: currentEditingTagGroup)
                                }
                                ForEach(orderedTags) { tag in
                                    HStack {
                                        let index = currentEditingTagGroup.tags.firstIndex(of: tag)
                                        let isTagSelected = index == nil ? false : true

                                        DS.Component.Button(
                                            icon: "tag",
                                            text: tag.name,
//                                            subtext: index == nil ? "" : "\(index! + 1)",
                                            theme:.systemWithIconColorAsPalette(tag.color),
                                            style: .hollow,
                                            size: .fitWithCompact,
                                            alignment: .leading,
                                            isSelected: isTagSelected
                                        ) {
                                            if isTagSelected {
                                                session.delete(
                                                    tag: tag,
                                                    from:
                                                        currentEditingTagGroup,
                                                    in: modelContext
                                                )
                                            } else {
                                                session.appendTag(
                                                    existingTag: tag,
                                                    to: currentEditingTagGroup,
                                                    for: currentSubject,
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
                                            session.setCurrentEditingTag(
                                                to: tag
                                            )
                                            router.navigate(to: .tagEditorRoute)
                                        }
                                    }
                                }
                            }
                            .cancelScrollViewDelay()
                            .padding()
                            .onAppear{
                                selectedMatchingRule = matchingRule
                            }
                        }
                    } else {
                        let matchingRule = currentEditingTagGroup.matchingRule
                        VStack {
                            matchingRuleButton(icon: "circleSmall", text: "Every Note", matchingRule: .universal, tagGroup: currentEditingTagGroup)
                            matchingRuleButton(icon: "vennDiagramComplement", text: "Notes Without Tags", matchingRule: .complement, tagGroup: currentEditingTagGroup)
                        }
                        DS.Component.SummaryView(
                            icon: "mascotWithTag",
                            textView: Text(
                                """
                                **No tags created.**
                                Tags help you group your notes by different categories.
                                Create a new tag by pressing \(Image("plus")) on the top right.
                                """
                            )
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
                        messages.append(
                            "Current subject in session is missing."
                        )
                    }
                    if session.currentEditingTag == nil {
                        messages.append(
                            "Current editing tag in session is missing."
                        )
                    }
                    return messages
                }
                DS.Component.ErrorView(messages: messages).onAppear {
                    Log.model.debug("GroupEditorView: \(messages)")
                }
            }
        }
    }
}

extension GroupEditorView {
    func paneBar(
        session: Session,
        currentSubject: Subject,
        currentEditingTagGroup: TagGroup,
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
                        let isMatchRuleWithNoTagsRequired = selectedMatchingRule == .universal || selectedMatchingRule == .complement
                        let isValid = isMatchRuleWithNoTagsRequired || (!isMatchRuleWithNoTagsRequired && !currentEditingTagGroup.tags.isEmpty)
                        guard let selectedMatchingRule = selectedMatchingRule, isValid else {
                            session.setCurrentEditingTagGroup(to: nil)
                            session.delete(tagGroup: currentEditingTagGroup, in: modelContext)
                            router.navigateBack()
                            return
                        }
                        var name: String{
                            switch selectedMatchingRule{
                            case .universal: "All Notes"
                            case .complement: "Untagged"
                            default: stringifyTags(for: currentEditingTagGroup.tags)
                            }
                        }
                        
                        session.update(
                            tagGroup: currentEditingTagGroup,
                            for: currentSubject,
                            name: name,
                            matchingRule: selectedMatchingRule,
                            in: modelContext
                        )
                        session.reorderTagGroups(for: currentSubject)
                        session.setCurrentEditingTagGroup(to: nil)
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
                        session.delete(
                            tagGroup: currentEditingTagGroup,
                            in: modelContext
                        )
                        router.navigateBack()
                    }
                    DS.Component.Button(
                        icon: "plus",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact
                    ) {
                        let newTag = session.appendTag(
                            named: "",
                            colored: .sapphire,
                            to: currentSubject,
                            in: modelContext
                        )
                        session.setCurrentEditingTag(to: newTag)
                        router.navigate(to: .tagEditorRoute)
                    }
                }
                HStack {
                    Spacer()
                    Text("Edit Group")
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

extension GroupEditorView {
    private func paletteSelectorView(for tagGroup: TagGroup) -> some View {
        return HStack {
            ForEach(DS.Color.Palette.allCases, id: \.self) { palette in
                DS.Component.Button(
                    icon: "rectanglesBoxedMono",
                    theme: .systemWithIconColorAsPalette(palette),
                    style: .hollow,
                    size: .compact,
                    isSelected: palette == tagGroup.color
                ) {
                    tagGroup.color = palette
                }
            }
        }
    }
    private func matchingRuleButton(icon: String, text: String, matchingRule: TagMatchingRule, tagGroup: TagGroup) -> some View {
        DS.Component.Button(
            icon: icon,
            text: text,
            theme: .system(.sapphire),
            style: .hollow,
            size: .standard,
            alignment: .leading,
            isSelected: selectedMatchingRule == matchingRule
        ) {
            selectedMatchingRule = matchingRule
        }
    }
}
