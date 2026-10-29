import Foundation
import CoreGraphics
import AppKit

/// Dispatches macOS system-level shortcuts for Mission Control, Spaces, and Application Switching.
public final class SystemActionController: @unchecked Sendable {
    public static let shared = SystemActionController()

    // Virtual key codes on macOS
    private let kVK_UpArrow: CGKeyCode = 126
    private let kVK_DownArrow: CGKeyCode = 125
    private let kVK_LeftArrow: CGKeyCode = 123
    private let kVK_RightArrow: CGKeyCode = 124
    private let kVK_Tab: CGKeyCode = 48
    private let kVK_F11: CGKeyCode = 103

    public var onToggleAppSwitcher: (@Sendable () -> Void)?

    public init() {}

    /// Triggers macOS Mission Control.
    public func triggerMissionControl() {
        postKeyCombination(keyCode: kVK_UpArrow, flags: .maskControl)
    }

    /// Triggers Show Desktop.
    public func triggerShowDesktop() {
        postKeyCombination(keyCode: kVK_DownArrow, flags: .maskControl)
    }

    /// Navigates to the Previous Space.
    public func triggerPreviousSpace() {
        postKeyCombination(keyCode: kVK_LeftArrow, flags: .maskControl)
    }

    /// Navigates to the Next Space.
    public func triggerNextSpace() {
        postKeyCombination(keyCode: kVK_RightArrow, flags: .maskControl)
    }

    /// Triggers application switching: either standard Command+Tab or custom floating switcher.
    public func triggerApplicationSwitch(native: Bool = false) {
        if native {
            postKeyCombination(keyCode: kVK_Tab, flags: .maskCommand)
        } else {
            onToggleAppSwitcher?()
        }
    }

    private func postKeyCombination(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        DiagnosticsLogger.shared.recordEvent()
    }
}
