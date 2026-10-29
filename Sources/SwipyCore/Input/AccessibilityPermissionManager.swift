import Foundation
import ApplicationServices
import AppKit

/// Verifies and requests macOS Accessibility privileges required for synthetic input generation.
public final class AccessibilityPermissionManager: @unchecked Sendable {
    public static let shared = AccessibilityPermissionManager()

    public init() {}

    /// Checks if the process is trusted for accessibility.
    public var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant accessibility permission in System Settings.
    public func promptForAccessibility() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings > Privacy & Security > Accessibility.
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
