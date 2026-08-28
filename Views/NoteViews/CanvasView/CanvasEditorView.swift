import PencilKit
import SwiftUI
import SwiftData
import os

struct CanvasEditorView: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var currentEditingBlock: Block? {session?.currentEditingBlock}
    var isEditable: Bool = true
    private var currentImage: UIImage? {
        if currentEditingBlock?.type == .annotation {
            return currentEditingBlock?.image ?? UIImage(named: "grid")
        }
        return currentEditingBlock?.image
    }

    @State private var currentTool: CanvasTool = .pen
    @State private var toolSize: CanvasToolSize = .small
    @State private var toolColor: ToolColor = .primary
    @State private var canvasHistoryAction: canvasHistoryAction? = nil

    var body: some View {
        if let session = session, let currentImage = currentImage, let currentEditingBlock = currentEditingBlock{
            ZStack {
                DS.Color.System.background.primary.ignoresSafeArea()
                CanvasEditor(
                    annotation: Binding(
                        get: { currentEditingBlock.type == .annotation ? currentEditingBlock.annotation : currentEditingBlock.imageAnnotation },
                        set: { newValue in
                            if currentEditingBlock.type == .annotation {
                                currentEditingBlock.annotation = newValue
                            } else {
                                currentEditingBlock.imageAnnotation = newValue
                            }
                        }
                    ),
                    image: currentImage,
                    activeTool: currentTool,
                    toolSize: toolSize,
                    toolColor: toolColor,
                    action: $canvasHistoryAction
                )
                .ignoresSafeArea()
                
                VStack {
                    HStack(spacing: 12) {
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
                    
                    Spacer()
                    
                    CanvasEditBar(
                        currentTool: $currentTool,
                        toolSize: $toolSize,
                        toolColor: $toolColor,
                        canvasHistoryAction: $canvasHistoryAction
                    )
                    .padding(DS.Spacing.lg)
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
                if currentImage == nil {
                    messages.append("Image is missing.")
                }
                return messages
            }
            DS.Component.ErrorView(messages: messages).onAppear{
                for message in messages{
                    Log.model.debug("CanvasEditorView: \(message)")
                }
            }
        }
    }
}
