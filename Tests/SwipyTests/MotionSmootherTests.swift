import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct MotionSmootherTests {
    public static func run() {
        testSteadyStateNoJitter()
        testHighSpeedTrackingTracksMotion()
    }

    private static func testSteadyStateNoJitter() {
        let smoother = MotionSmoother(minCutoff: 1.0, beta: 0.007)
        let initial = CGPoint(x: 100, y: 100)

        _ = smoother.filter(point: initial, timestamp: 1.0)

        var result = initial
        for i in 1...10 {
            let t = 1.0 + Double(i) * 0.033
            let noisy = CGPoint(x: 100.0 + Double(i % 2) * 0.5, y: 100.0 - Double(i % 2) * 0.5)
            result = smoother.filter(point: noisy, timestamp: t)
        }

        TestHarness.assertEqual(result.x, 100.0, accuracy: 0.6, "Stationary jitter smoothing X")
        TestHarness.assertEqual(result.y, 100.0, accuracy: 0.6, "Stationary jitter smoothing Y")
    }

    private static func testHighSpeedTrackingTracksMotion() {
        let smoother = MotionSmoother(minCutoff: 1.0, beta: 0.01)

        _ = smoother.filter(point: CGPoint(x: 100, y: 100), timestamp: 1.0)
        let swept = smoother.filter(point: CGPoint(x: 500, y: 500), timestamp: 1.1)

        TestHarness.assertTrue(swept.x > 300.0, "High velocity sweep follows motion X")
        TestHarness.assertTrue(swept.y > 300.0, "High velocity sweep follows motion Y")
    }
}
