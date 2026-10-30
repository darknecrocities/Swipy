import Foundation
import CoreGraphics
import AppKit

/// Strategies for delivering a keyboard shortcut to macOS. Several exist so the real delivery behaviour can be
/// measured on the target machine (see the in-app `--selftest-spaces` run) instead of assumed.
public enum KeyComboVariant: String, CaseIterable, Sendable {
    /// One event pair at the HID tap; the modifier is carried only as an event flag.
    case hidArrowOnly
    /// Same, plus the Fn flag that physical arrow keys always carry.
    case hidArrowWithFn
    /// Modifier key-down, key press, modifier key-up: what a physical keyboard produces.
    case hidModifierSequence
    /// Legacy behaviour: the same event posted to both the session tap and the HID tap.
    case legacyDoublePost
}

/// Dispatches macOS system-level shortcuts for Mission Control, Spaces, and Application Switching.
public final class SystemActionController: @unchecked Sendable {
    public static let shared = SystemActionController()

    // Virtual key codes on macOS
    private let kVK_UpArrow: CGKeyCode = 126
    private let kVK_DownArrow: CGKeyCode = 125
    private let kVK_LeftArrow: CGKeyCode = 123
    private let kVK_RightArrow: CGKeyCode = 124
    private let kVK_Tab: CGKeyCode = 48
    private let kVK_Command: CGKeyCode = 55
    private let kVK_Shift: CGKeyCode = 56
    private let kVK_Control: CGKeyCode = 59

    /// Delivery strategy used for Control+Arrow shortcuts (Spaces, Mission Control).
    public var shortcutVariant: KeyComboVariant = .hidModifierSequence

    public var onToggleAppSwitcher: (@Sendable () -> Void)?
    public var onToggleTrackingPause: (@Sendable () -> Void)?

    /// Key synthesis runs here so the camera/Vision thread never sleeps between key events.
    private let queue = DispatchQueue(label: "com.swipy.system-actions", qos: .userInteractive)

    public init() {}

    // MARK: - Actions

    /// Performs a bound gesture action. Non-system actions (clicks, scroll, ...) are ignored here.
    public func perform(_ action: GestureAction) {
        switch action {
        case .missionControl: triggerMissionControl()
        case .showDesktop: triggerShowDesktop()
        case .previousSpace: triggerPreviousSpace()
        case .nextSpace: triggerNextSpace()
        case .nextApplication: postApplicationSwitch(reverse: false)
        case .previousApplication: postApplicationSwitch(reverse: true)
        case .toggleAppSwitcher: onToggleAppSwitcher?()
        case .toggleTrackingPause: onToggleTrackingPause?()
        default: break
        }
    }

    /// Resolves which action a recognized swipe should run from the user's gesture bindings.
    /// Returns `nil` when the matching binding is missing, disabled, or set to "No Action".
    public static func swipeAction(
        direction: SwipeDirection,
        fingers: Int,
        bindings: [GestureBinding]
    ) -> GestureAction? {
        let type: GestureType
        switch (direction, fingers >= 4) {
        case (.left, true): type = .fourFingerSwipeLeft
        case (.right, true): type = .fourFingerSwipeRight
        case (.left, false): type = .threeFingerSwipeLeft
        case (.right, false): type = .threeFingerSwipeRight
        case (.up, _): type = .threeFingerSwipeUp
        case (.down, _): type = .threeFingerSwipeDown
        }
        guard let binding = bindings.first(where: { $0.gestureType == type }),
              binding.isEnabled,
              binding.action != .none else { return nil }
        return binding.action
    }

    /// Triggers macOS Mission Control.
    public func triggerMissionControl() {
        postControlShortcut(keyCode: kVK_UpArrow, variant: shortcutVariant)
    }

    /// Triggers Show Desktop.
    public func triggerShowDesktop() {
        postControlShortcut(keyCode: kVK_DownArrow, variant: shortcutVariant)
    }

