import Cocoa
import SwiftUI

// Custom window to allow borderless window to become key
class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class CaptureOverlayController: NSObject, SelectionViewDelegate {
    private var window: OverlayWindow?
    private var selectionView: SelectionView?
    
    override init() {
        super.init()
        setupOverlay()
        
        // Listen for show notification
        NotificationCenter.default.addObserver(self, selector: #selector(showOverlay), name: Notification.Name("ShowOverlay"), object: nil)
    }
    
    private func setupOverlay() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Create selection view
        selectionView = SelectionView(frame: screenRect)
        selectionView?.delegate = self
        
        // Create window
        window = OverlayWindow(contentRect: screenRect,
                               styleMask: [.borderless, .fullSizeContentView],
                               backing: .buffered,
                               defer: false)
        
        // Configure window
        window?.level = .screenSaver
        window?.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window?.isOpaque = false
        window?.hasShadow = false
        window?.ignoresMouseEvents = false
        window?.contentView = selectionView
        
        // Important: ensure it can receive events
        window?.makeKey()
    }
    
    @objc func showOverlay() {
        Logger.shared.log("Show Overlay Triggered")
        // Refresh frame in case of screen changes.
        if let screen = NSScreen.main {
            window?.setFrame(screen.frame, display: true)
            selectionView?.frame = NSRect(origin: .zero, size: screen.frame.size)
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        selectionView?.reset()
    }
    
    func hideOverlay() {
        window?.orderOut(nil)
    }
    
    // MARK: - SelectionViewDelegate
    
    func didSelectRect(_ rect: CGRect) {
        Logger.shared.log("Selection made: \(rect)")
        
        guard let window = self.window, let screen = window.screen else {
            Logger.shared.log("Error: Window or Screen not found")
            hideOverlay()
            return
        }
        
        // Capture window ID BEFORE hiding
        let windowID = CGWindowID(window.windowNumber)
        Logger.shared.log("Excluding Window ID: \(windowID)")
        
        selectionView?.reset()
        hideOverlay()
        
        // In Cocoa (AppKit), y is from bottom. In CoreGraphics (Quartz), y is from top (usually).
        // Let's use the screen height to flip Y.
        let screenHeight = screen.frame.height
        var screenRect = rect
        screenRect.origin.y = screenHeight - rect.maxY // Flip Y
        
        Logger.shared.log("Converted Rect: \(screenRect)")
        
        // Trigger OCR
        OCRService.shared.performOCR(for: screenRect, windowToExclude: windowID)
    }
    
    func didCancelSelection() {
        Logger.shared.log("Selection cancelled by user.")
        hideOverlay()
    }
}
