import Foundation
import SwiftData
import os

struct Scheduler {
    static func schedule(review: Review, isPass: Bool, reviewDate: Date = Date()) {
        let elapsedDays = calculateElapsedDays(since: review.lastReviewAt, relativeTo: reviewDate)
        let rating = getRating(review: review, isPass: isPass)
        let log = createReviewLog(for: review, rating: rating, reviewedAt: reviewDate, elapsedDays: elapsedDays)
        if let lastLog = review.logs.last, Calendar.current.isDate(lastLog.reviewedAt, inSameDayAs: reviewDate) {
                if let index = review.logs.indices.last {
                    review.logs[index] = log
                }
            } else {
                review.logs.append(log)
            }
        
        switch review.state {
            case .new:
            update(review: review, stability: review.stability, difficulty: review.difficulty, rating: rating, state: .learning, reviewDate: reviewDate, nextDate: Date())
            case .learning, .relearning:
                if isPass {
                    update(review: review, stability: review.stability, difficulty: review.difficulty, rating: rating, state: .review, reviewDate: reviewDate, nextDate: Date())
                }
            case .review:
            let nextDate = Date() //getNextReviewDate(review: review, rating: rating)
            let stability = 0.0 //getStability(review: review, rating: rating)
            let difficulty = 0.0 //getDifficulty(review: review, rating: rating)
                return update(review: review, stability: stability, difficulty: difficulty, rating: rating, state: .review, reviewDate: reviewDate, nextDate: Date())
        default: break
        }
    }
}

private extension Scheduler {
    static func calculateElapsedDays(since lastReviewAt: Date?, relativeTo currentDate: Date) -> Int {
        guard let lastReviewAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastReviewAt, to: currentDate).day ?? 0
    }
    
    static func createReviewLog(for review: Review, rating: Rating, reviewedAt: Date, elapsedDays: Int) -> ReviewLog {
        ReviewLog(
            review: review,
            rating: rating,
            state: review.state,
            reviewedAt: reviewedAt,
            stability: review.stability,
            difficulty: review.difficulty,
            elapsedDays: elapsedDays
        )
    }
    
    static func update(review: Review, stability: Double, difficulty: Double, rating: Rating, state: SchedulingState, reviewDate: Date, nextDate: Date) {
        review.lastReviewAt = reviewDate
        review.nextReviewAt = nextDate
        review.state = state
        review.repetitions += 1
        if review.state == .review, rating == .again{
            review.lapses += 1
        }
        review.stability = stability
        review.difficulty = difficulty
    }
    
    static func getRating(review: Review, isPass: Bool) -> Rating {
        return isPass ? .good : .again
    }
}
