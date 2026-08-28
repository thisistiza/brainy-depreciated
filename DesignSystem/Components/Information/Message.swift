import SwiftUI

extension DesignSystem.Component {
    struct Message: View {
        let icon: String
        let textView: Text
        let palette: DesignSystem.Color.Palette
        
        var body: some View {
            HStack(alignment: .top){
                Image(icon)
                textView
                Spacer()
            }
            .font(DesignSystem.Typography.bodyLarge)
            .foregroundColor(palette.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Spacing.md)
                    .fill(palette.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Spacing.md)
                    .stroke(
                        palette.base,
                        lineWidth: 3
                    )
            )
        }
    }
}
