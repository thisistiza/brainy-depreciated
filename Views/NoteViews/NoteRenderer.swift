import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers
import os

struct NoteRenderer: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var note: Note
    var isTemporary: Bool
    var isReviewing: Bool
    @Binding var noteState: NoteState
    @Binding var isAllBlocksHidden: Bool
    @State var draggedBlock: Block? = nil
    @State var isTestedBlocksHidden: Bool = true
    @State var hiddenBlockIDs: Set<UUID> = Set()
    @State private var shakingBlockID: UUID? = nil
    @State private var shakeTrigger: Int = 0
    @State private var hiddenBlockTrigger: Int = 0

    var testedBlockIDs: Set<UUID> {
        Set(note.blocks.filter { $0.isTested }.map { $0.id })
    }

    var body: some View {
        if let session = session {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    if isTemporary {
                        temporaryTitleView().padding(.top)
                    } else {
                        titleView().padding(.top)
                        TagView(
                            note: note,
                            noteState: noteState,
                            isTagsHidden: $isAllBlocksHidden
                        )
                    }
                    blocksListView(session: session)
                        .padding(.vertical)
                        .onAppear {
                            guard isTemporary == false else { return }
                            if noteState == .hideable || noteState == .viewable
                            {
                                hiddenBlockIDs = testedBlockIDs
                                Log.view.debug(
                                    "NoteRenderer: Note renderer appeared in hidden/viewable mode: Hide all tested blocks."
                                )
                            }
                        }
                        .onChange(of: noteState, initial: true) { _, newState in
                            guard isTemporary == false else { return }
                            if newState == .hideable || newState == .viewable {
                                hiddenBlockIDs = testedBlockIDs
                                Log.view.debug(
                                    "NoteRenderer: Note state updated to hidden/viewable: Hide all tested blocks."
                                )
                            }
                        }
                        .onChange(of: isAllBlocksHidden) {
                            guard isTemporary == false else { return }
                            if isAllBlocksHidden {
                                hiddenBlockIDs = testedBlockIDs
                                Log.view.debug(
                                    "NoteRenderer: isAllBlocksHidden is set to true: Hide all tested blocks."
                                )
                            } else {
                                hiddenBlockIDs = Set()
                                Log.view.debug(
                                    "NoteRenderer: isAllBlocksHidden is set to false: Unhide all tested blocks."
                                )
                            }
                        }
                        .onChange(of: hiddenBlockIDs) {
                            guard isTemporary == false else { return }
                            if hiddenBlockIDs.isEmpty && isAllBlocksHidden {
                                isAllBlocksHidden = false
                                Log.view.debug(
                                    "NoteRenderer: All tested blocks are unhidden: Set isAllBlocksHidden to false."
                                )
                            } else if hiddenBlockIDs.count
                                == testedBlockIDs.count && !isAllBlocksHidden
                            {
                                isAllBlocksHidden = true
                                Log.view.debug(
                                    "NoteRenderer: All tested blocks are hidden: Set isAllBlocksHidden to true."
                                )
                            }
                        }
                }
            }
            .padding(.horizontal)
        } else {
            DS.Component.ErrorView(messages: ["Session is missing."]).onAppear {
                Log.model.debug("NoteRenderer: Session is missing.")
            }
        }
    }
}

extension NoteRenderer {
    func temporaryTitleView() -> some View {
        return VStack {
            HStack {
                Text("Scratchpad")
                    .font(DS.Typography.titleSmall)
                    .foregroundStyle(DS.Color.System.foreground.primary)
                Spacer()
            }
            HStack {
                Text("Draft ideas and temporary notes")
                    .font(DS.Typography.bodyLarge)
                    .foregroundStyle(DS.Color.System.foreground.secondary)
                Spacer()
            }
        }
    }

    func titleView() -> some View {
        let titlePlaceholder = "Title"
        var titleBinding: Binding<String> {
            return Binding(
                get: { note.title },
                set: { title in note.title = title }
            )
        }
        return Group {
            if noteState == .editable {
                TextField(
                    titlePlaceholder,
                    text: titleBinding,
                    prompt: Text(titlePlaceholder).foregroundStyle(
                        DS.Color.System.foreground.secondary
                    ),
                    axis: .vertical
                )
                .multilineTextAlignment(.leading)
            } else {
                HStack {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                    Spacer()
                }
            }
        }
        .font(DS.Typography.titleSmall)
        .foregroundStyle(DS.Color.System.foreground.primary)
    }

