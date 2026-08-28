import Foundation
import SwiftData
import SwiftUI

struct Performance{
    var maxStreak: Int
    var streak: Int
    var missedDaysDuringStreak: Int
    var numberOfMatureNotes: Int
    var numberOfTotalNotes: Int
    var dailyPoints: Int
    var weeklyPoints: Int
    var monthlyPoints: Int
    var totalPoints: Int
    var retrievalStrength: Double
}

@Model
final class PointsLog {
    // Parent
    var subject: Subject? = nil
    
    // Core
    var points: Int = 0
    var earnedAt: Date = Date()
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()
    
    init(
        subject: Subject? = nil,
        points: Int = 0,
        earnedAt: Date = Date(),
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        updatedAt: Date = Date()
        
    ) {
        self.subject = subject
        self.points = points
        self.earnedAt = earnedAt
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.updatedAt = updatedAt
    }
}
