import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct TrackpadMotionTests {
    public static func run() {
        testAnchorInitialization()
        testRelativeDisplacementDirection()
        testDeadZoneSuppression()
        testBoundaryClamping()
        testResetClearsAnchor()
        testTrackpadMotionUnfreezesDuringDrag()
        testPinchAndSwipeDragLifecycle()
        testPinchApproachDampingAndStrictLock()
        testThumbMiddleZoomInOut()
    }

    private static func testAnchorInitialization() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.002)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        // First point should establish reference and return current position without jumping
        let startPoint = CGPoint(x: 0.5, y: 0.5)
        let pos1 = controller.update(
            normalizedPoint: startPoint,
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )

        TestHarness.assertTrue(pos1.x >= 0 && pos1.x <= 1440, "Initial position in bounds")
        TestHarness.assertTrue(pos1.y >= 0 && pos1.y <= 900, "Initial position Y in bounds")
    }

    private static func testRelativeDisplacementDirection() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.001)
        let screen = CGRect(x: 0, y: 0, width: 3000, height: 3000)

        // Anchor at (0.5, 0.5)
        let p0 = controller.update(
            normalizedPoint: CGPoint(x: 0.5, y: 0.5),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )

        // Move hand right (lower camera sensor x: 0.45)
        let pRight = controller.update(
            normalizedPoint: CGPoint(x: 0.45, y: 0.5),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertTrue(pRight.x > p0.x, "Hand right moves cursor right in screen space")

        // Move hand up (higher camera sensor y: 0.55 in Vision coordinates)
        let pUp = controller.update(
            normalizedPoint: CGPoint(x: 0.45, y: 0.55),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertTrue(pUp.y < pRight.y, "Hand up decreases Quartz Y (moves cursor up)")
    }

    private static func testDeadZoneSuppression() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.01)
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        let p0 = controller.update(
            normalizedPoint: CGPoint(x: 0.5, y: 0.5),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )

        // Micro-tremor below dead zone
        let pJitter = controller.update(
            normalizedPoint: CGPoint(x: 0.501, y: 0.501),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertEqual(pJitter.x, p0.x, "Dead zone suppresses micro tremor X")
        TestHarness.assertEqual(pJitter.y, p0.y, "Dead zone suppresses micro tremor Y")
    }

    private static func testBoundaryClamping() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.001)
        let screen = CGRect(x: 0, y: 0, width: 500, height: 500)

        _ = controller.update(
            normalizedPoint: CGPoint(x: 0.5, y: 0.5),
            sensitivity: 10.0,
            screenFrame: screen,
            isAdaptive: false
        )

        // Huge movement beyond screen left
        let farLeft = controller.update(
            normalizedPoint: CGPoint(x: 1.0, y: 0.5),
            sensitivity: 10.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertTrue(farLeft.x >= 0, "Clamped at minX")

        // Huge movement beyond screen bottom
        let farDown = controller.update(
            normalizedPoint: CGPoint(x: 0.5, y: 0.0),
            sensitivity: 10.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertTrue(farDown.y <= 500, "Clamped at maxY")
    }

    private static func testResetClearsAnchor() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.001)
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        _ = controller.update(
            normalizedPoint: CGPoint(x: 0.5, y: 0.5),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )
        controller.reset()

        // After reset, next point re-anchors without jumping
        let reanchor = controller.update(
            normalizedPoint: CGPoint(x: 0.2, y: 0.8),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )
        TestHarness.assertTrue(reanchor.x >= 0 && reanchor.x <= 1000, "Re-anchored in bounds")
    }

    private static func testTrackpadMotionUnfreezesDuringDrag() {
        let controller = TrackpadMotionController(deadZoneRadius: 0.001)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let p0 = controller.update(
            normalizedPoint: CGPoint(x: 0.50, y: 0.50),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false
        )

        // 1. Stationary pinch aiming (isPinching: true, isDragging: false) -> locks cursor position
        let pFrozen = controller.update(
            normalizedPoint: CGPoint(x: 0.48, y: 0.50),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false,
            pinchRatio: 0.20,
            isPinching: true,
            isDragging: false
        )
        TestHarness.assertEqual(pFrozen.x, p0.x, "Stationary pinch freezes cursor on target")

        // 2. Active drag (isPinching: true, isDragging: true) -> moves cursor smoothly!
        let pDragged = controller.update(
            normalizedPoint: CGPoint(x: 0.44, y: 0.50),
            sensitivity: 1.0,
            screenFrame: screen,
            isAdaptive: false,
            pinchRatio: 0.20,
            isPinching: true,
            isDragging: true
        )
        TestHarness.assertTrue(pDragged.x > pFrozen.x, "Active drag moves cursor smoothly without freezing")
    }

    private static func testPinchAndSwipeDragLifecycle() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        func makePinchHand(x: Double, isPinched: Bool) -> HandSkeleton {
            var joints: [HandJointName: HandJoint] = [:]
            joints[.wrist] = HandJoint(name: .wrist, x: x, y: 0.15, confidence: 1.0)
            joints[.middleMCP] = HandJoint(name: .middleMCP, x: x, y: 0.35, confidence: 1.0)
            joints[.middlePIP] = HandJoint(name: .middlePIP, x: x, y: 0.28, confidence: 1.0)
            joints[.middleTip] = HandJoint(name: .middleTip, x: x, y: 0.22, confidence: 1.0)

            joints[.indexMCP] = HandJoint(name: .indexMCP, x: x - 0.05, y: 0.35, confidence: 1.0)
            joints[.indexPIP] = HandJoint(name: .indexPIP, x: x - 0.05, y: 0.55, confidence: 1.0)
            joints[.indexTip] = HandJoint(name: .indexTip, x: x - 0.05, y: 0.70, confidence: 1.0)

            let thumbY = isPinched ? 0.68 : 0.40 // palmScale = 0.20; dist = 0.02 -> ratio = 0.10 when pinched
            joints[.thumbTip] = HandJoint(name: .thumbTip, x: x - 0.05, y: thumbY, confidence: 1.0)

            joints[.ringMCP] = HandJoint(name: .ringMCP, x: x + 0.05, y: 0.30, confidence: 1.0)
            joints[.ringPIP] = HandJoint(name: .ringPIP, x: x + 0.05, y: 0.25, confidence: 1.0)
            joints[.ringTip] = HandJoint(name: .ringTip, x: x + 0.05, y: 0.20, confidence: 1.0)

            joints[.littleMCP] = HandJoint(name: .littleMCP, x: x + 0.10, y: 0.25, confidence: 1.0)
            joints[.littlePIP] = HandJoint(name: .littlePIP, x: x + 0.10, y: 0.20, confidence: 1.0)
            joints[.littleTip] = HandJoint(name: .littleTip, x: x + 0.10, y: 0.15, confidence: 1.0)

            return HandSkeleton(chirality: .right, joints: joints)
        }

        // Frame 1: Pinch starts at x = 0.50 -> enters .pinchPending
        let s1 = machine.process(skeleton: makePinchHand(x: 0.50, isPinched: true), settings: settings, timestamp: 1.00)
        if case .pinchPending = s1 {
            TestHarness.assertTrue(true, "Pinch starts in .pinchPending")
        } else {
            TestHarness.fail("Expected .pinchPending, got \(s1)")
        }

        // Frame 2: Hand swipes while pinched (x = 0.50 -> 0.53, dist = 0.03 > 0.012) -> immediately enters .dragging!
        let s2 = machine.process(skeleton: makePinchHand(x: 0.53, isPinched: true), settings: settings, timestamp: 1.05)
        if case .dragging = s2 {
            TestHarness.assertTrue(true, "Pinch and swipe immediately enters .dragging")
        } else {
            TestHarness.fail("Expected .dragging on pinch and swipe, got \(s2)")
        }

        // Frame 3: Continue dragging to x = 0.58 -> stays in .dragging
        let s3 = machine.process(skeleton: makePinchHand(x: 0.58, isPinched: true), settings: settings, timestamp: 1.10)
        if case .dragging = s3 {
            TestHarness.assertTrue(true, "Continues .dragging smoothly")
        } else {
            TestHarness.fail("Expected continued .dragging, got \(s3)")
        }

        // Frame 4: Release pinch at x = 0.58 -> drops cleanly back to .pointing (does NOT fire click)
        let s4 = machine.process(skeleton: makePinchHand(x: 0.58, isPinched: false), settings: settings, timestamp: 1.15)
        if case .pointing = s4 {
            TestHarness.assertTrue(true, "Releasing drag returns cleanly to .pointing without unintended click")
        } else {
            TestHarness.fail("Expected .pointing upon drag release, got \(s4)")
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

    private static func testThumbMiddleZoomInOut() {
        let history = GestureHistory()
        let resolver = GestureConflictResolver()
        let machine = GestureStateMachine(history: history, resolver: resolver)
        let settings = SwipySettings()

        func makeZoomHand(middleDist: Double) -> HandSkeleton {
            var joints: [HandJointName: HandJoint] = [:]
            joints[.wrist] = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)
            joints[.middleMCP] = HandJoint(name: .middleMCP, x: 0.5, y: 0.35, confidence: 1.0)
            joints[.middlePIP] = HandJoint(name: .middlePIP, x: 0.5, y: 0.45, confidence: 1.0)
            joints[.thumbTip] = HandJoint(name: .thumbTip, x: 0.45, y: 0.45, confidence: 1.0)
            joints[.middleTip] = HandJoint(name: .middleTip, x: 0.45 + middleDist, y: 0.45, confidence: 1.0)
            joints[.indexMCP] = HandJoint(name: .indexMCP, x: 0.35, y: 0.35, confidence: 1.0)
            joints[.indexPIP] = HandJoint(name: .indexPIP, x: 0.35, y: 0.25, confidence: 1.0)
            joints[.indexTip] = HandJoint(name: .indexTip, x: 0.35, y: 0.20, confidence: 1.0)
            joints[.ringMCP] = HandJoint(name: .ringMCP, x: 0.55, y: 0.30, confidence: 1.0)
            joints[.ringPIP] = HandJoint(name: .ringPIP, x: 0.55, y: 0.25, confidence: 1.0)
            joints[.ringTip] = HandJoint(name: .ringTip, x: 0.55, y: 0.20, confidence: 1.0)
            joints[.littleMCP] = HandJoint(name: .littleMCP, x: 0.60, y: 0.25, confidence: 1.0)
            joints[.littlePIP] = HandJoint(name: .littlePIP, x: 0.60, y: 0.20, confidence: 1.0)
            joints[.littleTip] = HandJoint(name: .littleTip, x: 0.60, y: 0.15, confidence: 1.0)
            return HandSkeleton(chirality: .right, joints: joints)
        }

        let h1 = makeZoomHand(middleDist: 0.05)
        let s1 = machine.process(skeleton: h1, settings: settings, timestamp: 1.0)
        if case .zooming(let delta1, _) = s1 {
            TestHarness.assertEqual(delta1, 0.0, accuracy: 0.001, "Frame 1 zoom starts anchored with delta 0")
        } else {
            TestHarness.fail("Expected .zooming state on frame 1, got \(s1)")
        }

        let h2 = makeZoomHand(middleDist: 0.10)
        let s2 = machine.process(skeleton: h2, settings: settings, timestamp: 1.05)
        if case .zooming(let delta2, _) = s2 {
            TestHarness.assertTrue(delta2 > 0.0, "Spreading thumb and middle finger produces positive delta (Zoom In)")
        } else {
            TestHarness.fail("Expected .zooming state on frame 2, got \(s2)")
        }

        let h3 = makeZoomHand(middleDist: 0.06)
        let s3 = machine.process(skeleton: h3, settings: settings, timestamp: 1.10)
        if case .zooming(let delta3, _) = s3 {
            TestHarness.assertTrue(delta3 < 0.0, "Contracting thumb and middle finger produces negative delta (Zoom Out)")
        } else {
            TestHarness.fail("Expected .zooming state on frame 3, got \(s3)")
        }
    }
}
