import SwiftUI
import SwiftData
import os

//TODO
struct OnboardingView: View{
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: Date = Date()

    var body: some View {
        DS.Component.ContentContainer {
            VStack {
                DS.Component.WorkInProgress(text: "Onboarding").padding()
                DS.Component.Button(
                    text: "CONTINUE"
                ) {
                    let newSession = Session()
                    newSession.saveSession(in: modelContext)
                    let _ = newSession.createProfile(fistName: firstName, lastName: lastName, dateOfBirth: Date(), for: newSession, in: modelContext) // automatically sets profile as current profile in session
                    router.navigate(to: .dashboardRoute)
                }
            }
            .padding(.vertical, DS.Spacing.xxxl)
        }
    }
}
