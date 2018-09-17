
import AppKit

enum ProgressHUDMode { /// ProgressHUD operation mode
    case indeterminate // Progress is shown using an Spinning Progress Indicator. This is the default.
    case determinate // Progress is shown using a round, pie-chart like, progress view.
    case error // Shows an error icon and the text labels.
    case success // Shows a success icon and the text labels.
    case customView // Shows a custom view and the text labels.
    case text // Shows only the text labels labels.
}

enum ProgressHUDStyle {
    case light
    case dark
    case custom
}

enum ProgressHUDMaskType {
    case none // default mask type, allow user interactions while HUD is displayed
    case clear // don't allow user interactions with background objects
    case black // don't allow user interactions with background objects and dim the UI in the back of the HUD (as seen in iOS 7 and above)
    case gradient // don't allow user interactions with background objects and dim the UI with a a-la UIAlertView background gradient (as seen in iOS 6)
    case custom // don't allow user interactions with background objects and dim the UI in the back of the HUD with a custom color (customMaskTypeColor)
}

enum ProgressHUDPosition {
    case top
    case center
    case bottom
}

extension NSView {
    func showProgressHUD(title: String,
                         message: String,
                         style: ProgressHUDStyle = .light,
                         mode: ProgressHUDMode = .indeterminate,
                         mask: ProgressHUDMaskType = .none,
                         position: ProgressHUDPosition = .bottom,
                         duration: TimeInterval = 0) {
        let hud = ProgressHUD.showAdded(to: self, animated: true)
        hud.title = title
        hud.message = message
        hud.style = style
        hud.mode = mode
        hud.maskType = mask
        hud.position = position
        if duration > 0 {
            hud.hide(true, afterDelay: duration)
        }
    }

    func setProgressHUDProgress(_ progress: Double) {
        DispatchQueue.main.async {
            if let hud = ProgressHUD.hud(in: self) {
                hud.progress = progress
            }
        }
    }

    func hideProgressHUD(afterDelay delay: TimeInterval = 0) {
        DispatchQueue.main.async {
            if let hud = ProgressHUD.hud(in: self) {
                hud.hide(true, afterDelay: delay)
            }
        }
    }
}

typealias ProgressHUDCompletionBlock = () -> Void

class ProgressHUD: NSView {

    // MARK: - Properties

    /// A block that gets called after the HUD is completely hidden.
    var completionBlock: ProgressHUDCompletionBlock?

