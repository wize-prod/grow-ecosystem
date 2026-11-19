import SwiftUI
import UIKit

public struct ZoomableImageView: UIViewRepresentable {
    public let image: UIImage

    public init(image: UIImage) {
        self.image = image
    }

    public func makeUIView(context: Context) -> CenteringScrollView {
        let scrollView = CenteringScrollView()
        scrollView.delegate = context.coordinator
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.addSubview(imageView)
        scrollView.contentSize = image.size
        scrollView.imageView = imageView

        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    public func updateUIView(_ scrollView: CenteringScrollView, context: Context) {
        if scrollView.imageView?.image !== image {
            scrollView.imageView?.image = image
            scrollView.imageView?.frame = CGRect(origin: .zero, size: image.size)
            scrollView.contentSize = image.size
            scrollView.resetInitialScale()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: CenteringScrollView?

        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView, let imageView = imageView else { return }
            let bounds = scrollView.bounds
            let imgW = imageView.image?.size.width ?? bounds.width
            let imgH = imageView.image?.size.height ?? bounds.height
            let fitScale = min(bounds.width / max(imgW, 1.0), bounds.height / max(imgH, 1.0))

            if scrollView.zoomScale > fitScale * 1.2 {
                scrollView.setZoomScale(fitScale, animated: true)
            } else {
                let pointInView = gesture.location(in: imageView)
                let targetScale = min(scrollView.maximumZoomScale, fitScale * 3.0)
                let w = bounds.width / targetScale
                let h = bounds.height / targetScale
                let x = pointInView.x - (w / 2.0)
                let y = pointInView.y - (h / 2.0)
                scrollView.zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
            }
        }
    }
}

public class CenteringScrollView: UIScrollView {
    weak var imageView: UIImageView?
    private var initialScaleConfigured: Bool = false
    private var lastObservedBoundsSize: CGSize = .zero

    public func resetInitialScale() {
        initialScaleConfigured = false
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let subview = imageView else { return }

        let currentSize = bounds.size
        if currentSize.width > 10 && currentSize.height > 10 {
            if !initialScaleConfigured || currentSize != lastObservedBoundsSize {
                lastObservedBoundsSize = currentSize
                configureScales(for: subview, containerSize: currentSize)
            }
        }

        centerContent(subview: subview, containerSize: currentSize)
    }

    private func configureScales(for subview: UIView, containerSize: CGSize) {
        let imgW = max(subview.bounds.size.width, 1.0)
        let imgH = max(subview.bounds.size.height, 1.0)

        let widthScale = containerSize.width / imgW
        let heightScale = containerSize.height / imgH
        let fitScale = min(widthScale, heightScale)

        // Allow zooming out to 25% of fit scale, down to 0.05 minimum
        self.minimumZoomScale = min(fitScale * 0.25, 0.05)
        // Allow zooming in to 8x of fit scale, up to 6.0 minimum
        self.maximumZoomScale = max(fitScale * 8.0, 6.0)

        if !initialScaleConfigured {
            self.zoomScale = fitScale
            initialScaleConfigured = true
        }
    }

    private func centerContent(subview: UIView, containerSize: CGSize) {
        var frameToCenter = subview.frame

        if frameToCenter.size.width < containerSize.width {
            frameToCenter.origin.x = (containerSize.width - frameToCenter.size.width) / 2.0
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < containerSize.height {
            frameToCenter.origin.y = (containerSize.height - frameToCenter.size.height) / 2.0
        } else {
            frameToCenter.origin.y = 0
        }

        subview.frame = frameToCenter
    }
}
