import PencilKit
import SwiftUI
import SwiftData
import os

struct CanvasView: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    var currentEditingBlock: Block? {session?.currentEditingBlock}
    
    private var currentImage: UIImage? {
        if currentEditingBlock?.type == .annotation {
            return currentEditingBlock?.image ?? UIImage(named: "grid")
        }
        return currentEditingBlock?.image
    }

    var body: some View {
        if let session = session, let currentImage = currentImage, let currentEditingBlock = currentEditingBlock {
            ZStack(alignment: .top) {
                DS.Color.System.background.primary.ignoresSafeArea()
                ZoomableCanvasView(
                    image: currentImage,
                    annotation: (currentEditingBlock.type == .annotation ? currentEditingBlock.annotation : currentEditingBlock.imageAnnotation) ?? PKDrawing()
                )
                .ignoresSafeArea()
                
                HStack {
                    Spacer()
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(DS.Color.Palette.sapphire),
                        style: .hollow,
                        size: .compact
                    ) {
                        session.setCurrentEditingBlock(to: nil)
                        router.navigateBack()
                    }
                }
                .padding()
            }
        }
        else{
            var messages: [String] {
                var messages: [String] = []
                guard let session = session else {
                    messages.append("Session is missing.")
                    return messages
                }
                if session.currentEditingBlock == nil {
                    messages.append("Current editing block in session is missing.")
                }
                if currentImage == nil {
                    messages.append("Image is missing.")
                }
                return messages
            }
            DS.Component.ErrorView(messages: messages).onAppear{
                Log.model.debug("CanvasView: \(messages)")
            }
        }
    }
}
