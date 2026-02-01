import Cocoa

// Usage: swift set_icon.swift <image_path> <file_path>

guard CommandLine.arguments.count == 3 else {
    print("Usage: swift set_icon.swift <image_path> <file_path>")
    exit(1)
}

let imagePath = CommandLine.arguments[1]
let targetPath = CommandLine.arguments[2]

// Load image
guard let image = NSImage(contentsOfFile: imagePath) else {
    print("Error: Could not load image from \(imagePath)")
    exit(1)
}

// Set icon
let success = NSWorkspace.shared.setIcon(image, forFile: targetPath, options: [])

if success {
    print("Success: Icon applied to \(targetPath)")
} else {
    print("Error: Failed to apply icon.")
    exit(1)
}
