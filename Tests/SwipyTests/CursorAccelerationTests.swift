import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct CursorAccelerationTests {
    public static func run() {
        testLinearAcceleration()
        testAdaptivePrecisionDamping()
        testAdaptiveHighSpeedBoost()
    }

    private static func testLinearAcceleration() {
        let accel = CursorAcceleration(isAdaptive: false, sensitivity: 1.5)
        let delta = CGVector(dx: 10, dy: 20)
        let result = accel.accelerate(delta: delta, dt: 0.033)

        TestHarness.assertEqual(result.dx, 15.0, accuracy: 0.01, "Linear acceleration X")
        TestHarness.assertEqual(result.dy, 30.0, accuracy: 0.01, "Linear acceleration Y")
    }

    private static func testAdaptivePrecisionDamping() {
        let accel = CursorAcceleration(isAdaptive: true, sensitivity: 1.0)
        // Very slow movement: speed = 0.001 / 0.033 ~ 0.03 (< 0.15)
        let microDelta = CGVector(dx: 0.001, dy: 0.0)
        let result = accel.accelerate(delta: microDelta, dt: 0.033)

        // Damped output for precision
        TestHarness.assertTrue(result.dx < microDelta.dx * 1.0, "Adaptive curve damps micro-movements for precision")
    }

    private static func testAdaptiveHighSpeedBoost() {
        let accel = CursorAcceleration(isAdaptive: true, sensitivity: 1.0)
        // High speed sweep: 0.05 / 0.033 ~ 1.5 (> 0.60)
        let fastDelta = CGVector(dx: 0.05, dy: 0.0)
        let result = accel.accelerate(delta: fastDelta, dt: 0.033)

        // Boosted output
        TestHarness.assertTrue(result.dx > fastDelta.dx * 1.5, "Adaptive curve accelerates high-velocity sweeps")
    }
}
