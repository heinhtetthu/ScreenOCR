import Cocoa
import Carbon

final class HotKeyManager: @unchecked Sendable {
    static let shared = HotKeyManager()
    
    private var eventHotKeyRef: EventHotKeyRef?
    private var hotKeyID = EventHotKeyID(signature: 0x534F4352, id: 1) // 'SOCR', 1
    
    var onTrigger: (() -> Void)?
    
    private init() {
        setupEventHandler()
    }
    
    func registerHotKey(keyCode: Int = 8, modifiers: Int = cmdKey | shiftKey) {
        unregisterHotKey()
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install handler only once if not already installed? 
        // Actually InstallEventHandler can be called once in init.
        // But for simplicity let's keep it here but we should be careful about multiple handlers.
        // Better: unique handler installation.
        
        if eventHotKeyRef == nil {
             // Only install the handler if we don't have a ref (implying first time or clean start), 
             // but actually connection is to the target. 
             // Let's just install it once in init or lazy load.
             // For this simple class, we'll strip the handler installation from here and put it in init.
        }
        
        // Register the HotKey
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hotKeyID, GetApplicationEventTarget(), 0, &eventHotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        } else {
            print("Hotkey Registered: KeyCode \(keyCode), Modifiers \(modifiers)")
        }
    }
    
    func unregisterHotKey() {
        if let ref = eventHotKeyRef {
            UnregisterEventHotKey(ref)
            eventHotKeyRef = nil
        }
    }
    
    // Helper for initialization
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
            HotKeyManager.shared.onTrigger?()
            return noErr
        }, 1, &eventType, nil, nil)
    }
}
