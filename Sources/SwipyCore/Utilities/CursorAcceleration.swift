import Foundation
import CoreGraphics

/// Translates raw movement deltas into ergonomic cursor displacements using linear or adaptive power curves.
public struct CursorAcceleration: Sendable {
    public var isAdaptive: Bool
    public var sensitivity: Double

    public init(isAdaptive: Bool = true, sensitivity: Double = 1.15) {
        self.isAdaptive = isAdaptive
        self.sensitivity = sensitivity
    }

    /// Calculates scaled output displacement given movement vector and elapsed time.
    public func accelerate(delta: CGVector, dt: Double) -> CGVector {
        guard dt > 0.0001 else { return delta }

        let rawDistance = (delta.dx * delta.dx + delta.dy * delta.dy).squareRoot()
        let speed = rawDistance / dt

        let multiplier: Double
        if isAdaptive {
            // Adaptive power curve: fine control when slow, swift traversal when fast
            if speed < 0.15 {
                // Precision damping
                multiplier = sensitivity * (0.65 + 0.35 * (speed / 0.15))
            } else if speed < 0.60 {
                // Natural linear range
                let t = (speed - 0.15) / 0.45
                multiplier = sensitivity * (1.0 + 0.5 * t)
            } else {
                // High-velocity boost (caps at 2.4x)
                let boost = min(2.4, 1.5 + (speed - 0.60) * 1.5)
                multiplier = sensitivity * boost
            }
        } else {
            multiplier = sensitivity
        }

        return CGVector(dx: delta.dx * multiplier, dy: delta.dy * multiplier)
    }
}
