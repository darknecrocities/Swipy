import Foundation
import CoreGraphics

/// Generates smooth continuous zoom/magnification events on macOS centered at target cursor coordinates.
public final class ZoomController: @unchecked Sendable {
    public static let shared = ZoomController()

    public init() {}

    /// Dispatches zoom events targeting the active cursor position.
    /// - Parameters:
    ///   - scaleDelta: Positive = Zoom In (pinch out), Negative = Zoom Out (pinch in)
    ///   - point: Target screen coordinate in Quartz coordinates (defaults to current cursor position)
    ///   - speedMultiplier: User sensitivity adjustment
    public func zoom(
        scaleDelta: Double,
        at point: CGPoint? = nil,
        speedMultiplier: Double = 1.0
    ) {
        let pixelScale = 800.0
        let scaledDelta = Int32(scaleDelta * speedMultiplier * pixelScale)

        guard scaledDelta != 0 else { return }

        let target = point ?? CursorController.shared.currentQuartzCursorPosition

        guard let event = CGEvent(
            scrollWheelEvent2Source: CGEventSource(stateID: .hidSystemState),
            units: .pixel,
            wheelCount: 1,
            wheel1: scaledDelta,
            wheel2: 0,
            wheel3: 0
        ) else { return }

        // Setting location ensures the zoom centers on the target element/window
        event.location = target
        // Control key modifier with continuous flag maps to native trackpad pinch-to-zoom in macOS browsers & viewers
        event.flags = .maskControl
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        event.post(tap: .cghidEventTap)
        DiagnosticsLogger.shared.recordEvent()
    }
}
