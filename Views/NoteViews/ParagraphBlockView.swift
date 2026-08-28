import SwiftUI

struct ParagraphBlockView: View {
    var block: Block
    var isEditable: Bool

    var body: some View {
        Group {
            if isEditable {
                TextField(
                    "Enter paragraph...",
                    text: textBinding,
                    prompt: Text("Enter paragraph...").foregroundStyle(
                        DS.Color.System.foreground.secondary
                    ),
                    axis: .vertical
                )
                .multilineTextAlignment(.leading)
            } else {
                Text(block.text ?? "")
                    .contextMenu {
                        Button(action: copyToPasteboard) {
                            Label("Copy Text", systemImage: "doc.on.doc")
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(DS.Typography.bodySmall)
        .foregroundStyle(DS.Color.System.foreground.primary)
    }
}

extension ParagraphBlockView {
    private var textBinding: Binding<String> {
        Binding(
            get: { block.text ?? "" },
            set: { block.text = $0.isEmpty ? nil : $0 }
        )
    }

    private func copyToPasteboard() {
        UIPasteboard.general.string = block.text ?? ""
    }
}
