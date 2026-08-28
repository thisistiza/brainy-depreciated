import PencilKit
import SwiftUI
import SwiftData

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct BlockView: View {
    var block: Block
    @Binding var noteState: NoteState
    let isHidden: Bool
    let onCopy: (Block) -> Void
    @State private var activeHeight: CGFloat = 0
    @State private var handleIconTrigger: Int = 0
    private var isBlockValid: Bool {
        block.modelContext != nil
    }

    var body: some View {
        if isBlockValid {
            let isHidable =
            isHidden && (noteState == .viewable || noteState == .hideable)
            let isCanvas =
            block.type == .image || block.type == .annotation
            || block.type == .annotatedImage
            HStack(alignment: .top) {
                handleIcon
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .sensoryFeedback(
                        .impact(weight: .medium),
                        trigger: handleIconTrigger
                    )
                    .shake(trigger: $handleIconTrigger)
                ZStack(alignment: .topLeading) {
                    activeBlockView
                        .opacity(isHidable ? 0 : 1)
                        .background(
                            GeometryReader { geometry in
                                DS.Color.System.background.primary
                                    .preference(
                                        key: ViewHeightKey.self,
                                        value: geometry.size.height
                                    )
                            }
                        )
                    
                    if isHidable && isCanvas {
                        testedCanvasSkeletonView
                            .transition(.scaleAndFade)
                    } else if isHidable {
                        testedSkeletonView
                            .transition(.scaleAndFade)
                    }
                }
                .onPreferenceChange(ViewHeightKey.self) { newHeight in
                    activeHeight = newHeight
                }
                .animation(.interactiveSpring(duration: 0.25), value: isHidden)
                .animation(
                    .interactiveSpring(response: 0.25, dampingFraction: 0.75),
                    value: noteState
                )
            }
        }
        else{
            EmptyView()
        }
    }
}

extension BlockView {
    @ViewBuilder
    private var handleIcon: some View {
        switch noteState {
        case .deletable: Image("trash").jiggle(enabled: true)
        case .hideable:
            Image(block.isTested ? "eyeClosed" : "eyeOpened").jiggle(
                enabled: true
            )
        case .reorderable: Image("slide").jiggle(enabled: true)
        case .editable:
            Image("duplicateBoxed").onTapGesture {
                handleIconTrigger += 1
                onCopy(block)
            }
        case .viewable:
            block.isTested
                ? Image("duplicateBoxedAlt").onTapGesture {
                    handleIconTrigger += 1
                    onCopy(block)
                }
                : Image("duplicateBoxedMuted").onTapGesture {
                    handleIconTrigger += 1
                    onCopy(block)
                }
        case .none: EmptyView()
        }
    }

    private var testedSkeletonView: some View {
        let barHeight: CGFloat = DS.Spacing.md
        let spacing: CGFloat = DS.Spacing.sm
        let rawCount = (activeHeight + spacing) / (barHeight + spacing)
        let numberOfLines = max(1, Int(rawCount))

        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<numberOfLines, id: \.self) { index in
                RoundedRectangle(cornerRadius: DS.Spacing.sm)
                    .fill(DS.Color.System.foreground.secondary)
                    .frame(height: barHeight)
                    .frame(
                        maxWidth: (index % 4 == 0 && numberOfLines > 1)
                            ? 150 : .infinity
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }

    private var testedCanvasSkeletonView: some View {
        return ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: DS.Spacing.md)
                .fill(DS.Color.System.foreground.secondary)
                .frame(maxWidth: .infinity, maxHeight: activeHeight)
        }
    }

    @ViewBuilder
    private var activeBlockView: some View {
        switch block.type {
        case .heading:
            HeadingBlockView(block: block, isEditable: noteState == .editable)
        case .paragraph:
            ParagraphBlockView(block: block, isEditable: noteState == .editable)
        case .image:
            EmptyView()  // unimplemented because all images default to annotatedIamge
        case .annotation:
            CanvasBlockView(block: block, isEditable: noteState == .editable)
        case .math:
            MathBlockView(block: block, isEditable: noteState == .editable)
        case .code:
            CodeBlockView(block: block, isEditable: noteState == .editable)
        case .annotatedImage:
            CanvasBlockView(block: block, isEditable: noteState == .editable)
        default:
            EmptyView()
        }
    }
}
