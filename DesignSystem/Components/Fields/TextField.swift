import SwiftUI

extension DesignSystem.Component {
    struct TextField: View {
        @Binding var text: String
        let placeholder: String
        let showKeyboardButton: Bool
        
        @FocusState private var isFocused: Bool

        init(
            text: Binding<String>,
            placeholder: String,
            showKeyboardButton: Bool = true
        ) {
            self._text = text
            self.placeholder = placeholder
            self.showKeyboardButton = showKeyboardButton
        }

        private let faceColor = DesignSystem.Color.System.background.primary
        private let textColor = DesignSystem.Color.System.foreground.primary
        private let strokeColor = DesignSystem.Color.System.foreground.secondary
        private let overlay = DesignSystem.Color.System.background.primary
        private let cornerRadius: CGFloat = 12
        private let strokeWidth: CGFloat = 3
        private let maxWidth: CGFloat = 370
        private let height: CGFloat = 45

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(faceColor)
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(overlay)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(strokeColor, lineWidth: strokeWidth)
                        }
                    )

                HStack {
                    SwiftUI.TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder)
                            .font(DesignSystem.Typography.textFieldLabel)
                            .foregroundColor(DesignSystem.Color.System.foreground.secondary)
                    )
                    .focused($isFocused)
                    .font(DesignSystem.Typography.textFieldLabel)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                    .textFieldStyle(.plain)

                    #if !targetEnvironment(macCatalyst)
                    if showKeyboardButton {
                        DesignSystem.Component.Button(
                            icon: "keyboard",
                            theme: .system(),
                            style: .plain,
                            size: .compact
                        ) {
                            isFocused.toggle()
                        }
                    }
                    #endif
                }
            }
            .frame(maxWidth: maxWidth)
            .frame(height: height)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture {
                isFocused = true
            }
        }
    }
}
