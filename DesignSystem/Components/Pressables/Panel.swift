import SwiftUI

extension DesignSystem.Component.Panel {
    enum Color {
        case palette(DesignSystem.Color.Palette)
        case system(DesignSystem.Color.Palette = .sapphire)
    }
}

extension DesignSystem.Component {
    struct Panel: View {
        let icon: String?
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Panel.Color
        let rating: Float
        let charge: Float
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        init(
            icon: String? = nil,
            text: String? = nil,
            subtext: String? = nil,
            theme: DesignSystem.Component.Panel.Color = .palette(.sapphire),
            rating: Float = 0,
            charge: Float = 0,
            isDisabled: Bool = false,
            isSelected: Bool? = nil,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.text = text
            self.subtext = subtext
            self.theme = theme
            self.rating = rating
            self.charge = charge
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        var body: some View {
            SwiftUI.Button(action: action) {}
                .disabled(isDisabled)
                .buttonStyle(
                    InternalPanelStyle(
                        icon: icon,
                        text: text,
                        subtext: subtext,
                        theme: theme,
                        rating: rating,
                        charge: charge,
                        isDisabled: isDisabled,
                        isSelected: isSelected,
                        action: action
                    )
                )
        }
    }
}

extension DesignSystem.Component.Panel {
    struct InternalPanelStyle: ButtonStyle {
        let icon: String?
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Panel.Color
        let rating: Float
        let charge: Float
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        private let horizontalPadding: CGFloat = 16
        private let iconSize: CGFloat = 24
        private let faceCornerRadius: CGFloat = 16
        private let depthCornerRadius: CGFloat = 16
        private let depthDistance: CGFloat = 24
        private let strokeWidth: CGFloat = 4
        private var height: CGFloat = 65
        private var maxWidth: CGFloat = 100
        private var starSize: CGFloat = 15

        init(
            icon: String?,
            text: String?,
            subtext: String?,
            theme: DesignSystem.Component.Panel.Color,
            rating: Float,
            charge: Float,
            isDisabled: Bool,
            isSelected: Bool?,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.text = text
            self.subtext = subtext
            self.theme = theme
            self.rating = rating
            self.charge = charge
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        func makeBody(configuration: Configuration) -> some View {
            let isDown =
                isDisabled || configuration.isPressed || isSelected ?? false

            return VStack(spacing: 0) {
                if let text = text {
                    HStack(spacing: 0) {
                        Spacer()
                        if let icon = icon {
                            Image(icon)
                                .frame(width: 10, height: 10)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                                .opacity(isDown ? 0.5 : 1)
                        }
                        Text(text)
                            .font(DesignSystem.Typography.buttonLabel)
                            .foregroundColor(textColor(isDown: isDown))
                            .padding(.horizontal, horizontalPadding)
                    }
                }
            }
            .offset(y: isDown ? depthDistance : 0)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .background(
                ZStack {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: depthCornerRadius)
                            .fill(depthColor(isDown: isDown))

                        if let subtext = subtext {
                            HStack {
                                Text(subtext)
                                    .font(DesignSystem.Typography.panelLabel)
                                    .foregroundColor(
                                        subtextColor(isDown: isDown)
                                    )
                                    .padding(DS.Spacing.xs)
                            }
                        }
                    }
                    .offset(y: depthDistance)
                    RoundedRectangle(cornerRadius: faceCornerRadius)
                        .fill(faceColor(isDown: isDown))
                        .frame(maxWidth: maxWidth - strokeWidth)
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: faceCornerRadius)
                                    .stroke(
                                            strokeColor(isDown: isDown),
                                            lineWidth: strokeWidth
                                        )
                            }
                        )
                        .offset(y: isDown ? depthDistance : 0)
                }
            )
            .padding(.bottom, depthDistance)
            .sensoryFeedback(
                .impact(weight: .medium),
                trigger: configuration.isPressed
            )
            .animation(
                isDown
                    ? DesignSystem.Animation.push
                    : DesignSystem.Animation.release,
                value: isDown
            )
        }
    }
}

extension DesignSystem.Component.Panel.InternalPanelStyle {
    private func faceColor(isDown: Bool) -> Color {
        return DesignSystem.Color.System.background.primary
    }

    private func depthColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.overlay
            }
        }
    }

    private func strokeColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.overlay
            }
        }
    }

    private func iconColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.primary
        } else {
            switch theme {
            case .palette:
                return DesignSystem.Color.System.foreground.primary
            case .system:
                return DesignSystem.Color.System.foreground.primary
            }
        }
    }

    private func textColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.primary
        } else {
            switch theme {
            case .palette:
                return DesignSystem.Color.System.foreground.primary
            case .system:
                return DesignSystem.Color.System.foreground.primary
            }
        }
    }

    private func subtextColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.background.primary
        } else {
            switch theme {
            case .palette:
                return DesignSystem.Color.System.background.primary
            case .system:
                return DesignSystem.Color.System.background.primary
            }
        }
    }
}
