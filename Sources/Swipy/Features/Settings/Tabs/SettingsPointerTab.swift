import SwiftUI
import SwipyCore

/// Pointer HUD reticle customization tab featuring the live interactive studio preview.
public struct SettingsPointerTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Live Interactive Preview Canvas
            PointerStudioPreview(appState: appState)

            SettingsToggleRow(
                title: "Enable Floating Pointer Overlay HUD",
                subtitle: "Projects a system-level hardware reticle over apps following your index finger.",
                isOn: $appState.settings.pointer.isEnabled,
                onCommit: { appState.settings.save() }
            )

            if appState.settings.pointer.isEnabled {
                styleSection
                themeSection

                SettingsSliderRow(
                    title: "Pointer Size",
                    subtitle: "Physical pixel diameter of the reticle glyph.",
                    value: $appState.settings.pointer.size,
                    range: 16...56,
                    step: 2,
                    format: "%.0f",
                    unit: " px",
                    onCommit: { appState.settings.save() }
                )

                SettingsSliderRow(
                    title: "Pointer Opacity",
                    subtitle: "Translucency level of the floating HUD reticle.",
                    value: $appState.settings.pointer.opacity,
                    range: 0.3...1.0,
                    step: 0.05,
                    format: "%.0f%%",
                    unit: "",
                    onCommit: { appState.settings.save() }
                )

                SettingsToggleRow(
                    title: "Pinch Contraction & Click Ripple Pulse",
                    subtitle: "Visual spring compression on pinch and expanding ring pulse on mouse click.",
                    isOn: $appState.settings.pointer.showClickRipple,
                    onCommit: { appState.settings.save() }
                )
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reticle Style")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "171717"))

            HStack(spacing: 8) {
                ForEach(CustomPointerStyle.allCases, id: \.self) { style in
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
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Palette")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "171717"))

            HStack(spacing: 8) {
                ForEach(PointerTheme.allCases, id: \.self) { theme in
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
            }
        }
    }
}
