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
        testAllGestureCategoriesPopulatedAndMigrated()
        testAppUpdateManifestComparisonAndParsing()
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

    private static func testAllGestureCategoriesPopulatedAndMigrated() {
        let settings = SwipySettings()
        TestHarness.assertEqual(settings.bindings.count, 15, "All 15 gestures present in defaultBindings")

        for category in GestureCategory.allCases {
            let count = settings.bindings.filter { $0.category == category }.count
            TestHarness.assertTrue(count > 0, "Category \(category.rawValue) has at least 1 binding (got \(count))")
        }

        // Simulate migrating an older v3 configuration missing Two-Hand Controls and Pinch & Drag
        let legacyBindings = [
            GestureBinding(gestureType: .indexPointing, category: .cursorAndClick, action: .none),
            GestureBinding(gestureType: .thumbIndexPinch, category: .cursorAndClick, action: .leftClick)
        ]
        var legacySettings = SwipySettings(bindings: legacyBindings, schemaVersion: 3)
        legacySettings.migrateIfNeeded()

        TestHarness.assertEqual(legacySettings.bindings.count, 15, "Schema v4 migration backfills all 15 gestures")
        let twoHandCount = legacySettings.bindings.filter { $0.category == .twoHand }.count
        TestHarness.assertEqual(twoHandCount, 2, "Two-Hand Controls category populated with 2 zoom bindings")
        let indexBinding = legacySettings.bindings.first { $0.gestureType == .indexPointing }
        TestHarness.assertEqual(indexBinding?.action, .moveCursor, "Index Pointing migrated from .none to .moveCursor")
    }

    private static func testAppUpdateManifestComparisonAndParsing() {
        let sampleJSON = """
        {
          "tag_name": "latest",
          "target_commitish": "a1b2c3d4e5f60718293a",
          "published_at": "2026-10-30T12:00:00Z",
          "body": "## Swipy Build\\n- Commit: `9f8e7d6`\\n- Automated macOS release",
          "assets": [
            {
              "name": "Swipy-macOS.zip",
              "browser_download_url": "https://github.com/darknecrocities/Swipy/releases/download/latest/Swipy-macOS.zip"
            }
          ]
        }
        """.data(using: .utf8)!

        guard let manifest = AppUpdateManager.parseGitHubReleasePayload(sampleJSON, defaultVersion: "1.0.0") else {
            TestHarness.fail("Expected valid ReleaseManifest from GitHub release payload")
            return
        }

        TestHarness.assertEqual(manifest.commitSHA, "9f8e7d6", "Extracted 7-char commit SHA from release body")
        TestHarness.assertTrue(manifest.downloadURL.hasSuffix("Swipy-macOS.zip"), "Extracted Swipy-macOS.zip asset URL")

        // Same commit SHA -> should NOT offer update
        let sameUpdate = AppUpdateManager.shouldOfferUpdate(
            localVersion: "1.0.0",
            localCommitSHA: "9f8e7d6",
            remote: manifest
        )
        TestHarness.assertFalse(sameUpdate, "Identical commit SHA does not trigger redundant update")

        // Newer commit SHA on main -> SHOULD offer update immediately even if semantic version is still 1.0.0
        let newerCommitUpdate = AppUpdateManager.shouldOfferUpdate(
            localVersion: "1.0.0",
            localCommitSHA: "14af833",
            remote: manifest
        )
        TestHarness.assertTrue(newerCommitUpdate, "Different commit SHA on latest release triggers OTA update")
    }
}