    /// An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    /// If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to @"", then no message is displayed.
    var title = "" {
        didSet {
            titleLabel.string = title
            titleLabel.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    /// An optional details message displayed below the labelText message. This message is displayed only if the labelText
    /// property is also set and is different from an empty string (@""). The details text can span multiple lines.
    var message = "" {
        didSet {
            messageLabel.string = message
            messageLabel.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    var mode: ProgressHUDMode = .indeterminate {
        didSet {
            updateIndicators()
            needsLayout = true
            needsDisplay = true
        }
    }

    var style: ProgressHUDStyle = .light {
        didSet {
            switch style {
            case .light:
                backgroundColor = .white
                tintColor = .black
                progressIndicator.color = tintColor
            case .dark:
                backgroundColor = .black
                tintColor = .init(white: 0.95, alpha: 1)
                progressIndicator.color = tintColor
            default:
                break
            }
            setupLabels()
            needsLayout = true
            needsDisplay = true
        }
    }

    var position: ProgressHUDPosition = .bottom {
        didSet {
            switch position {
            case .top: yOffset = -bounds.size.height / 5
            case .center: yOffset = 0
            case .bottom: yOffset = bounds.size.height / 5
            }
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The view to be shown when the HUD is in ProgressHUDModeCustomView. For best results use a 60 by 60 pixel view (so the bounds match the built in indicator bounds)
    var customView: NSView? {
        didSet {
            updateIndicators()
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The opacity of the HUD window.
    var opacity: CGFloat = 0.9

    /// The color of the HUD window.
    var backgroundColor: NSColor = .white { didSet { needsDisplay = true } }

    /// The color of the text and details.
    var tintColor: NSColor = .black { didSet { needsDisplay = true } }

    /// The x-axis offset of the HUD relative to the centre of the superview.
    var xOffset: CGFloat = 0.0

    /// The y-axis offset of the HUD relative to the centre of the superview.
    var yOffset: CGFloat = 0.0

    /// The size both horizontally and vertically of the spinner
    var spinsize: CGFloat = 60.0

    /// The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
    var margin: CGFloat = 20.0

    /// The amount of space between the HUD elements (labels, indicators or custom views).
    var padding: CGFloat = 4.0

    /// The corner radius for th HUD
    var cornerRadius: CGFloat = 10.0

    /// The HUD's background view.
    var maskType = ProgressHUDMaskType.clear

    /// This color will be used as the view background when maskType is set to .custom.
    var customMaskTypeColor = NSColor.black.withAlphaComponent(0.6)

    /// Allow User to dismiss HUD manually by a tap event. This calls the optional hudWasTapped: delegate.
    var dismissible = true

    /// Removes the HUD from its parent view when hidden.
    var removeFromSuperViewOnHide = true

    var titleFont = NSFont.boldSystemFont(ofSize: 18) {
        didSet {
            titleLabel.font = titleFont
            needsLayout = true
            needsDisplay = true
        }
    }

    var titleColor = NSColor.black {
        didSet {
            titleLabel.textColor = titleColor
            needsLayout = true
            needsDisplay = true
        }
    }

    var messageFont = NSFont.systemFont(ofSize: 16) {
        didSet {
            messageLabel.font = messageFont
            needsLayout = true
            needsDisplay = true
        }
    }

    var messageColor = NSColor.black {
        didSet {
            messageLabel.textColor = messageColor
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0
    var progress: Double = 0.0 {
        didSet {
            needsLayout = true
            needsDisplay = true
        }
    }

    /// Force the HUD dimensions to be equal if possible.
    var square = false

    // MARK: - Private Properties

    private var indicator: NSView?
    private var progressIndicator = ProgressIndicatorLayer(size: 60)
    private var size = CGSize.zero
    private var useAnimation = true
    private let titleLabel = NSText(frame: .zero)
    private let messageLabel = NSText(frame: .zero)
    private var isFinished = false
    private var rotationTransform: CGAffineTransform = .identity

    // MARK: - Class methods

    /**
     * Creates a new HUD, adds it to provided view and shows it. The counterpart to this method is hideHUDForView:animated:.
     *
     * @param view The view that the HUD will be added to
     * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
     * animations while appearing.
     * @return A reference to the created HUD.
     *
     * @see hideHUDForView:animated:
     * @see animationType
     */
    class func showAdded(to view: NSView, animated: Bool) -> ProgressHUD {
        let hud = ProgressHUD(view: view)
        view.addSubview(hud)
        hud.show(animated)
        return hud
    }

    /**
     * Finds the top-most HUD subview and returns it.
     *
     * @param view The view that is going to be searched.
     * @return A reference to the last HUD subview discovered.
     */
    class func hud(in view: NSView) -> ProgressHUD? {
        for subview in view.subviews where subview is ProgressHUD {
            return subview as? ProgressHUD
        }
        return nil
    }

    // MARK: - Lifecycle

    /**
     * A convenience constructor that initializes the HUD with the view's bounds. Calls the designated constructor with
     * view.bounds as the parameter
     *
     * @param view The view instance that will provide the bounds for the HUD. Should be the same instance as
     * the HUD's superview (i.e., the view that the HUD will be added to).
     */
    convenience init(view: NSView) {
        var bounds = view.frame
        bounds.origin.x = 0.0
        bounds.origin.y = 0.0
        self.init(frame: bounds)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
        alphaValue = 0.0
        setupLabels()
        updateIndicators()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabels() {
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.alignment = .center
        titleLabel.layer?.isOpaque = false
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = tintColor
        titleLabel.font = titleFont
        titleLabel.string = title
        titleLabel.sizeToFit()
        addSubview(titleLabel)

        messageLabel.font = messageFont
        messageLabel.isEditable = false
        messageLabel.isSelectable = false
        messageLabel.alignment = .center
        messageLabel.layer?.isOpaque = false
        messageLabel.backgroundColor = .clear
        messageLabel.textColor = tintColor
        messageLabel.font = messageFont
        messageLabel.string = message
        messageLabel.sizeToFit()
        addSubview(messageLabel)
    }

    // MARK: - Show & Hide

    /// Display the HUD. You need to make sure that the main thread completes its run loop soon after this method call so the user interface can be updated.
    /// Call this method when your task is already set-up to be executed in a new thread (e.g., when using something like NSOperation or calling an asynchronous call like NSURLRequest).
    func show(_ animated: Bool) {
        updateIndicators()
        // allow self.spinsize to be effective
        useAnimation = animated

        needsDisplay = true
        show(usingAnimation: useAnimation)
    }

    /// Hide the HUD. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    func hide(_ animated: Bool) {
        useAnimation = animated
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        // ... otherwise hide the HUD immediately
        hide(usingAnimation: useAnimation)
    }

    // Hide the HUD after a delay. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to  hide the HUD when your task completes.
    func hide(_ animated: Bool, afterDelay delay: TimeInterval) {
        perform(#selector(hideDelayed(_:)), with: animated ? 1 : 0, afterDelay: delay)
    }

    private func hide(usingAnimation animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        // Fade out
        if animated {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.20
            NSAnimationContext.current.completionHandler = {
                self.done()
            }
            animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        } else {
            alphaValue = 0.0
            done()
        }
    }

    private func show(usingAnimation animated: Bool) {

        // Fade in
        isHidden = false
        if animated {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.20
            animator().alphaValue = 1.0
            NSAnimationContext.endGrouping()
        } else {
            alphaValue = 1.0
        }
    }

    private func done() {
        isFinished = true
        alphaValue = 0.0
        // self.acceptsTouchEvents = NO;
        isHidden = true
        if removeFromSuperViewOnHide {
            removeFromSuperview()
        }
        completionBlock?()
        completionBlock = nil
    }

    override func mouseDown(with theEvent: NSEvent) {
        if maskType == .none {
            super.mouseDown(with: theEvent)
        }
        if dismissible {
            performSelector(onMainThread: #selector(cleanUp), with: nil, waitUntilDone: true)
        }
    }

    private func updateIndicators() {
        let isActivityIndicator = indicator?.layer is ProgressIndicatorLayer

        if mode == .indeterminate && !isActivityIndicator {
            indicator?.removeFromSuperview()
            let view = NSView(frame: NSRect(x: 0, y: 0, width: spinsize, height: spinsize))
            view.wantsLayer = true
            progressIndicator.startProgressAnimation()
            view.layer?.addSublayer(progressIndicator)
            indicator = view
            addSubview(indicator!)

        } else if mode == .determinate || mode == .text {

            indicator?.removeFromSuperview()
            indicator = nil

        } else if mode == .customView && customView != indicator {

            indicator?.removeFromSuperview()
            indicator = customView
            addSubview(indicator!)

        }
    }

    @objc private func cleanUp() {
        hide(useAnimation)
    }

    @objc private func hideDelayed(_ animated: NSNumber?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        hide((animated != 0))
    }

    // MARK: - Internal show & hide operations

    func animationFinished(_ animationID: String?, finished: Bool, context: UnsafeMutableRawPointer?) {
        done()
    }

    // MARK: - Layout

    func layoutSubviews() {

        // Entirely cover the parent view
        frame = superview?.bounds ?? .zero

        // Determine the total width and height needed
        let maxWidth = bounds.size.width - margin * 4
        var totalSize = CGSize.zero
        var indicatorF = indicator?.bounds ?? .zero
        if mode == .determinate {
            indicatorF.size.height = spinsize
        }
        indicatorF.size.width = min(indicatorF.size.width, maxWidth)
        totalSize.width = max(totalSize.width, indicatorF.size.width)
        totalSize.height += indicatorF.size.height
        if indicatorF.size.height > 0.0 {
            totalSize.height += padding
        }

        var labelSize: CGSize = titleLabel.string.count > 0 ? titleLabel.string.size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!]) : CGSize.zero
        if labelSize.width > 0.0 {
            labelSize.width += 10.0
        }
        labelSize.width = min(labelSize.width, maxWidth)
        totalSize.width = max(totalSize.width, labelSize.width)
        totalSize.height += labelSize.height
        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            totalSize.height += padding
        }
        var detailsLabelSize: CGSize = messageLabel.string.count > 0 ? messageLabel.string.size(withAttributes: [NSAttributedString.Key.font: messageLabel.font!]) : CGSize.zero
        if detailsLabelSize.width > 0.0 {
            detailsLabelSize.width += 10.0
        }
        detailsLabelSize.width = min(detailsLabelSize.width, maxWidth)
        totalSize.width = max(totalSize.width, detailsLabelSize.width)
        totalSize.height += detailsLabelSize.height
        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            totalSize.height += padding
        }
        totalSize.width += margin * 2
        totalSize.height += margin * 2

        // Position elements
        var yPos = round((bounds.size.height - totalSize.height) / 2) + margin - yOffset
        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            yPos += padding + labelSize.height
        }
        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            yPos += padding + detailsLabelSize.height
        }
        let xPos = xOffset
        indicatorF.origin.y = yPos
        indicatorF.origin.x = round((bounds.size.width - indicatorF.size.width) / 2) + xPos
        indicator?.frame = indicatorF

        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            yPos -= padding + labelSize.height
        }
        if indicatorF.size.height > 0.0 {
            yPos -= padding
        }
        var labelF = CGRect.zero
        labelF.origin.y = yPos
        labelF.origin.x = round((bounds.size.width - labelSize.width) / 2) + xPos
        labelF.size = labelSize
        titleLabel.frame = labelF

        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            yPos -= padding + detailsLabelSize.height
        }
        var detailsLabelF = CGRect.zero
        detailsLabelF.origin.y = yPos
        detailsLabelF.origin.x = round((bounds.size.width - detailsLabelSize.width) / 2) + xPos
        detailsLabelF.size = detailsLabelSize
        messageLabel.frame = detailsLabelF

        // Enforce square rules
        if square {
            let maximum = max(totalSize.width, totalSize.height)
            if maximum <= bounds.size.width - margin * 2 {
                totalSize.width = maximum
            }
            if maximum <= bounds.size.height - margin * 2 {
                totalSize.height = maximum
            }
        }
        size = totalSize
    }

    // MARK: - Background Drawing

    override func draw(_ rect: NSRect) {
        layoutSubviews()
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if maskType == .gradient {
            // Gradient colours
            let gradLocationsNum: size_t = 2
            let gradLocations: [CGFloat] = [0.0, 1.0]
            let gradColors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradColors, locations: gradLocations, count: gradLocationsNum)!
            // Gradient center
            let gradCenter = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            // Gradient radius
            let gradRadius = min(bounds.size.width, bounds.size.height)
            // Gradient draw
            context.drawRadialGradient(gradient, startCenter: gradCenter, startRadius: 0, endCenter: gradCenter, endRadius: gradRadius, options: CGGradientDrawingOptions.drawsAfterEndLocation)
        } else if maskType == .black {
            context.setFillColor(NSColor.black.withAlphaComponent(0.6).cgColor)
            rect.fill()
        } else if maskType == .custom {
            context.setFillColor(customMaskTypeColor.cgColor)
            rect.fill()
        }

        // Set background rect color
        context.setFillColor(backgroundColor.withAlphaComponent(opacity).cgColor)

        // Center HUD
        let allRect = bounds

        // Draw rounded HUD backgroud rect
        let boxRect = CGRect(x: round((allRect.size.width - size.width) / 2) + xOffset,
                             y: round((allRect.size.height - size.height) / 2) - yOffset,
                             width: size.width, height: size.height)
        let radius = cornerRadius
        context.beginPath()
        context.move(to: CGPoint(x: boxRect.minX + radius, y: boxRect.minY))
        context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi * 3 / 2, endAngle: 0, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: false)
        context.closePath()
        context.fillPath()

        if mode == .determinate {
            // Draw progress
            let lineWidth: CGFloat = 5.0
            let processBackgroundPath = NSBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .round

            let center = CGPoint(x: boxRect.origin.x + boxRect.size.width / 2, y: boxRect.origin.y + boxRect.size.height - spinsize * 0.9)
            let radius = spinsize / 2
            let startAngle: CGFloat = 90
            var endAngle = startAngle - 360 * CGFloat(progress)
            processBackgroundPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setStrokeColor(tintColor.cgColor)
            processBackgroundPath.stroke()
            let processPath = NSBezierPath()
            processPath.lineCapStyle = .round
            processPath.lineWidth = lineWidth
            endAngle = startAngle - .pi * 2
            processPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setFillColor(tintColor.cgColor)
            processPath.stroke()
        }

        NSGraphicsContext.restoreGraphicsState()
    }

}

class ProgressIndicatorLayer: CALayer {

    private(set) var isRunning = false

    var color = NSColor.black {
        didSet {
            // Update do all of the fins to this new color
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            for fin in finLayers {
                fin.backgroundColor = color.cgColor
            }
            CATransaction.commit()
            setNeedsDisplay()
        }
    }

    private var finBoundsForCurrentBounds: CGRect {
        let size: CGSize = bounds.size
        let minSide: CGFloat = size.width > size.height ? size.height : size.width
        let width: CGFloat = minSide * 0.095
        let height: CGFloat = minSide * 0.30
        return CGRect(x: 0, y: 0, width: width, height: height)
    }

    private var finAnchorPointForCurrentBounds: CGPoint {
        let size: CGSize = bounds.size
        let minSide: CGFloat = size.width > size.height ? size.height : size.width
        let height: CGFloat = minSide * 0.30
        return CGPoint(x: 0.5, y: -0.9 * (minSide - height) / minSide)
    }

    var animationTimer: Timer?
    var fposition = 0
    var fadeDownOpacity: CGFloat = 0.0
    var numFins = 12
    var finLayers = [CALayer]()

    init(size: CGFloat) {
        super.init()
        bounds = CGRect(x: -(size / 2), y: -(size / 2), width: size, height: size)
        createFinLayers()
        if isRunning {
            setupAnimTimer()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopProgressAnimation()
        removeFinLayers()
    }

    func toggleProgressAnimation() {
        if isRunning {
            stopProgressAnimation()
        } else {
            startProgressAnimation()
        }
    }

    func startProgressAnimation() {
        isHidden = false
        isRunning = true
        fposition = numFins - 1
        setNeedsDisplay()
        setupAnimTimer()
    }

    func stopProgressAnimation() {
        isRunning = false
        disposeAnimTimer()
        setNeedsDisplay()
    }

    // Animation
    @objc private func advancePosition() {
        fposition += 1
        if fposition >= numFins {
            fposition = 0
        }
        let fin = finLayers[fposition]
        // Set the next fin to full opacity, but do it immediately, without any animation
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        fin.opacity = 1.0
        CATransaction.commit()
        // Tell that fin to animate its opacity to transparent.
        fin.opacity = Float(fadeDownOpacity)
        setNeedsDisplay()
    }

    private func removeFinLayers() {
        for finLayer in finLayers {
            finLayer.removeFromSuperlayer()
        }
    }

    private func createFinLayers() {
        removeFinLayers()
        // Create new fin layers
        let finBounds: CGRect = finBoundsForCurrentBounds
        let finAnchorPoint: CGPoint = finAnchorPointForCurrentBounds
        let finPosition = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let finCornerRadius: CGFloat = finBounds.size.width / 2
        for i in 0..<numFins {
            let newFin = CALayer()
            newFin.bounds = finBounds
            newFin.anchorPoint = finAnchorPoint
            newFin.position = finPosition
            newFin.transform = CATransform3DMakeRotation(CGFloat(i) * (-6.282185 / CGFloat(numFins)), 0.0, 0.0, 1.0)
            newFin.cornerRadius = finCornerRadius
            newFin.backgroundColor = color.cgColor
            // Set the fin's initial opacity
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            newFin.opacity = Float(fadeDownOpacity)
            CATransaction.commit()
            // set the fin's fade-out time (for when it's animating)
            let anim = CABasicAnimation()
            anim.duration = 0.7
            let actions = ["opacity": anim]
            newFin.actions = actions
            addSublayer(newFin)
            finLayers.append(newFin)
        }
    }

    private func setupAnimTimer() {
        // Just to be safe kill any existing timer.
        disposeAnimTimer()
        // Why animate if not visible?  viewDidMoveToWindow will re-call this method when needed.
        animationTimer = Timer(timeInterval: TimeInterval(0.05), target: self, selector: #selector(ProgressIndicatorLayer.advancePosition), userInfo: nil, repeats: true)
        animationTimer?.fireDate = Date()
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .common)
        }
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .default)
        }
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .eventTracking)
        }
    }

    private func disposeAnimTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set(newBounds) {
            super.bounds = newBounds

            // Resize the fins
            let finBounds: CGRect = finBoundsForCurrentBounds
            let finAnchorPoint: CGPoint = finAnchorPointForCurrentBounds
            let finPosition = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            let finCornerRadius: CGFloat = finBounds.size.width / 2

            // do the resizing all at once, immediately
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            for fin in finLayers {
                fin.bounds = finBounds
                fin.anchorPoint = finAnchorPoint
                fin.position = finPosition
                fin.cornerRadius = finCornerRadius
            }
            CATransaction.commit()
        }
    }

}
