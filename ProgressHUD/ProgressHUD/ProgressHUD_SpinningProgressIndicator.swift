
import AppKit

//
//  YRKSpinningProgressIndicator.h
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//
//  Modified for ObjC-ARC compatibility by Wayne Fox 2014
class YRKSpinningProgressIndicator: NSView {
    var color: NSColor? {
        didSet {
            // generate all the fin colors, with the alpha components
            // they already have
            for i in 0..<numFins {
                let alpha = finColors[i].alphaComponent
                let anAlpha = foreColor.withAlphaComponent(alpha)
                finColors[i] = anAlpha
            }
            needsDisplay = true
        }
    }
    
    var backgroundColor: NSColor? {
        didSet {
            needsDisplay = true
        }
    }
    
    var drawsBackground: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var displayedWhenStopped: Bool = true {
        didSet {
            // Show/hide ourself if necessary
            if !isAnimating {
                if displayedWhenStopped && isHidden {
                    isHidden = false
                } else if !displayedWhenStopped && !isHidden {
                    isHidden = true
                }
            }
        }
    }
    
    var usesThreadedAnimation: Bool = true {
        didSet {
            if isAnimating {
                // restart the timer to use the new mode
                stopAnimation(self)
                startAnimation(self)
            }
        }
    }
    
    var indeterminate: Bool = true {
        didSet {
            if !indeterminate && isAnimating {
                stopAnimation(self)
            }
            needsDisplay = true
        }
    }
    
    var doubleValue: Double = 0 {
        didSet {
            // Automatically put it into determinate mode if it's not already.
            if indeterminate {
                indeterminate = false
            }
            needsDisplay = true
        }
    }
    
    var maxValue: Double = 100 {
        didSet {
            needsDisplay = true
        }
    }
    
    var position = 0
    var numFins = 12
    var finColors = [NSColor]()
    var isAnimating = false
    var isFadingOut = false
    var animationTimer: Timer?
    var animationThread: Thread?
    var foreColor = NSColor.black
    var backColor = NSColor.clear
    var currentValue: Double = 0.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func stopAnimation(_ sender: Any?) {
        // animate to stopped state
        isFadingOut = true
    }
    
    func startAnimation(_ sender: Any?) {
        if !indeterminate {
            return
        }
        if isAnimating && !isFadingOut {
            return
        }
        actuallyStartAnimation()
    }
    
    @objc private func updateFrame(_ timer: Timer?) {
        if position > 0 {
            position -= 1
        } else {
            position = numFins - 1
        }
        // update the colors
        let minAlpha = CGFloat(displayedWhenStopped ? kAlphaWhenStopped : 0.01)
        for i in 0..<numFins {
            // want each fin to fade exponentially over _numFins frames of animation
            var newAlpha = CGFloat(Double(finColors[i].alphaComponent) * kFadeMultiplier)
            if newAlpha < minAlpha {
                newAlpha = minAlpha
            }
            let anAlpha = foreColor.withAlphaComponent(newAlpha)
            finColors[i] = anAlpha
        }
        if isFadingOut {
            // check if the fadeout is done
            var done = true
            for i in 0..<numFins {
                if abs(Float(finColors[i].alphaComponent - minAlpha)) > 0.01 {
                    done = false
                    break
                }
            }
            if done {
                actuallyStopAnimation()
            }
        } else {
            // "light up" the next fin (with full alpha)
            finColors[position] = foreColor
        }
        if usesThreadedAnimation {
            // draw now instead of waiting for setNeedsDisplay (that's the whole reason
            // we're animating from background thread)
            display()
        } else {
            needsDisplay = true
        }
    }
    
    @objc private func animateInBackgroundThread() {
        autoreleasepool {
            // Set up the animation speed to subtly change with size > 32.
            // int animationDelay = 38000 + (2000 * ([self bounds].size.height / 32));
            // Set the rev per minute here
            let omega: useconds_t = 100
            // RPM
            let animationDelay: useconds_t = 60 * 1000000 / omega / useconds_t(numFins)
            var poolFlushCounter: Int = 0
            repeat {
                updateFrame(nil)
                usleep(animationDelay)
                poolFlushCounter += 1
                if poolFlushCounter > 256 {
                    poolFlushCounter = 0
                }
            } while !Thread.current.isCancelled
        }
    }
    
