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
        case .pointing(let normalizedPt), .pinchPending(let normalizedPt, _):
            let screenPt = calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp)
            if isDraggingActive {
                MouseEventController.shared.endDrag(at: screenPt)
                isDraggingActive = false
            }
            CursorController.shared.moveCursor(to: screenPt)
            onCursorUpdate?(screenPt, state)

        case .dragging(let normalizedPt):
            let screenPt = calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp)
            if !isDraggingActive {
                isDraggingActive = true
                MouseEventController.shared.startDrag(at: screenPt)
            } else {
                MouseEventController.shared.updateDrag(at: screenPt)
            }
            onCursorUpdate?(screenPt, state)

        case .leftClicked(let normalizedPt):
            let screenPt = calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp)
            MouseEventController.shared.leftClick(at: screenPt)
            onCursorUpdate?(screenPt, state)

        case .doubleClicked(let normalizedPt):
            let screenPt = calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp)
            MouseEventController.shared.doubleClick(at: screenPt)
            onCursorUpdate?(screenPt, state)

        case .rightClicked(let normalizedPt):
            let screenPt = calculateSmoothedPoint(normalizedPt: normalizedPt, displayFrame: displayFrame, settings: settings, timestamp: timestamp)
            MouseEventController.shared.rightClick(at: screenPt)
            onCursorUpdate?(screenPt, state)

        case .scrolling(let dy, let dx):
            ScrollController.shared.scroll(
                deltaY: dy,
                deltaX: dx,
                isNatural: settings.isNaturalScroll,
                speedMultiplier: settings.scrollSpeed
            )

        case .swiping(let direction, let fingers):
            handleSwipeDispatch(direction: direction, fingers: fingers, settings: settings)

        case .idle, .twoHandZooming, .paused:
            break
        }
    }

    private func handleSwipeDispatch(direction: SwipeDirection, fingers: Int, settings: SwipySettings) {
        if fingers == 4 {
            SystemActionController.shared.triggerApplicationSwitch(native: settings.useNativeAppSwitcher)
            return
        }

        switch direction {
        case .up:
            SystemActionController.shared.triggerMissionControl()
        case .down:
            SystemActionController.shared.triggerShowDesktop()
        case .left:
            SystemActionController.shared.triggerPreviousSpace()
        case .right:
            SystemActionController.shared.triggerNextSpace()
        }
    }

    private func calculateSmoothedPoint(
        normalizedPt: CGPoint,
        displayFrame: CGRect,
        settings: SwipySettings,
        timestamp: TimeInterval
    ) -> CGPoint {
        let targetPoint: CGPoint
        switch settings.trackingMode {
        case .trackpad:
            targetPoint = trackpadMotion.update(
                normalizedPoint: normalizedPt,
                sensitivity: settings.cursorSensitivity,
                screenFrame: displayFrame,
                isAdaptive: settings.isAdaptiveAcceleration
            )
        case .directPointer:
            targetPoint = coordinateMapper.mapToScreen(
                normalizedPoint: normalizedPt,
                previousPoint: previousScreenPoint,
                screenFrame: displayFrame,
                sensitivity: settings.cursorSensitivity
            )
        }

        let smoothed = smoother.filter(point: targetPoint, timestamp: timestamp)
        previousScreenPoint = smoothed
        lastTimestamp = timestamp
        return smoothed
    }

    private func handleHalt() {
        if isDraggingActive {
            isDraggingActive = false
            MouseEventController.shared.safetyReleaseHeldButtons()
        }
        smoother.reset()
        trackpadMotion.reset()
        previousScreenPoint = nil
        lastTimestamp = nil
        lock.lock()
        _activeState = .idle
        lock.unlock()
    }
}
