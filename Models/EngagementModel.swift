import Foundation
import SwiftData
@Model
final class EngagementLog {
    // ID
    var dateIdentifier: String = ""
    var date: Date = Date()
    var timeZoneIdentifier: String = TimeZone.current.identifier

    // Parent
    var subject: Subject? = nil

    // Core: Hourly
    var numOfReviewsByHour: [Int] = Array(repeating: 0, count: 24)
    var durationOfReviewsByHour: [TimeInterval] = Array(repeating: 0.0, count: 24)

    // Core: Today
    var durationOfReviews: TimeInterval = 0
    var numOfReviews: Int = 0
    var numOfReviewsCompleted: Int = 0
    var reviewProgress: Double = 0.0
    
    @Relationship(deleteRule: .cascade, inverse: \NotificationLog.engagementLog)
    var notifications: [NotificationLog] = []
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(
        date: Date = Date(),
        dateIdentifier: String? = nil,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        subject: Subject? = nil,
        numOfReviewsByHour: [Int] = Array(repeating: 0, count: 24),
        durationOfReviewsByHour: [TimeInterval] = Array(repeating: 0.0, count: 24),
        durationOfReviews: TimeInterval = 0,
        numOfReviews: Int = 0,
        numOfReviewsCompleted: Int = 0,
        reviewProgress: Double = 0.0,
        notifications: [NotificationLog] = [],
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.date = date
        self.timeZoneIdentifier = timeZoneIdentifier
        self.subject = subject
        self.numOfReviewsByHour = numOfReviewsByHour
        self.durationOfReviewsByHour = durationOfReviewsByHour
        self.durationOfReviews = durationOfReviews
        self.numOfReviews = numOfReviews
        self.numOfReviewsCompleted = numOfReviewsCompleted
        self.reviewProgress = reviewProgress
        self.notifications = notifications
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.updatedAt = updatedAt
        
        if let providedID = dateIdentifier {
            self.dateIdentifier = providedID
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.dateIdentifier = formatter.string(from: date)
        }
    }
}

enum EngagementStyle: String, Codable {
    case lossAverse
    case progressOriented
    case social
    case lowBarrier
    case coaching
    case guilty
    case passiveAggresive
    case encouraging
    case positiveForcasting
    case negativeForcasting
    case neutral
}

enum EngagementState: String, Codable {
    case start // create notes
    
    case rampUp1 // get to day 3
    case rampUp2 // get to day 5
    case rampUp3 // get to day 7
    case rampUp4 // get to day 14
    
    case active3 // 60-90% reviews
    case active2 // 30-59% reviews
    case active1 // <30% reviews
    
    case inactive1 // missed <3 days
    case inactive2 // missed <5 days
    case inactive3 // missed <7 days
    case inactive4 // missed <14 days
    
    case restart
}

@Model
final class NotificationLog {
    // Parent
    var engagementLog: EngagementLog? = nil
    
    // Core
    var style: EngagementStyle? = EngagementStyle.neutral
    var sentAt: Date = Date()
    var openedAt: Date? = nil
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()
    
    init(
        engagementLog: EngagementLog? = nil,
        style: EngagementStyle = .neutral,
        sentAt: Date = Date(),
        openedAt: Date? = nil,
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        updatedAt: Date = Date()
        
    ) {
        self.engagementLog = engagementLog
        self.style = style
        self.sentAt = sentAt
        self.openedAt = openedAt
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.updatedAt = updatedAt
    }
}

extension EngagementLog {
    convenience init(copying otherLog: EngagementLog) {
        let copiedNotifications = otherLog.notifications.map { NotificationLog(copying: $0) }
        
        self.init(
            date: otherLog.date,
            dateIdentifier: otherLog.dateIdentifier,
            timeZoneIdentifier: otherLog.timeZoneIdentifier,
            subject: nil,
            numOfReviewsByHour: otherLog.numOfReviewsByHour,
            durationOfReviewsByHour: otherLog.durationOfReviewsByHour,
            durationOfReviews: otherLog.durationOfReviews,
            numOfReviews: otherLog.numOfReviews,
            numOfReviewsCompleted: otherLog.numOfReviewsCompleted,
            reviewProgress: otherLog.reviewProgress,
            notifications: copiedNotifications
        )
    }
}

extension NotificationLog {
    convenience init(copying otherLog: NotificationLog) {
        self.init(
            engagementLog: nil,
            style: otherLog.style ?? .neutral,
            sentAt: otherLog.sentAt,
            openedAt: otherLog.openedAt
        )
    }
}
