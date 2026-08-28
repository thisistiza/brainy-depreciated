import Foundation
import SwiftData
import SwiftUI

@Model
class Profile {
    // ID
    var id: UUID = UUID()

    // Core
    var firstName: String
    var lastName: String
    var dateOfBirth: Date

    // Children
    @Relationship(deleteRule: .cascade, inverse: \Subject.profile)
    var subjects: [Subject] = []
    var currentSubject: Subject? = nil

    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()
    
    init(
        firstName: String,
        lastName: String,
        dateOfBirth: Date
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
    }
}

extension Profile {
    convenience init(copying otherProfile: Profile) {
        self.init(
            firstName: otherProfile.firstName,
            lastName: otherProfile.lastName,
            dateOfBirth: otherProfile.dateOfBirth
        )
        self.id = UUID()
        self.subjects = otherProfile.subjects.map { Subject(copying: $0) }
        self.currentSubject = nil // Runtime explicit assignment state
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
