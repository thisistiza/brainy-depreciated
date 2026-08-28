import PencilKit
import SwiftUI

enum CanvasTool {
    case pen
    case eraser
}

enum CanvasToolSize: Int {
    case extraSmall = 2
    case small = 4
    case medium = 8
    case large = 60
}

enum ToolColor: Equatable {
    case primary
    case sapphire
    case amethyst
    case emerald
    case ruby
    case iron
    case gold

    var color: Color {
        switch self {
        case .primary: return .black
        case .sapphire: return Color(
            red: 45 / 255.0,
            green: 155 / 255.0,
            blue: 240 / 255.0,
            opacity: 1.0
        )
        case .amethyst:
            return Color(
                red: 195 / 255.0,
                green: 75 / 255.0,
                blue: 245 / 255.0,
                opacity: 1.0
            )
        case .emerald: return DS.Color.Palette.emerald.base
        case .ruby: return DS.Color.Palette.ruby.base
        case .iron: return DS.Color.Palette.iron.base
        case .gold: return DS.Color.Palette.gold.base
        }
    }

    var theme: DesignSystem.Component.Button.Color {
        switch self {
        case .sapphire: return .palette(.sapphire)
        case .amethyst: return .palette(.amethyst)
        case .emerald: return .palette(.emerald)
        case .ruby: return .palette(.ruby)
        case .iron: return .palette(.iron)
        case .gold: return .palette(.gold)
        case .primary: return .system(.sapphire)
        }
    }
}
struct CanvasEditBar: View {
    @Binding var currentTool: CanvasTool
    @Binding var toolSize: CanvasToolSize
    @Binding var toolColor: ToolColor
    @Binding var canvasHistoryAction: canvasHistoryAction?

    var body: some View {
        DS.Component.Bar {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // Undo/Redo Buttons
                    DS.Component.Button(
                        icon: "loopLeft",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact
                    ) { canvasHistoryAction = .undo }
                    DS.Component.Button(
                        icon: "loopRight",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact
                    ) { canvasHistoryAction = .redo }

                    DesignSystem.Component.VerticalDivider()

                    // Tool Selection
                    DesignSystem.Component.Button(
                        icon: "pen",
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true,
                        isSelected: currentTool == .pen
                    ) { currentTool = .pen }
                    DesignSystem.Component.Button(
                        icon: "eraser",
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true,
                        isSelected: currentTool == .eraser
                    ) { currentTool = .eraser }

                    DesignSystem.Component.VerticalDivider()

                    // Size Buttons
                    DesignSystem.Component.Button(
                        icon: "circleExtraSmall",
                        theme: toolColor.theme,
                        style: .plain,
                        size: .compact,
                        isSelected: toolSize == .extraSmall
                    ) { toolSize = .extraSmall }
                    DesignSystem.Component.Button(
                        icon: "circleSmall",
                        theme: toolColor.theme,
                        style: .plain,
                        size: .compact,
                        isSelected: toolSize == .small
                    ) { toolSize = .small }
                    DesignSystem.Component.Button(
                        icon: "circleMedium",
                        theme: toolColor.theme,
                        style: .plain,
                        size: .compact,
                        isSelected: toolSize == .medium
                    ) { toolSize = .medium }
                    DesignSystem.Component.Button(
                        icon: "circleLarge",
                        theme: toolColor.theme,
                        style: .plain,
                        size: .compact,
                        isSelected: toolSize == .large
                    ) { toolSize = .large }

                    DesignSystem.Component.VerticalDivider()

                    // Color Buttons
                    DesignSystem.Component.Button(
                        icon: "splitCircle",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact,
                        preserveIconColor: true,
                        isSelected: toolColor == .primary
                    ) {
                        toolColor = .primary
                    }
                    colorButton(for: .sapphire)
                    colorButton(for: .amethyst)
                    colorButton(for: .emerald)
                    colorButton(for: .ruby)
                    colorButton(for: .iron)
                    colorButton(for: .gold)
                }
                .padding(.horizontal, 16)
            }
            .fadeEdges(.horizontal)
            .frame(width: 300)
        }
    }

    @ViewBuilder
    private func colorButton(for color: ToolColor) -> some View {
        DesignSystem.Component.Button(
            icon: "circleLarge",
            theme: color.theme,
            style: .plain,
            size: .compact,
            isSelected: toolColor == color
        ) {
            currentTool = .pen
            toolColor = color
        }
    }
}
