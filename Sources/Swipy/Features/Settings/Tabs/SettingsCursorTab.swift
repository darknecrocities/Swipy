import SwiftUI
import SwipyCore

/// Cursor sensitivity, non-linear acceleration curves, and motion filtering settings.
public struct SettingsCursorTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSliderRow(
                title: "Cursor Sensitivity",
                subtitle: "Direct multiplier mapping hand movement to cursor travel.",
                value: $appState.settings.cursorSensitivity,
                range: 0.2...4.0,
                step: 0.05,
                format: "%.2f",
                unit: "x",
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Adaptive Power Curve Acceleration",
                subtitle: "Automatically damps micro-jitters during precision tasks while boosting rapid screen-wide sweeps.",
                isOn: $appState.settings.isAdaptiveAcceleration,
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Smoothing Jitter Cutoff",
                subtitle: "One Euro minimum cutoff frequency; lower values eliminate hand tremor when still.",
                value: $appState.settings.smoothingMinCutoff,
                range: 0.2...3.0,
                step: 0.1,
                format: "%.1f",
                unit: " Hz",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Responsiveness Beta",
                subtitle: "One Euro speed coefficient; higher values eliminate tracking lag during fast hand movements.",
                value: $appState.settings.smoothingBeta,
                range: 0.001...0.03,
                step: 0.001,
                format: "%.3f",
                unit: "",
                onCommit: { appState.settings.save() }
            )

            SettingsSliderRow(
                title: "Dead Zone Margin",
                subtitle: "Ignores infinitesimal involuntary finger twitches when attempting to stay motionless.",
                value: $appState.settings.deadZoneRadius,
                range: 0.0...0.02,
                step: 0.001,
                format: "%.3f",
                unit: "",
                onCommit: { appState.settings.save() }
            )
        }
    }
}
