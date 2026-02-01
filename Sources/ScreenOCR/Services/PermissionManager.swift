import Cocoa
import CoreGraphics

class PermissionManager {
    
    func checkScreenRecordingPermission() -> Bool {
        // CGPreflightScreenCaptureAccess() returns true if we have permission.
        // Available in macOS 11.0+.
        return CGPreflightScreenCaptureAccess()
    }
    
    @MainActor
    func requestScreenRecordingPermission() {
        // Requesting access via CGRequestScreenCaptureAccess() creates a prompt.
        // Available in macOS 11.0+.
        CGRequestScreenCaptureAccess()
        
        // We can also alert the user
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "ScreenOCR needs screen recording permission to capture the text on your screen. Please grant it in System Settings > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open System Settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
