
import AppKit

class BarProgressView: NSView {
    
    @objc var progress: CGFloat = 0.0 { didSet { needsDisplay = true } }
    
    var progressColor: NSColor = .black { didSet { needsDisplay = true } }
    
    // MARK: - Lifecycle
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 140.0, height: 30.0))
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
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // setup properties
        context.setLineWidth(2)
        context.setStrokeColor(progressColor.cgColor)
        context.setFillColor(progressColor.cgColor)
        
        // draw line border
        var radius = (rect.size.height / 2) - 2
        context.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2, y: 2), radius: radius)
        context.addLine(to: CGPoint(x: rect.size.width - radius - 2, y: 2))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context.strokePath()
        
        // draw progress
        radius -= 2
        let amount = progress * rect.size.width
        // if progress is in the middle area
        if amount >= radius + 4 && amount <= (rect.size.width - radius - 4) {
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: 4))
            context.addLine(to: CGPoint(x: amount, y: radius + 4))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height - 4))
            context.addLine(to: CGPoint(x: amount, y: radius + 4))
            context.fillPath()
        } else if amount > radius + 4 {
            let x = amount - rect.size.width - radius - 4
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: 4))
            var angle = -acos(x / radius)
            if angle.isNaN {
                angle = 0
            }
            context.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height / 2), radius: radius, startAngle: .pi, endAngle: angle, clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height - 4))
            angle = acos(x / radius)
            if angle.isNaN {
                angle = 0
            }
            context.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height / 2), radius: radius, startAngle: -.pi, endAngle: angle, clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            context.fillPath()
        } else if amount < radius + 4 && amount > 0 {
            // top
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            // bottom
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            context.fillPath()
        }
    }
    
}
