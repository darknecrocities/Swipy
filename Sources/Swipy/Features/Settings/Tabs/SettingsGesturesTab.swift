import SwiftUI
import SwipyCore

/// Thresholds and individual enable toggles for supported hand gestures.
public struct SettingsGesturesTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSliderRow(
                title: "Pinch Sensitivity Ratio",
                subtitle: "Scale-invariant ratio between fingertip contact and rigid palm length (0.32 recommended).",
                value: $appState.settings.pinchThreshold,
                range: 0.18...0.48,
                step: 0.01,
                format: "%.2f",
                unit: "",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Drag Delay Threshold",
                subtitle: "Duration to hold a pinch before converting a click into a drag operation.",
                value: Binding(
                    get: { Double(appState.settings.dragDelayMs) },
                    set: { appState.settings.dragDelayMs = Int($0) }
                ),
                range: 150...500,
                step: 25,
                format: "%.0f",
                unit: " ms",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Double Click Window",
                subtitle: "Maximum interval between two pinches to register a double click.",
                value: Binding(
                    get: { Double(appState.settings.doubleClickWindowMs) },
                    set: { appState.settings.doubleClickWindowMs = Int($0) }
                ),
                range: 200...600,
                step: 20,
                format: "%.0f",
                unit: " ms",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Swipe Velocity Threshold",
                subtitle: "How fast the open palm must travel to trigger Spaces and Mission Control (lower = easier). 1.0 means one camera-width per second.",
                value: $appState.settings.swipeVelocityThreshold,
                range: 0.5...2.5,
                step: 0.1,
                format: "%.1f",
                unit: " ×/s",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Swipe Cooldown Interval",
                subtitle: "Cooldown lock preventing accidental consecutive space shifts.",
                value: Binding(
                    get: { Double(appState.settings.swipeCooldownMs) },
                    set: { appState.settings.swipeCooldownMs = Int($0) }
                ),
                range: 300...1200,
                step: 50,
                format: "%.0f",
                unit: " ms",
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Native App Switcher",
                subtitle: "Triggers macOS Command+Tab instead of Swipy's floating dock overlay.",
                isOn: $appState.settings.useNativeAppSwitcher,
                onCommit: { appState.settings.save() }
            )
        }
    }
}
