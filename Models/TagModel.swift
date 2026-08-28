import Foundation
import SwiftData

@Model
final class Tag {
    // ID
    var id: UUID = UUID()
    var order: Int = 0 // non-custom tag types all have an order of 0

    // Parent
    var subject: Subject? = nil
    var notes: [Note] = []
    var groups: [TagGroup] = []

    // Core
    #Index<Tag>([\.name])
    var name: String = ""
    var color: DS.Color.Palette = DS.Color.Palette.sapphire
    @Transient
    var isSystem: Bool = false
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(name: String, color: DS.Color.Palette = .sapphire, isSystem: Bool = false) {
        self.name = name
        self.color = color
    }
}

extension Tag {
    convenience init(copying otherTag: Tag) {
        self.init(name: otherTag.name, color: otherTag.color)
        self.id = UUID()
        self.order = otherTag.order
        self.groups = otherTag.groups
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
