import SwiftUI
import Carbon

// Carbon constants might not be automatically exposed as simple Ints in Swift in all contexts without bridging,
// but usually they are valid. Let's ensure we use the correct Int values if the build fails.
// cmdKey = 256, shiftKey = 512, optionKey = 2048, controlKey = 4096


struct PreferencesView: View {
    @AppStorage("hotkeyKeyCode") private var storedKeyCode: Int = 8 // 'C'
    @AppStorage("hotkeyModifiers") private var storedModifiers: Int = 768 // Cmd + Shift (256 + 512)
    
    @State private var isRecording = false
    @AppStorage("showHUD") private var showHUD: Bool = true
    
    @State private var shortcutString: String = "Press a key..."
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ScreenOCR Preferences")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Global Shortcut:")
                    .font(.headline)
                
                HStack {
                    Button(action: {
                        isRecording.toggle()
                    }) {
                        Text(isRecording ? "Press keys now..." : shortcutString)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .frame(minWidth: 200)
                            .background(isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isRecording ? Color.red : Color.gray, lineWidth: 1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    if isRecording {
                        Button("Cancel") {
                            isRecording = false
                        }
                    }
                }
            }
            
            if isRecording {
                Text("Press your desired key combination (e.g., Cmd+Shift+S)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // HUD Toggle
            Toggle("Show Visual HUD", isOn: $showHUD)
                .toggleStyle(SwitchToggleStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Shows a floating 'Copied' message at the bottom of the screen.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button("Done") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 400, height: 300)
        .onAppear {
            updateShortcutString()
        }
        .onChange(of: storedKeyCode) { _ in updateShortcutString(); updateHotKey() }
        .onChange(of: storedModifiers) { _ in updateShortcutString(); updateHotKey() }
        .onChange(of: isRecording) { recording in
            Logger.shared.log("isRecording changed to: \(recording)")
            if recording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }
    
    private func updateShortcutString() {
        // Simple formatter
        var parts: [String] = []
        if (storedModifiers & cmdKey) != 0 { parts.append("Cmd") }
        if (storedModifiers & shiftKey) != 0 { parts.append("Shift") }
        if (storedModifiers & optionKey) != 0 { parts.append("Opt") }
        if (storedModifiers & controlKey) != 0 { parts.append("Ctrl") }
        
        // Convert keycode to string (simplified)
        // In reality, we need UCKeyTranslate, but for now we can handle common letters
        let keyChar = keyToString(keyCode: CGKeyCode(storedKeyCode))
        parts.append(keyChar)
        
        shortcutString = parts.joined(separator: "+")
    }
    
    private func keyToString(keyCode: CGKeyCode) -> String {
        // Very basic map for common keys
        switch keyCode {
        case 8: return "C"
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 53: return "Esc"
        default: return "Key(\(keyCode))"
        }
    }
    
    private func updateHotKey() {
        HotKeyManager.shared.registerHotKey(keyCode: storedKeyCode, modifiers: storedModifiers)
    }
    
    // Recording Logic
    @State private var monitor: Any?
    
    private func startRecording() {
        Logger.shared.log("Start recording shortcut...")
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            Logger.shared.log("KeyDown: \(event.keyCode), Modifiers: \(event.modifierFlags.rawValue)")
            
            if self.isRecording {
                // If escape, cancel
                if event.keyCode == 53 {
                    Logger.shared.log("Escape pressed, cancelling recording")
                    self.isRecording = false
                    return nil
                }
                
                // Save
                // Convert Cocoa modifiers to Carbon modifiers
                var mods = 0
                if event.modifierFlags.contains(.command) { mods |= cmdKey }
                if event.modifierFlags.contains(.shift) { mods |= shiftKey }
                if event.modifierFlags.contains(.option) { mods |= optionKey }
                if event.modifierFlags.contains(.control) { mods |= controlKey }
                
                Logger.shared.log("Recorded: KeyCode \(event.keyCode), Mods: \(mods)")
                
                self.storedKeyCode = Int(event.keyCode)
                self.storedModifiers = mods
                self.isRecording = false
                return nil // consume event
            }
            return event
        }
    }
    
    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
