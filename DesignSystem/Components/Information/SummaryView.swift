import SwiftUI

extension DesignSystem.Component{
    struct SummaryView: View {
        var icon: String
        var textView: Text
        
        var body: some View {
            VStack{
                Image(icon)
                textView
                    .font(DS.Typography.bodyMedium)
                    .foregroundStyle(DS.Color.System.foreground.secondary)
                    //.multilineTextAlignment(.center)
                Spacer()
            }.padding()
        }
    }
}