    private func actuallyStartAnimation() {
        // Just to be safe kill any existing timer.
        actuallyStopAnimation()
        isAnimating = true
        isFadingOut = false
        // always start from the top
        position = 1
        if !displayedWhenStopped {
            isHidden = false
        }
        if window != nil {
            // Why animate if not visible?  viewDidMoveToWindow will re-call this method when needed.
            if usesThreadedAnimation {
                animationThread = Thread(target: self, selector: #selector(YRKSpinningProgressIndicator.animateInBackgroundThread), object: nil)
                animationThread?.start()
            } else {
                animationTimer = Timer(timeInterval: TimeInterval(0.05), target: self, selector: #selector(YRKSpinningProgressIndicator.updateFrame(_:)), userInfo: nil, repeats: true)
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
        }
    }
    
    private func actuallyStopAnimation() {
        isAnimating = false
        isFadingOut = false
        if !displayedWhenStopped {
            isHidden = true
        }
        if animationThread != nil {
            // we were using threaded animation
            animationThread!.cancel()
            if !animationThread!.isFinished {
                RunLoop.current.run(mode: .modalPanel, before: Date(timeIntervalSinceNow: 0.05))
            }
            animationThread = nil
        } else if animationTimer != nil {
            // we were using timer-based animation
            animationTimer?.invalidate()
            animationTimer = nil
        }
        needsDisplay = true
    }
    
    private func generateFinColorsStart(atPosition startPosition: Int) {
        for i in 0..<numFins {
            let oldColor = finColors[i]
            let alpha = oldColor.alphaComponent
            let anAlpha = foreColor.withAlphaComponent(alpha)
            finColors[i] = anAlpha
        }
    }
    
    // MARK: Init
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        finColors = [NSColor].init(repeating: .white, count: numFins)
    }
    
    deinit {
        if isAnimating {
            stopAnimation(self)
        }
    }
    
    // MARK: NSView overrides
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            // No window?  View hierarchy may be going away.  Dispose timer to clear circular retain of timer to self to timer.
            actuallyStopAnimation()
        } else if isAnimating {
            actuallyStartAnimation()
        }
    }
    
    override func draw(_ rect: NSRect) {
        // Determine size based on current bounds
        let size: NSSize = bounds.size
        var theMaxSize: CGFloat
        if size.width >= size.height {
            theMaxSize = size.height
        } else {
            theMaxSize = size.width
        }
        // fill the background, if set
        if drawsBackground {
            backColor.set()
            NSBezierPath.fill(bounds)
        }
        guard let currentContext = NSGraphicsContext.current?.cgContext else { return }
        NSGraphicsContext.saveGraphicsState()
        // Move the CTM so 0,0 is at the center of our bounds
        currentContext.translateBy(x: bounds.size.width / 2, y: bounds.size.height / 2)
        if indeterminate {
            let path = NSBezierPath()
            let lineWidth: CGFloat = 0.0859375 * theMaxSize
            // should be 2.75 for 32x32
            let lineStart: CGFloat = 0.234375 * theMaxSize
            // should be 7.5 for 32x32
            let lineEnd: CGFloat = 0.421875 * theMaxSize
            // should be 13.5 for 32x32
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.move(to: NSPoint(x: 0, y: lineStart))
            path.line(to: NSPoint(x: 0, y: lineEnd))
            for i in 0..<numFins {
                if isAnimating {
                    finColors[i].set()
                    // Sets the fill and stroke colors in the current drawing context.
                } else {
                    foreColor.withAlphaComponent(CGFloat(kAlphaWhenStopped)).set()
                }
                path.stroke()
                // we draw all the fins by rotating the CTM, then just redraw the same segment again
                currentContext.rotate(by: 6.282185 / CGFloat(numFins))
            }
        } else {
            let lineWidth = 1 + (0.01 * theMaxSize)
            let circleRadius = (theMaxSize - lineWidth) / 2.1
            let circleCenter = NSPoint(x: 0, y: 0)
            foreColor.set()
            var path = NSBezierPath()
            path.lineWidth = lineWidth
            path.appendOval(in: NSRect(x: -circleRadius, y: -circleRadius, width: circleRadius * 2, height: circleRadius * 2))
            path.stroke()
            path = NSBezierPath()
            path.appendArc(withCenter: circleCenter, radius: circleRadius, startAngle: 90, endAngle: CGFloat(90 - (360 * (currentValue / maxValue))), clockwise: true)
            path.line(to: circleCenter)
            path.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    
    // MARK: NSProgressIndicator API
    
    /// Only the spinning style is implemented
    func setStyle(_ style: NSProgressIndicator.Style) {
        if .spinning != style {
            assert(false, "Non-spinning styles not available.")
        }
    }
}

let kAlphaWhenStopped = 0.15
let kFadeMultiplier = 0.85
