import SwiftData
import SwiftUI
import os

struct SubjectEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    @State private var newSubjectName: String = ""

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentProfile = session.currentProfile, let currentSubject = session.currentSubject {
                VStack(spacing: DS.Spacing.md) {
                    paneBar(session: session, currentProfile: currentProfile, currentSubject: currentSubject)
                    
                    DS.Component.TextField(
                        text: $newSubjectName,
                        placeholder: "Enter subject name..."
                    )

                    Spacer()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onAppear {
                    if let currentSubject = session.currentSubject {
                        newSubjectName = currentSubject.name
                    }
                }
            } else {
                var messages: [String] {
                    var messages: [String] = []
                    guard let session = session else {
                        messages.append("Session is missing.")
                        return messages
                    }
                    if session.currentSubject == nil {
                        messages.append("Current subject in session is missing.")
                    }
                    return messages
                }
                DS.Component.ErrorView(messages: messages).onAppear{
                    for message in messages{
                        Log.model.debug("SubjectEditorView: \(message)")
                    }
                }
            }
        }
    }
}

extension SubjectEditorView {
    func paneBar(
        session: Session,
        currentProfile: Profile,
        currentSubject: Subject
    ) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        guard !newSubjectName.isEmpty else{
                            session.setCurrentSubject(to: nil)
                            session.delete(subject: currentSubject, in: modelContext)
                            router.navigateBack()
                            return
                        }
                        session.update(subject: currentSubject, name: newSubjectName, in: modelContext)
                        session.setCurrentSubject(to: nil)
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: "trash",
                        theme: .palette(.ruby),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true
                    ) {
                        session.setCurrentSubject(to: nil)
                        session.delete(subject: currentSubject, in: modelContext)
                        router.navigateBack()
                    }
                }
                HStack {
                    Spacer()
                    Text("Edit Subject")
                        .font(DS.Typography.bodyLarge)
                        .foregroundStyle(DS.Color.System.foreground.primary)
                    Spacer()
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }
}
