import SwiftUI

extension Int {
    func toHoursAndMinutes() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours) hr \(minutes) min" : "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }
}

extension Date {
    func daysRemainingFromToday() -> String {
        let calendar = Calendar.current
        
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: self)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        let days = max(0, components.day ?? 0)
        
        let dayUnit = days == 1 ? "day" : "days"
        return "\(days) \(dayUnit)"
    }
}

extension Date {
    func relativeTimeRemaining() -> String {
        let calendar = Calendar.current
        
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: self)
        
        if startOfTarget <= startOfToday {
            return "0 days"
        }
        
        let timeInterval = startOfTarget.timeIntervalSince(startOfToday)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .day]
        formatter.unitsStyle = .full
        
        if #available(iOS 18.0, macOS 15.0, *) {
            formatter.formattingContext = .standalone
        }
        return formatter.string(from: timeInterval) ?? "0 days"
    }
}
