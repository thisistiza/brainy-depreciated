import SwiftData
import SwiftUI
import os

@main
struct BrainyApp: App {
    let container: ModelContainer?
    
    init() {
        let schema = Schema([
            Session.self,
            Profile.self,
            Subject.self,
            Note.self,
            Tag.self,
            TagGroup.self,
            Event.self,
            Block.self,
            Review.self,
            ReviewLog.self,
            EngagementLog.self,
            NotificationLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            "BrainyAppStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            Log.model.debug("BrainyApp: Loading model container...")
            self.container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Log.model.debug("BrainyApp: Successfully loaded model container.")
        } catch {
            Log.model.error("BrainyApp: Failed to load model container: \(error.localizedDescription)")
            self.container = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let container = container {
                AppView()
                    .modelContainer(container)
            } else {
                DS.Component.ContentContainer {
                    DS.Component.ErrorView(messages: ["BrainyApp: Failed to load database store."])
                        .onAppear {
                            Log.model.error("BrainyApp: Displaying container failure view.")
                        }
                }
            }
        }
    }
}
