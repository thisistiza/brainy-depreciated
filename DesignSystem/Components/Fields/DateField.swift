import SwiftUI

extension DesignSystem.Component {
    struct DateField: View {
        @Binding var date: Date

        @State private var day: String = ""
        @State private var month: String = ""
        @State private var year: String = ""

        var body: some View {
            HStack {
                DesignSystem.Component.TextField(
                    text: $day,
                    placeholder: "DD",
                    showKeyboardButton: false
                )
                .frame(width: 70)
                Text("/")
                    .font(DesignSystem.Typography.dateFieldLabel)
                    .foregroundStyle(
                        DesignSystem.Color.System.foreground.primary
                    )
                DesignSystem.Component.TextField(
                    text: $month,
                    placeholder: "MM",
                    showKeyboardButton: false
                )
                .frame(width: 70)
                Text("/")
                    .font(DesignSystem.Typography.dateFieldLabel)
                    .foregroundStyle(
                        DesignSystem.Color.System.foreground.primary
                    )
                DesignSystem.Component.TextField(
                    text: $year,
                    placeholder: "YYYY",
                    showKeyboardButton: false
                )
                .frame(width: 80)
            }
            .onAppear {
                updateStringsFromDate()
            }
            .onChange(of: day) { new, old in updateDateFromStrings() }
            .onChange(of: month) { new, old in updateDateFromStrings() }
            .onChange(of: year) { new, old in updateDateFromStrings() }
        }

        private func updateStringsFromDate() {
            let calendar = Calendar.current
            day = String(calendar.component(.day, from: date))
            month = String(calendar.component(.month, from: date))
            year = String(calendar.component(.year, from: date))
        }

        private func updateDateFromStrings() {
            var components = DateComponents()
            components.day = Int(day)
            components.month = Int(month)
            components.year = Int(year)

            if let newDate = Calendar.current.date(from: components) {
                date = newDate
            }
        }
    }
}
