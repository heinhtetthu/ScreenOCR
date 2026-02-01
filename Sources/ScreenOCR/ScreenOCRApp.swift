import SwiftUI
import AppKit

@main
struct ScreenOCRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app doesn't show in the Dock
        NSApp.setActivationPolicy(.accessory)
        
        menuBarManager = MenuBarManager()
    }
}