    /// Navigates to the Previous Space.
    public func triggerPreviousSpace() {
        postControlShortcut(keyCode: kVK_LeftArrow, variant: shortcutVariant)
    }

    /// Navigates to the Next Space.
    public func triggerNextSpace() {
        postControlShortcut(keyCode: kVK_RightArrow, variant: shortcutVariant)
    }

    /// Triggers application switching: either standard Command+Tab or custom floating switcher.
    public func triggerApplicationSwitch(native: Bool = false) {
        if native {
            postApplicationSwitch(reverse: false)
        } else {
            onToggleAppSwitcher?()
        }
    }

    // MARK: - Delivery

    /// Posts Control+`keyCode` using the given strategy. Public so the self-test can compare strategies.
    public func postControlShortcut(keyCode: CGKeyCode, variant: KeyComboVariant) {
        queue.async { [self] in
            switch variant {
            case .legacyDoublePost:
                let source = CGEventSource(stateID: .combinedSessionState)
                postPair(keyCode: keyCode, flags: .maskControl, source: source, taps: [.cgSessionEventTap, .cghidEventTap])
            case .hidArrowOnly:
                let source = CGEventSource(stateID: .hidSystemState)
                postPair(keyCode: keyCode, flags: .maskControl, source: source, taps: [.cghidEventTap])
            case .hidArrowWithFn:
                let source = CGEventSource(stateID: .hidSystemState)
                postPair(keyCode: keyCode, flags: [.maskControl, .maskSecondaryFn], source: source, taps: [.cghidEventTap])
            case .hidModifierSequence:
                postSequence(keyCode: keyCode, modifiers: [(kVK_Control, .maskControl)])
            }
            DiagnosticsLogger.shared.recordEvent()
        }
    }

    private func postApplicationSwitch(reverse: Bool) {
        queue.async { [self] in
            var modifiers: [(CGKeyCode, CGEventFlags)] = [(kVK_Command, .maskCommand)]
            if reverse { modifiers.append((kVK_Shift, .maskShift)) }
            postSequence(keyCode: kVK_Tab, modifiers: modifiers, tap: .cghidEventTap)
            DiagnosticsLogger.shared.recordEvent()
        }
    }

    private func postPair(
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        source: CGEventSource?,
        taps: [CGEventTapLocation],
        holdMicroseconds: useconds_t = 30_000
    ) {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        taps.forEach { down.post(tap: $0) }
        usleep(holdMicroseconds)
        taps.forEach { up.post(tap: $0) }
    }

    /// Presses modifiers, taps `keyCode`, then releases the modifiers in reverse order.
    /// Posts strictly to `.cghidEventTap` to bypass frontmost app key interception (Chrome, Terminal).
    private func postSequence(
        keyCode: CGKeyCode,
        modifiers: [(CGKeyCode, CGEventFlags)],
        tap: CGEventTapLocation = .cghidEventTap
    ) {
        let source = CGEventSource(stateID: .hidSystemState)
        var held: CGEventFlags = []

        for (key, flag) in modifiers {
            held.insert(flag)
            postFlagsChanged(key: key, flags: held, down: true, source: source, tap: tap)
            usleep(12_000)
        }

        var eventFlags = held
        // Physical arrow keys on macOS include the Fn modifier flag (.maskSecondaryFn)
        if [kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow].contains(keyCode) {
            eventFlags.insert(.maskSecondaryFn)
        }

        postPair(keyCode: keyCode, flags: eventFlags, source: source, taps: [tap], holdMicroseconds: 30_000)
        usleep(12_000)

        for (key, flag) in modifiers.reversed() {
            held.remove(flag)
            postFlagsChanged(key: key, flags: held, down: false, source: source, tap: tap)
            usleep(12_000)
        }
    }

    private func postFlagsChanged(
        key: CGKeyCode,
        flags: CGEventFlags,
        down: Bool,
        source: CGEventSource?,
        tap: CGEventTapLocation = .cghidEventTap
    ) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down) else { return }
        event.type = .flagsChanged
        event.flags = flags
        event.post(tap: tap)
    }
}
