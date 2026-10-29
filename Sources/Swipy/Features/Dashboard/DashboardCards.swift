import SwiftUI
import SwipyCore

/// Metrics cards reporting real-time inference latency and FPS.
public struct DashboardMetricsRow: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 16) {
            metricCard(title: "Inference Rate", value: String(format: "%.1f FPS", appState.currentFPS), icon: "gauge")
            metricCard(title: "Frame Latency", value: String(format: "%.1f ms", appState.currentInferenceMs), icon: "timer")
            metricCard(title: "Hand Presence", value: appState.primaryHand != nil ? "1 Hand Tracked" : "Searching...", icon: "hand.raised")
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "777777"))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "999999"))
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "171717"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}

/// Quick action triggers for recalibration and skeleton display.
public struct DashboardQuickActionsCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 16) {
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(hex: "171717"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Interactive practice pad for testing real-time gestures and click synthesis.
public struct DashboardPracticePadCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cursor Practice Pad")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Spacer()
                Text("Pinch to Click Target")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "777777"))
            }

            Button(action: {
                appState.practiceClickCount += 1
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                    Text("Practice Target (Clicked: \(appState.practiceClickCount))")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "171717"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
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
