import SwiftUI
import SwipyCore

/// System settings and parameter tuning interface.
public struct SettingsView: View {
    @ObservedObject var appState: AppLifecycleManager
    @StateObject private var viewModel = SettingsViewModel()

    private let tabs = ["Cursor", "Pointer", "Gestures", "Scrolling", "System", "Privacy", "Advanced"]

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            tabPicker
            Divider().background(Color(hex: "EAEAEA"))
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.selectedTab {
                    case "Cursor": cursorSettings
                    case "Pointer": pointerSettings
                    case "Gestures": gestureSettings
                    case "Scrolling": scrollingSettings
                    case "System": systemSettings
                    case "Privacy": privacySettings
                    default: advancedSettings
                    }
                }
                .padding(32)
            }
        }
        .background(Color.white)
    }

    private var tabPicker: some View {
        HStack(spacing: 20) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: { viewModel.selectedTab = tab }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.system(size: 13, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedTab == tab ? Color(hex: "171717") : Color(hex: "777777"))
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? Color(hex: "171717") : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
    }

    private var cursorSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingSlider(title: "Cursor Sensitivity", value: $appState.settings.cursorSensitivity, range: 0.2...4.0, step: 0.05, unit: "x")
            Toggle("Adaptive Acceleration (Precision slow control, rapid screen traversal)", isOn: $appState.settings.isAdaptiveAcceleration)
                .onChange(of: appState.settings.isAdaptiveAcceleration) { appState.settings.save() }
            settingSlider(title: "Smoothing Jitter Cutoff", value: $appState.settings.smoothingMinCutoff, range: 0.2...3.0, step: 0.1, unit: " Hz")
            settingSlider(title: "Smoothing Responsiveness Beta", value: $appState.settings.smoothingBeta, range: 0.001...0.03, step: 0.001, unit: "")
            settingSlider(title: "Dead Zone Margin", value: $appState.settings.deadZoneRadius, range: 0.0...0.02, step: 0.001, unit: "")
        }
    }

    private var pointerSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable Floating Pointer Overlay HUD", isOn: $appState.settings.pointer.isEnabled)
                .onChange(of: appState.settings.pointer.isEnabled) { appState.settings.save() }

            if appState.settings.pointer.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pointer Style")
                        .font(.system(size: 13, weight: .medium))
                    HStack(spacing: 8) {
                        ForEach(CustomPointerStyle.allCases, id: \.self) { style in
                            pointerStyleButton(style: style)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Palette")
                        .font(.system(size: 13, weight: .medium))
                    HStack(spacing: 8) {
                        ForEach(PointerTheme.allCases, id: \.self) { theme in
                            pointerThemeButton(theme: theme)
                        }
                    }
                }

                settingSlider(title: "Pointer Size", value: $appState.settings.pointer.size, range: 16...56, step: 2, unit: "px")
                settingSlider(title: "Pointer Opacity", value: $appState.settings.pointer.opacity, range: 0.3...1.0, step: 0.05, unit: "")

                Toggle("Animated Pinch Contraction & Click Ripple", isOn: $appState.settings.pointer.showClickRipple)
                    .onChange(of: appState.settings.pointer.showClickRipple) { appState.settings.save() }
            }
        }
    }

    private func pointerStyleButton(style: CustomPointerStyle) -> some View {
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

    private func pointerThemeButton(theme: PointerTheme) -> some View {
        Button(action: {
            appState.settings.pointer.theme = theme
            appState.settings.save()
        }) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: theme.hexColor)).frame(width: 10, height: 10)
                Text(theme.rawValue).font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.settings.pointer.theme == theme ? Color(hex: "171717") : Color(hex: "FAFAFA"))
            .foregroundColor(appState.settings.pointer.theme == theme ? .white : Color(hex: "777777"))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var gestureSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingSlider(title: "Pinch Activation Distance", value: $appState.settings.pinchThreshold, range: 0.02...0.08, step: 0.002, unit: "")
            settingIntSlider(title: "Drag Delay", value: $appState.settings.dragDelayMs, range: 150...500, step: 25, unit: " ms")
            settingIntSlider(title: "Double Click Window", value: $appState.settings.doubleClickWindowMs, range: 200...600, step: 20, unit: " ms")
        }
    }

    private var scrollingSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingSlider(title: "Scroll Velocity", value: $appState.settings.scrollSpeed, range: 0.4...3.0, step: 0.1, unit: "x")
            Toggle("Natural Scrolling Direction", isOn: $appState.settings.isNaturalScroll)
                .onChange(of: appState.settings.isNaturalScroll) { appState.settings.save() }
            Toggle("Horizontal Scrolling Support", isOn: $appState.settings.isHorizontalScrollEnabled)
                .onChange(of: appState.settings.isHorizontalScrollEnabled) { appState.settings.save() }
        }
    }

    private var systemSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Launch at Login", isOn: $appState.settings.launchAtLogin)
            Toggle("Menu Bar Only Mode", isOn: $appState.settings.menuBarOnlyMode)
            Toggle("Use Native Command+Tab for App Switcher", isOn: $appState.settings.useNativeAppSwitcher)
        }
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Guarantee")
                .font(.system(size: 15, weight: .semibold))
            Text("Swipy operates 100% locally on your Mac. Video frames from your camera are processed entirely in memory via Apple Vision and discarded immediately after landmark extraction. Zero images or biometric data are recorded, stored, or transmitted over the network.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .lineSpacing(4)
        }
    }

    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Reset All Settings to Factory Defaults") {
                appState.settings = SwipySettings()
                appState.settings.save()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "FFF1F0"))
            .foregroundColor(Color.red)
            .cornerRadius(8)
        }
    }

    private func settingSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer()
                Text(String(format: "%.3f%@", value.wrappedValue, unit))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "777777"))
            }
            Slider(value: value, in: range, step: step)
                .onChange(of: value.wrappedValue) { appState.settings.save() }
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
    }

    private func settingIntSlider(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(value.wrappedValue)\(unit)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "777777"))
            }
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
            .onChange(of: value.wrappedValue) { appState.settings.save() }
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
    }
}
