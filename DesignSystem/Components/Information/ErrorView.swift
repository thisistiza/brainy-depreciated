import Foundation
import SwiftUI
import os

extension DesignSystem.Component {
    struct ErrorView: View {
        @Environment(Router.self) var router
        let messages: [String]
        var imageName: String = "crossCircled"

        var body: some View {
            VStack {
                HStack(spacing: DS.Spacing.sm) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text("Oops! Something went wrong.")
                        .font(DS.Typography.bodyLarge)
                        .foregroundStyle(DS.Color.Palette.ruby.base)
                }

                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .font(DS.Typography.bodyLarge)
                        .foregroundStyle(DS.Color.System.foreground.primary)
                }
            }
            .padding()
            .dashedBorder()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
