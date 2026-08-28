import Foundation
import SwiftData

// MARK: - Enums

enum Rating: Int, Codable, Sendable {
    case again = 1  // Forgot
    case hard = 2  // Recalled with effort
    case good = 3  // Recalled normally
    case easy = 4  // Recalled effortlessly
}

enum SchedulingState: Int, Codable, Sendable, Equatable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3
    case suspend = 4
}

// MARK: - Review Model
@Model
final class Review {
    // Parent
    @Attribute(.unique) var id: UUID = UUID()
    var note: Note? = nil

    // Children
    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.review)
    var logs: [ReviewLog] = []
    
    // Core
    #Index<Review>([\.nextReviewAt])
    var nextReviewAt: Date = Date()
    var lastReviewAt: Date? = nil
    var state: SchedulingState = SchedulingState.new
    var stability: Double = 0.0
    var difficulty: Double = 0.0
    var repetitions: Int = 0
    var lapses: Int = 0
    var step: Int = 0

    // Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date? = nil

    init(note: Note? = nil) {
        self.note = note
    }
}

extension Review{
    var maturity: Double {
        guard state != .new else { return 0.0 }
        // Tier 1: 0..1 day    (Immediate)
        // Tier 2: 1..7 days   (Short-term)
        // Tier 3: 7..21 days  (Medium-term / Entering Maturity)
        // Tier 4: 21..60 days (Long-term)
        // Tier 5: 60..180 days (Deeply Encoded)
        // Tier 6: 180+ days   (Permanent / Mastered)
        let maxTargetStability: Double = 180.0
        
        let clampedStability = max(0.0, min(stability, maxTargetStability))
        
        // Using a 0.4 exponent (nth root) creates a front-loaded curve where
        // small initial gains in stability result in large early jumps in maturity score.
        let rawScore = pow(clampedStability / maxTargetStability, 0.4)
        
        // Clamp result to 0.0 ... 1.0 range
        return min(1.0, max(0.0, rawScore))
    }
    
    var retrievability: Double {
        guard state != .new, stability > 0.0, let lastReviewAt else {
            return 0.0
        }
        let currentDate = Date()
        let elapsedSeconds = currentDate.timeIntervalSince(lastReviewAt)
        let elapsedDays = max(0.0, elapsedSeconds / 86400.0)
        let r = pow(1.0 + (elapsedDays / (9.0 * stability)), -1.0)
        
        return min(1.0, max(0.0, r))
    }
    
    var retrievalStrength: Double {
            guard state != .new else { return 0.0 }
            
            let r = retrievability
            
            // Power constant derived from: ln(0.5) / ln(0.90)
            let exponent = 6.5788
            
            let smoothScore = pow(r, exponent)
            return min(1.0, max(0.0, smoothScore))
        }
}

// MARK: - Review Model Extensions
extension Review {
    convenience init(copying otherReview: Review, note: Note? = nil) {
        self.init(note: note)

        // FSRS State Variables
        self.nextReviewAt = otherReview.nextReviewAt
        self.lastReviewAt = otherReview.lastReviewAt
        self.state = otherReview.state
        self.stability = otherReview.stability
        self.difficulty = otherReview.difficulty
        self.repetitions = otherReview.repetitions
        self.lapses = otherReview.lapses
        self.step = otherReview.step

        // Deep-copy child logs & bind relationship
        let copiedLogs = otherReview.logs.map { oldLog -> ReviewLog in
            let newLog = ReviewLog(copying: oldLog)
            newLog.review = self
            return newLog
        }
        self.logs = copiedLogs

        // Metadata
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}

// MARK: - ReviewLog Model
@Model
final class ReviewLog {
    // 1. Identifiers & Relationships
    @Attribute(.unique) var id: UUID = UUID()
    var review: Review? = nil

    // 2. Core Review Performance Data
    var rating: Rating? = nil
    var state: SchedulingState? = nil
    var reviewedAt: Date = Date()
    var duration: Double? = nil
    var stability: Double? = nil
    var difficulty: Double? = nil
    var elapsedDays: Int = 0

    // 3. Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date? = nil

    init(
        review: Review? = nil,
        rating: Rating? = nil,
        state: SchedulingState? = nil,
        reviewedAt: Date = Date(),
        duration: Double? = nil,
        stability: Double? = nil,
        difficulty: Double? = nil,
        elapsedDays: Int = 0
    ) {
        self.review = review
        self.rating = rating
        self.state = state
        self.reviewedAt = reviewedAt
        self.duration = duration
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
    }
}

// MARK: - ReviewLog Model Extensions
extension ReviewLog {
    convenience init(copying otherLog: ReviewLog) {
        self.init(
            review: nil,
            rating: otherLog.rating,
            state: otherLog.state,
            reviewedAt: otherLog.reviewedAt,
            duration: otherLog.duration,
            stability: otherLog.stability,
            difficulty: otherLog.difficulty,
            elapsedDays: otherLog.elapsedDays
        )

        // Metadata
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
