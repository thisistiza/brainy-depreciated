import SwiftUI

extension DesignSystem.Component {
    struct VerticalDivider: View {
        private let cornerRadius: CGFloat = 10
        private var lineThickness: CGFloat = 3

        var body: some View {
            return RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: lineThickness)
                .foregroundStyle(DesignSystem.Color.System.foreground.secondary)
                .padding(.vertical, DS.Spacing.sm)
        }
    }
}
