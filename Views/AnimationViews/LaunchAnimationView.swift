import RiveRuntime
import SwiftUI
import os

struct LaunchAnimationView: View {
    @State private var rive: Rive? = nil
    @State private var errorOccurred = false
    let action: () -> Void

    let secondsToWaitBeforeEntering = 0.1
    let secondsToWaitBeforeExiting = 2.0
    let secondsToWaitBeforeAction = 1.0

    var body: some View {
        ZStack {
            if let rive = rive {
                RiveUIViewRepresentable(rive: rive)
            } else if errorOccurred {
                DS.Component.ContentContainer {
                    DS.Component.ErrorView(messages: ["Launch animation failed."]).onAppear{
                        Log.model.debug("LaunchAnimationView: Launch animation failed.")
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            await loadRive()
            try? await Task.sleep(for: .seconds(secondsToWaitBeforeEntering))
            rive?.viewModelInstance?.fire(
                trigger: TriggerProperty(path: "enterAction")
            )
            try? await Task.sleep(for: .seconds(secondsToWaitBeforeExiting))
            rive?.viewModelInstance?.fire(
                trigger: TriggerProperty(path: "exitAction")
            )
            try? await Task.sleep(for: .seconds(secondsToWaitBeforeAction))
            action()
        }
    }

    @MainActor
    private func loadRive() async {
        do {
            let worker = try await Worker()
            let file = try await File(
                source: .local("launch", Bundle.main),
                worker: worker
            )
            let artboard = try await file.createArtboard("Artboard")
            let stateMachine = try await artboard.createStateMachine(
                "State Machine"
            )
            self.rive = try await Rive(
                file: file,
                artboard: artboard,
                stateMachine: stateMachine
            )
            Log.animation.debug("LaunchAnimationView: Loaded launch animation.")
        } catch {
            Log.animation.debug("LaunchAnimationView: Failed to load launch animation: \(error)")
            self.errorOccurred = true
        }
    }
}

#Preview {
    LaunchAnimationView(action: {})
}
