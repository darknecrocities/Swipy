import SwiftUI
import SwipyCore

/// Real-time telemetry metrics card reporting inference rate, frame latency, and hand presence.
public struct DashboardMetricsRow: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 12) {
            metricCard(title: "Inference", value: String(format: "%.0f FPS", appState.currentFPS), icon: "gauge")
            metricCard(title: "Latency", value: String(format: "%.1f ms", appState.currentInferenceMs), icon: "timer")
            metricCard(title: "Tracking", value: appState.primaryHand != nil ? "1 Hand" : "Searching", icon: "hand.raised")
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "777777"))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "999999"))
            }
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "171717"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}

/// Interactive practice pad for testing pointing, pinching, and click synthesis.
public struct DashboardPracticePadCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interactive Practice Target")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Point here and pinch thumb to index finger to test clicks.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                Text("\(appState.practiceClickCount) Clicks")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "F2F2F2"))
                    .foregroundColor(Color(hex: "171717"))
                    .cornerRadius(6)
            }

            Button(action: {
                appState.practiceClickCount += 1
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 13))
                    Text(appState.practiceClickCount == 0 ? "Pinch Here to Click Target" : "Target Hit! Click Again")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: "171717"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E0E0E0"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}

/// Cursor navigation speed and adaptive acceleration controls.
public struct DashboardSensitivityCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cursor Sensitivity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Navigation speed multiplier across displays.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                Text(String(format: "%.2fx", appState.settings.cursorSensitivity))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "171717"))
            }

            Slider(value: $appState.settings.cursorSensitivity, in: 0.2...4.0, step: 0.05)
                .onChange(of: appState.settings.cursorSensitivity) {
                    appState.settings.save()
                }

            HStack(spacing: 6) {
                presetChip(title: "0.7x", value: 0.7)
                presetChip(title: "1.15x", value: 1.15)
                presetChip(title: "2.0x", value: 2.0)
                presetChip(title: "3.0x", value: 3.0)
            }

            Toggle("Adaptive Power Curve (Damp small jitters, boost sweeps)", isOn: $appState.settings.isAdaptiveAcceleration)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "555555"))
                .onChange(of: appState.settings.isAdaptiveAcceleration) {
                    appState.settings.save()
                }
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private func presetChip(title: String, value: Double) -> some View {
        Button(action: {
            appState.settings.cursorSensitivity = value
            appState.settings.save()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(abs(appState.settings.cursorSensitivity - value) < 0.05 ? Color(hex: "171717") : Color.white)
                .foregroundColor(abs(appState.settings.cursorSensitivity - value) < 0.05 ? .white : Color(hex: "777777"))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Pointer overlay HUD design picker and size adjustments.
public struct DashboardPointerCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pointer Overlay HUD")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Floating cursor ring with pinch feedback.")
                        .font(.system(size: 11))
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
                HStack(spacing: 6) {
                    ForEach(CustomPointerStyle.allCases, id: \.self) { style in
                        styleChip(style: style)
                    }
                }

                HStack {
                    Text("Size")
                        .font(.system(size: 11))
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private func styleChip(style: CustomPointerStyle) -> some View {
        Button(action: {
            appState.settings.pointer.style = style
            appState.settings.save()
        }) {
            Text(style.rawValue)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(appState.settings.pointer.style == style ? Color(hex: "171717") : Color(hex: "FAFAFA"))
                .foregroundColor(appState.settings.pointer.style == style ? .white : Color(hex: "777777"))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Action bar for calibration wizard, camera skeleton, and smoothing reset.
public struct DashboardQuickActionsCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 12) {
            actionButton(title: "Calibrate Bounds", icon: "scope") {
                appState.isCalibrating = true
            }
            actionButton(title: "Camera Skeleton", icon: "eye") {
                appState.settings.showCameraPreview.toggle()
                appState.settings.save()
            }
            actionButton(title: "Reset Smoothing", icon: "arrow.counterclockwise") {
                GestureRecognizer.shared.smoother.reset()
            }
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "171717"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

extension Color {
    public init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
