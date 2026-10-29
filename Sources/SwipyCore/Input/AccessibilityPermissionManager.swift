import Foundation
import ApplicationServices
import AppKit

/// Verifies and requests macOS Accessibility privileges required for synthetic input generation.
public final class AccessibilityPermissionManager: @unchecked Sendable {
    public static let shared = AccessibilityPermissionManager()

    public init() {}

    /// Checks if the process is trusted for accessibility (forcing a fresh non-cached TCC query).
    public var isTrusted: Bool {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Prompts the user to grant accessibility permission in System Settings.
    public func promptForAccessibility() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings > Privacy & Security > Accessibility after triggering the system prompt.
    public func openAccessibilitySettings() {
        promptForAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
