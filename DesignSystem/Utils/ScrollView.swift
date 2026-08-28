import SwiftUI
import UIKit

extension View {
    func cancelScrollViewDelay() -> some View {
        self.background(ScrollTouchConfigurationView())
    }
}

struct ScrollTouchConfigurationView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            var responder: UIResponder? = view
            while responder != nil {
                if let scrollView = responder as? UIScrollView {
                    scrollView.delaysContentTouches = false
                    break
                }
                responder = responder?.next
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
