import SwiftUI

extension DesignSystem.Component {
    struct WorkInProgress: View {
        let text: String?
        var imageName: String = "workInProgress"

        var body: some View {
            VStack {
                HStack(spacing: DS.Spacing.sm) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    if let text = text {
                        Text("Work In Progress: ").font(DS.Typography.bodyLarge)
                            .foregroundStyle(DS.Color.Palette.gold.base)
                        Text(text).font(DS.Typography.bodyLarge).foregroundStyle(
                            DS.Color.System.foreground.primary
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dashedBorder()
        }
    }
}
