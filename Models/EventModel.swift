import Foundation
import SwiftData

@Model
final class Event {
    // ID
    var id: UUID = UUID()

    // Parent
    var subject: Subject? = nil

    // Core
    var name: String = ""
    var nextReviewAt: Date = Date()
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(
        name: String = "",
        nextReviewAt: Date = Date()
    ) {
        self.name = name
        self.nextReviewAt = nextReviewAt
    }
}

extension Event {
    convenience init(copying otherEvent: Event) {
        self.init(name: otherEvent.name, nextReviewAt: otherEvent.nextReviewAt)
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
