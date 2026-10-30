import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct PointerStabilityTests {
    public static func run() {
        testIndexPointingNeverHijackedByCurledMiddleFinger()
        testContinuousPointingWithoutFreezeUnderCameraJitter()
        testFourFingerSwipeLeftAndRightSpaceNavigation()
        testZoomGestureRequiresCurledIndex()
    }

    private static func makePointingHand(indexY: Double = 0.80, jitterX: Double = 0.0) -> HandSkeleton {
        var joints: [HandJointName: HandJoint] = [:]
        joints[.wrist] = HandJoint(name: .wrist, x: 0.5 + jitterX, y: 0.15, confidence: 1.0)
        joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.45 + jitterX, y: 0.35, confidence: 1.0)
        joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.45 + jitterX, y: 0.55, confidence: 1.0)
        joints[.indexTip] = HandJoint(name: .indexTip, x: 0.45 + jitterX, y: indexY, confidence: 1.0)

        // Middle finger naturally curled into palm when pointing
        joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.52 + jitterX, y: 0.35, confidence: 1.0)
        joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.52 + jitterX, y: 0.28, confidence: 1.0)
        joints[.middleTip] = HandJoint(name: .middleTip, x: 0.52 + jitterX, y: 0.22, confidence: 1.0)

        // Thumb resting naturally against curled middle finger
        joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.49 + jitterX, y: 0.25, confidence: 1.0)

        // Ring and little curled into palm
        joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.58 + jitterX, y: 0.30, confidence: 1.0)
        joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.58 + jitterX, y: 0.25, confidence: 1.0)
        joints[.ringTip] = HandJoint(name: .ringTip, x: 0.58 + jitterX, y: 0.20, confidence: 1.0)

        joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.63 + jitterX, y: 0.25, confidence: 1.0)
        joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.63 + jitterX, y: 0.20, confidence: 1.0)
        joints[.littleTip] = HandJoint(name: .littleTip, x: 0.63 + jitterX, y: 0.15, confidence: 1.0)

        return HandSkeleton(chirality: .right, joints: joints)
    }

    private static func testIndexPointingNeverHijackedByCurledMiddleFinger() {
        let hand = makePointingHand()
        TestHarness.assertTrue(!hand.isThumbMiddleZooming, "Index pointing hand is NEVER classified as thumb-middle zoom")
        TestHarness.assertEqual(hand.fingerPoseState, .oneFinger, "Index pointing hand is classified as .oneFinger")

        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        let state = machine.process(skeleton: hand, settings: settings, timestamp: 1.0)
        if case .pointing(let pt) = state {
            TestHarness.assertEqual(Double(pt.y), 0.80, accuracy: 0.01, "Pointing state active with correct index tip")
        } else {
            TestHarness.fail("Expected .pointing state, got \(state)")
        }
    }

    private static func testContinuousPointingWithoutFreezeUnderCameraJitter() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        var frozenCount = 0
        for i in 0..<20 {
            let t = 1.0 + Double(i) * 0.033 // 30 FPS stream
            let jitter = (Double(i % 5) - 2.0) * 0.003
            let hand = makePointingHand(indexY: 0.78 + Double(i) * 0.005, jitterX: jitter)
            let s = machine.process(skeleton: hand, settings: settings, timestamp: t)
            if case .pointing = s {
                // Correct: glide active
            } else {
                frozenCount += 1
            }
        }
        TestHarness.assertEqual(frozenCount, 0, "All 20 frames of pointing glide continuously without freezing")
    }

    private static func testFourFingerSwipeLeftAndRightSpaceNavigation() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings(swipeVelocityThreshold: 0.55)

        func makePalm(centerX: Double) -> HandSkeleton {
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

        // Swipe Left in front of webcam: camera dx = +0.12 in 0.15s (speed = 0.80)
        _ = machine.process(skeleton: makePalm(centerX: 0.35), settings: settings, timestamp: 1.0)
        let sLeft = machine.process(skeleton: makePalm(centerX: 0.47), settings: settings, timestamp: 1.15)
        if case .swiping(let dir, let fingers) = sLeft {
            TestHarness.assertEqual(dir, .left, "Swipe left detected")
            TestHarness.assertEqual(fingers, 4, "4-finger count detected")
            let action = SystemActionController.swipeAction(direction: dir, fingers: fingers, bindings: settings.bindings)
            TestHarness.assertEqual(action, .nextSpace, "Swipe left maps to Next Space action")
        } else {
            TestHarness.fail("Expected 4-finger swipe left, got \(sLeft)")
        }

        // Reset and test Swipe Right
        let machine2 = GestureStateMachine(history: GestureHistory(), resolver: GestureConflictResolver())
        _ = machine2.process(skeleton: makePalm(centerX: 0.55), settings: settings, timestamp: 3.0)
        let sRight = machine2.process(skeleton: makePalm(centerX: 0.43), settings: settings, timestamp: 3.15)
        if case .swiping(let dir, let fingers) = sRight {
            TestHarness.assertEqual(dir, .right, "Swipe right detected")
            TestHarness.assertEqual(fingers, 4, "4-finger count detected")
            let action = SystemActionController.swipeAction(direction: dir, fingers: fingers, bindings: settings.bindings)
            TestHarness.assertEqual(action, .previousSpace, "Swipe right maps to Previous Space action")
        } else {
            TestHarness.fail("Expected 4-finger swipe right, got \(sRight)")
        }
    }

    private static func testZoomGestureRequiresCurledIndex() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        func makeHand(indexExtended: Bool, thumbMiddleContact: Bool) -> HandSkeleton {
            var joints: [HandJointName: HandJoint] = [:]
            joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.15, confidence: 1.0)
            joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.5, y: 0.35, confidence: 1.0)
            joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.5, y: 0.45, confidence: 1.0)
            joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.45, y: 0.45, confidence: 1.0)

            let midX = thumbMiddleContact ? 0.48 : 0.60
            joints[.middleTip] = HandJoint(name: .middleTip, x: midX, y: 0.45, confidence: 1.0)

            joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.35, y: 0.35, confidence: 1.0)
            if indexExtended {
                joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.35, y: 0.55, confidence: 1.0)
                joints[.indexTip] = HandJoint(name: .indexTip, x: 0.35, y: 0.75, confidence: 1.0)
            } else {
                joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.35, y: 0.25, confidence: 1.0)
                joints[.indexTip] = HandJoint(name: .indexTip, x: 0.35, y: 0.20, confidence: 1.0)
            }

            joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.55, y: 0.30, confidence: 1.0)
            joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.55, y: 0.25, confidence: 1.0)
            joints[.ringTip] = HandJoint(name: .ringTip, x: 0.55, y: 0.20, confidence: 1.0)

            joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.60, y: 0.25, confidence: 1.0)
            joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.60, y: 0.20, confidence: 1.0)
            joints[.littleTip] = HandJoint(name: .littleTip, x: 0.60, y: 0.15, confidence: 1.0)

            return HandSkeleton(chirality: .right, joints: joints)
        }

        // Frame 1: Index curled, thumb and middle in contact -> enters zoom
        let h1 = makeHand(indexExtended: false, thumbMiddleContact: true)
        let s1 = machine.process(skeleton: h1, settings: settings, timestamp: 1.0)
        TestHarness.assertTrue(h1.isThumbMiddleZooming, "Thumb-middle zoom true when index curled")
        if case .zooming = s1 {
            TestHarness.assertTrue(true, "Enters zoom state")
        } else {
            TestHarness.fail("Expected .zooming state, got \(s1)")
        }

        // Frame 2: User extends index finger to point -> IMMEDIATELY exits zoom!
        let h2 = makeHand(indexExtended: true, thumbMiddleContact: true)
        let s2 = machine.process(skeleton: h2, settings: settings, timestamp: 1.05)
        TestHarness.assertTrue(!h2.isThumbMiddleZooming, "Zooming immediately false when index is extended")
        if case .pointing = s2 {
            TestHarness.assertTrue(true, "Zoom cleanly hands off to pointing without cursor freeze")
        } else {
            TestHarness.fail("Expected .pointing state upon index extension, got \(s2)")
        }
    }
}