    @ViewBuilder
    func blocksListView(session: Session) -> some View {
        let orderedBlocks = note.orderedBlocks
        if !orderedBlocks.isEmpty {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.md) {
                ForEach(note.orderedBlocks, id: \.persistentModelID) { block in
                    BlockView(
                        block: block,
                        noteState: $noteState,
                        isHidden: hiddenBlockIDs.contains(block.id),
                        onCopy: {block in session.copyBlockToClipboard(block)}
                    )
                    .sensoryFeedback(.error, trigger: shakeTrigger) {
                        _,
                        newValue in
                        return shakingBlockID == block.id && newValue > 0
                    }
                    .sensoryFeedback(
                        .impact(weight: .medium),
                        trigger: hiddenBlockTrigger
                    )
                    .shake(
                        trigger: Binding(
                            get: {
                                shakingBlockID == block.id ? shakeTrigger : 0
                            },
                            set: { newValue in
                                if newValue == 0 { shakingBlockID = nil }
                                shakeTrigger = newValue
                            }
                        )
                    )
                    .onDrag {
                        guard noteState == .reorderable else {
                            return NSItemProvider()
                        }
                        self.draggedBlock = block
                        return NSItemProvider(
                            object: block.id.uuidString as NSString
                        )
                    } preview: {
                        if noteState == .reorderable {
                            HStack {
                                Image("grab")
                                Text(
                                    "\(getString(from: block.type)) Block on line \(block.order+1) grabbed."
                                )
                                .font(DS.Typography.blockLabel)
                                .foregroundStyle(
                                    DS.Color.System.foreground.secondary
                                )
                            }
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xs)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DS.Color.System.background.secondary)
                            }
                        } else {
                            Color.clear
                        }
                    }
                    .onDrop(
                        of: [.plainText],
                        delegate: BlockDropDelegate(
                            item: block,
                            note: note,
                            session: session,
                            draggedBlock: $draggedBlock
                        )
                    )
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            hiddenBlockTrigger += 1
                            switch noteState {
                            case .viewable:
                                guard isTemporary == false else { return }
                                if block.isTested {
                                    if hiddenBlockIDs.contains(block.id) {
                                        hiddenBlockIDs.remove(block.id)
                                    } else {
                                        hiddenBlockIDs.insert(block.id)
                                    }
                                } else {
                                    shakingBlockID = block.id
                                    shakeTrigger += 1
                                }
                            case .deletable:
                                session.delete(block: block, in: modelContext)

                            case .hideable:
                                block.isTested.toggle()

                                if block.isTested {
                                    hiddenBlockIDs.insert(block.id)
                                } else {
                                    hiddenBlockIDs.remove(block.id)
                                }
                            default:
                                break
                            }
                        }
                    )
                }
            }
            .padding(.bottom, DS.Spacing.lg)
            .animation(
                .interactiveSpring(response: 0.3, dampingFraction: 0.8),
                value: note.orderedBlocks
            )
        } else {
            if isReviewing{
                DS.Component.SummaryView(
                    icon: "mascotWithPen",
                    textView: Text("""
                        **Note is empty.**
                        Press 'EDIT' on the top right to add content.
                        """
                    )
                )
            }
            else{
                if noteState == .editable{
                    DS.Component.SummaryView(
                        icon: "",
                        textView: Text("""
                        **Note is empty.**
                        Start adding blocks using the bottom toolbar:
                        
                        \(Image("heading")) **Heading:** Add heading.
                        \(Image("paragraph")) **Paragraph:** Add paragraph.
                        \(Image("terminal")) **Code:** Add code snippets for programming languages.
                        \(Image("equation")) **Math:** Add equations in LATEX.
                        \(Image("picture")) **Image:** Add image to annotate over.
                        \(Image("pen")) **Drawing:** Add drawing.
                        \(Image("clipboard")) **Paste:** Paste blocks you copied using \(Image("duplicateBoxed")) beside each block.
                        
                        Categorize notes using the top tag field:
                        \(Image("tagBoxed")) **Tag:** Edit and manage tags for this note.
                        """)
                    )
                }
                else{
                    DS.Component.SummaryView(
                        icon: "",
                        textView: Text("""
                        **Note is empty.**
                        Start creating using the top-right editbar:
                        
                        \(Image("draft")) **Add Blocks:** Create a new paragraph, image, or more.
                        \(Image("eyeOpened")) **Hide Blocks:** Hide blocks to test your memory.
                        \(Image("slide")) **Reorder Blocks:** Drag and rearrange blocks.
                        \(Image("trash")) **Delete Blocks:** Remove blocks.
                        \(Image("dotsBoxed")) **More Options:** Duplicate, delete and start a new note.
                        """)
                    )
                }
            }
        }
    }
}
