import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct GestureRecognitionTests {
    public static func run() {
        testPointingState()
        testPinchToClick()
        testPinchHeldWithMotionTriggersDrag()
        testOpenHandWithoutVelocityDoesNotSwipe()
    }

    private static func makeHand(
        indexTip: CGPoint,
        thumbTip: CGPoint,
        wrist: CGPoint = CGPoint(x: 0.5, y: 0.1),
        isMiddleExtended: Bool = false
    ) -> HandSkeleton {
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: wrist.x, y: wrist.y, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: indexTip.x, y: wrist.y + 0.1, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: indexTip.x, y: wrist.y + 0.2, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: indexTip.x, y: indexTip.y, confidence: 1.0)

        joints[.thumbTip] = HandJoint(name: .thumbTip, x: thumbTip.x, y: thumbTip.y, confidence: 1.0)

        let midY = isMiddleExtended ? 0.7 : 0.2
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.6, y: 0.2, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.6, y: 0.35, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.6, y: midY, confidence: 1.0)

        return HandSkeleton(chirality: .right, joints: joints)
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
        let settings = SwipySettings(pinchThreshold: 0.05, dragDelayMs: 250)

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

    private static func testPinchHeldWithMotionTriggersDrag() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.05, dragDelayMs: 200)

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

    private static func isPinchPending(_ state: RecognizedGestureState) -> Bool {
        if case .pinchPending = state { return true }
        return false
    }

    private static func isSwiping(_ state: RecognizedGestureState) -> Bool {
        if case .swiping = state { return true }
        return false
    }
}
