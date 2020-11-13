//
//  Common.swift
//  Fragment
//
//  Created by Cyrus Pellet on 24/08/2020.
//

import Cocoa

func popUpError(title: String, message: String = ""){
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.runModal()
}

extension URL {
    
    var representsBundle: Bool {
        pathExtension == "app"
    }
    
    var isValid: Bool {
        !path.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var numberOfFilesInDirectory: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: path))?.count ?? 0
    }
    
}

extension Bundle {
    
    var localizedName: String {
        NSRunningApplication.current.localizedName ?? "The App"
    }
    
    var isInstalled: Bool {
        NSSearchPathForDirectoriesInDomains(.applicationDirectory, .allDomainsMask, true).contains(where: { $0.hasPrefix(bundlePath)
        }) || bundlePath.split(separator: "/").contains("Applications")
    }
    
    func copy(to url: URL) throws {
        try FileManager.default.copyItem(at: bundleURL, to: url)
    }
    
}

extension Process {
    
    static func runTask(command: String, arguments: [String] = [], completion: ((Int32) -> Void)? = nil) {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        task.terminationHandler = { task in
            completion?(task.terminationStatus)
        }
        task.launch()
    }
    
}

extension NSImage {
    func tinting(with tintColor: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }
        
        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)
            return true
        }
    }
}

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
