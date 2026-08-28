import SwiftUI

extension DesignSystem.Component {
    struct Capsule: View {
        let icon: String?
        let text: String
        let palette: DesignSystem.Color.Palette?
        let onRemove: (() -> Void)?

        init(
            icon: String? = nil,
            text: String,
            palette: DesignSystem.Color.Palette? = nil,
            onRemove: (() -> Void)? = nil
        ) {
            self.icon = icon
            self.text = text
            self.palette = palette
            self.onRemove = onRemove
        }

        var faceColor: Color {
            palette?.overlay ?? DS.Color.System.foreground.overlay
        }
        var iconColor: Color {
            palette?.base ?? DS.Color.System.foreground.primary
        }
        var textColor: Color {
            palette?.base ?? DS.Color.System.foreground.primary
        }

        private let cornerRadius: CGFloat = 100
        @State private var pressTrigger: Int = 0

        var body: some View {
            HStack(spacing: DS.Spacing.sm) {
                if let icon = icon {
                    Image(icon)
                        .renderingMode(.template)
                        .foregroundColor(iconColor)
                }

                Text(text)
                    .font(DesignSystem.Typography.tagLabel)
                    .foregroundColor(textColor)
                    .lineLimit(1)

                if let onRemove = onRemove {
                    SwiftUI.Button(action: {
                        pressTrigger += 1
                        onRemove()
                    }) {
                        Image("crossCircled")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(iconColor)
                            .frame(width: DS.Spacing.md, height: DS.Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(
                        .impact(weight: .medium),
                        trigger: pressTrigger
                    )
                }
            }
            .padding(.leading, DS.Spacing.sm)
            .padding(.trailing, onRemove == nil ? DS.Spacing.sm : DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xs)
            .background(SwiftUI.Capsule().fill(faceColor))
        }
    }
}
