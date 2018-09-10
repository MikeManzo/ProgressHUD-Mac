
import AppKit

/**
 * A flat bar progress view.
 */
class BarProgressView: NSView {
    /**
     * Progress (0.0 to 1.0)
     */
    @objc var progress: Float = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Bar border line color.
     * Defaults to black
     */
    var lineColor: NSColor = .black {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Bar background color.
     * Defaults to clear
     */
    var progressRemainingColor: NSColor = .clear {
        didSet {
            needsDisplay = true
        }
    }
    
    /**
     * Bar progress color.
     * Defaults to dark gray
     */
    var progressColor: NSColor = .darkGray {
        didSet {
            needsDisplay = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecycle
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: 20.0))
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        // setup properties
        context.setLineWidth(2)
        context.setStrokeColor(lineColor.cgColor)
        
        context.setFillColor(progressRemainingColor.cgColor)
        // draw line border
        var radius = Float((rect.size.height / 2) - 2)
        context.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: CGFloat(radius + 2), y: 2), radius: CGFloat(radius))
        context.addLine(to: CGPoint(x: rect.size.width - CGFloat(radius) - 2, y: 2))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: CGFloat(radius))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - CGFloat(radius) - 2, y: rect.size.height - 2), radius: CGFloat(radius))
        context.addLine(to: CGPoint(x: CGFloat(radius + 2), y: rect.size.height - 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: CGFloat(radius))
        context.fillPath()
        // draw progress background
        context.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: CGFloat(radius + 2), y: 2), radius: CGFloat(radius))
        context.addLine(to: CGPoint(x: rect.size.width - CGFloat(radius) - 2, y: 2))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: CGFloat(radius))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - CGFloat(radius) - 2, y: rect.size.height - 2), radius: CGFloat(radius))
        context.addLine(to: CGPoint(x: CGFloat(radius + 2), y: rect.size.height - 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: CGFloat(radius))
        context.strokePath()
        // setup to draw progress color
        context.setFillColor(progressColor.cgColor)

        radius -= 2
        let amount = Float(CGFloat(progress) * rect.size.width)
        // if progress is in the middle area
        if amount >= radius + 4 && CGFloat(amount) <= (rect.size.width - CGFloat(radius) - 4) {
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: CGFloat(amount), y: 4))
            context.addLine(to: CGPoint(x: CGFloat(amount), y: CGFloat(radius + 4)))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: rect.size.height - 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: CGFloat(amount), y: rect.size.height - 4))
            context.addLine(to: CGPoint(x: CGFloat(amount), y: CGFloat(radius + 4)))
            context.fillPath()
        } else if amount > radius + 4 {
            let x = Float(CGFloat(amount) - (rect.size.width - CGFloat(radius) - 4))
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: rect.size.width - CGFloat(radius) - 4, y: 4))
            var angle = -acos(x / radius)
            if angle.isNaN {
                angle = 0
            }
            context.addArc(center: CGPoint(x: rect.size.width - CGFloat(radius) - 4, y: rect.size.height / 2), radius: CGFloat(radius), startAngle: .pi, endAngle: CGFloat(angle), clockwise: false)
            context.addLine(to: CGPoint(x: CGFloat(amount), y: rect.size.height / 2))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: rect.size.height - 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: rect.size.width - CGFloat(radius) - 4, y: rect.size.height - 4))
            angle = acos(x / radius)
            if angle.isNaN {
                angle = 0
            }
            context.addArc(center: CGPoint(x: rect.size.width - CGFloat(radius) - 4, y: rect.size.height / 2), radius: CGFloat(radius), startAngle: -.pi, endAngle: CGFloat(angle), clockwise: true)
            context.addLine(to: CGPoint(x: CGFloat(amount), y: rect.size.height / 2))
            context.fillPath()
        } else if amount < radius + 4 && amount > 0 {
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: CGFloat(radius + 4), y: rect.size.height / 2))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: CGFloat(radius + 4), y: rect.size.height - 4), radius: CGFloat(radius))
            context.addLine(to: CGPoint(x: CGFloat(radius + 4), y: rect.size.height / 2))
            context.fillPath()
        }
    }
    
}

/**
 * A Spinner indefinite progress view modifying look of NSProgressIndicator.
 */
class SpinnerProgressView: NSProgressIndicator {
    // Create subclass of NSProgressIndicator inside method do like this
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        // Drawing code here.
        controlTint = .graphiteControlTint
        if let context = NSGraphicsContext.current?.cgContext {
            context.setBlendMode(.softLight)
        }
        NSColor.white.withAlphaComponent(1).set()
        NSBezierPath.fill(dirtyRect)
        super.draw(dirtyRect)
    }
}
