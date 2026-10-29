import Foundation
import SwipyCore

@MainActor
public struct SettingsTests {
    public static func run() {
        testDefaultSettingsIntegrity()
        testProfileApplication()
        testSanitizationBounds()
        testCodableSerialization()
        testPointerSettingsSerialization()
    }

    private static func testDefaultSettingsIntegrity() {
        let settings = SwipySettings()
        TestHarness.assertFalse(settings.isTrackingEnabled, "Default tracking disabled")
        TestHarness.assertFalse(settings.isPaused, "Default tracking unpaused")
        TestHarness.assertEqual(settings.selectedProfileKind, .balanced, "Default profile balanced")
        TestHarness.assertFalse(settings.bindings.isEmpty, "Bindings present")
        TestHarness.assertTrue(settings.pointer.isEnabled, "Default pointer HUD enabled")
        TestHarness.assertEqual(settings.pointer.style, .visionProRing, "Default pointer style Vision Pro")
    }

    private static func testProfileApplication() {
        var settings = SwipySettings()
        settings.applyProfile(.precision)

        TestHarness.assertEqual(settings.selectedProfileKind, .precision, "Precision profile set")
        TestHarness.assertEqual(settings.cursorSensitivity, GestureProfile.precision.cursorSensitivity, accuracy: 0.001, "Precision sensitivity")

        settings.applyProfile(.fast)
        TestHarness.assertEqual(settings.selectedProfileKind, .fast, "Fast profile set")
        TestHarness.assertEqual(settings.cursorSensitivity, GestureProfile.fast.cursorSensitivity, accuracy: 0.001, "Fast sensitivity")
    }

    private static func testSanitizationBounds() {
        var settings = SwipySettings()
        settings.cursorSensitivity = 999.0
        settings.pinchThreshold = -5.0
        settings.pointer.size = 1000.0
        settings.sanitize()

        TestHarness.assertTrue(settings.cursorSensitivity <= 4.0, "Sensitivity capped at max 4.0")
        TestHarness.assertTrue(settings.pinchThreshold >= 0.02, "Pinch threshold bounded at min 0.02")
        TestHarness.assertTrue(settings.pointer.size <= 64.0, "Pointer size capped at max 64")
    }

    private static func testCodableSerialization() {
        let original = SwipySettings(
            isTrackingEnabled: true,
            isPaused: false,
            cursorSensitivity: 1.75
        )

        do {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(SwipySettings.self, from: encoded)

            TestHarness.assertEqual(original.isTrackingEnabled, decoded.isTrackingEnabled, "Serialized tracking flag")
            TestHarness.assertEqual(original.cursorSensitivity, decoded.cursorSensitivity, accuracy: 0.001, "Serialized sensitivity")
        } catch {
            TestHarness.fail("Failed to serialize settings: \(error)")
        }
    }

    private static func testPointerSettingsSerialization() {
        var settings = SwipySettings()
        settings.pointer.style = .crosshair
        settings.pointer.size = 36.0
        settings.pointer.theme = .electricCyan

        do {
            let encoded = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(SwipySettings.self, from: encoded)

            TestHarness.assertEqual(decoded.pointer.style, .crosshair, "Decoded pointer style")
            TestHarness.assertEqual(decoded.pointer.size, 36.0, accuracy: 0.1, "Decoded pointer size")
            TestHarness.assertEqual(decoded.pointer.theme, .electricCyan, "Decoded pointer theme")
        } catch {
            TestHarness.fail("Failed to serialize pointer settings: \(error)")
        }
    }
}
