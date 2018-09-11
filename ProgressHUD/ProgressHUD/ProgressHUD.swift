
import AppKit

enum ProgressHUDMode {
    case indeterminate // Progress is shown using an YRKSpinningProgressIndicator. This is the default.
    case determinateCircular // Progress is shown using a round, pie-chart like, progress view.
    case determinateAnnular // Progress is shown using a ring-shaped progress view.
    case determinateHorizontalBar // Progress is shown using a horizontal progress bar.
    case customView // Shows a custom view and the text labels.
    case text // Shows only the text labels labels.
}

enum ProgressHUDMaskType {
    case none // default mask type, allow user interactions while HUD is displayed
    case clear // don't allow user interactions with background objects
    case black // don't allow user interactions with background objects and dim the UI in the back of the HUD (as seen in iOS 7 and above)
    case gradient // don't allow user interactions with background objects and dim the UI with a a-la UIAlertView background gradient (as seen in iOS 6)
    case custom // don't allow user interactions with background objects and dim the UI in the back of the HUD with a custom color (customMaskTypeColor)
}

typealias ProgressHUDCompletionBlock = () -> Void

@objc protocol ProgressHUDDelegate: NSObjectProtocol {
    func hudWasHidden(_ hud: ProgressHUD) // Called after the HUD was fully hidden from the screen.
    func hudWasHidden(afterDelay hud: ProgressHUD) // Called after the HUD delay timed out but before HUD was fully hidden from the screen.
    func hudWasTapped(_ hud: ProgressHUD) // Called after the HUD was Tapped with dismissible option enabled.
}

class ProgressHUD: NSView {

    // MARK: - Properties

    /// A block that gets called after the HUD was completely hidden.
    var completionBlock: ProgressHUDCompletionBlock?

    /// ProgressHUD operation mode
    var mode: ProgressHUDMode = .indeterminate {
        didSet {
            updateIndicators()
            needsLayout = true
            needsDisplay = true
        }
    }

    /**
     * The UIView (e.g., a UIImageView) to be shown when the HUD is in ProgressHUDModeCustomView.
     * For best results use a 60 by 60 pixel view (so the bounds match the built in indicator bounds).
     */
    var customView: NSView? {
        didSet {
            updateIndicators()
            needsLayout = true
            needsDisplay = true
        }
    }

    weak var delegate: ProgressHUDDelegate?

