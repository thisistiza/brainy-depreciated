import SwiftUI

extension DesignSystem.Component.Tile {
    enum Color {
        case palette(DesignSystem.Color.Palette)
        case system(DesignSystem.Color.Palette = .sapphire)
    }
}

extension DesignSystem.Component {
    struct Tile: View {
        let text: String?
        let subtext: String?
        let tags: [Tag]?
        let theme: DesignSystem.Component.Tile.Color
        let isPass: Bool?
        let rating: Double?
        let charge: Double?
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        init(
            text: String? = nil,
            subtext: String? = nil,
            tags: [Tag]? = nil,
            theme: DesignSystem.Component.Tile.Color = .palette(.sapphire),
            isPass: Bool? = nil,
            rating: Double? = nil,
            charge: Double? = nil,
            isDisabled: Bool = false,
            isSelected: Bool? = nil,
            action: @escaping () -> Void
        ) {
            self.text = text
            self.subtext = subtext
            self.tags = tags
            self.theme = theme
            self.isPass = isPass
            self.rating = rating
            self.charge = charge
            self.isDisabled = isDisabled
            self.isSelected = isSelected
            self.action = action
        }

        var body: some View {
            HStack {
                SwiftUI.Button(action: action) {}
                    .disabled(isDisabled)
                    .buttonStyle(
                        InternalTileStyle(
                            theme: theme,
                            rating: rating,
                            charge: charge,
                            isDisabled: isDisabled,
                            isSelected: isSelected,
                            action: action
                        )
                    )
                VStack(alignment: .leading) {
                    HStack{
                        Text(subtext ?? "")
                            .font(DesignSystem.Typography.bodyLarge)
                            .foregroundStyle(subTextColor())
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(text ?? "")
                            .font(DesignSystem.Typography.bodyLarge)
                            .foregroundStyle(DesignSystem.Color.System.foreground.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    HStack{
                        if let isPass = isPass{
                            Image(isPass ? "checkCircled" : "crossCircled")
                        }
                        if let tags = tags{
                            viewableTagListView(for: tags)
                        }
                        else{
                            DS.Component.Capsule(text: "Tags Hidden")
                        }
                    }
                }

            }
        }
    }
}

extension DesignSystem.Component.Tile{
    private func viewableTagListView(for tags: [Tag]) -> some View {
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                if tags.isEmpty {
                    DS.Component.Capsule(text: "No Tags")
                }
                ForEach(tags.sorted { $0.createdAt > $1.createdAt }) { tag in
                    DS.Component.Capsule(
                        text: tag.name,
                        palette: tag.color
                    )
                }
                Spacer()
            }
        }.clipShape(Capsule())
    }
    private func subTextColor() -> SwiftUI.Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        }
    }
}

extension DesignSystem.Component.Tile {
    struct InternalTileStyle: ButtonStyle {
        let theme: DesignSystem.Component.Tile.Color
        let rating: Double?
        let charge: Double?
        let isDisabled: Bool
        var isSelected: Bool?
        let action: () -> Void

        private let horizontalPadding: CGFloat = 16
        private let iconSize: CGFloat = 24
        private let faceCornerRadius: CGFloat = 15
        private let depthCornerRadius: CGFloat = 13
        private let depthDistance: CGFloat = 5
        private let strokeWidth: CGFloat = 5
        private var height: CGFloat? = 54
        private var maxWidth: CGFloat? = 56
        private var starSize: CGFloat = 15 //14
        private var silhouetteSize: CGFloat = 20

        init(
            theme: DesignSystem.Component.Tile.Color,
            rating: Double?,
            charge: Double?,
            isDisabled: Bool,
            isSelected: Bool?,
            action: @escaping () -> Void
        ) {
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
                if let charge = charge{
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
                else{
                    Image("silhouette")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(iconColor())
                        .frame(width: silhouetteSize, height: silhouetteSize)
                }
                if let rating = rating{
                    let starsYOffset = 3.0
                    HStack(spacing: DS.Spacing.xxs) {
                        let roundedRating = (rating * 2).rounded() / 2
                        
                        ForEach(0..<3, id: \.self) { i in
                            let starIndex = Double(i)
                            let yOffset = i != 1 ? -5.0  : 0.0
                            Group {
                                if roundedRating >= starIndex + 1.0 {
                                    Image("starFilledMono")
                                        .resizable()
                                        .frame(width: starSize, height: starSize)
                                } else if roundedRating >= starIndex + 0.5 {
                                    Image("starHalfMono")
                                        .resizable()
                                        .frame(width: starSize, height: starSize)
                                } else {
                                    Image("starEmpty").resizable()
                                        .resizable()
                                        .frame(width: starSize, height: starSize)
                                }
                            }
                            .offset(y: yOffset)
                        }
                    }
                    .offset(y: starsYOffset)
                    .padding(.horizontal, horizontalPadding)
                }
            }
            .offset(y: isDown ? depthDistance : 0)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: faceCornerRadius)
                        .fill(depthColor(isDown: isDown))
                        .offset(y: depthDistance + 1)
                    RoundedRectangle(cornerRadius: faceCornerRadius)
                        .fill(faceColor(isDown: isDown))
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

extension DesignSystem.Component.Tile.InternalTileStyle {
    private func faceColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.base
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        }
    }

    private func depthColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.overlay
            }
        }
    }

    private func strokeColor(isDown: Bool) -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.subtle
            case .system: return DesignSystem.Color.System.foreground.overlay
            }
        }
    }
    
    private func iconColor() -> Color {
        if isDisabled {
            return DesignSystem.Color.System.foreground.secondary
        } else {
            switch theme {
            case .palette(let palette): return palette.bold
            case .system: return DesignSystem.Color.System.foreground.secondary
            }
        }
    }
}
