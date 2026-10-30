import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct AdditionalGesturesTests {
    public static func run() {
        testTwoFingerTapFiresSecondaryClick()
        testVictorySignTriggersAppSwitcher()
        testFistHoldTogglesPause()
        testPinchOpeningPreventsAccidentalDrag()
        testTiltedHandExtensionDetection()
    }

    private static func makeHand(
        indexTip: CGPoint,
        middleTip: CGPoint,
        wrist: CGPoint = CGPoint(x: 0.5, y: 0.1),
        thumbTip: CGPoint = CGPoint(x: 0.35, y: 0.25),
        isRingCurled: Bool = true,
        isLittleCurled: Bool = true
    ) -> HandSkeleton {
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: wrist.x, y: wrist.y, confidence: 1.0)
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.55, y: 0.30, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.55, y: 0.45, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: middleTip.x, y: middleTip.y, confidence: 1.0)

        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45, y: 0.30, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45, y: 0.45, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: indexTip.x, y: indexTip.y, confidence: 1.0)

        joints[.thumbTip] = HandJoint(name: .thumbTip, x: thumbTip.x, y: thumbTip.y, confidence: 1.0)

        let ringTipY = isRingCurled ? 0.20 : 0.65
        joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.62, y: 0.28, confidence: 1.0)
        joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.62, y: 0.25, confidence: 1.0)
        joints[.ringTip] = HandJoint(name: .ringTip, x: 0.62, y: ringTipY, confidence: 1.0)

        let littleTipY = isLittleCurled ? 0.18 : 0.60
        joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.68, y: 0.25, confidence: 1.0)
        joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.68, y: 0.22, confidence: 1.0)
        joints[.littleTip] = HandJoint(name: .littleTip, x: 0.68, y: littleTipY, confidence: 1.0)

        return HandSkeleton(chirality: .right, joints: joints)
    }

    private static func testTwoFingerTapFiresSecondaryClick() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        // Index and middle fingertips touching together
        let tapHand = makeHand(
            indexTip: CGPoint(x: 0.49, y: 0.70),
            middleTip: CGPoint(x: 0.51, y: 0.70)
        )
        TestHarness.assertTrue(tapHand.isTwoFingerTapping, "Hand recognized as two-finger tapping")

        let state = machine.process(skeleton: tapHand, settings: settings, timestamp: 1.0)
        if case .rightClicked = state {
            TestHarness.assertTrue(true, "Two-finger tap registered .rightClicked")
        } else {
            TestHarness.fail("Expected .rightClicked on two-finger tap, got \(state)")
        }
    }

    private static func testVictorySignTriggersAppSwitcher() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        // Index and middle fingers extended apart in a distinct 'V'
        let vHand = makeHand(
            indexTip: CGPoint(x: 0.40, y: 0.70),
            middleTip: CGPoint(x: 0.60, y: 0.70)
        )
        TestHarness.assertTrue(vHand.isVictoryPose, "Hand recognized as victory pose")

        _ = machine.process(skeleton: vHand, settings: settings, timestamp: 1.0)
        // Sustained for 280ms
        let state2 = machine.process(skeleton: vHand, settings: settings, timestamp: 1.28)

        if case .actionTriggered(let action) = state2 {
            TestHarness.assertEqual(action, .toggleAppSwitcher, "Victory pose triggers App Switcher action")
        } else {
            TestHarness.fail("Expected .actionTriggered(.toggleAppSwitcher), got \(state2)")
        }
    }

    private static func testFistHoldTogglesPause() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        // Fist: all fingertips curled below their PIPs and MCPs
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45, y: 0.25, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45, y: 0.30, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.45, y: 0.18, confidence: 1.0)

        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.52, y: 0.25, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.52, y: 0.30, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.52, y: 0.18, confidence: 1.0)

        joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.58, y: 0.24, confidence: 1.0)
        joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.58, y: 0.28, confidence: 1.0)
        joints[.ringTip] = HandJoint(name: .ringTip, x: 0.58, y: 0.16, confidence: 1.0)

        joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.64, y: 0.23, confidence: 1.0)
        joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.64, y: 0.26, confidence: 1.0)
        joints[.littleTip] = HandJoint(name: .littleTip, x: 0.64, y: 0.15, confidence: 1.0)

        // Thumb resting across outer knuckles in a natural fist
        joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.55, y: 0.28, confidence: 1.0)

        let fist = HandSkeleton(chirality: .right, joints: joints)
        TestHarness.assertTrue(fist.isFist, "Hand recognized as closed fist")

        _ = machine.process(skeleton: fist, settings: settings, timestamp: 1.0)
        // Held for 650ms
        let s2 = machine.process(skeleton: fist, settings: settings, timestamp: 1.65)

        if case .paused = s2 {
            TestHarness.assertTrue(true, "Sustained closed fist triggered .paused")
        } else {
            TestHarness.fail("Expected .paused after 650ms fist hold, got \(s2)")
        }
    }

    private static func testPinchOpeningPreventsAccidentalDrag() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(pinchThreshold: 0.32, dragDelayMs: 250)

        // 1. Initial tight pinch
        var joints1: [HandJointName: HandJoint] = [:]
        joints1[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
        joints1[.middleMCP] = HandJoint(name: .middleMCP, x: 0.55, y: 0.30, confidence: 1.0)
        joints1[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45, y: 0.30, confidence: 1.0)
        joints1[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45, y: 0.45, confidence: 1.0)
        joints1[.indexTip] = HandJoint(name: .indexTip, x: 0.45, y: 0.50, confidence: 1.0)
        joints1[.thumbTip] = HandJoint(name: .thumbTip, x: 0.455, y: 0.505, confidence: 1.0) // pinched
        let h1 = HandSkeleton(chirality: .right, joints: joints1)

        let s1 = machine.process(skeleton: h1, settings: settings, timestamp: 1.0)
        TestHarness.assertTrue(isPinchPending(s1), "Initial tight pinch is pending")

        // 2. Fingers actively opening (thumb separating from index, slight movement)
        var joints2 = joints1
        joints2[.indexTip] = HandJoint(name: .indexTip, x: 0.46, y: 0.52, confidence: 1.0)
        joints2[.thumbTip] = HandJoint(name: .thumbTip, x: 0.38, y: 0.38, confidence: 1.0) // separated!
        let h2 = HandSkeleton(chirality: .right, joints: joints2)

        let s2 = machine.process(skeleton: h2, settings: settings, timestamp: 1.12)

        // Must register .leftClicked, NOT .dragging
        if case .leftClicked(let pt) = s2 {
            TestHarness.assertEqual(pt.x, 0.45, accuracy: 0.001, "Left click anchored to start point")
        } else {
            TestHarness.fail("Expected .leftClicked on pinch release, got \(s2)")
        }
    }

    private static func testTiltedHandExtensionDetection() {
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45, y: 0.30, confidence: 1.0)
        // Foreshortened camera perspective: PIP is at 0.52, Tip is at 0.51 (slight downward tilt)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45, y: 0.52, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.45, y: 0.51, confidence: 1.0)
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.55, y: 0.30, confidence: 1.0)

        let tiltedHand = HandSkeleton(chirality: .right, joints: joints)
        TestHarness.assertTrue(
            tiltedHand.isFingerExtended(.index),
            "Index finger recognized as extended even under camera foreshortening tilt"
        )
    }

    private static func isPinchPending(_ state: RecognizedGestureState) -> Bool {
        if case .pinchPending = state { return true }
        return false
    }
}
