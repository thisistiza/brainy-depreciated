import SwiftUI
import SwiftData
import os

struct LaunchView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted {$0.createdAt > $1.createdAt}.first
    }

    var body: some View {
        VStack{
            Spacer()
            LaunchAnimationView{
                if let session = session, let _ = session.currentProfile{
                    Log.model.debug("LaunchView: Session and current profile in session is found.")
                    router.setSession(to: session, in: modelContext)
                    router.syncPathFromSession(defaultTo: .dashboardRoute)
                }
                else{
                    Log.model.debug("LaunchView: Session and current profile in session is missing.")
                    router.navigate(to: .onboardingRoute)
                }
            }.aspectRatio(contentMode: .fit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(DesignSystem.Color.Palette.sapphire.bold)
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchView()
}
