import SwiftUI

struct FadeEdges: ViewModifier {
    enum Direction {
        case vertical, horizontal
    }
    
    let direction: Direction
    let fadeLength: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: fadeLength / 500),
                        .init(color: .black, location: 1 - (fadeLength / 500)),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: direction == .vertical ? .top : .leading,
                    endPoint: direction == .vertical ? .bottom : .trailing
                )
            )
    }
}

extension View {
    func fadeEdges(_ direction: FadeEdges.Direction) -> some View {
        self.modifier(FadeEdges(direction: direction))
    }
}
