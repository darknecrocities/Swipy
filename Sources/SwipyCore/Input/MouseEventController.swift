import Foundation
import CoreGraphics
import AppKit

/// Dispatches mouse clicks, double clicks, right clicks, and drag-and-drop operations with tactile timing.
public final class MouseEventController: @unchecked Sendable {
    public static let shared = MouseEventController()

    private let lock = NSLock()
    private var isLeftButtonHeld = false
    private var isRightButtonHeld = false

    public init() {}

    /// Performs a single left mouse click with realistic tactile duration.
    public func leftClick(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .leftMouseDown, point: point, button: .left, clickState: 1)
        usleep(25_000) // 25ms press duration
        postMouseEvent(type: .leftMouseUp, point: point, button: .left, clickState: 1)
        DiagnosticsLogger.shared.recordEvent()
    }

    /// Performs a rapid double click with proper inter-click separation.
    public func doubleClick(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .leftMouseDown, point: point, button: .left, clickState: 1)
        usleep(20_000)
        postMouseEvent(type: .leftMouseUp, point: point, button: .left, clickState: 1)
        usleep(40_000)
        postMouseEvent(type: .leftMouseDown, point: point, button: .left, clickState: 2)
        usleep(20_000)
        postMouseEvent(type: .leftMouseUp, point: point, button: .left, clickState: 2)
        DiagnosticsLogger.shared.recordEvent()
    }

    /// Performs a right mouse click with tactile duration.
    public func rightClick(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .rightMouseDown, point: point, button: .right, clickState: 1)
        usleep(25_000)
        postMouseEvent(type: .rightMouseUp, point: point, button: .right, clickState: 1)
        DiagnosticsLogger.shared.recordEvent()
    }

    /// Initiates a mouse drag operation.
    public func startDrag(at point: CGPoint) {
        lock.lock()
        isLeftButtonHeld = true
        lock.unlock()

        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .leftMouseDown, point: point, button: .left, clickState: 1)
        DiagnosticsLogger.shared.recordEvent()
    }

    /// Continues moving a dragged item across the desktop.
    public func updateDrag(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .leftMouseDragged, point: point, button: .left, clickState: 1)
        DiagnosticsLogger.shared.recordEvent()
    }

    /// Completes and releases a mouse drag operation.
    public func endDrag(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        postMouseEvent(type: .leftMouseUp, point: point, button: .left, clickState: 1)
        lock.lock()
        isLeftButtonHeld = false
        lock.unlock()

        DiagnosticsLogger.shared.recordEvent()
    }

    /// Immediate safety release of any held mouse buttons on tracking interruption or pause.
    public func safetyReleaseHeldButtons() {
        lock.lock()
        let releaseLeft = isLeftButtonHeld
        let releaseRight = isRightButtonHeld
        isLeftButtonHeld = false
        isRightButtonHeld = false
        lock.unlock()

        let currentPos = NSEvent.mouseLocation
        if releaseLeft {
            postMouseEvent(type: .leftMouseUp, point: currentPos, button: .left, clickState: 1)
        }
        if releaseRight {
            postMouseEvent(type: .rightMouseUp, point: currentPos, button: .right, clickState: 1)
        }
    }

    private func postMouseEvent(
        type: CGEventType,
        point: CGPoint,
        button: CGMouseButton,
        clickState: Int64
    ) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }

        event.setIntegerValueField(.mouseEventClickState, value: clickState)
        event.post(tap: .cgSessionEventTap)
        event.post(tap: .cghidEventTap)
    }
}
