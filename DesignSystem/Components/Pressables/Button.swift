import SwiftUI

extension DesignSystem.Component.Button {
    enum Style {
        case filled
        case hollow
        case plain
    }

    enum Color {
        case palette(DesignSystem.Color.Palette)
        case system(DesignSystem.Color.Palette = .sapphire)
        case systemWithIconColorAsPalette(
            DesignSystem.Color.Palette = .sapphire
        )
    }

    enum Alignment {
        case leading
        case center
    }

    enum Size {
        case compact
        case fitWithCompact
        case fitToIcon
        case standard
        case split
    }
}

extension DesignSystem.Component {
    struct Button: View {
        let icon: String?
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Button.Color
        let style: DesignSystem.Component.Button.Style
        let size: DesignSystem.Component.Button.Size
        let alignment: DesignSystem.Component.Button.Alignment
        let preserveIconColor: Bool
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        init(
            icon: String? = nil,
            text: String? = nil,
            subtext: String? = nil,
            theme: DesignSystem.Component.Button.Color = .palette(.sapphire),
            style: DesignSystem.Component.Button.Style = .filled,
            size: DesignSystem.Component.Button.Size = .standard,
            alignment: DesignSystem.Component.Button.Alignment = .center,
            preserveIconColor: Bool = false,
            isDisabled: Bool = false,
            isSelected: Bool? = nil,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.text = text
            self.subtext = subtext
            self.theme = theme
            self.style = style
            self.size = size
            self.alignment = alignment
            self.preserveIconColor = preserveIconColor
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        var body: some View {
            SwiftUI.Button(action: action) {}
                .disabled(isDisabled)
                .buttonStyle(
                    InternalButtonStyle(
                        icon: icon,
                        text: text,
                        subtext: subtext,
                        theme: theme,
                        style: style,
                        size: size,
                        alignment: alignment,
                        preserveIconColor: preserveIconColor,
                        isDisabled: isDisabled,
                        isSelected: isSelected,
                        action: action
                    )
                )
        }
    }
}

extension DesignSystem.Component.Button {
    struct InternalButtonStyle: ButtonStyle {
        let icon: String?
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Button.Color
        let style: DesignSystem.Component.Button.Style
        let size: DesignSystem.Component.Button.Size
        let alignment: DesignSystem.Component.Button.Alignment
        let preserveIconColor: Bool
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        private let textHorizontalPadding: CGFloat = 16
        private let iconSize: CGFloat = 24
        private let faceCornerRadius: CGFloat = 12
        private let depthCornerRadius: CGFloat = 16
        private let depthDistance: CGFloat = 4
        private let strokeWidth: CGFloat = 3
        private var height: CGFloat? {
            if size == .fitToIcon {
                return 24
            } else {
                return style == .hollow ? 45 - strokeWidth : 45
            }
        }
        private var maxWidth: CGFloat {
            switch size {
            case .compact: return 49
            case .fitWithCompact:
                return style == .hollow ? 303 - strokeWidth : 303  // .standard - (.compact - 8pt gap) - [strokeWidth]
            case .fitToIcon: return 24
            case .standard: return style == .hollow ? 360 - strokeWidth : 360
            case .split: return 180
            }
        }

        func makeBody(configuration: Configuration) -> some View {
            let isDown =
                isDisabled || configuration.isPressed || isSelected ?? false
            let shouldExpand = size != .compact

            return HStack {
                if subtext == nil && alignment == .center && shouldExpand {
                    Spacer(minLength: 0)
                }

                if let icon = icon {
                    if preserveIconColor {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .opacity(isDown ? 0.5 : 1)
                    } else {
                        Image(icon)
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(iconColor(isDown: isDown))
                    }
                }

                if let text = text {
                    Text(text)
                        .font(DesignSystem.Typography.buttonLabel)
                        .foregroundColor(textColor(isDown: isDown))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if shouldExpand {
                    Spacer(minLength: 0)
                    if subtext != nil {
                        Spacer(minLength: 0)
                    }
                }

                if let subtext = subtext {
                    Text(subtext)
                        .font(DesignSystem.Typography.buttonLabel)
                        .foregroundColor(subtextColor(isDown: isDown))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(
                .horizontal,
                size == .compact || size == .fitToIcon
                    ? 0 : textHorizontalPadding
            )
            .offset(y: style != .plain && isDown ? depthDistance : 0)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .background(
                ZStack {
                    if style != .plain {
                        RoundedRectangle(cornerRadius: depthCornerRadius)
                            .fill(depthColor(isDown: isDown))
                            .offset(y: depthDistance)
                        RoundedRectangle(cornerRadius: faceCornerRadius)
                            .fill(faceColor(isDown: isDown))
                            .overlay(
                                ZStack {
                                    RoundedRectangle(
                                        cornerRadius: faceCornerRadius
                                    )
                                    .fill(overlayColor(isDown: isDown))

                                    RoundedRectangle(
                                        cornerRadius: faceCornerRadius
                                    )
                                    .stroke(
                                        strokeColor(isDown: isDown),
                                        lineWidth: style != .filled
                                            ? strokeWidth : 0
                                    )
                                }
                            )
                            .offset(y: isDown ? depthDistance : 0)
                    }
                }
            )
            .sensoryFeedback(
                .impact(weight: .medium),
                trigger: configuration.isPressed
            )
            .contentShape(Rectangle())
            .animation(
                isDown
                    ? DesignSystem.Animation.push
                    : DesignSystem.Animation.release,
                value: isDown
            )
        }
    }
}

extension DesignSystem.Component.Button.InternalButtonStyle {
    private func faceColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette:
                return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            case .systemWithIconColorAsPalette:
                return DesignSystem.Color.System.background.primary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear

            case .systemWithIconColorAsPalette: return .clear
            }
        }
    }

    private func depthColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            case .systemWithIconColorAsPalette: return .clear
            }
        }
    }

    private func overlayColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.background.primary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.overlay
            case .system(let palette):
                return isDown
                    ? palette.overlay
                    : DesignSystem.Color.System.background.primary
            case .systemWithIconColorAsPalette(let palette):
                return isDown
                    ? palette.overlay
                    : DesignSystem.Color.System.background.primary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            case .systemWithIconColorAsPalette: return .clear
            }
        }
    }

    private func strokeColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.foreground.primary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            case .systemWithIconColorAsPalette: return .clear
            }
        }
    }

    private func iconColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.background.primary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.background.primary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette(let palette): return palette.base
            }
        } else {
            switch theme {
            case .palette(let palette):
                return isDown ? palette.bold : palette.base
            case .system:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            }
        }
    }

    private func textColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.background.primary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.background.primary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.foreground.primary
            }
        } else {
            switch theme {
            case .palette(let palette):
                return isDown ? palette.subtle : palette.base
            case .system:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            }
        }
    }

    private func subtextColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.background.primary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            case .plain: return .clear
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            case .systemWithIconColorAsPalette(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette(let palette):
                return isDown ? palette.bold : palette.base
            case .system:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            case .systemWithIconColorAsPalette:
                return isDown
                    ? DesignSystem.Color.System.foreground.secondary
                    : DesignSystem.Color.System.foreground.primary
            }
        }
    }
}
