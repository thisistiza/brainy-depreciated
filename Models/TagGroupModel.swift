import Foundation
import SwiftData

enum TagMatchingRule: String, Codable {
    // Universal
    case universal                      // All notes

    // Primary Operations
    case union                          // OR: Contains ANY selected tag
    case intersection                   // AND: Contains ALL selected tags
    case subset                         // EXACT: Contains ONLY selected tags

    // Complements (Negations)
    case complement                     // Untagged (Complement of All Tags)
    case complementOfUnion              // NOT ANY: Contains NONE of the selected tags
    case complementOfIntersection       // NOT ALL: Missing AT LEAST ONE selected tag
    case complementOfSubset             // NOT EXACT: Everything EXCEPT exact tag match
}

@Model
final class TagGroup {
    // ID
    var id: UUID = UUID()
    var order: Int = 0

    // Core
    var name: String
    var color: DS.Color.Palette = DS.Color.Palette.sapphire
    var matchingRule: TagMatchingRule = TagMatchingRule.union
    
    // Parent
    var subject: Subject?

    // Children
    @Relationship(inverse: \Tag.groups)
    var tags: [Tag] = []

    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(name: String, color: DS.Color.Palette = .sapphire, matchingRule: TagMatchingRule = .universal) {
        self.name = name
        self.color = color
        self.matchingRule = matchingRule
    }
}

extension TagGroup {
    convenience init(copying otherGroup: TagGroup) {
        self.init(name: otherGroup.name, color: otherGroup.color, matchingRule: otherGroup.matchingRule)
        self.id = UUID()
        self.tags = otherGroup.tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
