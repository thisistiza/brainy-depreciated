import SwiftUI

extension DesignSystem.Typography {
    // titles
    static let titleLarge = SwiftUI.Font.system(size: 32, weight: .black, design: .rounded)
    static let titleMedium = SwiftUI.Font.system(size: 18, weight: .black, design: .rounded)
    static let titleSmall = SwiftUI.Font.system(size: 20, weight: .bold, design: .rounded)
    
    // Body
    static let bodyLarge = SwiftUI.Font.system(size: 18, weight: .bold, design: .rounded)
    static let bodyMedium = SwiftUI.Font.system(size: 18, weight: .medium, design: .rounded)
    static let bodySmall = SwiftUI.Font.system(size: 18, weight: .regular, design: .rounded)
    
    // Dialog
    static let dialog = SwiftUI.Font.system(size: 20, weight: .bold, design: .rounded)
    
    // Component
    static let buttonLabel = SwiftUI.Font.system(size: 16, weight: .heavy, design: .rounded)
    static let panelLabel = SwiftUI.Font.system(size: 14, weight: .heavy, design: .rounded)
    static let dateFieldLabel = SwiftUI.Font.system(size: 24, weight: .heavy, design: .rounded)
    static let textFieldLabel = SwiftUI.Font.system(size: 16, weight: .heavy, design: .rounded)
    static let tagLabel = SwiftUI.Font.system(size: 16, weight: .semibold, design: .rounded)
    static let blockLabel = SwiftUI.Font.system(size: 14, weight: .bold, design: .rounded)
    
    // Code
    static let code = SwiftUI.Font.system(size: 14, weight: .regular, design: .monospaced)
}
