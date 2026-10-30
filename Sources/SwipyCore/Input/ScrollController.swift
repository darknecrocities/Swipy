import Foundation
import CoreGraphics

/// Generates vertical and horizontal scroll wheel events on macOS.
public final class ScrollController: @unchecked Sendable {
    public static let shared = ScrollController()

    public init() {}

    /// Dispatches scroll wheel events.
    /// - Parameters:
    ///   - deltaY: Vertical scroll delta (positive = up, negative = down)
    ///   - deltaX: Horizontal scroll delta (positive = right, negative = left)
    ///   - isNatural: Whether natural scrolling direction is enabled
    ///   - speedMultiplier: Multiplier to adjust scroll velocity
    public func scroll(
        deltaY: Double,
        deltaX: Double = 0.0,
        isNatural: Bool = true,
        speedMultiplier: Double = 1.0
    ) {
        let directionFactor: Double = isNatural ? -1.0 : 1.0
        let pixelScrollScale = 1200.0
        let scaledDeltaY = Int32(deltaY * speedMultiplier * directionFactor * pixelScrollScale)
        let scaledDeltaX = Int32(-deltaX * speedMultiplier * directionFactor * pixelScrollScale)

        guard scaledDeltaY != 0 || scaledDeltaX != 0 else { return }

        guard let event = CGEvent(
            scrollWheelEvent2Source: CGEventSource(stateID: .hidSystemState),
            units: .pixel,
            wheelCount: 2,
            wheel1: scaledDeltaY,
            wheel2: scaledDeltaX,
            wheel3: 0
        ) else { return }

        // Continuous scrolling flag is mandatory for Chromium/WebKit smooth scrolling
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.post(tap: .cghidEventTap)
        DiagnosticsLogger.shared.recordEvent()
    }
}
