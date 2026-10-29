import SwiftUI
import SwipyCore

/// Scroll wheel direction, speed, and axis settings.
public struct SettingsScrollingTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSliderRow(
                title: "Scroll Velocity Multiplier",
                subtitle: "Controls how fast pages and documents scroll per centimeter of hand travel.",
                value: $appState.settings.scrollSpeed,
                range: 0.4...3.0,
                step: 0.1,
                format: "%.1f",
                unit: "x",
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Natural Scrolling Direction",
                subtitle: "Matches macOS trackpad convention where content tracks finger movement direction.",
                isOn: $appState.settings.isNaturalScroll,
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Horizontal Scrolling Support",
                subtitle: "Enables horizontal panning when moving parallel fingers sideways.",
                isOn: $appState.settings.isHorizontalScrollEnabled,
                onCommit: { appState.settings.save() }
            )
        }
    }
}
