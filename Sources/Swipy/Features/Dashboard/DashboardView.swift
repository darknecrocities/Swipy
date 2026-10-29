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
            VStack(spacing: 24) {
                headerBar
                permissionAlerts
                masterControlCard
                sensitivityCard
                pointerHUDCard
                DashboardPracticePadCard(appState: appState)
                DashboardMetricsRow(appState: appState)
                DashboardQuickActionsCard(appState: appState)
            }
            .padding(32)
        }
        .background(Color.white)
        .sheet(isPresented: $appState.isCalibrating) {
            CalibrationView(appState: appState, isPresented: $appState.isCalibrating)
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Swipy")
                    .font(.system(size: 26, weight: .semibold, design: .default))
                    .foregroundColor(Color(hex: "171717"))
                Text("Touchless macOS Gesture Control")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(appState.trackingState.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "171717"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "EAEAEA"), lineWidth: 1)
        )
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var masterControlCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gesture Control")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text(appState.settings.isTrackingEnabled ? "Camera tracking is active and controlling the macOS cursor." : "Tracking paused. The built-in camera is offline.")
                        .font(.system(size: 13))
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
                Divider().background(Color(hex: "EAEAEA"))
                HStack(spacing: 16) {
                    Button(action: { appState.togglePause() }) {
                        Label(appState.settings.isPaused ? "Resume Tracking" : "Emergency Pause", systemImage: appState.settings.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(appState.settings.isPaused ? Color.green : Color.orange)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Profile: \(appState.settings.selectedProfileKind.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "777777"))
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }

    private var sensitivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cursor Sensitivity & Navigation")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Adjust cursor travel speed and acceleration curve for natural wrist navigation.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                Text(String(format: "%.2fx", appState.settings.cursorSensitivity))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "171717"))
            }

            Slider(value: $appState.settings.cursorSensitivity, in: 0.2...4.0, step: 0.05)
                .onChange(of: appState.settings.cursorSensitivity) {
                    appState.settings.save()
                }

            HStack(spacing: 8) {
                sensitivityChip(title: "Precision (0.7x)", value: 0.7)
                sensitivityChip(title: "Standard (1.15x)", value: 1.15)
                sensitivityChip(title: "Fast (2.0x)", value: 2.0)
                sensitivityChip(title: "Extreme (3.0x)", value: 3.0)
            }

            Toggle("Adaptive Acceleration (Slow for accuracy, fast sweeps across screen)", isOn: $appState.settings.isAdaptiveAcceleration)
                .font(.system(size: 12))
                .onChange(of: appState.settings.isAdaptiveAcceleration) {
                    appState.settings.save()
                }
        }
        .padding(20)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private func sensitivityChip(title: String, value: Double) -> some View {
        Button(action: {
            appState.settings.cursorSensitivity = value
            appState.settings.save()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(abs(appState.settings.cursorSensitivity - value) < 0.05 ? Color(hex: "171717") : Color.white)
                .foregroundColor(abs(appState.settings.cursorSensitivity - value) < 0.05 ? .white : Color(hex: "777777"))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var pointerHUDCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pointer Overlay Design")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Custom on-screen visual pointer with pinch compression and click ripples.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                Toggle("", isOn: $appState.settings.pointer.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: appState.settings.pointer.isEnabled) {
                        appState.settings.save()
                    }
            }

            if appState.settings.pointer.isEnabled {
                Divider().background(Color(hex: "EAEAEA"))
                HStack(spacing: 8) {
                    ForEach(CustomPointerStyle.allCases, id: \.self) { style in
                        pointerStyleChip(style: style)
                    }
                }

                HStack {
                    Text("Pointer Size")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "777777"))
                    Slider(value: $appState.settings.pointer.size, in: 16...48, step: 2)
                        .onChange(of: appState.settings.pointer.size) {
                            appState.settings.save()
                        }
                    Text("\(Int(appState.settings.pointer.size))px")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "777777"))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private func pointerStyleChip(style: CustomPointerStyle) -> some View {
        Button(action: {
            appState.settings.pointer.style = style
            appState.settings.save()
        }) {
            Text(style.rawValue)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(appState.settings.pointer.style == style ? Color(hex: "171717") : Color(hex: "FAFAFA"))
                .foregroundColor(appState.settings.pointer.style == style ? .white : Color(hex: "777777"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
