import Foundation
import CoreGraphics

/// Low-pass filter component for the One Euro filter.
private struct LowPassFilter: Sendable {
    var hatXPrev: Double?

    mutating func filter(_ x: Double, alpha: Double) -> Double {
        let result: Double
        if let prev = hatXPrev {
            result = alpha * x + (1.0 - alpha) * prev
        } else {
            result = x
        }
        hatXPrev = result
        return result
    }

    mutating func reset() {
        hatXPrev = nil
    }
}

/// One Euro adaptive filter reducing hand jitter while maintaining low-latency response.
public final class MotionSmoother: @unchecked Sendable {
    public var minCutoff: Double
    public var beta: Double
    public var dCutoff: Double

    private var xFilter = LowPassFilter()
    private var dxFilter = LowPassFilter()
    private var yFilter = LowPassFilter()
    private var dyFilter = LowPassFilter()
    private var lastTimestamp: TimeInterval?

    public init(minCutoff: Double = 1.0, beta: Double = 0.007, dCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }

    /// Smooths a 2D point based on timestamp delta.
    public func filter(point: CGPoint, timestamp: TimeInterval) -> CGPoint {
        guard let prevTime = lastTimestamp else {
            lastTimestamp = timestamp
            _ = xFilter.filter(Double(point.x), alpha: 1.0)
            _ = yFilter.filter(Double(point.y), alpha: 1.0)
            return point
        }

        let dt = max(0.001, timestamp - prevTime)
        lastTimestamp = timestamp

        let smoothX = filterChannel(
            val: Double(point.x),
            filter: &xFilter,
            dFilter: &dxFilter,
            dt: dt
        )
        let smoothY = filterChannel(
            val: Double(point.y),
            filter: &yFilter,
            dFilter: &dyFilter,
            dt: dt
        )

        return CGPoint(x: smoothX, y: smoothY)
    }

    private func filterChannel(
        val: Double,
        filter: inout LowPassFilter,
        dFilter: inout LowPassFilter,
        dt: Double
    ) -> Double {
        let prevVal = filter.hatXPrev ?? val
        let dx = (val - prevVal) / dt
        let edx = dFilter.filter(dx, alpha: alpha(cutoff: dCutoff, dt: dt))
        let cutoff = minCutoff + beta * abs(edx)
        return filter.filter(val, alpha: alpha(cutoff: cutoff, dt: dt))
    }

    private func alpha(cutoff: Double, dt: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * cutoff)
        let te = dt
        return 1.0 / (1.0 + tau / te)
    }

    /// Resets filter history on tracking interruptions.
    public func reset() {
        xFilter.reset()
        dxFilter.reset()
        yFilter.reset()
        dyFilter.reset()
        lastTimestamp = nil
    }
}
