import Foundation
import CoreGraphics

/// Evaluates hand skeletons across time to produce deterministic gesture events.
public final class GestureStateMachine: @unchecked Sendable {
    private enum InternalState {
        case idle
        case pointing
        case pinching(startTime: TimeInterval, startPoint: CGPoint, isDragging: Bool)
        case scrolling(lastPoint: CGPoint)
        case zooming(lastRatio: Double, anchorPoint: CGPoint)
    }

    private var currentState: InternalState = .idle
    private var lastClickTimestamp: TimeInterval = 0
    private let history: GestureHistory
    private let resolver: GestureConflictResolver
    private let lock = NSLock()
    private let swipeTracker = SwipeTracker()

    private var isCurrentlyPinching: Bool {
        if case .pinching = currentState {
            return true
        }
        return false
    }

    private var isCurrentlyZooming: Bool {
        if case .zooming = currentState {
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

        let pose = skeleton.fingerPoseState
        swipeTracker.observe(pose: pose, timestamp: timestamp)

        // Multi-finger flicks come first: motion blur can make Vision misread an open palm mid-swipe,
        // so a recent armed open palm plus a fast axis-aligned travel is enough to fire.
        if swipeTracker.isFlickCandidate(timestamp: timestamp) {
            if let flick = swipeTracker.evaluate(
                skeleton: skeleton, history: history, settings: settings,
                timestamp: timestamp, resolver: resolver
            ) {
                currentState = .idle
                swipeTracker.didFireSwipe(direction: flick.direction, timestamp: timestamp)
                history.resetBaseline(at: timestamp)
                return .swiping(direction: flick.direction, fingers: flick.fingers)
            }
            // Blurred mid-flick frame: hold still instead of moving the cursor or scrolling.
            if pose.fingerCount < 3,
               swipeTracker.palmSpeed(skeleton: skeleton, history: history) >= max(0.35, settings.swipeVelocityThreshold) * 0.5 {
                return .idle
            }
        }

        // Prioritize dedicated thumb + index pinch (and pinch release click)
        if skeleton.isThumbIndexPinching || isCurrentlyPinching {
            return evaluatePinchAndPoint(skeleton: skeleton, indexPt: indexPt, settings: settings, timestamp: timestamp)
        }

        // Thumb + Middle finger zoom (pinching in & pinching out, cursor strictly locked)
        // Zoom requires index finger to NOT be extended (index extension always means pointing)
        if (skeleton.isThumbMiddleZooming && !skeleton.isFingerExtended(.index)) || isCurrentlyZooming {
            return evaluateThumbMiddleZoom(skeleton: skeleton, settings: settings, timestamp: timestamp)
        }

        // Deterministic gating based on discrete finger extension count
        switch pose {
        case .zeroFingers:
            // Fist / resting hand: neutralize state and reject accidental gestures
            if isCurrentlyPinching || isCurrentlyZooming {
                currentState = .idle
            }
            return .idle

        case .fourFingers, .threeFingers:
            // Open palm: flicks are handled above; otherwise stay neutral.
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

    private func evaluateThumbMiddleZoom(
        skeleton: HandSkeleton,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> RecognizedGestureState {
        // If index finger is extended, immediately release zoom and hand off to pointing
        if skeleton.isFingerExtended(.index) {
            currentState = .pointing
            let indexPt = skeleton[.indexTip].map { CGPoint(x: $0.x, y: $0.y) } ?? .zero
            return .pointing(normalizedPoint: indexPt)
        }

        let currentRatio = skeleton.middlePinchRatio
        switch currentState {
        case .zooming(let lastRatio, let anchorPt):
            if !skeleton.isThumbMiddleZooming && currentRatio > 0.45 {
                currentState = .idle
                return .idle
            }
            let delta = currentRatio - lastRatio
            if abs(delta) < 0.003 {
                return .zooming(scaleDelta: 0.0, anchorPoint: anchorPt)
            }
            currentState = .zooming(lastRatio: currentRatio, anchorPoint: anchorPt)
            return .zooming(scaleDelta: delta, anchorPoint: anchorPt)

        default:
            let anchor = CursorController.shared.currentQuartzCursorPosition
            currentState = .zooming(lastRatio: currentRatio, anchorPoint: anchor)
            return .zooming(scaleDelta: 0.0, anchorPoint: anchor)
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

            // Transition to drag when moved past threshold (pinch & swipe) or held with motion
            let isDeliberateSwipe = dist > 0.012
            let isSustainedMotion = elapsedMs > 180 && dist > 0.008

            if isDragging || isDeliberateSwipe || isSustainedMotion {
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
        swipeTracker.reset()
        currentState = .idle
        history.clear()
        resolver.reset()
        return .idle
    }
}
