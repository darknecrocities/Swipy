import Foundation
import CoreGraphics

/// Sliding temporal buffer of hand skeletons for velocity and trajectory estimation.
public final class GestureHistory: @unchecked Sendable {
    public struct Sample: Sendable {
        public let skeleton: HandSkeleton
        public let timestamp: TimeInterval
    }

    private var samples: [Sample] = []
    private let maxWindowSeconds: TimeInterval
    private let lock = NSLock()

    public init(maxWindowSeconds: TimeInterval = 0.5) {
        self.maxWindowSeconds = maxWindowSeconds
    }

    /// Appends a new observation and prunes expired historical frames.
    public func add(skeleton: HandSkeleton, timestamp: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }

        samples.append(Sample(skeleton: skeleton, timestamp: timestamp))
        let cutoff = timestamp - maxWindowSeconds
        samples.removeAll(where: { $0.timestamp < cutoff })
    }

    /// Computes displacement vector for a designated joint over the given window.
    public func displacement(
        for joint: HandJointName,
        windowSeconds: TimeInterval = 0.25
    ) -> CGVector? {
        lock.lock()
        defer { lock.unlock() }

        guard samples.count >= 2,
              let latest = samples.last,
              let latestPt = latest.skeleton[joint] else {
            return nil
        }

        let targetTime = latest.timestamp - windowSeconds
        // Find sample closest to targetTime
        guard let baseline = samples.first(where: { $0.timestamp >= targetTime }),
              let basePt = baseline.skeleton[joint] else {
            return nil
        }

        let dx = latestPt.x - basePt.x
        let dy = latestPt.y - basePt.y
        return CGVector(dx: dx, dy: dy)
    }

    /// Computes average velocity vector (units per second) for a designated joint.
    public func velocity(
        for joint: HandJointName,
        windowSeconds: TimeInterval = 0.20
    ) -> CGVector? {
        lock.lock()
        defer { lock.unlock() }

        guard samples.count >= 2,
              let latest = samples.last,
              let latestPt = latest.skeleton[joint] else {
            return nil
        }

        let targetTime = latest.timestamp - windowSeconds
        guard let baseline = samples.first(where: { $0.timestamp >= targetTime }),
              let basePt = baseline.skeleton[joint] else {
            return nil
        }

        let dt = latest.timestamp - baseline.timestamp
        guard dt > 0.01 else { return nil }

        let vx = (latestPt.x - basePt.x) / dt
        let vy = (latestPt.y - basePt.y) / dt
        return CGVector(dx: vx, dy: vy)
    }

    /// Re-anchors baseline to the designated timestamp, clearing pre-swipe trajectory samples
    /// so subsequent chained swipes have an unpolluted baseline.
    public func resetBaseline(at timestamp: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        if let latest = samples.last {
            samples = [latest]
        } else {
            samples.removeAll()
        }
    }

    /// Clears historical data on tracking interruption.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        samples.removeAll()
    }
}
