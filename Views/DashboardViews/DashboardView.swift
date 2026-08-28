import SwiftData
import SwiftUI
import os

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @Query private var sessions: [Session]
    @Query private var allNotes: [Note]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var newNotesCount: Int {
        if let currentSubject = currentSubject{
            return session?.filterNewNotes(from: allNotes, in: currentSubject).count ?? 0
        }
        return 0
    }
    var learningNotesCount: Int {
        if let currentSubject = currentSubject{
            return session?.filterLearnNotes(from: allNotes, in: currentSubject).count ?? 0
        }
        return 0
    }
    var reviewNotesDueTodayCount: Int {
        if let currentSubject = currentSubject{
            return session?.filterReviewNotesDueToday(from: allNotes, in: currentSubject).count ?? 0
        }
        return 0
    }
    
    var currentSubject: Subject? { return session?.currentSubject }

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session {
                VStack(spacing: DS.Spacing.lg) {
                    introductionView()
                    CalendarView()
                    AchievementView()
                    actionView(session: session)
                    reviewView()
                        .onAppear{
                            if let currentSubject = currentSubject{
                                logReview(session: session, subject: currentSubject, allNotes: allNotes)
                            }
                        }
                    Spacer()
                    navBar()
                }
                .safeAreaPadding(.vertical)
                .padding(.vertical, DS.Spacing.sm)
                .onAppear {
                    if let currentSubject = currentSubject {
                        Log.model.debug(
                            "DashboardView: Current subject in session is \"\(currentSubject.name)\"."
                        )
                        Log.view.debug(
                            "DashboardView: Enabled UI elements that require subject selection."
                        )
                    } else {
                        Log.model.debug(
                            "DashboardView: Current subject in session is missing."
                        )
                        Log.view.debug(
                            "DashboardView: Disabled UI elements that require subject selection."
                        )
                    }
                }
            } else {
                DS.Component.ErrorView(messages: ["Session is missing."])
                    .onAppear {
                        Log.model.debug("DashboardView: Session is missing.")
                    }
            }
        }
    }
}

extension DashboardView {
    func introductionView() -> some View {
        Text("Welcome Back!")
            .font(DS.Typography.bodyLarge)
            .foregroundStyle(DS.Color.System.foreground.primary)
            .padding(.horizontal)
    }
    func actionView(session: Session) -> some View {
        return HStack {
            DS.Component.Button(
                icon: "cards",
                text: "VIEW NOTES",
                theme: .system(.amethyst),
                style: .hollow,
                size: .fitWithCompact,
                preserveIconColor: true,
                isDisabled: currentSubject == nil
            ) {
                router.navigate(to: .noteListRoute)
            }
            DS.Component.Button(
                icon: "plus",
                theme: .system(.amethyst),
                style: .hollow,
                size: .compact,
                isDisabled: currentSubject == nil
            ) {
                if let subject = session.currentSubject {
                    let newNote = session.appendNote(
                        to: subject,
                        in: modelContext
                    )
                    session.setCurrentEditingNote(to: newNote)
                } else {
                    Log.model.debug(
                        "DashboardView: Current subject in session is missing."
                    )
                }
                router.navigate(to: .noteEditorRoute)
            }
        }
        .padding()
        .padding(.horizontal)
    }

    func reviewView() -> some View {
        return VStack {
            HStack {
                DS.Component.Panel(
                    icon: "spark",
                    text: "\(newNotesCount)",
                    subtext: "NEW",
                    theme: .palette(.gold),
                    isDisabled: currentSubject == nil
                ) {
                    router.navigate(to: .newNoteListRoute)
                }
                DS.Component.Panel(
                    icon: "graduationCap",
                    text: "\(learningNotesCount)",
                    subtext: "LEARNING",
                    theme: .palette(.amethyst),
                    isDisabled: currentSubject == nil
                ) {
                    router.navigate(to: .learningNoteListRoute)
                }
                DS.Component.Panel(
                    icon: "calendar",
                    text: "\(reviewNotesDueTodayCount)",
                    subtext: "REVIEW",
                    theme: .palette(.ruby),
                    isDisabled: currentSubject == nil
                ) {
                    router.navigate(to: .reviewNoteListRoute)
                }
            }
            DS.Component.Button(
                text: "START STUDYING",
                theme: .palette(.emerald),
                preserveIconColor: true,
                isDisabled: currentSubject == nil
            ) {
                //TODO
            }.padding()
        }.padding(.horizontal)
    }

