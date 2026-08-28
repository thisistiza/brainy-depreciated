import SwiftUI

extension DesignSystem.Component {
    struct ProgressBar: View {
        var progress: CGFloat
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    SwiftUI.Capsule()
                        .fill(DesignSystem.Color.System.foreground.overlay)
                    
                    SwiftUI.Capsule()
                        .fill(DesignSystem.Color.Palette.emerald.base)
                        .mask(
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 100)
                                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
                                Spacer(minLength: 0)
                            }
                        )
                        .animation(.spring(duration: 0.5), value: progress)
                }
            }
            .frame(height: 15)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var progress: CGFloat = 0.03
        
        var body: some View {
            VStack(spacing: 20) {
                DesignSystem.Component.ProgressBar(progress: progress)
                    .padding(.horizontal)
                
                Slider(value: $progress, in: 0...1)
                    .padding(.horizontal)
            }
        }
    }
    
    return PreviewWrapper()
}
