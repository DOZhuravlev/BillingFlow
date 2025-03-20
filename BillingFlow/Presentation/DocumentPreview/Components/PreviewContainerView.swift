import UIKit
import WebKit

final class PreviewContainerView: UIView, UIScrollViewDelegate {

    // MARK: - Properties

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let webView: WKWebView

    private let paperSize = CGSize(width: 760, height: 1075)

    private var currentHTML: String?
    private var lastBoundsSize: CGSize = .zero
    private var didApplyInitialScale = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        webView = WKWebView(
            frame: .zero,
            configuration: Self.makeWebViewConfiguration()
        )

        super.init(frame: frame)

        setupLayout()
        configureScroll()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.size != .zero else { return }

        scrollView.frame = bounds

        if lastBoundsSize != bounds.size {
            updateLayout()
            lastBoundsSize = bounds.size
        }

        if !didApplyInitialScale {
            applyInitialScale()
        }

        centerContent()
    }

    // MARK: - LoadHTML

    func loadHTMLIfNeeded(_ html: String) {
        guard currentHTML != html else { return }

        currentHTML = html
        didApplyInitialScale = false
        scrollView.setZoomScale(1, animated: false)
        scrollView.contentOffset = .zero

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)

        setNeedsLayout()
    }

    // MARK: - Setup

    private static func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        return config
    }

    private func setupLayout() {
        backgroundColor = .clear

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(webView)

        contentView.frame = CGRect(origin: .zero, size: paperSize)
        webView.frame = contentView.bounds

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false

        webView.scrollView.isScrollEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false

        webView.isUserInteractionEnabled = false
    }

    private func configureScroll() {
        scrollView.delegate = self
        scrollView.backgroundColor = .clear

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = true

        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4

        scrollView.bounces = true
        scrollView.bouncesZoom = true

        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true

        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true

        scrollView.decelerationRate = .fast
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true

        scrollView.panGestureRecognizer.minimumNumberOfTouches = 1

        let doubleTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    private func updateLayout() {
        contentView.frame = CGRect(origin: .zero, size: paperSize)
        webView.frame = contentView.bounds

        scrollView.contentSize = paperSize

        updateZoomScales()
    }

    // MARK: - Zoom

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.contentSize = contentView.frame.size
        centerContent()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let threshold: CGFloat = 40

        if abs(targetContentOffset.pointee.x) < threshold {
            targetContentOffset.pointee.x = 0
        }

        if abs(targetContentOffset.pointee.y) < threshold {
            targetContentOffset.pointee.y = 0
        }
    }

    private func updateZoomScales() {
        guard scrollView.bounds.size != .zero else { return }

        let widthScale = scrollView.bounds.width / paperSize.width
        let heightScale = scrollView.bounds.height / paperSize.height

        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale * 4, 3)

        if scrollView.zoomScale < minScale {
            scrollView.zoomScale = minScale
        }
    }

    private func applyInitialScale() {
        updateZoomScales()

        let minScale = scrollView.minimumZoomScale
        let initial = min(minScale * 1.1, scrollView.maximumZoomScale)

        scrollView.setZoomScale(initial, animated: false)

        didApplyInitialScale = true
    }

    // MARK: - Centering

    private func centerContent() {
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        let offsetX = max((boundsSize.width - contentSize.width) * 0.5, 0)
        let offsetY = max((boundsSize.height - contentSize.height) * 0.5, 0)

        contentView.center = CGPoint(
            x: contentSize.width * 0.5 + offsetX,
            y: contentSize.height * 0.5 + offsetY
        )
    }

    // MARK: - Double Tap

    @objc
    private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: contentView)

        let newScale: CGFloat

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            newScale = scrollView.minimumZoomScale
        } else {
            newScale = min(scrollView.zoomScale * 2, scrollView.maximumZoomScale)
        }

        let size = CGSize(
            width: scrollView.bounds.width / newScale,
            height: scrollView.bounds.height / newScale
        )

        let rect = CGRect(
            x: location.x - size.width / 2,
            y: location.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        scrollView.zoom(to: rect, animated: true)
    }
}