    func navBar() -> some View {
        return HStack {
            DS.Component.Button(
                icon: "notebook",
                text: currentSubject?.name ?? "PICK SUBJECT",
                theme: .palette(.iron),
                style: .plain,
                alignment: .leading,
                preserveIconColor: true
            ) {
                if currentSubject == nil {
                    Log.model.debug(
                        "DashboardView: Current subject in session is missing."
                    )
                }
                router.navigate(to: .subjectPickerRoute)
            }
            DS.Component.Button(
                icon: "workInProgress",
                style: .plain,
                size: .compact,
                preserveIconColor: true,
                isDisabled: currentSubject == nil
            ) {
                //TODO
            }
            DS.Component.Button(
                icon: "workInProgress",
                style: .plain,
                size: .compact,
                preserveIconColor: true,
                isDisabled: currentSubject == nil
            ) {
                //TODO
            }
        }.padding(.horizontal)
    }
}


func logReview(session: Session, subject: Subject, allNotes: [Note]) {
    // 1. Fetch filtered notes using your filter functions
    let newNotes = session.filterNewNotes(from: allNotes, in: subject)
    let learningNotes = session.filterLearnNotes(from: allNotes, in: subject)
    let reviewNotes = session.filterReviewNotesDueToday(from: allNotes, in: subject)
    
    // 2. Identify remaining notes in this subject that didn't match the three active categories
    let categorizedIDs = Set(newNotes.map(\.id) + learningNotes.map(\.id) + reviewNotes.map(\.id))
    let otherNotes = allNotes.filter { note in
        note.subject == subject && !categorizedIDs.contains(note.id)
    }
    
    // Date formatter for display
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d/yyyy"
    
    // Helper to format each Note item using the first 4 characters of UUID: '#A1B2 (1/10/2000)'
    func formatNote(_ note: Note) -> String {
        let shortID = String(note.id.uuidString.prefix(4))
        let nextDate = note.review?.nextReviewAt ?? note.createdAt
        let dateString = formatter.string(from: nextDate)
        return "#\(shortID) (\(dateString))"
    }
    
    let newStrings = newNotes.map { formatNote($0) }
    let learningStrings = learningNotes.map { formatNote($0) }
    let reviewStrings = reviewNotes.map { formatNote($0) }
    let otherStrings = otherNotes.map { formatNote($0) }
    
    let colWidth = 22
    let maxRows = max(newStrings.count, max(learningStrings.count, max(reviewStrings.count, otherStrings.count)))
    
    // Build Table Header & Divider
    var output = "\nReview Table\n"
    output += "NEW".padding(toLength: colWidth, withPad: " ", startingAt: 0)
    output += "LEARN".padding(toLength: colWidth, withPad: " ", startingAt: 0)
    output += "REVIEW".padding(toLength: colWidth, withPad: " ", startingAt: 0)
    output += "OTHER".padding(toLength: colWidth, withPad: " ", startingAt: 0)
    output += "\n" + String(repeating: "-", count: colWidth * 4) + "\n"
    
    // Build Rows
    if maxRows == 0 {
        output += "(No notes in this subject)\n"
    } else {
        for i in 0..<maxRows {
            let newCol = (i < newStrings.count ? newStrings[i] : "").padding(toLength: colWidth, withPad: " ", startingAt: 0)
            let learningCol = (i < learningStrings.count ? learningStrings[i] : "").padding(toLength: colWidth, withPad: " ", startingAt: 0)
            let reviewCol = (i < reviewStrings.count ? reviewStrings[i] : "").padding(toLength: colWidth, withPad: " ", startingAt: 0)
            let otherCol = (i < otherStrings.count ? otherStrings[i] : "").padding(toLength: colWidth, withPad: " ", startingAt: 0)
            
            output += "\(newCol)\(learningCol)\(reviewCol)\(otherCol)\n"
        }
    }
    
    // Log output
    Log.model.debug("\(output, privacy: .public)")
}
