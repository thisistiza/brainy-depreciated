import SwiftUI

extension DesignSystem.Component {
    struct DurationField: View {
        @Binding var duration: Int

        @State private var hours: String = ""
        @State private var minutes: String = ""

        private let textTypography = SwiftUI.Font.system(
            size: 24,
            weight: .heavy,
            design: .rounded
        )

        var body: some View {
            HStack {
                DesignSystem.Component.TextField(
                    text: $hours,
                    placeholder: "HH",
                    showKeyboardButton: false
                )
                .frame(width: 70)

                Text(":")
                    .font(textTypography)
                    .foregroundStyle(
                        DesignSystem.Color.System.foreground.primary
                    )

                DesignSystem.Component.TextField(
                    text: $minutes,
                    placeholder: "MM",
                    showKeyboardButton: false
                )
                .frame(width: 70)
            }
            .onAppear {
                updateStringsFromDuration()
            }
            .onChange(of: duration) { _, _ in
                updateStringsFromDuration()
            }
            .onChange(of: hours) { _, _ in updateDurationFromStrings() }
            .onChange(of: minutes) { _, _ in updateDurationFromStrings() }
        }

        private func updateStringsFromDuration() {
            let h = duration / 3600
            let m = (duration % 3600) / 60

            let newHours = h > 0 ? "\(h)" : ""
            let newMinutes: String
            if m == 0 && h == 0 {
                newMinutes = ""
            } else {
                newMinutes = String(format: "%02d", m)
            }

            if hours != newHours { hours = newHours }
            if minutes != newMinutes { minutes = newMinutes }
        }

        private func updateDurationFromStrings() {
            let h = Int(hours) ?? 0
            let m = Int(minutes) ?? 0

            let totalSeconds = (h * 3600) + (m * 60)
            let newDuration = totalSeconds

            if duration != newDuration {
                duration = newDuration
            }
        }
    }
}

extension Duration {
    func toHoursAndMinutes(
        style: Duration.UnitsFormatStyle.UnitWidth = .abbreviated
    ) -> String {
        self.formatted(
            .units(
                allowed: [.hours, .minutes],
                width: style,
                maximumUnitCount: 2,
                zeroValueUnits: .hide
            )
        )
    }
}
