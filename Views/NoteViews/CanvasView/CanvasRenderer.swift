import PencilKit
import SwiftUI

struct CanvasRenderer: UIViewRepresentable {
    let image: UIImage
    let annotation: PKDrawing

    func makeUIView(context: Context) -> CanvasResponsiveView {
        let canvas = CanvasResponsiveView()
        canvas.isUserInteractionEnabled = true
        canvas.drawingGestureRecognizer.isEnabled = false
        canvas.isScrollEnabled = false
        canvas.pinchGestureRecognizer?.isEnabled = false

        canvas.backgroundImage = image
        canvas.updateDrawingSafely(annotation)
        return canvas
    }

    func updateUIView(_ uiView: CanvasResponsiveView, context: Context) {
        if uiView.backgroundImage != image { uiView.backgroundImage = image }
        uiView.updateDrawingSafely(annotation)
    }
}

struct ZoomableCanvasView: UIViewRepresentable {
    let image: UIImage
    let annotation: PKDrawing

    func makeUIView(context: Context) -> CanvasResponsiveView {
        let canvas = CanvasResponsiveView()
        
        // Fix: Turn off drawing input
        canvas.drawingGestureRecognizer.isEnabled = false
        
        // Fix: Temporarily stabilize scrolling/zooming states while mounting bounds
        canvas.isScrollEnabled = true
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        
        // Map data layers
        canvas.backgroundImage = image
        canvas.updateDrawingSafely(annotation)
        return canvas
    }

    func updateUIView(_ uiView: CanvasResponsiveView, context: Context) {
        if uiView.backgroundImage != image { uiView.backgroundImage = image }
        uiView.updateDrawingSafely(annotation)
    }
}
class CanvasResponsiveView: PKCanvasView {
    private let backgroundImageView = UIImageView()
    private var previousBoundsSize: CGSize = .zero
    private var pendingDrawing: PKDrawing?
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let actionString = action.description
        if actionString.contains("_insertSpace") ||
           actionString.contains("insertSpace") ||
           actionString.contains("select") {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    // MARK: - Lifecycle Management
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // If the view is removed from the active window hierarchy (e.g., navigating away or closing),
        // reset the bounds tracker. When SwiftUI reuses this view later, it will treat it
        // as a fresh "initial load" and skip the heavy redraw hack.
        if self.window == nil {
            self.previousBoundsSize = .zero
        }
    }

    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
            updateForImageSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.contentInsetAdjustmentBehavior = .never

        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.anchorPoint = .zero

        self.insertSubview(backgroundImageView, at: 0)
    }
    
    // MARK: - Safe Drawing Assignment
    func updateDrawingSafely(_ newDrawing: PKDrawing) {
        if bounds.width > 0 && bounds.height > 0 && contentSize.width > 0 {
            if self.drawing != newDrawing {
                self.drawing = newDrawing
            }
        } else {
            self.pendingDrawing = newDrawing
        }
    }

    private func updateForImageSize() {
        guard let image = backgroundImage, image.size.width > 0, image.size.height > 0 else { return }
        backgroundImageView.transform = .identity
        self.contentSize = image.size
        backgroundImageView.frame = CGRect(origin: .zero, size: image.size)
        previousBoundsSize = .zero
        
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0 && bounds.height > 0 else { return }
        guard let imageSize = backgroundImage?.size,
              imageSize.width > 0 && imageSize.height > 0 else { return }

        let scaleX = bounds.width / imageSize.width
        let scaleY = bounds.height / imageSize.height
        let minScale = min(scaleX, scaleY)
        
        var isInitialLoadOrResize = false
        
        // 1. Check if the frame size actually changed from our last layout pass
        if bounds.size != previousBoundsSize {
            isInitialLoadOrResize = true
            self.minimumZoomScale = minScale
            self.maximumZoomScale = max(minScale * 5.0, 3.0)
            
            if previousBoundsSize == .zero || self.zoomScale < minScale {
                self.zoomScale = minScale
            }
        }

        // 2. Compute margins and transform the UI components
        let scaledCanvasWidth = imageSize.width * self.zoomScale
        let scaledCanvasHeight = imageSize.height * self.zoomScale

        let horizontalPadding = max(0, (bounds.width - scaledCanvasWidth) / 2)
        let verticalPadding = max(0, (bounds.height - scaledCanvasHeight) / 2)

        self.contentInset = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        
        backgroundImageView.transform = CGAffineTransform(
            scaleX: self.zoomScale,
            y: self.zoomScale
        )
        self.sendSubviewToBack(backgroundImageView)
        
        // 3. Process Drawing updates asynchronously to avoid breaking animation layout threads
        if let pending = pendingDrawing {
            DispatchQueue.main.async { [weak self] in
                self?.drawing = pending
                self?.pendingDrawing = nil
            }
        } else if isInitialLoadOrResize && previousBoundsSize != .zero && !self.drawing.bounds.isEmpty {
            
            // Measure exactly how much the size shifted
            let widthChange = abs(bounds.width - previousBoundsSize.width)
            let heightChange = abs(bounds.height - previousBoundsSize.height)
            
            // Only force PencilKit to rebuild if it's a real layout change (e.g., Rotation/Split View)
            // Ignore minor layout fluctuations (< 5 points) caused by navigation bar push transitions
            if widthChange > 5 || heightChange > 5 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let currentDrawing = self.drawing
                    self.drawing = PKDrawing()
                    self.drawing = currentDrawing
                }
            }
        }
        
        // 4. Safely update bounds tracker at the very end
        if isInitialLoadOrResize {
            previousBoundsSize = bounds.size
        }
    }
}
