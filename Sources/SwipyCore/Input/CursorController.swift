import Foundation
import CoreGraphics
import AppKit

/// Dispatches real system cursor movement to macOS.
public final class CursorController: @unchecked Sendable {
    public static let shared = CursorController()

    private let lock = NSLock()
    private var lastDispatchedPoint: CGPoint?

    public init() {}

    /// Current cursor location on the primary display in Cocoa coordinates (origin bottom-left).
    public var currentCursorPosition: CGPoint {
        NSEvent.mouseLocation
    }

    /// Current cursor location in Core Graphics Quartz global coordinates (origin top-left).
    /// Thread-safe and independent of NSScreen.main or window focus.
    public var currentQuartzCursorPosition: CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    /// Moves the actual macOS cursor to the specified screen coordinate.
    public func moveCursor(to point: CGPoint) {
        lock.lock()
        lastDispatchedPoint = point
        lock.unlock()

        // Warp hardware cursor position
        CGWarpMouseCursorPosition(point)

        let source = CGEventSource(stateID: .hidSystemState)
        source?.localEventsSuppressionInterval = 0.0

        // Post mouse moved event to update window focus and hover states in active GUI session
        if let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) {
            event.post(tap: .cghidEventTap)
            DiagnosticsLogger.shared.recordEvent()
        }
    }

    /// Primary display frame in global screen coordinates.
    /// Thread-safe via Quartz Display Services.
    public func primaryDisplayFrame() -> CGRect {
        CGDisplayBounds(CGMainDisplayID())
    }
}
