import Foundation
import SwiftData

@Model
final class Subject {
    // ID
    var id: UUID = UUID()

    // Parent
    var profile: Profile? = nil
    
    // Core
    var name: String
    var studyDuration: Int = 0

    // Children
    @Relationship(deleteRule: .cascade, inverse: \Event.subject)
    var events: [Event] = []
    @Relationship(deleteRule: .cascade, inverse: \Note.subject)
    var notes: [Note] = []
    @Relationship(deleteRule: .cascade, inverse: \Tag.subject)
    var tags: [Tag] = []
    @Relationship(deleteRule: .cascade, inverse: \TagGroup.subject)
    var tagGroups: [TagGroup] = []
    var orderedTagGroups: [TagGroup] { tagGroups.sorted { $0.order < $1.order } }
    @Relationship(deleteRule: .cascade, inverse: \EngagementLog.subject)
    var engagement: [EngagementLog] = []

    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(name: String = "") {
        self.name = name
    }
}


extension Subject {
    convenience init(copying otherSubject: Subject) {
        self.init(name: otherSubject.name)
        self.id = UUID()
        self.studyDuration = otherSubject.studyDuration
        
        // Deep copy items owned solely by this subject
        self.events = otherSubject.events.map { Event(copying: $0) }
        self.notes = otherSubject.notes.map { Note(copying: $0) }
        self.tags = otherSubject.tags.map { Tag(copying: $0) }
        self.tagGroups = otherSubject.tagGroups.map { TagGroup(copying: $0) }
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
