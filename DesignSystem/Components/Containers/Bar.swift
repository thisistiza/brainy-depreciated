import SwiftUI

extension DesignSystem.Component {
    struct Bar<Content: View>: View {
        let content: Content
        
        private let height: CGFloat = 45
        private let faceCornerRadius: CGFloat = 12
        private let depthCornerRadius: CGFloat = 16
        private let depthDistance: CGFloat = 4
        private let strokeWidth: CGFloat = 3
        
        init(
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
        }
        
        var body: some View {
            content
                .frame(height: height)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: depthCornerRadius)
                            .fill(DesignSystem.Color.System.foreground.secondary)
                            .offset(y: depthDistance + 1)
                        
                        RoundedRectangle(cornerRadius: faceCornerRadius)
                            .fill(DesignSystem.Color.System.background.primary)
                            .overlay(
                                ZStack {
                                    RoundedRectangle(cornerRadius: faceCornerRadius)
                                        .stroke(
                                            DesignSystem.Color.System.foreground
                                                .secondary,
                                            lineWidth: strokeWidth
                                        )
                                }
                            )
                    }
                )
        }
    }
}
