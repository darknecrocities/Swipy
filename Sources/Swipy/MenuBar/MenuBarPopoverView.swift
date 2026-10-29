import SwiftUI
import AppKit
import SwipyCore

/// High-density, minimal glassmorphic popover for the macOS menu bar.
public struct MenuBarPopoverView: View {
    @ObservedObject var appState: AppLifecycleManager
    var onOpenDashboard: () -> Void
    var onOpenCalibration: () -> Void

    public init(
        appState: AppLifecycleManager,
        onOpenDashboard: @escaping () -> Void,
        onOpenCalibration: @escaping () -> Void
    ) {
        self.appState = appState
        self.onOpenDashboard = onOpenDashboard
        self.onOpenCalibration = onOpenCalibration
    }

    public var body: some View {
        VStack(spacing: 14) {
            headerRow

            Button(action: {
                appState.toggleTracking()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: appState.settings.isTrackingEnabled ? "stop.fill" : "play.fill")
                        .font(.system(size: 11))
                    Text(appState.settings.isTrackingEnabled ? "Stop Gesture Tracking" : "Start Gesture Tracking")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(appState.settings.isTrackingEnabled ? Color(hex: "FAFAFA") : Color(hex: "171717"))
                .foregroundColor(appState.settings.isTrackingEnabled ? Color(hex: "171717") : .white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Divider().background(Color(hex: "EAEAEA"))
            statusSection
            sensitivitySlider
            actionButtons
            Divider().background(Color(hex: "EAEAEA"))
            footerControls
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.white)
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            SwipyLogoView(size: 20)
            Text("Swipy")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "171717"))
            Spacer()
            Toggle("", isOn: Binding(
                get: { appState.settings.isTrackingEnabled },
                set: { _ in appState.toggleTracking() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tracking Status:")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
                Spacer()
                Text(appState.trackingState.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            HStack {
                Text("Inference Rate:")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
                Spacer()
                Text(String(format: "%.0f FPS", appState.currentFPS))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "171717"))
            }
        }
    }

    private var statusColor: Color {
        switch appState.trackingState {
        case .tracking: return Color.green
        case .paused: return Color.orange
        case .permissionRequired, .accessibilityRequired, .error: return Color.red
        default: return Color(hex: "777777")
        }
    }

    private var sensitivitySlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Sensitivity")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
                Spacer()
                Text(String(format: "%.2fx", appState.settings.cursorSensitivity))
                    .font(.system(size: 11, design: .monospaced))
            }
            CustomSliderBar(
                value: $appState.settings.cursorSensitivity,
                range: 0.2...4.0,
                step: 0.05,
                onCommit: { appState.settings.save() }
            )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 6) {
            if appState.settings.isTrackingEnabled {
                menuButton(
                    title: appState.settings.isPaused ? "Resume Tracking" : "Emergency Pause",
                    icon: appState.settings.isPaused ? "play.fill" : "pause.fill"
                ) {
                    appState.togglePause()
                }
            }
            menuButton(title: "Calibrate Bounds...", icon: "scope") {
                onOpenCalibration()
            }
            menuButton(title: "Open Dashboard", icon: "macwindow") {
                onOpenDashboard()
            }
        }
    }

    private var footerControls: some View {
        HStack {
            Spacer()
            Button("Quit Swipy") {
                appState.stopTrackingSession()
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.red)
        }
    }

    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "171717"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
