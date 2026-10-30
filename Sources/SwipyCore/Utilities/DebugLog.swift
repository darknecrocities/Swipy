import Foundation

/// Opt-in diagnostic log written to `~/Library/Logs/Swipy/swipy-debug.log`.
///
/// Enabled by launching with `SWIPY_DEBUG=1` or `defaults write com.swipy.Swipy com.swipy.debugLog -bool true`.
/// Disabled (zero overhead beyond one boolean check) otherwise.
public enum DebugLog {
    public static let isEnabled: Bool = {
        ProcessInfo.processInfo.environment["SWIPY_DEBUG"] == "1"
            || UserDefaults.standard.bool(forKey: "com.swipy.debugLog")
    }()

    private static let queue = DispatchQueue(label: "com.swipy.debuglog", qos: .utility)
    private static let maxBytes = 1_000_000

    public static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Swipy/swipy-debug.log")
    }

    public static func log(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message())\n"
        queue.async {
            let url = fileURL
            let fm = FileManager.default
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let size = (try? fm.attributesOfItem(atPath: url.path)[.size]) as? Int, size > maxBytes {
                try? fm.removeItem(at: url)
            }
            if !fm.fileExists(atPath: url.path) {
                fm.createFile(atPath: url.path, contents: nil)
            }
            guard let handle = try? FileHandle(forWritingTo: url),
                  let data = line.data(using: .utf8) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }
}
