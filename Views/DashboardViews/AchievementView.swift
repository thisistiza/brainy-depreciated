import SwiftUI

//TODO
struct AchievementView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OVERVIEW")
                .font(DS.Typography.titleMedium)
                .foregroundStyle(DS.Color.System.foreground.secondary)
            
            Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 16) {
                GridRow {
                    StatCell(image: "flameMono", text: "0 Days")
                    StatCell(image: "badge", text: "Gold")
                }
                
                GridRow {
                    StatCell(image: "batteryHigh", text: "100 HP")
                    StatCell(image: "bolt", text: "1200 XP")
                }
            }
        }
        .frame(maxWidth: 360)
        .padding(.horizontal)
        .padding(.horizontal)
    }
}

// Helper subview to keep code clean and reusable
private struct StatCell: View {
    let image: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(image)
            Text(text)
                .font(DS.Typography.bodyLarge)
                .foregroundStyle(DS.Color.System.foreground.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
