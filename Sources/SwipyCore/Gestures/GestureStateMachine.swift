import Foundation
import CoreGraphics

/// Evaluates hand skeletons across time to produce deterministic gesture events.
public final class GestureStateMachine: @unchecked Sendable {
    private enum InternalState {
        case idle
        case pointing
        case pinching(startTime: TimeInterval, startPoint: CGPoint, isDragging: Bool)
        case scrolling(lastPoint: CGPoint)
    }

    private var currentState: InternalState = .idle
    private var lastClickTimestamp: TimeInterval = 0
    private let history: GestureHistory
    private let resolver: GestureConflictResolver
    private let lock = NSLock()

    public init(history: GestureHistory, resolver: GestureConflictResolver) {
        self.history = history
        self.resolver = resolver
    }

    /// Evaluates a hand skeleton observation and advances the state machine.
    public func process(
        skeleton: HandSkeleton?,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        lock.lock()
        defer { lock.unlock() }

        guard let skeleton = skeleton,
              let indexTip = skeleton[.indexTip],
              skeleton[.wrist] != nil else {
            return handleTrackingLost()
        }

        history.add(skeleton: skeleton, timestamp: timestamp)
        let indexPt = CGPoint(x: indexTip.x, y: indexTip.y)

        // 1. Check for multi-finger directional swipes
        if let swipeState = evaluateSwipe(skeleton: skeleton, settings: settings, timestamp: timestamp) {
            return swipeState
        }

        // 2. Check for two-finger scrolling
        if let scrollState = evaluateScroll(skeleton: skeleton, currentPt: indexPt) {
            return scrollState
        }

        // 3. Check for thumb-middle pinch (Right Click)
        if let rightClick = evaluateRightClick(skeleton: skeleton, settings: settings) {
            return rightClick
        }

        // 4. Check for thumb-index pinch (Click & Drag)
        return evaluatePinchAndPoint(skeleton: skeleton, indexPt: indexPt, settings: settings, timestamp: timestamp)
    }

    private func evaluateSwipe(
        skeleton: HandSkeleton,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState? {
        let isIndex = skeleton.isFingerExtended(.index)
        let isMiddle = skeleton.isFingerExtended(.middle)
        let isRing = skeleton.isFingerExtended(.ring)
        let isLittle = skeleton.isFingerExtended(.little)

        guard isIndex && isMiddle && isRing else { return nil }
        let fingerCount = isLittle ? 4 : 3

        guard let vel = history.velocity(for: .wrist, windowSeconds: 0.18) else { return nil }
        let speed = (vel.dx * vel.dx + vel.dy * vel.dy).squareRoot()

        guard speed >= settings.swipeVelocityThreshold,
              resolver.canExecuteSwipe(timestamp: timestamp, cooldownMs: settings.swipeCooldownMs) else {
            return nil
        }

        let direction: SwipeDirection
        if abs(vel.dx) > abs(vel.dy) {
            direction = vel.dx > 0 ? .right : .left
        } else {
            direction = vel.dy > 0 ? .up : .down
        }

        return .swiping(direction: direction, fingers: fingerCount)
    }

    private func evaluateScroll(skeleton: HandSkeleton, currentPt: CGPoint) -> RecognizedGestureState? {
        let isIndex = skeleton.isFingerExtended(.index)
        let isMiddle = skeleton.isFingerExtended(.middle)
        let isRing = skeleton.isFingerExtended(.ring)
        let isLittle = skeleton.isFingerExtended(.little)

        // Two fingers extended, other two curled
        guard isIndex && isMiddle && !isRing && !isLittle else {
            if case .scrolling = currentState {
                currentState = .idle
            }
            return nil
        }

        switch currentState {
        case .scrolling(let lastPt):
            let dy = Double(currentPt.y - lastPt.y)
            let dx = Double(currentPt.x - lastPt.x)
            currentState = .scrolling(lastPoint: currentPt)
            return .scrolling(deltaY: dy, deltaX: dx)
        default:
            currentState = .scrolling(lastPoint: currentPt)
            return .scrolling(deltaY: 0.0, deltaX: 0.0)
        }
    }

    private func evaluateRightClick(skeleton: HandSkeleton, settings: SwipySettings) -> RecognizedGestureState? {
        guard let dist = skeleton.distance(between: .thumbTip, and: .middleTip),
              dist < settings.pinchThreshold,
              !skeleton.isFingerExtended(.middle) else {
            return nil
        }
        let indexPt = skeleton[.indexTip].map { CGPoint(x: $0.x, y: $0.y) } ?? .zero
        return .rightClicked(screenPoint: indexPt)
    }

    private func evaluatePinchAndPoint(
        skeleton: HandSkeleton,
        indexPt: CGPoint,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        let pinchDist = skeleton.distance(between: .thumbTip, and: .indexTip) ?? 1.0
        let isPinched = resolver.resolvePinch(distance: pinchDist, baseThreshold: settings.pinchThreshold)

        if isPinched {
            return handlePinchActive(indexPt: indexPt, settings: settings, timestamp: timestamp)
        } else {
            return handlePinchInactive(indexPt: indexPt, settings: settings, timestamp: timestamp)
        }
    }

    private func handlePinchActive(
        indexPt: CGPoint,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        switch currentState {
        case .pinching(let startTime, let startPt, let isDragging):
            let elapsedMs = Int((timestamp - startTime) * 1000.0)
            let dx = indexPt.x - startPt.x
            let dy = indexPt.y - startPt.y
            let dist = (dx * dx + dy * dy).squareRoot()

            if isDragging || (elapsedMs > settings.dragDelayMs && dist > 0.015) {
                currentState = .pinching(startTime: startTime, startPoint: startPt, isDragging: true)
                return .dragging(screenPoint: indexPt)
            } else {
                return .pinchPending(normalizedPoint: indexPt, duration: timestamp - startTime)
            }
        default:
            currentState = .pinching(startTime: timestamp, startPoint: indexPt, isDragging: false)
            return .pinchPending(normalizedPoint: indexPt, duration: 0.0)
        }
    }

    private func handlePinchInactive(
        indexPt: CGPoint,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        switch currentState {
        case .pinching(let startTime, _, let isDragging):
            currentState = .pointing
            let durationMs = Int((timestamp - startTime) * 1000.0)

            if isDragging {
                // Drag ended; released without triggering click
                return .pointing(normalizedPoint: indexPt)
            } else if durationMs < settings.dragDelayMs {
                let doubleClickLimit = Double(settings.doubleClickWindowMs) / 1000.0
                if timestamp - lastClickTimestamp <= doubleClickLimit {
                    lastClickTimestamp = 0
                    return .doubleClicked(screenPoint: indexPt)
                } else {
                    lastClickTimestamp = timestamp
                    return .leftClicked(screenPoint: indexPt)
                }
            }
            return .pointing(normalizedPoint: indexPt)

        default:
            currentState = .pointing
            return .pointing(normalizedPoint: indexPt)
        }
    }

    private func handleTrackingLost() -> RecognizedGestureState {
        currentState = .idle
        history.clear()
        resolver.reset()
        return .idle
    }
}
