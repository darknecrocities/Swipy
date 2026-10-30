import Foundation
import CoreGraphics
import SwipyCore

@MainActor
public struct CoordinateMapperTests {
    public static func run() {
        testCenterMapping()
        testXMirroring()
        testYInversion()
        testSensitivityScaling()
        testDeadZoneSuppression()
    }

    private static func testCenterMapping() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0,
            overscanMargin: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let normalizedCenter = CGPoint(x: 0.5, y: 0.5)

        let mapped = mapper.mapToScreen(
            normalizedPoint: normalizedCenter,
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 1.0
        )

        TestHarness.assertEqual(mapped.x, 500, accuracy: 0.1, "Center X mapping")
        TestHarness.assertEqual(mapped.y, 400, accuracy: 0.1, "Center Y mapping")
    }

    private static func testXMirroring() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0,
            overscanMargin: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        // Hand at camera left (x=0.1) maps to screen right (x=900) for natural selfie tracking
        let leftPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.1, y: 0.5),
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 1.0
        )
        TestHarness.assertEqual(leftPoint.x, 900, accuracy: 0.1, "Selfie X mirroring right")

        // Hand at camera right (x=0.9) maps to screen left (x=100)
        let rightPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.9, y: 0.5),
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 1.0
        )
        TestHarness.assertEqual(rightPoint.x, 100, accuracy: 0.1, "Selfie X mirroring left")
    }

    private static func testYInversion() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0,
            overscanMargin: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        // Top of Vision camera (y=1.0) maps to top of screen (y=0.0)
        let topPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.5, y: 1.0),
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 1.0
        )
        TestHarness.assertEqual(topPoint.y, 0, accuracy: 0.1, "Top Y inversion")

        // Bottom of Vision camera (y=0.0) maps to bottom of screen (y=1000.0)
        let bottomPoint = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.5, y: 0.0),
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 1.0
        )
        TestHarness.assertEqual(bottomPoint.y, 1000, accuracy: 0.1, "Bottom Y inversion")
    }

    private static func testSensitivityScaling() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.0,
            overscanMargin: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)

        // At x=0.45 (slightly right of center), visionX = 0.55
        // With sensitivity = 2.0: (0.55 - 0.5) * 2.0 + 0.5 = 0.60 -> 600px
        let amplified = mapper.mapToScreen(
            normalizedPoint: CGPoint(x: 0.45, y: 0.5),
            previousPoint: nil,
            screenFrame: screen,
            sensitivity: 2.0
        )
        TestHarness.assertEqual(amplified.x, 600, accuracy: 0.1, "Sensitivity center-origin expansion")
    }

    private static func testDeadZoneSuppression() {
        let mapper = CoordinateMapper(
            activeRegion: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            deadZoneRadius: 0.05, // 5% of screen width = 50px
            overscanMargin: 0.0
        )
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let previous = CGPoint(x: 500, y: 500)

        // Small jitter movement: 0.495 -> visionX = 0.505 -> 505px, 505px (distance ~ 7px < 50px threshold)
        let smallJitter = CGPoint(x: 0.495, y: 0.495)
        let result = mapper.mapToScreen(
            normalizedPoint: smallJitter,
            previousPoint: previous,
            screenFrame: screen,
            sensitivity: 1.0
        )

        TestHarness.assertEqual(result.x, previous.x, "Dead zone X suppression")
        TestHarness.assertEqual(result.y, previous.y, "Dead zone Y suppression")
    }
}
