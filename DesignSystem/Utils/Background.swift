import SwiftUI

struct GlobalBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color(DesignSystem.Color.System.background.primary)
                .ignoresSafeArea()

            content
                .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    func applyAppBackground() -> some View {
        self.modifier(GlobalBackground())
    }
}

extension View {
    func dashedBorder(
        color: Color = DS.Color.System.foreground.secondary,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        dash: [CGFloat] = [6, 4]
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: dash
                    )
                )
        )
    }
}
