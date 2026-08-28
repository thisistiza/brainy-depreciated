import SwiftUI

enum ModalHeight{
    case height(CGFloat), full, almostFull
}

extension DesignSystem.Component {
    struct Modal<Content: View>: View {
        @Binding var isPresented: Bool
        let isBottom: Bool
        let height: ModalHeight
        let content: Content
        
        init(
            isPresented: Binding<Bool>,
            isBottom: Bool = true,
            height: ModalHeight = .almostFull,
            @ViewBuilder content: () -> Content
        ) {
            self._isPresented = isPresented
            self.isBottom = isBottom
            self.height = height
            self.content = content()
        }
        
        private func getHeight(height: ModalHeight, geometryHeight: CGFloat) -> CGFloat{
            switch height{
            case .height(let value): value
            case .full: geometryHeight
            case .almostFull: geometryHeight - 70
            }
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: isBottom ? .bottom : .top) {
                    if isPresented {
                        DesignSystem.Color.System.foreground.overlay.opacity(0.5) // Background Dimmer
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    isPresented = false
                                }
                            }
                            .transition(.opacity)
                        
                        VStack(spacing: 0) {
                            content
                                .frame(maxWidth: .infinity)
                                .frame(height: getHeight(height: height, geometryHeight: geometry.size.height))
                        }
                        .background(
                            DesignSystem.Color.System.background.primary
                        )
                        .transition(.move(edge: isBottom ? .bottom : .top))
                        .zIndex(1)
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(DS.Animation.springForPaneTransition, value: isPresented)
            .ignoresSafeArea()
        }
    }
}
