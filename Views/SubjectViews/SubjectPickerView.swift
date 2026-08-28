import SwiftData
import SwiftUI
import os

struct SubjectPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session, let currentProfile = session.currentProfile{
                VStack(spacing: 0) {
                    paneBar(session: session, currentProfile: currentProfile)
                    let orderedSubjects = currentProfile.subjects.sorted { $0.createdAt > $1.createdAt }
                    if !orderedSubjects.isEmpty{
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: DS.Spacing.md) {
                                ForEach(orderedSubjects) { subject in
                                    HStack {
                                        let isSubjectSelected =
                                        session.currentSubject == subject
                                        DS.Component.Button(
                                            icon: "notebook",
                                            text: subject.name,
                                            theme: .system(.iron),
                                            style: .hollow,
                                            size: .fitWithCompact,
                                            alignment: .leading,
                                            preserveIconColor: true,
                                            isSelected: isSubjectSelected
                                        ) {
                                            if isSubjectSelected {
                                                session.setCurrentSubject(to: nil)
                                            } else {
                                                session.setCurrentSubject(to: subject)
                                                router.navigateBack()
                                            }
                                        }
                                        DS.Component.Button(
                                            icon: "slidersMono",
                                            theme: .system(.iron),
                                            style: .hollow,
                                            size: .compact
                                        ) {
                                            session.setCurrentSubject(to: subject)
                                            router.navigate(to: .subjectEditorRoute)
                                        }
                                    }
                                }
                            }
                            .cancelScrollViewDelay()
                            .padding()
                        }
                    }
                    else{
                        DS.Component.SummaryView(
                            icon: "mascotWithNotebook",
                            textView: Text("""
                            **No subjects created.**
                            Subjects are where your notes live. 
                            Create a new subject by pressing \(Image("plus")) on the top right.
                            """)
                        )
                    }
                }.onAppear {
                    if session.currentSubject == nil {
                        if let newCurrentSubject = currentProfile.subjects.first
                        {
                            session.setCurrentSubject(to: newCurrentSubject)
                        }
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
                    Log.model.debug("SubjectPickerView: \(messages)")
                }
            }
        }
    }
}

extension SubjectPickerView {
    func paneBar(session: Session, currentProfile: Profile) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        router.navigateBack()
                    }
                    Spacer()
                    DS.Component.Button(
                        icon: "plus",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                    ) {
                        let newSubject = session.appendSubject(named: "", to: currentProfile, in: modelContext)
                        session.setCurrentSubject(to: newSubject)
                        router.navigate(to: .subjectEditorRoute)
                    }
                }
                HStack {
                    Spacer()
                    Text("Subjects")
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
