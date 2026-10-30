import SwiftUI
import SwipyCore

/// macOS system integrations, startup behavior, and application switching.
public struct SettingsSystemTab: View {
    @ObservedObject var appState: AppLifecycleManager
    @ObservedObject private var updater = AppUpdateManager.shared

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            softwareUpdateCard

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

    private var softwareUpdateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "171717"))
                        Text("Automatic Software Updates (OTA)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "171717"))
                    }
                    Text("Current Build: v\(updater.currentVersion) (\(updater.currentCommitSHA)) • Automatically syncs with latest main branch releases.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                updateActionButton
            }

            if let statusLine = updateStatusMessage {
                Text(statusLine)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(updateStatusColor)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    @ViewBuilder
    private var updateActionButton: some View {
        switch updater.status {
        case .updateAvailable(let manifest):
            Button(action: {
                Task { await updater.downloadAndInstallUpdate(from: manifest) }
            }) {
                Text("Update & Relaunch (\(manifest.commitSHA))")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        case .checking, .downloading, .installing:
            ProgressView()
                .controlSize(.small)
        default:
            Button(action: {
                Task { await updater.checkForUpdates(silent: false) }
            }) {
                Text("Check for Updates")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FAFAFA"))
                    .foregroundColor(Color(hex: "171717"))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var updateStatusMessage: String? {
        switch updater.status {
        case .idle:
            return nil
        case .checking:
            return "Checking GitHub Releases for newer macOS builds..."
        case .upToDate(let version, let sha):
            return "Swipy is up to date (v\(version) • \(sha))."
        case .updateAvailable(let manifest):
            return "New build available: v\(manifest.version) (\(manifest.commitSHA)). Ready to install and relaunch."
        case .downloading:
            return "Downloading latest Swipy-macOS.zip..."
        case .installing:
            return "Verifying code signature and swapping Swipy.app bundle..."
        case .failed(let message):
            return message
        }
    }

    private var updateStatusColor: Color {
        switch updater.status {
        case .updateAvailable:
            return Color.blue
        case .upToDate:
            return Color.green
        case .failed:
            return Color.red
        default:
            return Color(hex: "777777")
        }
    }
}
