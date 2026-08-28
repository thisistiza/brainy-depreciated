import SwiftUI

extension DesignSystem.Component.Header {
    enum Style {
        case filled
        case hollow
    }

    enum Color {
        case palette(DesignSystem.Color.Palette)
        case system(DesignSystem.Color.Palette = .sapphire)
    }
}

extension DesignSystem.Component {
    struct Header: View {
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Header.Color
        let style: DesignSystem.Component.Header.Style
        let rating: Double?
        let charge: Double?
        let matchingRule: TagMatchingRule?
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        init(
            text: String? = nil,
            subtext: String? = nil,
            theme: DesignSystem.Component.Header.Color = .palette(.sapphire),
            style: DesignSystem.Component.Header.Style = .filled,
            rating: Double? = nil,
            charge: Double? = nil,
            matchingRule: TagMatchingRule? = nil,
            isDisabled: Bool = false,
            isSelected: Bool? = nil,
            action: @escaping () -> Void
        ) {
            self.text = text
            self.subtext = subtext
            self.theme = theme
            self.style = style
            self.rating = rating
            self.charge = charge
            self.matchingRule = matchingRule
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        var body: some View {
            SwiftUI.Button(action: action) {}
                .disabled(isDisabled)
                .buttonStyle(
                    InternalHeaderStyle(
                        text: text,
                        subtext: subtext,
                        theme: theme,
                        style: style,
                        rating: rating,
                        charge: charge,
                        matchingRule: matchingRule,
                        isDisabled: isDisabled,
                        isSelected: isSelected,
                        action: action
                    )
                )
        }
    }
}

extension DesignSystem.Component.Header {
    struct InternalHeaderStyle: ButtonStyle {
        let text: String?
        let subtext: String?
        let theme: DesignSystem.Component.Header.Color
        let style: DesignSystem.Component.Header.Style
        let rating: Double?
        let charge: Double?
        let matchingRule: TagMatchingRule?
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        private let horizontalPadding: CGFloat = 16
        private let iconSize: CGFloat = 24
        private let faceCornerRadius: CGFloat = 12
        private let depthCornerRadius: CGFloat = 16
        private let depthDistance: CGFloat = 4
        private let strokeWidth: CGFloat = 3
        private var height: CGFloat { style == .hollow ? 65-strokeWidth : 65 }
        private var maxWidth: CGFloat? { style == .hollow ? 360-strokeWidth-2 : 360 }

