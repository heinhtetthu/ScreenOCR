import Cocoa

@MainActor
class HUDManager: NSObject {
    static let shared = HUDManager()
    
    private var hudWindow: NSWindow?
    private var timer: Timer?
    
    private override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.level = .floating
        window.backgroundColor = .clear // Important to avoid sharp corners
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        
        // Use Visual Effect for Blur
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow // Standard HUD blur
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10 // Slightly rounder
        visualEffect.layer?.masksToBounds = true
        // Optional: darken it a bit more if needed, but hudWindow is usually good.
        
        let label = NSTextField(labelWithString: "")
        label.identifier = NSUserInterfaceItemIdentifier("HUDLabel")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .white
        label.drawsBackground = false
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(label)
        
        // Tighter padding
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: visualEffect.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: visualEffect.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: visualEffect.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: visualEffect.trailingAnchor, constant: -12)
        ])
        
        window.contentView = visualEffect
        self.hudWindow = window
    }
    
    func show(message: String, icon: String? = nil) {
        guard let window = hudWindow, let contentView = window.contentView else { return }
        
        // Update text
        if let label = contentView.subviews.first(where: { $0.identifier?.rawValue == "HUDLabel" }) as? NSTextField {
            label.stringValue = message
            label.sizeToFit()
        }
        
        // Resize window to fit text + padding
        if let label = contentView.subviews.first(where: { $0.identifier?.rawValue == "HUDLabel" }) as? NSTextField {
             // Compact sizing
            let textSize = label.intrinsicContentSize
            let width = max(100, textSize.width + 30) // Reduced horizontal padding
            let height = max(36, textSize.height + 16) // Reduced vertical padding
            let frame = NSRect(x: 0, y: 0, width: width, height: height)
            window.setFrame(frame, display: true)
        }

        // Position: Bottom of Main Screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - window.frame.width / 2
            // 80 points from the bottom of the visible frame (above dock)
            let y = screenRect.minY + 80 
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        window.animator().alphaValue = 1.0
        
        timer?.invalidate()
        let win = window // Capture for block
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task { @MainActor in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    win.animator().alphaValue = 0
                } completionHandler: {
                    win.orderOut(nil)
                }
            }
        }
    }
}
