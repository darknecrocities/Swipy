import Foundation
import CoreGraphics

/// Top-level coordinator interpreting hand landmarks and dispatching macOS system input.
public final class GestureRecognizer: @unchecked Sendable {
    public static let shared = GestureRecognizer()

    public let history = GestureHistory()
    public let resolver = GestureConflictResolver()
    public lazy var stateMachine = GestureStateMachine(history: history, resolver: resolver)
    public var coordinateMapper = CoordinateMapper()
    public let smoother = MotionSmoother()
    public let trackpadMotion = TrackpadMotionController()

    private let lock = NSLock()
    private var isDraggingActive = false
    private var isCurrentlyPointing = false
    private var previousScreenPoint: CGPoint?
    private var lastTimestamp: TimeInterval?
    private var _activeState: RecognizedGestureState = .idle

    public var onCursorUpdate: (@Sendable (CGPoint, RecognizedGestureState) -> Void)?

    public var activeState: RecognizedGestureState {
        lock.lock()
        defer { lock.unlock() }
        return _activeState
    }

    public init() {}

    /// Main pipeline processing a hand pose frame into system interaction.
    public func process(
        pose: HandPoseResult,
        settings: SwipySettings,
        displayFrame: CGRect
    ) {
        guard settings.isTrackingEnabled && !settings.isPaused else {
            handleHalt()
            return
        }

        guard let skeleton = pose.primaryHand else {
            handleHalt()
            return
        }

        // Configure coordinate mapper and smoother parameters from settings
        coordinateMapper.activeRegion = CGRect(
            x: settings.activeRegionX,
            y: settings.activeRegionY,
            width: settings.activeRegionWidth,
            height: settings.activeRegionHeight
        )
        coordinateMapper.deadZoneRadius = settings.deadZoneRadius
        smoother.minCutoff = settings.smoothingMinCutoff
        smoother.beta = settings.smoothingBeta

        let gestureState = stateMachine.process(
            skeleton: skeleton,
            settings: settings,
            timestamp: pose.timestamp
        )

        lock.lock()
        _activeState = gestureState
        lock.unlock()

        dispatchGesture(gestureState, skeleton: skeleton, settings: settings, displayFrame: displayFrame, timestamp: pose.timestamp)
    }

    private func dispatchGesture(
        _ state: RecognizedGestureState,
        skeleton: HandSkeleton,
        settings: SwipySettings,
        displayFrame: CGRect,
        timestamp: TimeInterval
    ) {
        switch state {
        case .pointing(let normalizedPt):
            let isStateTransition = !isCurrentlyPointing
            isCurrentlyPointing = true
            if isStateTransition {
                trackpadMotion.resetReference(to: normalizedPt)
            }
            let screenPt = calculateSmoothedPoint(
                normalizedPt: normalizedPt,
                displayFrame: displayFrame,
                settings: settings,
                timestamp: timestamp,
                skeleton: skeleton
            )
            if isDraggingActive {
                MouseEventController.shared.endDrag(at: screenPt)
                isDraggingActive = false
            }
            CursorController.shared.moveCursor(to: screenPt)
            onCursorUpdate?(screenPt, state)

        case .pinchPending:
            isCurrentlyPointing = false
            // Strict cursor freeze on target: DO NOT move cursor while preparing or holding pinch
            let lockedPt = CursorController.shared.currentQuartzCursorPosition
            onCursorUpdate?(lockedPt, state)

        case .dragging(let normalizedPt):
            isCurrentlyPointing = false
            let screenPt = calculateSmoothedPoint(
                normalizedPt: normalizedPt,
                displayFrame: displayFrame,
                settings: settings,
                timestamp: timestamp,
                skeleton: skeleton
            )
            if !isDraggingActive {
                isDraggingActive = true
                MouseEventController.shared.startDrag(at: screenPt)
            } else {
                MouseEventController.shared.updateDrag(at: screenPt)
            }
            onCursorUpdate?(screenPt, state)

        case .leftClicked(let normalizedPt):
            isCurrentlyPointing = false
            let screenPt = settings.trackingMode == .trackpad
                ? CursorController.shared.currentQuartzCursorPosition
                : calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp, skeleton: skeleton)
            MouseEventController.shared.leftClick(at: screenPt)
            trackpadMotion.resetReference(to: normalizedPt)
            onCursorUpdate?(screenPt, state)

        case .doubleClicked(let normalizedPt):
            isCurrentlyPointing = false
            let screenPt = settings.trackingMode == .trackpad
                ? CursorController.shared.currentQuartzCursorPosition
                : calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp, skeleton: skeleton)
            MouseEventController.shared.doubleClick(at: screenPt)
            trackpadMotion.resetReference(to: normalizedPt)
            onCursorUpdate?(screenPt, state)

