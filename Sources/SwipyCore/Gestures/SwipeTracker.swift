import Foundation
import CoreGraphics

extension ExtendedFingerState {
    /// Number of extended non-thumb fingers represented by this pose.
    public var fingerCount: Int {
        switch self {
        case .zeroFingers: return 0
        case .oneFinger: return 1
        case .twoFingers: return 2
        case .threeFingers: return 3
        case .fourFingers: return 4
        }
    }
}

/// Detects deliberate multi-finger flicks (Spaces / Mission Control) while tolerating motion blur.
///
/// A flick is accepted only when an open palm was *recently* seen (so a blurred frame that Vision misclassifies
/// as a fist or two fingers does not cancel the swipe), the palm travelled far and fast enough, the motion is
/// clearly axis-aligned, and it is not the natural return stroke of the previous swipe.
final class SwipeTracker {
    struct Result {
        let direction: SwipeDirection
        let fingers: Int
        let distance: Double
        let speed: Double
    }

    /// How long after the last open-palm frame a blurred pose still counts as part of the same flick.
    static let graceSeconds: TimeInterval = 0.25
    /// Open palm must be held this long before a flick can fire, so a hand entering the frame never triggers.
    static let armSeconds: TimeInterval = 0.10
    static let windowSeconds: TimeInterval = 0.15
    static let minDistance: Double = 0.07
    static let axisDominance: Double = 1.5
    static let returnStrokeSeconds: TimeInterval = 0.30

    private var openSince: TimeInterval?
    private var lastOpen: TimeInterval = -.infinity
    private var recentFingerPeak = 0
    private var peakTimestamp: TimeInterval = -.infinity
    private var lastFired: (direction: SwipeDirection, time: TimeInterval)?

    func reset() {
        openSince = nil
        lastOpen = -.infinity
        recentFingerPeak = 0
        peakTimestamp = -.infinity
        lastFired = nil
    }

    /// Re-arms the tracker immediately following an accepted swipe, preventing stroke contamination.
    func didFireSwipe(direction: SwipeDirection, timestamp: TimeInterval) {
        lastFired = (direction, timestamp)
        openSince = timestamp
    }

    /// Updates the open-palm latch from this frame's pose. Call once per frame.
    func observe(pose: ExtendedFingerState, timestamp: TimeInterval) {
        let count = pose.fingerCount
        if count >= 3 {
            if openSince == nil || timestamp - lastOpen > Self.graceSeconds { openSince = timestamp }
            lastOpen = timestamp
            if count >= recentFingerPeak || timestamp - peakTimestamp > Self.graceSeconds {
                recentFingerPeak = count
                peakTimestamp = timestamp
            }
        } else if timestamp - lastOpen > Self.graceSeconds {
            openSince = nil
            recentFingerPeak = 0
        }
    }

    /// True while an armed open palm is current or was seen within the grace window.
    func isFlickCandidate(timestamp: TimeInterval) -> Bool {
        guard let since = openSince else { return false }
        return timestamp - lastOpen <= Self.graceSeconds && lastOpen - since >= Self.armSeconds
    }

    /// Instantaneous palm speed (frame-widths per second) over a short window.
    func palmSpeed(skeleton: HandSkeleton, history: GestureHistory) -> Double {
        let joint: HandJointName = skeleton[.middleMCP] != nil ? .middleMCP : .wrist
        guard let vel = history.velocity(for: joint, windowSeconds: 0.15) else { return 0 }
        return (vel.dx * vel.dx + vel.dy * vel.dy).squareRoot()
    }

    func evaluate(
        skeleton: HandSkeleton,
        history: GestureHistory,
        settings: SwipySettings,
        timestamp: TimeInterval,
        resolver: GestureConflictResolver
    ) -> Result? {
        let joint: HandJointName = skeleton[.middleMCP] != nil ? .middleMCP : .wrist
        guard let disp = history.displacement(for: joint, windowSeconds: Self.windowSeconds),
              let vel = history.velocity(for: joint, windowSeconds: Self.windowSeconds) else { return nil }

        let distance = (disp.dx * disp.dx + disp.dy * disp.dy).squareRoot()
        let speed = (vel.dx * vel.dx + vel.dy * vel.dy).squareRoot()
        guard distance >= Self.minDistance else { return nil }

        let threshold = max(0.35, settings.swipeVelocityThreshold)
        guard speed >= threshold else {
            DebugLog.log(String(format: "swipe-reject slow dist=%.3f speed=%.2f need=%.2f", distance, speed, threshold))
            return nil
        }

        // Selfie camera: sensor +x is the user's left, so mirror horizontally.
        let vx = -vel.dx
        let vy = vel.dy
        let direction: SwipeDirection
        if abs(vx) >= abs(vy) * Self.axisDominance {
            direction = vx > 0 ? .right : .left
        } else if abs(vy) >= abs(vx) * Self.axisDominance {
            direction = vy > 0 ? .up : .down
        } else {
            DebugLog.log(String(format: "swipe-reject diagonal vx=%.2f vy=%.2f", vx, vy))
            return nil
        }

        if let last = lastFired,
           timestamp - last.time < Self.returnStrokeSeconds,
           Self.isOpposite(last.direction, direction) {
            DebugLog.log("swipe-reject return-stroke \(direction.rawValue)")
            return nil
        }

        guard resolver.canExecuteSwipe(timestamp: timestamp, cooldownMs: settings.swipeCooldownMs) else {
            DebugLog.log("swipe-reject cooldown")
            return nil
        }

        lastFired = (direction, timestamp)
        let fingers = recentFingerPeak >= 4 ? 4 : 3
        DebugLog.log(String(format: "swipe-accept %@ fingers=%d dist=%.3f speed=%.2f", direction.rawValue, fingers, distance, speed))
        return Result(direction: direction, fingers: fingers, distance: distance, speed: speed)
    }

    private static func isOpposite(_ a: SwipeDirection, _ b: SwipeDirection) -> Bool {
        switch (a, b) {
        case (.left, .right), (.right, .left), (.up, .down), (.down, .up): return true
        default: return false
        }
    }
}
