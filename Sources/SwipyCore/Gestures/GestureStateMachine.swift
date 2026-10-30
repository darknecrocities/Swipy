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

    private var isCurrentlyPinching: Bool {
        if case .pinching = currentState {
            return true
        }
        return false
    }

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

        // Prioritize dedicated thumb + index pinch (and pinch release click)
        if skeleton.isThumbIndexPinching || isCurrentlyPinching {
            return evaluatePinchAndPoint(skeleton: skeleton, indexPt: indexPt, settings: settings, timestamp: timestamp)
        }

        // Deterministic gating based on discrete finger extension count
        switch skeleton.fingerPoseState {
        case .zeroFingers:
            // Fist / resting hand: neutralize state and reject accidental gestures
            if case .pinching = currentState {
                currentState = .idle
            }
            return .idle

        case .fourFingers:
            // Open palm: check for rapid 4-finger application switch swipe
            if let swipe = evaluateSwipe(skeleton: skeleton, settings: settings, timestamp: timestamp, fingerCount: 4) {
                return swipe
            }
            return .idle

        case .threeFingers:
            // 3 fingers: evaluate Spaces navigation and Mission Control flicks
            if let swipe = evaluateSwipe(skeleton: skeleton, settings: settings, timestamp: timestamp, fingerCount: 3) {
                return swipe
            }
            return .idle

        case .twoFingers:
            // 2 fingers: evaluate Right Click or smooth 2-finger scrolling (cursor locked)
            if let rightClick = evaluateRightClick(skeleton: skeleton, settings: settings) {
                return rightClick
            }
            let scrollPt: CGPoint
            if let idxTip = skeleton[.indexTip], let midTip = skeleton[.middleTip] {
                scrollPt = CGPoint(x: (idxTip.x + midTip.x) / 2.0, y: (idxTip.y + midTip.y) / 2.0)
            } else {
                scrollPt = indexPt
            }
            return evaluateScroll(skeleton: skeleton, currentPt: scrollPt)

        case .oneFinger:
            // 1 finger (Index only): precision pointer glide, pinch-to-click, and drag
            return evaluatePinchAndPoint(skeleton: skeleton, indexPt: indexPt, settings: settings, timestamp: timestamp)
        }
    }

    private func evaluateSwipe(
        skeleton: HandSkeleton,
        settings: SwipySettings,
        timestamp: TimeInterval,
        fingerCount: Int
    ) -> RecognizedGestureState? {
        // Require genuine physical displacement across the observation window
        guard let disp = history.displacement(for: .wrist, windowSeconds: 0.20) else { return nil }
        let distance = (disp.dx * disp.dx + disp.dy * disp.dy).squareRoot()
        guard distance >= 0.14 else { return nil }

        guard let vel = history.velocity(for: .wrist, windowSeconds: 0.18) else { return nil }
        let speed = (vel.dx * vel.dx + vel.dy * vel.dy).squareRoot()

        let requiredSpeed = fingerCount == 4 ? max(2.0, settings.swipeVelocityThreshold) : max(1.5, settings.swipeVelocityThreshold)
        guard speed >= requiredSpeed,
              resolver.canExecuteSwipe(timestamp: timestamp, cooldownMs: settings.swipeCooldownMs) else {
            return nil
        }

        // Mirror X velocity to account for selfie camera orientation (dx < 0 is user swiping right)
        let mirroredVx = -vel.dx
        let direction: SwipeDirection
        if abs(mirroredVx) > abs(vel.dy) * 1.3 {
            direction = mirroredVx > 0 ? .right : .left
        } else {
            direction = vel.dy > 0 ? .up : .down
        }

        return .swiping(direction: direction, fingers: fingerCount)
    }

    private func evaluateScroll(skeleton: HandSkeleton, currentPt: CGPoint) -> RecognizedGestureState {
        switch currentState {
        case .scrolling(let lastPt):
            let dy = Double(currentPt.y - lastPt.y)
            let dx = Double(currentPt.x - lastPt.x)
            let dist = (dy * dy + dx * dx).squareRoot()
            if dist < 0.002 {
                return .scrolling(deltaY: 0.0, deltaX: 0.0)
            }
            currentState = .scrolling(lastPoint: currentPt)
            return .scrolling(deltaY: dy, deltaX: dx)
        default:
            currentState = .scrolling(lastPoint: currentPt)
            return .scrolling(deltaY: 0.0, deltaX: 0.0)
        }
    }

    private func evaluateRightClick(skeleton: HandSkeleton, settings: SwipySettings) -> RecognizedGestureState? {
        if skeleton.middlePinchRatio <= settings.pinchThreshold {
            let indexPt = skeleton[.indexTip].map { CGPoint(x: $0.x, y: $0.y) } ?? .zero
            return .rightClicked(screenPoint: indexPt)
        }
        return nil
    }

    private func evaluatePinchAndPoint(
        skeleton: HandSkeleton,
        indexPt: CGPoint,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        // Dedicated thumb-index classifier or scale-invariant ratio with hysteresis
        let isPinched = skeleton.isThumbIndexPinching || resolver.resolvePinch(distance: skeleton.pinchRatio, baseThreshold: settings.pinchThreshold)

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

            // Transition to drag when moved past threshold or held with motion
            if isDragging || (elapsedMs > settings.dragDelayMs && dist > 0.025) {
                currentState = .pinching(startTime: startTime, startPoint: startPt, isDragging: true)
                return .dragging(screenPoint: indexPt)
            } else {
                // Stabilize cursor firmly on target icon during pinch contact
                return .pinchPending(normalizedPoint: startPt, duration: timestamp - startTime)
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
        case .pinching(_, let startPt, let isDragging):
            currentState = .pointing

            if isDragging {
                // Drag ended; released without triggering click
                return .pointing(normalizedPoint: indexPt)
            } else {
                // Guaranteed click on release of any stationary pinch (fixes dropped click bug)
                let doubleClickLimit = Double(settings.doubleClickWindowMs) / 1000.0
                if timestamp - lastClickTimestamp <= doubleClickLimit {
                    lastClickTimestamp = 0
                    return .doubleClicked(screenPoint: startPt)
                } else {
                    lastClickTimestamp = timestamp
                    return .leftClicked(screenPoint: startPt)
                }
            }

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
