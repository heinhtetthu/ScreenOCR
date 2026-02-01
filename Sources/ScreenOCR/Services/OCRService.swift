import Cocoa
import Vision
import UserNotifications

@MainActor
class OCRService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = OCRService()
    
    // Maintain a serial queue for background requests
    // Actually, dispatching to global global is fine, but let's keep it clean
    
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let os = ProcessInfo.processInfo.operatingSystemVersion
        Logger.shared.log("OCRService Init. OS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)")
        
        // Request permission eagerly
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.shared.log("Notification permission error: \(error)")
            } else {
                Logger.shared.log("Notification permission granted: \(granted)")
            }
        }
    }
    
    func performOCR(for rect: CGRect, windowToExclude: CGWindowID? = nil) {
        Logger.shared.log("Starting OCR for rect: \(rect)")
        
        // Validation
        if rect.width <= 1 || rect.height <= 1 {
            Logger.shared.log("Rect too small, aborting.")
            return
        }
        
        // 1. Capture Image from Screen
        let windowID = windowToExclude ?? kCGNullWindowID
        let options: CGWindowListOption = windowToExclude != nil ? .optionOnScreenBelowWindow : .optionOnScreenOnly
        
        guard let cgImage = CGWindowListCreateImage(rect, options, windowID, .bestResolution) else {
            Logger.shared.log("Failed to capture screen image (CGWindowListCreateImage returned nil)")
            return
        }
        
        Logger.shared.log("Performing OCR on image of size: \(cgImage.width)x\(cgImage.height)")
        
        // Debug: Save image
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        if let data = bitmapRep.representation(using: .png, properties: [:]) {
            let path = "/tmp/ScreenOCR_Debug.png"
            try? data.write(to: URL(fileURLWithPath: path))
            Logger.shared.log("Debug: Saved captured image to \(path)")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            Logger.shared.log("Dispatching Vision Request")
            
            // 1. Barcode Request
            let barcodeRequest = VNDetectBarcodesRequest()
            
            // 2. Text Request (Try latest revision)
            let textRequest: VNRecognizeTextRequest
            if #available(macOS 13.0, *) {
                textRequest = VNRecognizeTextRequest(completionHandler: nil)
                textRequest.revision = VNRecognizeTextRequestRevision3
            } else {
                textRequest = VNRecognizeTextRequest(completionHandler: nil)
                textRequest.revision = VNRecognizeTextRequestRevision2
            }
            
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true
            textRequest.automaticallyDetectsLanguage = true
            
            do {
                let supportedLanguages = try textRequest.supportedRecognitionLanguages()
                // Explicitly set all supported languages to encourage detection
                textRequest.recognitionLanguages = supportedLanguages
                Logger.shared.log("Vision Request Revision: \(textRequest.revision). Enabled languages: \(supportedLanguages)")
            } catch {
                Logger.shared.log("Error configuring languages: \(error)")
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([barcodeRequest, textRequest])
                
                // A. Check Barcodes
                if let barcodes = barcodeRequest.results, !barcodes.isEmpty {
                    Logger.shared.log("Found \(barcodes.count) barcodes")
                    if let firstWrapper = barcodes.first, let payload = firstWrapper.payloadStringValue {
                         Logger.shared.log("Barcode payload: \(payload)")
                         DispatchQueue.main.async {
                             self.handleResult(payload, type: "QR/Barcode")
                         }
                         return
                    }
                }
                
                // B. Check Text
                guard let observations = textRequest.results else {
                    DispatchQueue.main.async { self.showNotification(title: "OCR Failed", text: "No text recognized") }
                    return
                }
                
                Logger.shared.log("Found \(observations.count) text observations")
                
                if observations.isEmpty {
                    DispatchQueue.main.async { self.showNotification(title: "No Content Found", text: "No text or barcodes found.") }
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let joinedText = recognizedStrings.joined(separator: "\n")
                Logger.shared.log("Recognized text length: \(joinedText.count)")
                
                DispatchQueue.main.async {
                    self.handleResult(joinedText, type: "Text")
                }
                
            } catch {
                Logger.shared.log("Failed to perform Vision Request: \(error)")
                DispatchQueue.main.async {
                     self.showNotification(title: "Error", text: "Vision Exception: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleResult(_ text: String, type: String) {
        // Copy to Clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("Copied to clipboard: \(text)")
        
        // Show Notification
        showNotification(title: "\(type) Copied", text: "Copied: \(text.prefix(30))...")
    }
    
    private func showNotification(title: String = "Text Copied", text: String) {
        Logger.shared.log("Showing HUD: '\(title)' - '\(text)'")
        
        // Show Visual HUD (if enabled)
        if UserDefaults.standard.bool(forKey: "showHUD") != false { // Default true
             DispatchQueue.main.async {
                 HUDManager.shared.show(message: title)
             }
        }
        
        // Still try to send system notification for history
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.log("Failed to add notification: \(error)")
            }
        }
    }
    
    // Delegate method to show notification even when app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