        init(
            text: String?,
            subtext: String?,
            theme: DesignSystem.Component.Header.Color,
            style: DesignSystem.Component.Header.Style,
            rating: Double?,
            charge: Double?,
            matchingRule: TagMatchingRule?,
            isDisabled: Bool,
            isSelected: Bool?,
            action: @escaping () -> Void
        ) {
            self.text = text
            self.subtext = subtext
            self.theme = theme
            self.style = style
            self.rating = rating
            self.charge = charge
            self.matchingRule = matchingRule
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        func makeBody(configuration: Configuration) -> some View {
            let isDown =
                isDisabled || configuration.isPressed || isSelected ?? false

            return HStack {
                VStack(spacing: 0) {
                    if let subtext = subtext {
                        HStack {
                            Text(subtext)
                                .font(DesignSystem.Typography.buttonLabel)
                                .foregroundColor(subtextColor(isDown: isDown))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.horizontal, horizontalPadding)
                            Spacer()
                            if let matchingRule = matchingRule{
                                switch matchingRule {
                                case .universal:
                                    Image("circleSmall")
                                        .renderingMode(.template)
                                        .foregroundColor(matchingRuleColor(isDown: isDown))
                                case .union:
                                    Image("vennDiagramUnion")
                                        .renderingMode(.template)
                                        .foregroundColor(matchingRuleColor(isDown: isDown))

                                case .subset:
                                    Image("vennDiagramSubset")
                                        .renderingMode(.template)
                                        .foregroundColor(matchingRuleColor(isDown: isDown))

                                case .intersection:
                                    Image("vennDiagramIntersection")
                                        .renderingMode(.template)
                                        .foregroundColor(matchingRuleColor(isDown: isDown))

                                case .complement, .complementOfUnion, .complementOfIntersection, .complementOfSubset:
                                    Image("vennDiagramComplement")
                                        .renderingMode(.template)
                                        .foregroundColor(matchingRuleColor(isDown: isDown))
                                }
                            }
                        }
                    }
                    if let text = text {
                        HStack {
                            Text(text)
                                .font(DesignSystem.Typography.buttonLabel)
                                .foregroundColor(textColor(isDown: isDown))
                                .padding(.horizontal, horizontalPadding)
                                .lineLimit(1)
                                .truncationMode(.tail)
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                Text(text)
//                                    .font(DesignSystem.Typography.buttonLabel)
//                                    .foregroundColor(textColor(isDown: isDown))
//                                    .padding(.horizontal, horizontalPadding)
//                            }.fadeEdges(.horizontal)
                            Spacer()
                        }
                    }
                }
                Spacer()
                if let charge = charge{
                    Rectangle()
                        .frame(width: 3, height: height)
                        .foregroundColor(dividerColor(isDown: isDown))
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            if charge >= 0.6 {
                                Image("batteryHighMono")
                            } else if charge >= 0.3 {
                                Image("batteryMediumMono")
                            } else {
                                Image("batteryLowMono")
                            }
                        }
                    }
                }
                Spacer()
                if let rating = rating{
                    Rectangle()
                        .frame(width: 3, height: height)
                        .foregroundColor(dividerColor(isDown: isDown))
                    HStack(spacing: 0) {
                        let roundedRating = (rating * 2).rounded() / 2
                        
                        ForEach(0..<3, id: \.self) { i in
                            let starIndex = Double(i)
                            
                            if roundedRating >= starIndex + 1.0 {
                                Image("starFilledMono")
                            } else if roundedRating >= starIndex + 0.5 {
                                Image("starHalfMono")
                            } else {
                                Image("starEmpty")
                            }
                        }
                    }.padding(.horizontal, horizontalPadding)
                }
            }
            .offset(y: isDown ? depthDistance : 0)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: depthCornerRadius)
                        .fill(depthColor(isDown: isDown))
                        .offset(y: depthDistance + 1)
                    RoundedRectangle(cornerRadius: faceCornerRadius)
                        .fill(faceColor(isDown: isDown))
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: faceCornerRadius)
                                    .fill(overlayColor(isDown: isDown))

                                RoundedRectangle(cornerRadius: faceCornerRadius)
                                    .stroke(
                                        strokeColor(isDown: isDown),
                                        lineWidth: style != .filled
                                            ? strokeWidth : 0
                                    )
                            }
                        )
                        .offset(y: isDown ? depthDistance : 0)
                }
            )
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

extension DesignSystem.Component.Header.InternalHeaderStyle {
    private func faceColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            }
        }
    }

    private func depthColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            }
        }
    }

    private func overlayColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.background.primary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.overlay
            case .system(let palette):
                return isDown
                    ? palette.overlay
                    : DesignSystem.Color.System.background.primary
            }
        } else {
            switch theme {
            case .palette(_): return .clear
            case .system: return .clear
            }
        }
    }

    private func dividerColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.background.overlay
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            }
        }
    }

    private func strokeColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.background.primary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system(let palette):
                return isDown
                    ? palette.base
                    : DesignSystem.Color.System.foreground.secondary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            }
        }
    }

    private func iconColor() -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.foreground.secondary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.subtle
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            }
        } else {
            switch theme {
            case .palette: return .clear
            case .system: return .clear
            }
        }
    }

    private func textColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.background.primary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette: return DesignSystem.Color.System.background.primary
            case .system: return DesignSystem.Color.System.background.primary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.primary
            }
        } else {
            switch theme {
            case .palette(let palette):
                return isDown ? palette.bold : palette.base
            case .system:
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
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system(let palette):
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
            }
        }
    }
    
    private func matchingRuleColor(isDown: Bool) -> Color {
        if isDisabled {
            switch style {
            case .filled: return DesignSystem.Color.System.background.primary
            case .hollow: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .filled {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        } else if style == .hollow {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system(let palette):
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
            }
        }
    }
}
