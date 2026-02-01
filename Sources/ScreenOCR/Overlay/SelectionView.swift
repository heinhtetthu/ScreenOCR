import Cocoa

@MainActor
protocol SelectionViewDelegate: AnyObject {
    func didSelectRect(_ rect: CGRect)
    func didCancelSelection()
}

class SelectionView: NSView {
    
    weak var delegate: SelectionViewDelegate?
    
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var selectionLayer: CAShapeLayer!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayer() {
        selectionLayer = CAShapeLayer()
        selectionLayer.strokeColor = NSColor.white.cgColor
        selectionLayer.lineWidth = 1.0
        selectionLayer.lineDashPattern = [5, 3]
        selectionLayer.fillColor = NSColor.clear.cgColor
        selectionLayer.backgroundColor = NSColor.black.withAlphaComponent(0.0).cgColor // Clear inside, we might want to make outside dim
        
        // NOTE: A better way to do "dim everything but selection" is using a mask, 
        // but for simplicity we just draw a rectangle on top of the dimmed window.
        
        self.layer?.addSublayer(selectionLayer)
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        updateSelection()
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        updateSelection()
    }
    
    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        
        if let start = startPoint, let current = currentPoint {
            let rect = makeRect(from: start, to: current)
            if rect.width > 5 && rect.height > 5 {
                delegate?.didSelectRect(rect)
            } else {
                // Too small, treat as cancel or miss click
                delegate?.didCancelSelection()
            }
        }
        
        startPoint = nil
        currentPoint = nil
        selectionLayer.path = nil
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            delegate?.didCancelSelection()
        }
    }
    
    // Ensure we can receive key events
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private func updateSelection() {
        guard let start = startPoint, let current = currentPoint else { return }
        let rect = makeRect(from: start, to: current)
        let path = CGPath(rect: rect, transform: nil)
        selectionLayer.path = path
    }
    
    private func makeRect(from p1: NSPoint, to p2: NSPoint) -> CGRect {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        let w = abs(p1.x - p2.x)
        let h = abs(p1.y - p2.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
    func reset() {
        startPoint = nil
        currentPoint = nil
        selectionLayer.path = nil
    }
}
