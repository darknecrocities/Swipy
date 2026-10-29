import SwiftUI
import SwipyCore

/// macOS system integrations, startup behavior, and application switching.
public struct SettingsSystemTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsToggleRow(
                title: "Launch at Login",
                subtitle: "Starts Swipy in the background upon macOS user login.",
                isOn: $appState.settings.launchAtLogin,
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Menu Bar Only Mode",
                subtitle: "Hides the Dock icon and main window, leaving only the Menu Bar status icon.",
                isOn: $appState.settings.menuBarOnlyMode,
                onCommit: { appState.settings.save() }
            )

            SettingsToggleRow(
                title: "Native Command+Tab for App Switcher",
                subtitle: "Triggers native macOS App Switcher instead of Swipy's floating dock.",
                isOn: $appState.settings.useNativeAppSwitcher,
                onCommit: { appState.settings.save() }
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Emergency Safety Hotkey")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text("Press ⌥⎋ (Option + Escape) from any application to instantly suspend camera capture, release all held buttons, and stop mouse movement.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "777777"))
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
    }
}
