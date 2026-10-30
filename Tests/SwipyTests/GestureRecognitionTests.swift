import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct GestureRecognitionTests {
    public static func run() {
        testFingerPoseClassification()
        testPointingState()
        testPinchToClick()
        testThumbIndexPinchBentFinger()
        testLongPinchWithoutDragRegistersClick()
        testPinchHeldWithMotionTriggersDrag()
        testFistRejectedAsIdle()
        testTwoFingerScroll()
        testOpenHandWithoutVelocityDoesNotSwipe()
        testFourFingerSwipeLeft()
        testPinchApproachDampingAndStrictLock()
    }

    private static func makeHand(
        indexTip: CGPoint,
        thumbTip: CGPoint,
        wrist: CGPoint = CGPoint(x: 0.5, y: 0.1),
        isMiddleExtended: Bool = false,
        middleTipY: Double? = nil
    ) -> HandSkeleton {
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: wrist.x, y: wrist.y, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: indexTip.x, y: wrist.y + 0.1, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: indexTip.x, y: wrist.y + 0.2, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: indexTip.x, y: indexTip.y, confidence: 1.0)

        joints[.thumbTip] = HandJoint(name: .thumbTip, x: thumbTip.x, y: thumbTip.y, confidence: 1.0)

        let midY = middleTipY ?? (isMiddleExtended ? 0.7 : 0.2)
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.6, y: 0.2, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.6, y: 0.35, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.6, y: midY, confidence: 1.0)

        return HandSkeleton(chirality: .right, joints: joints)
    }

    private static func testFingerPoseClassification() {
        let hand1 = makeHand(indexTip: CGPoint(x: 0.5, y: 0.6), thumbTip: CGPoint(x: 0.3, y: 0.3), isMiddleExtended: false)
        TestHarness.assertEqual(hand1.fingerPoseState, .oneFinger, "Index only extended is .oneFinger")

        let hand2 = makeHand(indexTip: CGPoint(x: 0.5, y: 0.6), thumbTip: CGPoint(x: 0.3, y: 0.3), isMiddleExtended: true)
        TestHarness.assertEqual(hand2.fingerPoseState, .twoFingers, "Index and middle extended is .twoFingers")
    }

    private static func testPointingState() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        let hand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.6), thumbTip: CGPoint(x: 0.3, y: 0.3))
        let state = machine.process(skeleton: hand, settings: settings, timestamp: 1.0)

        if case .pointing(let pt) = state {
            TestHarness.assertEqual(pt.x, 0.5, accuracy: 0.001, "Pointing X coordinate")
            TestHarness.assertEqual(pt.y, 0.6, accuracy: 0.001, "Pointing Y coordinate")
        } else {
            TestHarness.fail("Expected pointing state, got \(state)")
        }
    }

    private static func testPinchToClick() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.32, dragDelayMs: 250)

        let pinchedHand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.5), thumbTip: CGPoint(x: 0.51, y: 0.5))
        let state1 = machine.process(skeleton: pinchedHand, settings: settings, timestamp: 1.0)
        TestHarness.assertTrue(isPinchPending(state1), "Frame 1 pinch pending")

        let state2 = machine.process(skeleton: pinchedHand, settings: settings, timestamp: 1.1)
        TestHarness.assertTrue(isPinchPending(state2), "Frame 2 pinch pending")

        let releasedHand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.5), thumbTip: CGPoint(x: 0.4, y: 0.3))
        let state3 = machine.process(skeleton: releasedHand, settings: settings, timestamp: 1.15)

        if case .leftClicked(let pt) = state3 {
            TestHarness.assertEqual(pt.x, 0.5, accuracy: 0.001, "Short pinch release anchored left click X")
        } else {
            TestHarness.fail("Expected .leftClicked on short pinch release, got \(state3)")
        }
    }

    private static func testThumbIndexPinchBentFinger() {
        // Create hand where index finger is curled/bent at PIP/DIP to contact thumb tip
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.55, y: 0.25, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.55, y: 0.22, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.55, y: 0.18, confidence: 1.0)

        joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.60, y: 0.23, confidence: 1.0)
        joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.60, y: 0.20, confidence: 1.0)
        joints[.ringTip] = HandJoint(name: .ringTip, x: 0.60, y: 0.16, confidence: 1.0)

        // Index finger curled down to meet thumb: tip is lower than PIP
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.48, y: 0.25, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.48, y: 0.32, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.45, y: 0.26, confidence: 1.0)

        // Thumb tip right at index tip
        joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.452, y: 0.262, confidence: 1.0)

        let bentPinchHand = HandSkeleton(chirality: .right, joints: joints)
        TestHarness.assertTrue(bentPinchHand.isThumbIndexPinching, "isThumbIndexPinching is true even with bent index")
        TestHarness.assertEqual(bentPinchHand.fingerPoseState, .oneFinger, "Bent index pinch retains .oneFinger pose")

        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.32)

        let s1 = machine.process(skeleton: bentPinchHand, settings: settings, timestamp: 1.0)
        TestHarness.assertTrue(isPinchPending(s1), "Bent index pinch produces .pinchPending")

        // Release fingers
        var releaseJoints = joints
        releaseJoints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.35, y: 0.20, confidence: 1.0)
        releaseJoints[.indexTip] = HandJoint(name: .indexTip, x: 0.48, y: 0.45, confidence: 1.0)
        let releasedHand = HandSkeleton(chirality: .right, joints: releaseJoints)

        let s2 = machine.process(skeleton: releasedHand, settings: settings, timestamp: 1.1)
        if case .leftClicked = s2 {
            TestHarness.assertTrue(true, "Bent index pinch release fires .leftClicked")
        } else {
            TestHarness.fail("Expected .leftClicked on bent index pinch release, got \(s2)")
        }
    }

    private static func testLongPinchWithoutDragRegistersClick() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.32, dragDelayMs: 250)

        let pinchedHand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.5), thumbTip: CGPoint(x: 0.51, y: 0.5))
        _ = machine.process(skeleton: pinchedHand, settings: settings, timestamp: 1.0)

        // Held for 400ms without dragging (dist = 0)
        _ = machine.process(skeleton: pinchedHand, settings: settings, timestamp: 1.40)

        let releasedHand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.5), thumbTip: CGPoint(x: 0.4, y: 0.3))
        let releaseState = machine.process(skeleton: releasedHand, settings: settings, timestamp: 1.45)

        if case .leftClicked(let pt) = releaseState {
            TestHarness.assertEqual(pt.x, 0.5, accuracy: 0.001, "Long pinch release executes left click without drop")
        } else {
            TestHarness.fail("Expected .leftClicked on long pinch release without drag, got \(releaseState)")
        }
    }

    private static func testFistRejectedAsIdle() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        // Hand where all fingertips are curled towards wrist
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.5, y: 0.2, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.5, y: 0.25, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.5, y: 0.15, confidence: 1.0) // curled below PIP

        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.6, y: 0.2, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.6, y: 0.25, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.6, y: 0.15, confidence: 1.0)

        joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.45, y: 0.2, confidence: 1.0)

        let fist = HandSkeleton(chirality: .right, joints: joints)
        let state = machine.process(skeleton: fist, settings: settings, timestamp: 1.0)

        if case .idle = state {
            TestHarness.assertTrue(true, "Fist posture recognized as .idle")
        } else {
            TestHarness.fail("Expected .idle for fist posture, got \(state)")
        }
    }

    private static func testTwoFingerScroll() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        let scrollHand1 = makeHand(indexTip: CGPoint(x: 0.5, y: 0.6), thumbTip: CGPoint(x: 0.3, y: 0.3), isMiddleExtended: true, middleTipY: 0.6)
        _ = machine.process(skeleton: scrollHand1, settings: settings, timestamp: 1.0)

        let scrollHand2 = makeHand(indexTip: CGPoint(x: 0.5, y: 0.65), thumbTip: CGPoint(x: 0.3, y: 0.3), isMiddleExtended: true, middleTipY: 0.65)
        let s2 = machine.process(skeleton: scrollHand2, settings: settings, timestamp: 1.05)

        if case .scrolling(let dy, _) = s2 {
            TestHarness.assertEqual(dy, 0.05, accuracy: 0.001, "Two finger scroll delta Y")
        } else {
            TestHarness.fail("Expected .scrolling state, got \(s2)")
        }
    }

    private static func testPinchHeldWithMotionTriggersDrag() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.32, dragDelayMs: 200)

        let initialHand = makeHand(indexTip: CGPoint(x: 0.5, y: 0.5), thumbTip: CGPoint(x: 0.51, y: 0.5))
        _ = machine.process(skeleton: initialHand, settings: settings, timestamp: 1.0)

        let movedHand = makeHand(indexTip: CGPoint(x: 0.58, y: 0.58), thumbTip: CGPoint(x: 0.59, y: 0.58))
        let state = machine.process(skeleton: movedHand, settings: settings, timestamp: 1.35)

        if case .dragging(let pt) = state {
            TestHarness.assertEqual(pt.x, 0.58, accuracy: 0.01, "Drag coordinate X tracking")
        } else {
            TestHarness.fail("Expected .dragging state, got \(state)")
        }
    }

    private static func testOpenHandWithoutVelocityDoesNotSwipe() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.2, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45, y: 0.4, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45, y: 0.6, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.45, y: 0.8, confidence: 1.0)

        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.5, y: 0.4, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.5, y: 0.6, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.5, y: 0.85, confidence: 1.0)

        joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.55, y: 0.4, confidence: 1.0)
        joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.55, y: 0.6, confidence: 1.0)
        joints[.ringTip] = HandJoint(name: .ringTip, x: 0.55, y: 0.8, confidence: 1.0)

        joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.6, y: 0.4, confidence: 1.0)
        joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.6, y: 0.55, confidence: 1.0)
        joints[.littleTip] = HandJoint(name: .littleTip, x: 0.6, y: 0.7, confidence: 1.0)

        joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.35, y: 0.4, confidence: 1.0)

        let openHand = HandSkeleton(chirality: .right, joints: joints)

        let s1 = machine.process(skeleton: openHand, settings: settings, timestamp: 1.0)
        let s2 = machine.process(skeleton: openHand, settings: settings, timestamp: 1.1)

        TestHarness.assertTrue(!isSwiping(s1), "Open hand frame 1 does not swipe")
        TestHarness.assertTrue(!isSwiping(s2), "Open hand frame 2 does not swipe")
    }

    private static func testFourFingerSwipeLeft() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(swipeVelocityThreshold: 0.60)

        func makeOpenHand(centerX: Double) -> HandSkeleton {
            var joints: [HandJointName: HandJoint] = [:]
            joints[.wrist] = HandJoint(name: .wrist, x: centerX, y: 0.2, confidence: 1.0)
            joints[.indexMCP] = HandJoint(name: .indexMCP, x: centerX - 0.05, y: 0.4, confidence: 1.0)
            joints[.indexPIP] = HandJoint(name: .indexPIP, x: centerX - 0.05, y: 0.6, confidence: 1.0)
            joints[.indexTip] = HandJoint(name: .indexTip, x: centerX - 0.05, y: 0.8, confidence: 1.0)

            joints[.middleMCP] = HandJoint(name: .middleMCP, x: centerX, y: 0.4, confidence: 1.0)
            joints[.middlePIP] = HandJoint(name: .middlePIP, x: centerX, y: 0.6, confidence: 1.0)
            joints[.middleTip] = HandJoint(name: .middleTip, x: centerX, y: 0.85, confidence: 1.0)

            joints[.ringMCP] = HandJoint(name: .ringMCP, x: centerX + 0.05, y: 0.4, confidence: 1.0)
            joints[.ringPIP] = HandJoint(name: .ringPIP, x: centerX + 0.05, y: 0.6, confidence: 1.0)
            joints[.ringTip] = HandJoint(name: .ringTip, x: centerX + 0.05, y: 0.8, confidence: 1.0)

            joints[.littleMCP] = HandJoint(name: .littleMCP, x: centerX + 0.10, y: 0.4, confidence: 1.0)
            joints[.littlePIP] = HandJoint(name: .littlePIP, x: centerX + 0.10, y: 0.55, confidence: 1.0)
            joints[.littleTip] = HandJoint(name: .littleTip, x: centerX + 0.10, y: 0.7, confidence: 1.0)

            joints[.thumbTip] = HandJoint(name: .thumbTip, x: centerX - 0.15, y: 0.4, confidence: 1.0)
            return HandSkeleton(chirality: .right, joints: joints)
        }

        let hand1 = makeOpenHand(centerX: 0.40)
        _ = machine.process(skeleton: hand1, settings: settings, timestamp: 1.0)

        // Hand moves to the right in sensor coordinates (dx = +0.10 in 0.15s -> velocity = 0.67, swiping left in front of webcam)
        let hand2 = makeOpenHand(centerX: 0.50)
        let s2 = machine.process(skeleton: hand2, settings: settings, timestamp: 1.15)

        if case .swiping(let dir, let fingers) = s2 {
            TestHarness.assertEqual(dir, .left, "Swipe direction is .left")
            TestHarness.assertEqual(fingers, 4, "4-finger swipe detected")
        } else {
            TestHarness.fail("Expected .swiping(.left, 4), got \(s2)")
        }
    }

    private static func testPinchApproachDampingAndStrictLock() {
        let trackpad = TrackpadMotionController()
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let p0 = trackpad.update(normalizedPoint: CGPoint(x: 0.5, y: 0.5), sensitivity: 1.0, screenFrame: screen)

        // Move hand slightly with pinchRatio = 1.0 (normal)
        let pNormal = trackpad.update(normalizedPoint: CGPoint(x: 0.52, y: 0.5), sensitivity: 1.0, screenFrame: screen, isAdaptive: false, pinchRatio: 1.0)
        let travelNormal = abs(pNormal.x - p0.x)

        trackpad.reset()
        _ = trackpad.update(normalizedPoint: CGPoint(x: 0.5, y: 0.5), sensitivity: 1.0, screenFrame: screen)

        // Move hand same distance with pinchRatio = 0.35 (pre-pinch approach)
        let pDamped = trackpad.update(normalizedPoint: CGPoint(x: 0.52, y: 0.5), sensitivity: 1.0, screenFrame: screen, isAdaptive: false, pinchRatio: 0.35)
        let travelDamped = abs(pDamped.x - p0.x)
        TestHarness.assertTrue(travelDamped < travelNormal, "Pre-pinch damping reduces cursor velocity")

        // In pinch contact: isPinching = true -> strict freeze
        let pFrozen = trackpad.update(normalizedPoint: CGPoint(x: 0.54, y: 0.5), sensitivity: 1.0, screenFrame: screen, isAdaptive: false, pinchRatio: 0.20, isPinching: true)
        TestHarness.assertEqual(pFrozen.x, pDamped.x, accuracy: 0.001, "Strict freeze holds cursor position during pinch")
    }

    private static func isPinchPending(_ state: RecognizedGestureState) -> Bool {
        if case .pinchPending = state { return true }
        return false
    }

    private static func isSwiping(_ state: RecognizedGestureState) -> Bool {
        if case .swiping = state { return true }
        return false
    }
}
