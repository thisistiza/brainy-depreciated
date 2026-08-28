import SwiftUI

extension DesignSystem.Component {
    struct HorizontalDivider: View {
        private let cornerRadius: CGFloat = 10
        private var lineThickness: CGFloat = 3
        
        var body: some View {
            return RoundedRectangle(cornerRadius: cornerRadius)
                .frame(height: lineThickness)
                .foregroundStyle(DesignSystem.Color.System.foreground.secondary)
                .padding(.horizontal, DS.Spacing.sm)
            
        }
    }
}
