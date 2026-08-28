import SwiftMath
import SwiftUI

struct MathBlockView: View {
    var block: Block
    var isEditable: Bool

    var body: some View {
        Group {
            if isEditable {
                editableEditorView
            } else {
                readOnlyDisplayView
            }
        }
        .padding()
        .background(DS.Color.System.foreground.overlay)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension MathBlockView {
    private var editableEditorView: some View {
        TextField(
            "Enter LATEX...",
            text: mathBinding,
            prompt: Text("Enter LATEX...").foregroundStyle(
                DS.Color.System.foreground.secondary
            ),
            axis: .vertical
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .textInputAutocapitalization(.none)
        .autocorrectionDisabled(true)
        .font(DS.Typography.code)
        .foregroundStyle(DS.Color.System.foreground.primary)
    }

    private var readOnlyDisplayView: some View {
        MathView(latex: block.text ?? "", fontSize: 19)
            .frame(maxWidth: .infinity, alignment: .center)
            .contextMenu {
                Button(action: copyToPasteboard) {
                    Label("Copy Math", systemImage: "doc.on.doc")
                }
            }
    }
}

extension MathBlockView {
    private var mathBinding: Binding<String> {
        Binding(
            get: { block.text ?? "" },
            set: { block.text = $0.isEmpty ? nil : $0 }
        )
    }

    private func copyToPasteboard() {
        UIPasteboard.general.string = block.text ?? ""
    }
}

struct MathView: UIViewRepresentable {
    var latex: String
    var fontSize: CGFloat = 20
    var color: UIColor = UIColor(DS.Color.System.foreground.primary)

    func makeUIView(context: Context) -> MTMathUILabel {
        let text = MTMathUILabel()
        text.fontSize = fontSize
        text.textColor = color
        text.backgroundColor = .clear
        text.textAlignment = .center

        text.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return text
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = latex
        uiView.textColor = color
        uiView.textAlignment = .center
    }
}
