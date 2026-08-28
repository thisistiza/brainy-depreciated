import PencilKit
import SwiftUI
import SwiftData
import os

struct CanvasBlockView: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var block: Block
    var isEditable: Bool

    @State private var isShowingViewer = false
    @State private var currentTool: CanvasTool = .pen
    @State private var toolSize: CanvasToolSize = .small
    @State private var toolColor: ToolColor = .primary
    @State private var canvasHistoryAction: canvasHistoryAction? = nil
    
    private let emptyDrawing = PKDrawing()

    private var displayImage: UIImage? {
        if block.type == .annotation {
            return block.image ?? UIImage(named: "grid")
        }
        return block.image
    }

    var body: some View {
        if let displayImage = displayImage{
            ZStack(alignment: .topTrailing) {
                CanvasRenderer(
                    image: displayImage,
                    annotation: (block.type == .annotation ? block.annotation : block.imageAnnotation) ?? emptyDrawing
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(displayImage.size, contentMode: .fit)
                .cornerRadius(12)
                .allowsHitTesting(false)
                
                if isEditable{
                    DS.Component.Button(
                        icon: "penBoxed",
                        theme: .palette(DS.Color.Palette.sapphire),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true
                    ) {
                        guard let session = session else {
                            Log.model.debug("CanvasBlockView: Session is missing.")
                            return
                        }
                        session.setCurrentEditingBlock(to: block)
                        hideKeyboard()
                        router.navigate(to: .canvasEditorRoute)
                    }
                }
                else{
                    DS.Component.Button(
                        icon: "magnifierBoxed",
                        theme: .palette(DS.Color.Palette.sapphire),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true
                    ) {
                        guard let session = session else {
                            Log.model.debug("CanvasBlockView: Session is missing.")
                            return
                        }
                        session.setCurrentEditingBlock(to: block)
                        hideKeyboard()
                        router.navigate(to: .canvasViewRoute)
                    }
                }
            }
        } else{
            DS.Component.ErrorView(messages: ["Image is missing."]).onAppear{
                Log.model.debug("CanvasBlockView: Image is missing.")
            }
        }
    }
}
