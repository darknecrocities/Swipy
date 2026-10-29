import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct CoordinateMapperTests {
    public static func run() {
        testCenterMapping()
        testYInversion()
        testDeadZoneSuppression()
    }

    private static func testCenterMapping() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let normalizedCenter = CGPoint(x: 0.5, y: 0.5)

        let mapped = mapper.mapToScreen(
            normalizedPoint: normalizedCenter,
            previousPoint: nil,
            screenFrame: screen
        )

        // Vision y=0.5 -> Screen y = (1.0 - 0.5) * 800 = 400
        TestHarness.assertEqual(mapped.x, 500, accuracy: 0.1, "Center X mapping")
        TestHarness.assertEqual(mapped.y, 400, accuracy: 0.1, "Center Y mapping")
    }

    private static func testYInversion() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        // Top of Vision camera (y=1.0) maps to top of screen (y=0.0)
        let topPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.0, y: 1.0),
            previousPoint: nil,
            screenFrame: screen
        )
        TestHarness.assertEqual(topPoint.y, 0, accuracy: 0.1, "Top Y inversion")

        // Bottom of Vision camera (y=0.0) maps to bottom of screen (y=1000.0)
        let bottomPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.0, y: 0.0),
            previousPoint: nil,
            screenFrame: screen
        )
        TestHarness.assertEqual(bottomPoint.y, 1000, accuracy: 0.1, "Bottom Y inversion")
    }

    private static func testDeadZoneSuppression() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.05 // 5% of screen width = 50px
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let previous = CGPoint(x: 500, y: 500)

        // Small jitter movement: 505, 505 (distance ~ 7px < 50px threshold)
        let smallJitter = CGPoint(x: 0.505, y: 0.495)
        let result = mapper.mapToScreen(
            normalizedPoint: smallJitter,
            previousPoint: previous,
            screenFrame: screen
        )

        TestHarness.assertEqual(result.x, previous.x, "Dead zone X suppression")
        TestHarness.assertEqual(result.y, previous.y, "Dead zone Y suppression")
    }
}
