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
}
