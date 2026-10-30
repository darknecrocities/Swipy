import Foundation
import CoreGraphics
import AppKit

/// Dispatches real system cursor movement to macOS.
public final class CursorController: @unchecked Sendable {
    public static let shared = CursorController()

    private let lock = NSLock()
    private var lastDispatchedPoint: CGPoint?

    public init() {}

    /// Current cursor location on the primary display.
    public var currentCursorPosition: CGPoint {
        NSEvent.mouseLocation
    }

    /// Moves the actual macOS cursor to the specified screen coordinate.
    public func moveCursor(to point: CGPoint) {
        lock.lock()
        lastDispatchedPoint = point
        lock.unlock()

        // Warp hardware cursor position
        CGWarpMouseCursorPosition(point)

        // Post mouse moved event to update window focus and hover states in active GUI session
        if let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) {
            event.post(tap: .cgSessionEventTap)
            event.post(tap: .cghidEventTap)
            DiagnosticsLogger.shared.recordEvent()
        }
    }

    /// Primary display frame in global screen coordinates.
    public func primaryDisplayFrame() -> CGRect {
        if let screen = NSScreen.main {
            return screen.frame
        }
        return CGRect(x: 0, y: 0, width: 1440, height: 900)
    }
}