    /**
     * An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit
     * the entire text. If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or
     * set to @"", then no message is displayed.
     */
    var labelText = "" {
        didSet {
            label.string = labelText
            label.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    /**
     * An optional details message displayed below the labelText message. This message is displayed only if the labelText
     * property is also set and is different from an empty string (@""). The details text can span multiple lines.
     */
    var detailsLabelText = "" {
        didSet {
            detailsLabel.string = detailsLabelText
            detailsLabel.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The opacity of the HUD window.
    var opacity: CGFloat = 0.9

    /// The color of the HUD window.
    var color: NSColor = .white { didSet { needsDisplay = true } }

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
    var maskType: ProgressHUDMaskType = .clear

    /// This color will be used as the view background when maskType is set to .custom.
    var customMaskTypeColor = NSColor.red.withAlphaComponent(0.6)

    /// Allow User to dismiss HUD manually by a tap event. This calls the optional hudWasTapped: delegate.
    var dismissible = true

    /**
     * Grace period is the time (in seconds) that the invoked method may be run without
     * showing the HUD. If the task finishes before the grace time runs out, the HUD will
     * not be shown at all.
     * This may be used to prevent HUD display for very short tasks.
     * Defaults to 0 (no grace time).
     * Grace time functionality is only supported when the task status is known!
     * @see taskInProgress
     */
    var graceTime: TimeInterval = 0.0

    /**
     * The minimum time (in seconds) that the HUD is shown.
     * This avoids the problem of the HUD being shown and than instantly hidden.
     * Defaults to 0 (no minimum show time).
     */
    var minShowTime: TimeInterval = 0.0

    /**
     * Indicates that the executed operation is in progress. Needed for correct graceTime operation.
     * If you don't set a graceTime (different than 0.0) this does nothing.
     * This property is automatically set when using showWhileExecuting:onTarget:withObject:animated:.
     * When threading is done outside of the HUD (i.e., when the show: and hide: methods are used directly),
     * you need to set this property when your task starts and completes in order to have normal graceTime
     * functionality.
     */
    var taskInProgress = false

    /**
     * Removes the HUD from its parent view when hidden.
     * Defaults to true.
     */
    var removeFromSuperViewOnHide = true

    var labelFont: NSFont = .boldSystemFont(ofSize: 18) {
        didSet {
            label.font = labelFont
            needsLayout = true
            needsDisplay = true
        }
    }

    var labelColor: NSColor = .black {
        didSet {
            label.textColor = labelColor
            needsLayout = true
            needsDisplay = true
        }
    }

    var detailsLabelFont: NSFont = .systemFont(ofSize: 16) {
        didSet {
            detailsLabel.font = detailsLabelFont
            needsLayout = true
            needsDisplay = true
        }
    }

    var detailsLabelColor: NSColor = .black {
        didSet {
            detailsLabel.textColor = detailsLabelColor
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0
    var progress: Float = 0.0 {
        didSet {
            indicator?.setValue(progress, forKeyPath: "progress")
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The minimum size of the HUD.
    var minSize: CGSize = .zero

    /// Force the HUD dimensions to be equal if possible.
    var square = false

    // MARK: - Private Properties

    private var indicator: NSView? // YRKSpinningProgressIndicator or RoundProgressView or BarProgressView
    private var graceTimer: Timer?
    private var minShowTimer: Timer?
    private var showStarted: Date?
    private var size: CGSize = .zero
    private var useAnimation = false
    private let label = NSText(frame: .zero)
    private let detailsLabel = NSText(frame: .zero)
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
     * Finds the top-most HUD subview and hides it. The counterpart to this method is showHUDAddedTo:animated:.
     *
     * @param view The view that is going to be searched for a HUD subview.
     * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
     * animations while disappearing.
     * @return YES if a HUD was found and removed, NO otherwise.
     *
     * @see showHUDAddedTo:animated:
     * @see animationType
     */
    class func hide(for view: NSView, animated: Bool) -> Bool {
        if let hud = hud(in: view) {
            hud.removeFromSuperViewOnHide = true
            hud.hide(animated)
            return true
        }
        return false
    }

    /**
     * Finds all the HUD subviews and hides them.
     *
     * @param view The view that is going to be searched for HUD subviews.
     * @param animated If set to YES the HUDs will disappear using the current animationType. If set to NO the HUDs will not use
     * animations while disappearing.
     * @return the number of HUDs found and removed.
     *
     * @see hideHUDForView:animated:
     * @see animationType
     */
    class func hideAllHUDs(in view: NSView, animated: Bool) -> Int {
        let huds = ProgressHUD.allHUDs(in: view)
        for hud in huds {
            hud.removeFromSuperViewOnHide = true
            hud.hide(animated)
        }
        return huds.count
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

    /**
     * Finds all HUD subviews and returns them.
     *
     * @param view The view that is going to be searched.
     * @return All found HUD views (array of ProgressHUD objects).
     */
    class func allHUDs(in view: NSView) -> [ProgressHUD] {
        var huds = [ProgressHUD]()
        for subView in view.subviews where subView is ProgressHUD {
            huds.append(subView as! ProgressHUD)
        }
        return huds
    }

    // MARK: - Lifecycle

    /**
     * A convenience constructor that initializes the HUD with the window's bounds. Calls the designated constructor with
     * window.bounds as the parameter.
     *
     * @param window The window instance that will provide the bounds for the HUD. Should be the same instance as
     * the HUD's superview (i.e., the window that the HUD will be added to).
     */
    class func topHud(in window: NSWindow) -> ProgressHUD? {
        guard let view = window.contentView else { return nil }
        return hud(in: view)
    }

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

    // MARK: - Show & Hide

    /// Display the HUD. You need to make sure that the main thread completes its run loop soon after this method call so the user interface can be updated.
    /// Call this method when your task is already set-up to be executed in a new thread (e.g., when using something like NSOperation or calling an asynchronous call like NSURLRequest).
    func show(_ animated: Bool) {
        updateIndicators()
        // allow self.spinsize to be effective
        useAnimation = animated
        // If the grace time is set postpone the HUD display
        if graceTime > 0.0 {
            graceTimer = Timer.scheduledTimer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
        } else {
            needsDisplay = true
            show(usingAnimation: useAnimation)
        }
    }

    /// Hide the HUD. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    func hide(_ animated: Bool) {
        useAnimation = animated
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        // If the minShow time is set, calculate how long the hud was shown,
        // and pospone the hiding operation if necessary
        if minShowTime > 0.0 && showStarted != nil {
            var interv: TimeInterval = 0
            if let aStarted = showStarted {
                interv = Date().timeIntervalSince(aStarted)
            }
            if interv < minShowTime {
                minShowTimer = Timer.scheduledTimer(timeInterval: minShowTime - interv, target: self, selector: #selector(handleMinShow(_:)), userInfo: nil, repeats: false)
                return
            }
        }
        // ... otherwise hide the HUD immediately
        hide(usingAnimation: useAnimation)
    }

    // Hide the HUD after a delay. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to  hide the HUD when your task completes.
    func hide(_ animated: Bool, afterDelay delay: TimeInterval) {
        perform(#selector(hideDelayed(_:)), with: animated ? 1 : 0, afterDelay: delay)
    }

    // MARK: - Threading

    /// Shows the HUD while a block is executing on a background queue, then hides the HUD.
    func show(animated: Bool, whileExecutingBlock block: @escaping () -> Void) {
        let queue = DispatchQueue.global(qos: .default)
        show(animated: animated, whileExecutingBlock: block, on: queue, completionBlock: nil)
    }

    /// Shows the HUD while a block is executing on a background queue, then hides the HUD and calls the completion block
    func show(animated: Bool, whileExecutingBlock block: @escaping () -> Void, completionBlock completion: @escaping () -> Void) {
        let queue = DispatchQueue.global(qos: .default)
        show(animated: animated, whileExecutingBlock: block, on: queue, completionBlock: completion)
    }

    /// Shows the HUD while a block is executing on the specified dispatch queue, then hides the HUD.
    func show(animated: Bool, whileExecutingBlock block: @escaping () -> Void, on queue: DispatchQueue) {
        show(animated: animated, whileExecutingBlock: block, on: queue, completionBlock: nil)
    }

    /**
     * Shows the HUD while a block is executing on the specified dispatch queue, executes completion block on the main queue, and then hides the HUD.
     *
     * @param animated If set to YES the HUD will (dis)appear using the current animationType. If set to NO the HUD will not use animations while (dis)appearing.
     * @param block The block to be executed while the HUD is shown.
     * @param queue The dispatch queue on which the block should be executed.
     * @param completion The block to be executed on completion.
     *
     * @see completionBlock
     */
    func show(animated: Bool, whileExecutingBlock block: @escaping () -> Void, on queue: DispatchQueue, completionBlock completion: ProgressHUDCompletionBlock?) {
        taskInProgress = true
        completionBlock = completion
        queue.async {
            block()
            DispatchQueue.main.async {
                self.cleanUp()
            }
        }
        show(animated)
    }

    private func setupLabels() {
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.layer?.isOpaque = false
        label.backgroundColor = .clear
        label.textColor = labelColor
        label.font = labelFont
        label.string = labelText
        label.sizeToFit()
        addSubview(label)

        detailsLabel.font = detailsLabelFont
        detailsLabel.isEditable = false
        detailsLabel.isSelectable = false
        detailsLabel.alignment = .center
        detailsLabel.layer?.isOpaque = false
        detailsLabel.backgroundColor = .clear
        detailsLabel.textColor = detailsLabelColor
        detailsLabel.font = detailsLabelFont
        detailsLabel.string = detailsLabelText
        detailsLabel.sizeToFit()
        addSubview(detailsLabel)
    }

    private func hide(usingAnimation animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        // Fade out
        if animated && showStarted != nil {
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
        showStarted = nil
    }

    private func show(usingAnimation animated: Bool) {
        showStarted = Date()
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
        if delegate?.responds(to: #selector(ProgressHUDDelegate.hudWasHidden(_:))) ?? false {
            _ = delegate?.perform(#selector(ProgressHUDDelegate.hudWasHidden(_:)), with: self)
        }
    }

    override func mouseDown(with theEvent: NSEvent) {
        if maskType == .none {
            super.mouseDown(with: theEvent)
        }
        if dismissible {
            performSelector(onMainThread: #selector(cleanUp), with: nil, waitUntilDone: true)
            if delegate?.responds(to: #selector(ProgressHUDDelegate.hudWasTapped(_:))) ?? false {
                _ = delegate?.perform(#selector(ProgressHUDDelegate.hudWasTapped(_:)), with: self)
            }
        }
    }

    private func updateIndicators() {
        let isActivityIndicator = indicator is YRKSpinningProgressIndicator
        let isRoundIndicator = indicator is RoundProgressView
        if mode == .indeterminate && !isActivityIndicator {
            indicator?.removeFromSuperview()
            indicator = YRKSpinningProgressIndicator(frame: NSRect(x: 20, y: 20, width: spinsize, height: spinsize))
            (indicator as? YRKSpinningProgressIndicator)?.color = .white
            (indicator as? YRKSpinningProgressIndicator)?.usesThreadedAnimation = false
            (indicator as? YRKSpinningProgressIndicator)?.startAnimation(self)
            addSubview(indicator!)
        } else if mode == .determinateHorizontalBar {
            indicator?.removeFromSuperview()
            indicator = BarProgressView()
            addSubview(indicator!)
        } else if mode == .determinateCircular || mode == .determinateAnnular {
            if !isRoundIndicator {
                indicator?.removeFromSuperview()
                indicator = RoundProgressView(frame: CGRect(x: 0.0, y: 0.0, width: spinsize, height: spinsize))
                addSubview(indicator!)
            }
            if mode == .determinateAnnular {
                (indicator as? RoundProgressView)?.annular = true
            }
        } else if mode == .customView && customView != indicator {
            indicator?.removeFromSuperview()
            indicator = customView
            addSubview(indicator!)
        } else if mode == .text {
            indicator?.removeFromSuperview()
            indicator = nil
        }
    }

    @objc private func handleGraceTimer(_ theTimer: Timer?) {
        // Show the HUD only if the task is still running
        if taskInProgress {
            needsDisplay = true
            show(usingAnimation: useAnimation)
        }
    }

    @objc private func handleMinShow(_ theTimer: Timer?) {
        hide(usingAnimation: useAnimation)
    }

    @objc private func cleanUp() {
        taskInProgress = false
        hide(useAnimation)
    }

    @objc private func hideDelayed(_ animated: NSNumber?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if delegate != nil {
            if delegate?.responds(to: #selector(ProgressHUDDelegate.hudWasHidden(afterDelay:))) ?? false {
                _ = delegate?.perform(#selector(ProgressHUDDelegate.hudWasHidden(afterDelay:)), with: self)
            }
        }
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
        indicatorF.size.width = min(indicatorF.size.width, maxWidth)
        totalSize.width = max(totalSize.width, indicatorF.size.width)
        totalSize.height += indicatorF.size.height
        if indicatorF.size.height > 0.0 {
            totalSize.height += padding
        }

        var labelSize: CGSize = label.string.count > 0 ? label.string.size(withAttributes: [NSAttributedString.Key.font: label.font!]) : CGSize.zero
        if labelSize.width > 0.0 {
            labelSize.width += 10.0
        }
        labelSize.width = min(labelSize.width, maxWidth)
        totalSize.width = max(totalSize.width, labelSize.width)
        totalSize.height += labelSize.height
        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            totalSize.height += padding
        }
        var detailsLabelSize: CGSize = detailsLabel.string.count > 0 ? detailsLabel.string.size(withAttributes: [NSAttributedString.Key.font: detailsLabel.font!]) : CGSize.zero
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
        label.frame = labelF

        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            yPos -= padding + detailsLabelSize.height
        }
        var detailsLabelF = CGRect.zero
        detailsLabelF.origin.y = yPos
        detailsLabelF.origin.x = round((bounds.size.width - detailsLabelSize.width) / 2) + xPos
        detailsLabelF.size = detailsLabelSize
        detailsLabel.frame = detailsLabelF

        // Enforce minsize and square rules
        if square {
            let maximum = max(totalSize.width, totalSize.height)
            if maximum <= bounds.size.width - margin * 2 {
                totalSize.width = maximum
            }
            if maximum <= bounds.size.height - margin * 2 {
                totalSize.height = maximum
            }
        }
        if totalSize.width < minSize.width {
            totalSize.width = minSize.width
        }
        if totalSize.height < minSize.height {
            totalSize.height = minSize.height
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
        context.setFillColor(color.withAlphaComponent(opacity).cgColor)

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
        NSGraphicsContext.restoreGraphicsState()
    }

}
