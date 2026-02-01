import Foundation

final class Logger: @unchecked Sendable {
    static let shared = Logger()
    private let logPath = "/tmp/screenocr.log"
    
    // Use a serial queue for thread safety
    private let queue = DispatchQueue(label: "com.screenocr.logger")
    
    private init() {
        // Reset log on start
        try? "".write(to: URL(fileURLWithPath: logPath), atomically: true, encoding: .utf8)
    }
    
    func log(_ message: String) {
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logMessage = "[\(timestamp)] \(message)\n"
            
            if let handle = FileHandle(forWritingAtPath: self.logPath) {
                handle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                try? logMessage.write(to: URL(fileURLWithPath: self.logPath), atomically: true, encoding: .utf8)
            }
            
            // Also print to stdout
            print(message)
        }
    }
}
