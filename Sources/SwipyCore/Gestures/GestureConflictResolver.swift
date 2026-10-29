import Foundation

/// Resolves gesture ambiguities, enforces state hysteresis, and prevents overlapping conflicting actions.
public final class GestureConflictResolver: @unchecked Sendable {
    private let lock = NSLock()
    private var lastSwipeTimestamp: TimeInterval = 0
    private var isPinchLocked = false

    public init() {}

    /// Checks whether a pinch should activate or stay active given hysteresis margins.
    public func resolvePinch(
        distance: Double,
        baseThreshold: Double
    ) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let activateMargin = baseThreshold
        let releaseMargin = baseThreshold * 1.35

        if isPinchLocked {
            if distance > releaseMargin {
                isPinchLocked = false
                return false
            }
            return true
        } else {
            if distance <= activateMargin {
                isPinchLocked = true
                return true
            }
            return false
        }
    }

    /// Determines if a swipe can be executed given the required cooldown.
    public func canExecuteSwipe(timestamp: TimeInterval, cooldownMs: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let cooldownSeconds = Double(cooldownMs) / 1000.0
        if timestamp - lastSwipeTimestamp >= cooldownSeconds {
            lastSwipeTimestamp = timestamp
            return true
        }
        return false
    }

    /// Resets all locks and cooldown timers.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        isPinchLocked = false
        lastSwipeTimestamp = 0
    }
}
