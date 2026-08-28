import SwiftUI
import PencilKit

enum canvasHistoryAction {
    case undo
    case redo
}

struct CanvasEditor: UIViewRepresentable {
    @Binding var annotation: PKDrawing?
    let image: UIImage
    var activeTool: CanvasTool
    var toolSize: CanvasToolSize
    var toolColor: ToolColor
    @Binding var action: canvasHistoryAction?

    func makeUIView(context: Context) -> CanvasResponsiveView {
        let canvas = CanvasResponsiveView()
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvas.backgroundImage = image
        canvas.drawing = annotation ?? PKDrawing()
        return canvas
    }

    func updateUIView(_ uiView: CanvasResponsiveView, context: Context) {
        let uiColor = UIColor(toolColor.color)
        let referenceWidth: CGFloat = 1000.0
        let imageScale = image.size.width / referenceWidth
        let scaledWidth = CGFloat(toolSize.rawValue) * imageScale

        switch activeTool {
        case .pen:
            uiView.tool = PKInkingTool(
                .monoline,
                color: uiColor,
                width: scaledWidth
            )
        case .eraser:
            uiView.tool = PKEraserTool(
                .bitmap,
                width: scaledWidth
            )
        }

        if !context.coordinator.isUpdatingFromCanvas {
            let currentDrawing = annotation ?? PKDrawing()
            if uiView.drawing != currentDrawing {
                uiView.drawing = currentDrawing
            }
        }

        if let currentAction = action {
            DispatchQueue.main.async {
                switch currentAction {
                case .undo:
                    uiView.undoManager?.undo()
                case .redo:
                    uiView.undoManager?.redo()
                }
                self.annotation = uiView.drawing
                self.action = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasEditor
        var isUpdatingFromCanvas = false
        init(_ parent: CanvasEditor) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromCanvas = true

            Task { @MainActor in
                self.parent.annotation = canvasView.drawing
                try? await Task.sleep(nanoseconds: 50_000_000)
                self.isUpdatingFromCanvas = false
            }
        }
    }
}