        case .rightClicked(let normalizedPt):
            isCurrentlyPointing = false
            let screenPt = settings.trackingMode == .trackpad
                ? CursorController.shared.currentQuartzCursorPosition
                : calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp, skeleton: skeleton)
            MouseEventController.shared.rightClick(at: screenPt)
            trackpadMotion.resetReference(to: normalizedPt)
            onCursorUpdate?(screenPt, state)

        case .scrolling(let dy, let dx):
            isCurrentlyPointing = false
            if isDraggingActive {
                MouseEventController.shared.endDrag(at: CursorController.shared.currentQuartzCursorPosition)
                isDraggingActive = false
            }
            ScrollController.shared.scroll(
                deltaY: dy,
                deltaX: dx,
                isNatural: settings.isNaturalScroll,
                speedMultiplier: settings.scrollSpeed
            )
            onCursorUpdate?(CursorController.shared.currentQuartzCursorPosition, state)

        case .swiping(let direction, let fingers):
            isCurrentlyPointing = false
            handleSwipeDispatch(direction: direction, fingers: fingers, settings: settings)

        case .zooming(let scaleDelta, let anchorPoint):
            isCurrentlyPointing = false
            if isDraggingActive {
                MouseEventController.shared.endDrag(at: CursorController.shared.currentQuartzCursorPosition)
                isDraggingActive = false
            }
            ZoomController.shared.zoom(scaleDelta: scaleDelta, at: anchorPoint)
            if let indexTip = skeleton[.indexTip] {
                trackpadMotion.resetReference(to: CGPoint(x: indexTip.x, y: indexTip.y))
            }
            onCursorUpdate?(anchorPoint, state)

        case .idle, .twoHandZooming, .paused:
            isCurrentlyPointing = false
            break
        }
    }

    private func handleSwipeDispatch(direction: SwipeDirection, fingers: Int, settings: SwipySettings) {
        if let action = SystemActionController.swipeAction(direction: direction, fingers: fingers, bindings: settings.bindings) {
            SystemActionController.shared.perform(action)
        } else {
            switch direction {
            case .up:
                SystemActionController.shared.triggerMissionControl()
            case .down:
                SystemActionController.shared.triggerShowDesktop()
            case .left:
                // Swiping hand left pulls the adjacent space from the right (like trackpad)
                SystemActionController.shared.triggerNextSpace()
            case .right:
                // Swiping hand right pulls the adjacent space from the left (like trackpad)
                SystemActionController.shared.triggerPreviousSpace()
            }
        }
    }

    private func calculateSmoothedPoint(
        normalizedPt: CGPoint,
        displayFrame: CGRect,
        settings: SwipySettings,
        timestamp: TimeInterval,
        skeleton: HandSkeleton? = nil
    ) -> CGPoint {
        switch settings.trackingMode {
        case .trackpad:
            let ratio = skeleton?.pinchRatio ?? 1.0
            let isPinching = skeleton?.isThumbIndexPinching ?? false
            let targetPoint = trackpadMotion.update(
                normalizedPoint: normalizedPt,
                sensitivity: settings.cursorSensitivity,
                screenFrame: displayFrame,
                isAdaptive: settings.isAdaptiveAcceleration,
                pinchRatio: ratio,
                isPinching: isPinching
            )
            previousScreenPoint = targetPoint
            lastTimestamp = timestamp
            return targetPoint
        case .directPointer:
            let targetPoint = coordinateMapper.mapToScreen(
                normalizedPoint: normalizedPt,
                previousPoint: previousScreenPoint,
                screenFrame: displayFrame,
                sensitivity: settings.cursorSensitivity
            )
            let smoothed = smoother.filter(point: targetPoint, timestamp: timestamp)
            previousScreenPoint = smoothed
            lastTimestamp = timestamp
            return smoothed
        }
    }

    private func handleHalt() {
        if isDraggingActive {
            isDraggingActive = false
            MouseEventController.shared.safetyReleaseHeldButtons()
        }
        isCurrentlyPointing = false
        smoother.reset()
        trackpadMotion.reset()
        previousScreenPoint = nil
        lastTimestamp = nil
        lock.lock()
        _activeState = .idle
        lock.unlock()
    }
}
