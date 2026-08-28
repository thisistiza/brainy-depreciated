import SwiftUI

struct CalendarView: View {
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    
    // Binding state for target scroll position
    @State private var scrolledMonthID: Int?
    
    var body: some View {
        // GeometryReader provides the actual available width safely
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(1...12, id: \.self) { month in
                        MonthView(month: month, currentYear: currentYear, currentMonth: currentMonth)
                            .id(month) // Identifies the view target for snapping
                    }
                }
                .scrollTargetLayout()
                // Removed padding from inside the layout so snapping calculations remain accurate
            }
            // Apply the exact same padding to the ScrollView's safe area instead
            .safeAreaPadding(.leading, 20)
            .safeAreaPadding(.trailing, max(0, geometry.size.width - 224))
            .scrollPosition(id: $scrolledMonthID, anchor: .leading)
            .scrollTargetBehavior(.viewAligned)
        }
        .onAppear {
            // Pin to current month on initial appearance
            scrolledMonthID = currentMonth
        }
    }
}

// Extracted Subview for cleaner state and better layout performance
struct MonthView: View {
    let month: Int
    let currentYear: Int
    let currentMonth: Int
    
    private let calendar = Calendar.current
    
    var body: some View {
        let dayCount = daysInMonth(month: month, year: currentYear)
        
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName(month: month))
                .font(DS.Typography.bodyLarge)
                .foregroundStyle(month == currentMonth ? DS.Color.System.foreground.primary : DS.Color.System.foreground.secondary)
            
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<(dayCount + 6) / 7, id: \.self) { row in
                    GridRow {
                        ForEach(0..<7, id: \.self) { column in
                            let dayIndex = row * 7 + column
                            
                            if dayIndex < dayCount {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DS.Color.System.foreground.overlay)
                                    .frame(width: 24, height: 24)
                            } else {
                                Color.clear
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func monthName(month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
}
