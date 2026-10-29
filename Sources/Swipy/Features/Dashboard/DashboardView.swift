import SwiftUI
import AppKit
import SwipyCore

/// Pure white, minimal, premium glassmorphism overview dashboard.
public struct DashboardView: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBar
                permissionAlerts
                masterHeroCard

                // 2-Column Responsive Control Grid
                HStack(alignment: .top, spacing: 16) {
                    // Left Column: Cursor & Pointer Control Hub
                    VStack(spacing: 16) {
                        DashboardSensitivityCard(appState: appState)
                        DashboardPointerCard(appState: appState)
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column: Interactive Practice & Telemetry
                    VStack(spacing: 16) {
                        DashboardPracticePadCard(appState: appState)
                        DashboardMetricsRow(appState: appState)
                    }
                    .frame(maxWidth: .infinity)
                }

                DashboardQuickActionsCard(appState: appState)
            }
            .padding(28)
        }
        .background(Color.white)
        .sheet(isPresented: $appState.isCalibrating) {
            CalibrationView(appState: appState, isPresented: $appState.isCalibrating)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 14) {
            SwipyLogoView(size: 40, showShadow: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Swipy")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text("Touchless macOS Gesture Control")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(appState.trackingState.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "171717"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var statusColor: Color {
        switch appState.trackingState {
        case .tracking: return Color.green
        case .paused: return Color.orange
        case .permissionRequired, .accessibilityRequired, .error: return Color.red
        default: return Color(hex: "777777")
        }
    }

    @ViewBuilder
    private var permissionAlerts: some View {
        if !appState.isCameraAuthorized {
            permissionBanner(
                title: "Camera Access Required",
                message: "Swipy processes camera frames locally on your Mac to detect hand gestures.",
                buttonText: "Grant Camera Access",
                action: {
                    Task {
                        let granted = await CameraPermissionManager.shared.requestAccess()
                        if !granted {
                            CameraPermissionManager.shared.openSystemSettingsCameraPrivacy()
                        }
                    }
                }
            )
        }
        if !appState.isAccessibilityTrusted {
            permissionBanner(
                title: "Accessibility Permission Required",
                message: "Accessibility trust enables Swipy to move the cursor and click across apps.",
                buttonText: "Grant Accessibility",
                action: { AccessibilityPermissionManager.shared.openAccessibilitySettings() }
            )
        }
    }

    private func permissionBanner(title: String, message: String, buttonText: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var masterHeroCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Gesture Control")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text(appState.settings.isTrackingEnabled
                         ? "FaceTime HD camera active • Controlling macOS cursor"
                         : "Tracking offline • Camera stream suspended")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.settings.isTrackingEnabled },
                    set: { _ in appState.toggleTracking() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            if appState.settings.isTrackingEnabled {
                Divider().background(Color(hex: "F0F0F0"))
                HStack(spacing: 12) {
                    Button(action: { appState.togglePause() }) {
                        Label(
                            appState.settings.isPaused ? "Resume Tracking" : "Emergency Pause",
                            systemImage: appState.settings.isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(appState.settings.isPaused ? Color.green : Color.orange)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Active Profile: \(appState.settings.selectedProfileKind.rawValue)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "777777"))
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}
