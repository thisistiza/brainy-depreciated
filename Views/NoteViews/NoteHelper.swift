import SwiftUI

enum NoteState: String {
    case editable, viewable, deletable, reorderable, hideable, none
}

enum AxisDirection {
    case forward
    case backward
}

struct BlockDropDelegate: DropDelegate {
    let item: Block
    let note: Note
    let session: Session
    let draggedBlock: Binding<Block?>

    func performDrop(info: DropInfo) -> Bool {
        draggedBlock.wrappedValue = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        let workingBlocks = note.orderedBlocks

        guard let dragged = draggedBlock.wrappedValue,
            dragged.id != item.id,
            let fromIndex = workingBlocks.firstIndex(where: {
                $0.id == dragged.id
            }),
            let toIndex = workingBlocks.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation {
            session.moveBlocks(
                in: note,
                from: IndexSet(integer: fromIndex),
                to: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

func getString(from type: BlockType) -> String {
    switch type {
    case .heading:
        return "Heading"
    case .paragraph:
        return "Paragraph"
    case .code:
        return "Code"
    case .math:
        return "Math"
    case .link:
        return "Link"
    case .image:
        return "Image"
    case .video:
        return "Video"
    case .annotation:
        return "Annotation"
    case .audio:
        return "Audio"
    case .file:
        return "File"
    case .annotatedImage:
        return "Annotated Image"
    }
}
