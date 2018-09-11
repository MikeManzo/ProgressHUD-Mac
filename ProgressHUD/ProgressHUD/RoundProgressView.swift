
import AppKit

class RoundProgressView: NSView {
    
    /// Progress (0.0 to 1.0)
    @objc var progress: CGFloat = 0.0 { didSet { needsDisplay = true } }
    
    var progressTintColor = NSColor.black { didSet { needsDisplay = true } }
    
    /// Display mode - false = circular or true = annular.
    var annular = false { didSet { needsDisplay = true } }
    
    // MARK: - Lifecycle
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: NSRect) {
        
        let allRect = bounds
        let circleRect = allRect.insetBy(dx: 2.0, dy: 2.0)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if annular {
            
            let lineWidth: CGFloat = 5.0
            let processBackgroundPath = NSBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .round
            
            // Draw progress
            let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            let radius = (bounds.size.width - lineWidth) / 2
            let startAngle: CGFloat = 90
            var endAngle = startAngle - 360 * progress
            processBackgroundPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            progressTintColor.set()
            processBackgroundPath.stroke()
            let processPath = NSBezierPath()
            processPath.lineCapStyle = .round
            processPath.lineWidth = lineWidth
            endAngle = startAngle - .pi * 2
            processPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            progressTintColor.set()
            processPath.stroke()
            
        } else {
            
            progressTintColor.setStroke()
            context.setLineWidth(2.0)
            context.strokeEllipse(in: circleRect)
            
            // Draw progress
            let center = CGPoint(x: allRect.size.width / 2, y: allRect.size.height / 2)
            let radius = (allRect.size.width - 4) / 2
            let startAngle: CGFloat = .pi / 2
            let endAngle = startAngle - .pi * 2 * progress
            context.setFillColor(progressTintColor.cgColor)
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addArc(center: CGPoint(x: center.x, y: center.y), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.closePath()
            context.fillPath()
        }
    }
    
}
