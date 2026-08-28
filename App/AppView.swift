import SwiftUI
import os

enum Route: String, Hashable, Codable {
    case launchRoute
    case dashboardRoute
    case onboardingRoute
    case subjectPickerRoute
    case subjectEditorRoute
    case noteEditorRoute
    case noteReviewerRoute
    case noteRoute
    case noteListRoute
    case tagPickerRoute
    case tagEditorRoute
    case programmingLanguageListRoute
    case canvasEditorRoute
    case canvasViewRoute
    case temporaryNoteEditorRoute
    case groupPickerRoute
    case groupEditorRoute
    case newNoteListRoute
    case learningNoteListRoute
    case reviewNoteListRoute
}

struct RouteViewFactory {
    @ViewBuilder
    static func view(for route: Route?) -> some View {
        switch route {
        case .launchRoute: LaunchView()
        case .dashboardRoute: DashboardView()
        case .onboardingRoute: OnboardingView()
        case .subjectPickerRoute: SubjectPickerView()
        case .subjectEditorRoute: SubjectEditorView()
        case .noteEditorRoute: NoteEditorView()
        case .noteReviewerRoute: NoteReviewerView()
        case .noteRoute: NoteView()
        case .noteListRoute: NoteListView()
        case .tagPickerRoute: TagPickerView()
        case .tagEditorRoute: TagEditorView()
        case .programmingLanguageListRoute: ProgrammingLanguageListView()
        case .canvasEditorRoute: CanvasEditorView()
        case .canvasViewRoute: CanvasView()
        case .temporaryNoteEditorRoute: TemporaryNoteEditorView()
        case .groupPickerRoute: GroupPickerView()
        case .groupEditorRoute: GroupEditorView()
        case .newNoteListRoute: NewNoteListView()
        case .learningNoteListRoute: LearningNoteListView()
        case .reviewNoteListRoute: ReviewNoteListView()
        default:
            {
                return DS.Component.ContentContainer {
                    DS.Component.ErrorView(messages: ["View is missing."])
                        .onAppear {
                            Log.model.debug("View is missing.")
                        }
                }
            }()
        }
    }
}

struct AppView: View {
    @State var router = Router(root: .launchRoute)
    var body: some View {
        ZStack {
            if let currentRoute = router.currentRoute() {
                RouteViewFactory.view(for: currentRoute)
                    .id(currentRoute)
                    .onChange(of: currentRoute) {
                        Log.view.debug(
                            "Displayed view for \(currentRoute.rawValue)."
                        )
                    }
                    .compositingGroup()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(router)
        .applyAppBackground()
        .animation(DS.Animation.springForPaneTransition, value: router.currentRoute())
    }
}

#Preview {
    AppView()
}
