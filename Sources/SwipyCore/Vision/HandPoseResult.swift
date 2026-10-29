import Foundation

/// Tracking state published to the UI and gesture systems.
public enum TrackingState: String, Codable, Sendable {
    case unavailable = "Camera Unavailable"
    case permissionRequired = "Camera Permission Required"
    case accessibilityRequired = "Accessibility Permission Required"
    case ready = "Camera Ready"
    case noHandDetected = "Looking for Hand"
    case tracking = "Tracking Active"
    case trackingUnstable = "Tracking Unstable"
    case paused = "Paused"
    case error = "Capture Error"
}

/// The multi-hand recognition result for a processed camera frame.
public struct HandPoseResult: Codable, Equatable, Sendable {
    public let primaryHand: HandSkeleton?
    public let secondaryHand: HandSkeleton?
    public let state: TrackingState
    public let timestamp: TimeInterval
    public let inferenceDurationMs: Double
    public let handCount: Int

    public init(
        primaryHand: HandSkeleton?,
        secondaryHand: HandSkeleton? = nil,
        state: TrackingState,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime,
        inferenceDurationMs: Double = 0.0
    ) {
        self.primaryHand = primaryHand
        self.secondaryHand = secondaryHand
        self.state = state
        self.timestamp = timestamp
        self.inferenceDurationMs = inferenceDurationMs
        self.handCount = (primaryHand != nil ? 1 : 0) + (secondaryHand != nil ? 1 : 0)
    }

    /// Empty result when no hands are in view.
    public static func empty(state: TrackingState = .noHandDetected) -> HandPoseResult {
        HandPoseResult(primaryHand: nil, secondaryHand: nil, state: state)
    }
}
