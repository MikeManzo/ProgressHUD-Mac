
import AppKit

/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */
class RoundProgressView: NSView {
    /**
     * Progress (0.0 to 1.0)
     */
    @objc var progress: Float = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Indicator progress color.
     * Defaults to black
     */
    var progressTintColor = NSColor.black {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Indicator background (non-progress) color.
     * Defaults to black
     */
    var backgroundTintColor = NSColor.clear {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Display mode - NO = round or YES = annular. Defaults to round.
     */
    var annular = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var cgColorFromNSColor: CGColor?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecycle
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: NSRect) {
        let allRect = bounds
        let circleRect = allRect.insetBy(dx: 2.0, dy: 2.0)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if annular {
            // Draw background
            let lineWidth: CGFloat = 5.0
            let processBackgroundPath = NSBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .round
            let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            let radius: CGFloat = (bounds.size.width - lineWidth) / 2
            let startAngle: CGFloat = 90
            // 90 degrees
            var endAngle = startAngle - 360 * CGFloat(progress)
            processBackgroundPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            progressTintColor.set()
            processBackgroundPath.stroke()
            // Draw progress
            let processPath = NSBezierPath()
            processPath.lineCapStyle = .round
            processPath.lineWidth = lineWidth
            endAngle = startAngle - CGFloat.pi * 2
            processPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            progressTintColor.set()
            processPath.stroke()
        } else {
            // Draw background
            progressTintColor.setStroke()
//            backgroundTintColor.setFill()
            context.setLineWidth(2.0)
//            context.fillEllipse(in: circleRect)
            context.strokeEllipse(in: circleRect)
            // Draw progress
            let center = CGPoint(x: allRect.size.width / 2, y: allRect.size.height / 2)
            let radius: CGFloat = (allRect.size.width - 4) / 2
            let startAngle: CGFloat = .pi / 2
            // 90 degrees
            let endAngle = startAngle - .pi * 2 * CGFloat(progress)
            context.setFillColor(progressTintColor.cgColor)
            // white
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addArc(center: CGPoint(x: center.x, y: center.y), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.closePath()
            context.fillPath()
        }
    }
    
}
