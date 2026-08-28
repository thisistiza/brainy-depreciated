import SwiftUI

extension DesignSystem.Animation {
    static var push: SwiftUI.Animation {
        .easeOut(duration: 0.05)
    }

    static var release: SwiftUI.Animation {
        .spring(response: 0.3, dampingFraction: 0.5)
    }
}

extension DesignSystem.Animation {
    static var springForPaneTransition: SwiftUI.Animation {
        .spring(response: 0.3, dampingFraction: 0.9)
    }
}

extension DesignSystem.Animation {
    static var handleIcon: SwiftUI.Animation {
        .easeInOut(duration: 0.2)
    }
}

extension AnyTransition {
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.1, anchor: .leading).combined(
                with: opacity
            ),
            removal: .scale(scale: 0.1, anchor: .leading).combined(
                with: opacity
            )
        )
    }
}

struct JiggleModifier: ViewModifier {
    let enabled: Bool
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(enabled && isAnimating ? 2.5 : 0))
            .offset(
                x: enabled && isAnimating ? 1.5 : 0,
                y: enabled && isAnimating ? -1.0 : 0
            )
            .onAppear {
                let randomDelay = Double.random(in: 0...0.05)

                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    withAnimation(
                        .linear(duration: 0.1).repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
            }
    }
}


struct ShakeModifier: ViewModifier {
    @Binding var trigger: Int
    @State private var animatableTrigger: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: animatableTrigger))
            .onChange(of: trigger) { _, _ in
                guard trigger > 0 else { return }
                withAnimation(.linear(duration: 0.4)) {
                    animatableTrigger = 1
                } completion: {
                    animatableTrigger = 0
                }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 3
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func jiggle(enabled: Bool) -> some View {
        self.modifier(JiggleModifier(enabled: enabled))
    }
}

extension View {
    func shake(trigger: Binding<Int>) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}
