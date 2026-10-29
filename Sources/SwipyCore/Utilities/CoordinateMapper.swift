import Foundation
import CoreGraphics

/// Maps normalized camera coordinate spaces into macOS screen coordinate space with front-facing webcam mirroring.
public struct CoordinateMapper: Sendable {
    public var activeRegion: CGRect
    public var deadZoneRadius: Double
    public var overscanMargin: Double

    public init(
        activeRegion: CGRect = CGRect(x: 0.15, y: 0.15, width: 0.70, height: 0.70),
        deadZoneRadius: Double = 0.003,
        overscanMargin: Double = 0.04
    ) {
        self.activeRegion = activeRegion
        self.deadZoneRadius = deadZoneRadius
        self.overscanMargin = overscanMargin
    }

    /// Maps normalized Vision coordinates (0..1, origin bottom-left) to a target screen frame.
    /// - Parameters:
    ///   - normalizedPoint: Hand coordinate from Apple Vision framework (0..1).
    ///   - previousPoint: Previous screen point for micro-deadzone stability.
    ///   - screenFrame: Target display bounds in Core Graphics points.
    ///   - sensitivity: Movement amplification factor around screen center (default: 1.0).
    public func mapToScreen(
        normalizedPoint: CGPoint,
        previousPoint: CGPoint?,
        screenFrame: CGRect,
        sensitivity: Double = 1.0
    ) -> CGPoint {
        // Mirror X for selfie webcam so hand moving to user's right moves cursor right.
        // Invert Y because Vision uses bottom-left origin while screen uses top-left origin.
        let visionX = 1.0 - Double(normalizedPoint.x)
        let visionY = 1.0 - Double(normalizedPoint.y)

        // Sub-region clamping & expansion
        let regionMinX = Double(activeRegion.origin.x)
        let regionMinY = Double(activeRegion.origin.y)
        let regionWidth = max(0.01, Double(activeRegion.size.width))
        let regionHeight = max(0.01, Double(activeRegion.size.height))

        let rawU = (visionX - regionMinX) / regionWidth
        let rawV = (visionY - regionMinY) / regionHeight

        // Apply center-scaled sensitivity expansion
        var scaledU = (rawU - 0.5) * sensitivity + 0.5
        var scaledV = (rawV - 0.5) * sensitivity + 0.5

        // Apply edge overscan to guarantee corners & dock are easily reachable
        scaledU = (scaledU - 0.5) * (1.0 + overscanMargin * 2.0) + 0.5
        scaledV = (scaledV - 0.5) * (1.0 + overscanMargin * 2.0) + 0.5

        let u = max(0.0, min(1.0, scaledU))
        let v = max(0.0, min(1.0, scaledV))

        let targetX = Double(screenFrame.origin.x) + u * Double(screenFrame.size.width)
        let targetY = Double(screenFrame.origin.y) + v * Double(screenFrame.size.height)
        let rawScreenPoint = CGPoint(x: targetX, y: targetY)

        // Dead zone filter
        if let prev = previousPoint {
            let dx = Double(rawScreenPoint.x - prev.x)
            let dy = Double(rawScreenPoint.y - prev.y)
            let distance = (dx * dx + dy * dy).squareRoot()
            let threshold = deadZoneRadius * Double(screenFrame.size.width)
            if distance < threshold {
                return prev
            }
        }

        return rawScreenPoint
    }
}
