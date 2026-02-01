import Cocoa
import SwiftUI

@MainActor
class MenuBarManager: NSObject {
    var statusItem: NSStatusItem
    var menu: NSMenu
    var permissionManager = PermissionManager()
    var overlayController: CaptureOverlayController?
    
    // We will keep a reference to the overlay window controller here later
    // var overlayController: OverlayWindowController?
    
    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        overlayController = CaptureOverlayController()
        super.init()
        
        setupMenu()
        setupHotKey()
    }
    
    var scanItem: NSMenuItem?

    func setupMenu() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // "doc.text.fill" is a solid, bold document icon.
            // No viewfinder. Represents "Text/Content" captured.
            button.image = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: "ScreenOCR")
        }
        
        print("Menu Bar Item configured.")
        
        // Clear existing menu items if setupMenu is called multiple times
        menu.removeAllItems()
        
        // Scan Selection
        scanItem = NSMenuItem(title: "Scan Selection", action: #selector(scanSelection), keyEquivalent: "C")
        scanItem?.target = self
        scanItem?.keyEquivalentModifierMask = [.command, .shift] // Default
        if let item = scanItem {
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit ScreenOCR", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Observe UserDefaults for changes
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        // Initial update
        updateMenuShortcut()
    }
    
    @objc func defaultsChanged() {
        updateMenuShortcut()
    }
    
    func updateMenuShortcut() {
        let keyCode = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        let mods = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
        
        // If 0, use default Cmd+Shift+C (Keycode 8)
        let effectiveKeyCode = keyCode == 0 ? 8 : keyCode
        let effectiveMods = mods == 0 ? 768 : mods
        
        // Convert Carbon keycode to string (simplistic approach for common keys)
        // This is tricky without a full mapping table, but we can try to use standard Carbon functions or a partial map.
        // For now, let's just map the most common ones or leave it as "C" if it fails, but update modifiers.
        // Actually, we can assume the user just recorded it, so we can try to get the character.
        
        if let keyString = keyCodeToString(effectiveKeyCode) {
             scanItem?.keyEquivalent = keyString
        }
        
        scanItem?.keyEquivalentModifierMask = carbonModifiersToCocoa(effectiveMods)
    }
    
    func carbonModifiersToCocoa(_ carbonMods: Int) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        // Carbon cmdKey = 256, shiftKey = 512, optionKey = 2048, controlKey = 4096
        if (carbonMods & 256) != 0 { flags.insert(.command) }
        if (carbonMods & 512) != 0 { flags.insert(.shift) }
        if (carbonMods & 2048) != 0 { flags.insert(.option) }
        if (carbonMods & 4096) != 0 { flags.insert(.control) }
        return flags
    }
    
    func keyCodeToString(_ keyCode: Int) -> String? {
        // Basic mapping for common keys
        switch keyCode {
        case 0: return "a"; case 1: return "s"; case 2: return "d"; case 3: return "f"; case 4: return "h"; case 5: return "g"
        case 6: return "z"; case 7: return "x"; case 8: return "c"; case 9: return "v"; case 11: return "b"; case 12: return "q"
        case 13: return "w"; case 14: return "e"; case 15: return "r"; case 16: return "y"; case 17: return "t"; case 31: return "o"
        case 34: return "i"; case 35: return "p"; case 37: return "l"; case 38: return "j"; case 40: return "k"; case 45: return "n"
        case 46: return "m"
        // Add more as needed or look up UCKeyTranslate if we want full support, but that's complex.
        // This covers letters.
        default: return nil 
        }
    }
    
    func setupHotKey() {
        HotKeyManager.shared.onTrigger = { [weak self] in
            DispatchQueue.main.async {
                self?.scanSelection()
            }
        }
        
        let defaults = UserDefaults.standard
        let keyCode = defaults.integer(forKey: "hotkeyKeyCode")
        let modifiers = defaults.integer(forKey: "hotkeyModifiers")
        
        if keyCode != 0 {
             HotKeyManager.shared.registerHotKey(keyCode: keyCode, modifiers: modifiers)
        } else {
             // Register with default values (Cmd+Shift+C) if not set
             // Note: PreferencesView uses 8 and 768 as defaults in AppStorage, but that logic is inside View.
             // We should match defaults.
             HotKeyManager.shared.registerHotKey()
        }
    }
    
    var preferencesWindow: NSWindow?

    @MainActor
    @objc func scanSelection() {
        // Check permissions first
        guard permissionManager.checkScreenRecordingPermission() else {
            print("Permission not granted")
            permissionManager.requestScreenRecordingPermission()
            return
        }

        print("Scan Selection Triggered")
        overlayController?.showOverlay()
    }
    
    @MainActor
    @objc func openPreferences() {
        print("Open Preferences")
        
        // If window already exists, show it
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        window.center()
        window.title = "ScreenOCR Preferences"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        preferencesWindow = window
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @MainActor
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
