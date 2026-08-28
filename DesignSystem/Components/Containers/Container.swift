import SwiftUI

extension DesignSystem.Component {
    struct ContentContainer<Content: View>: View {
        let content: () -> Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        
        var body: some View {
            content()
                .frame(maxWidth: DS.Constant.maxContentWidth)
                .overlay(
                    HStack {
                        Rectangle()
                            .fill(DS.Color.System.foreground.overlay) // Adjust to your design system color
                            .frame(width: 1)
                        Spacer()
                        Rectangle()
                            .fill(DS.Color.System.foreground.overlay) // Adjust to your design system color
                            .frame(width: 1)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
