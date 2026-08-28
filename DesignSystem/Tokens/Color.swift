import SwiftUI

extension DesignSystem.Color {
    enum System: String, Hashable, Codable, CaseIterable {
        case foreground, background

        var primary: SwiftUI.Color {
            switch self {
            case .foreground:
                return SwiftUI.Color.Theme.System.foregroundPrimary
            default: return SwiftUI.Color.Theme.System.background
            }
        }

        var secondary: SwiftUI.Color {
            switch self {
            case .foreground:
                return SwiftUI.Color.Theme.System.foregroundSecondary
            default: return SwiftUI.Color.Theme.System.background
            }
        }

        var overlay: SwiftUI.Color {
            switch self {
            case .foreground:
                return SwiftUI.Color.Theme.System.foregroundOverlay
            default: return SwiftUI.Color.Theme.System.background
            }
        }
    }

    enum Palette: String, Hashable, Codable, CaseIterable {
        case ruby, emerald, sapphire, gold, amethyst, iron

        var base: SwiftUI.Color {
            switch self {
            case .ruby: return SwiftUI.Color.Theme.Palette.Ruby.base
            case .emerald: return SwiftUI.Color.Theme.Palette.Emerald.base
            case .sapphire: return SwiftUI.Color.Theme.Palette.Sapphire.base
            case .gold: return SwiftUI.Color.Theme.Palette.Gold.base
            case .amethyst: return SwiftUI.Color.Theme.Palette.Amethyst.base
            case .iron: return SwiftUI.Color.Theme.Palette.Iron.base
            }
        }

        var bold: SwiftUI.Color {
            switch self {
            case .ruby: return SwiftUI.Color.Theme.Palette.Ruby.bold
            case .emerald: return SwiftUI.Color.Theme.Palette.Emerald.bold
            case .sapphire: return SwiftUI.Color.Theme.Palette.Sapphire.bold
            case .gold: return SwiftUI.Color.Theme.Palette.Gold.bold
            case .amethyst: return SwiftUI.Color.Theme.Palette.Amethyst.bold
            case .iron: return SwiftUI.Color.Theme.Palette.Iron.bold
            }
        }

        var subtle: SwiftUI.Color {
            switch self {
            case .ruby: return SwiftUI.Color.Theme.Palette.Ruby.subtle
            case .emerald: return SwiftUI.Color.Theme.Palette.Emerald.subtle
            case .sapphire: return SwiftUI.Color.Theme.Palette.Sapphire.subtle
            case .gold: return SwiftUI.Color.Theme.Palette.Gold.subtle
            case .amethyst: return SwiftUI.Color.Theme.Palette.Amethyst.subtle
            case .iron: return SwiftUI.Color.Theme.Palette.Iron.subtle
            }
        }

        var overlay: SwiftUI.Color {
            switch self {
            case .ruby: return SwiftUI.Color.Theme.Palette.Ruby.overlay
            case .emerald: return SwiftUI.Color.Theme.Palette.Emerald.overlay
            case .sapphire: return SwiftUI.Color.Theme.Palette.Sapphire.overlay
            case .gold: return SwiftUI.Color.Theme.Palette.Gold.overlay
            case .amethyst: return SwiftUI.Color.Theme.Palette.Amethyst.overlay
            case .iron: return SwiftUI.Color.Theme.Palette.Iron.overlay
            }
        }
    }
}
