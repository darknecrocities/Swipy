import SwiftUI
import SwipyCore

/// Privacy guarantees and real-time macOS system permission status cards.
public struct SettingsPrivacyTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            permissionCard(
                title: "Camera Access",
                subtitle: "Required for on-device Apple Vision hand pose detection.",
                isGranted: appState.isCameraAuthorized,
                onOpen: { CameraPermissionManager.shared.openSystemSettingsCameraPrivacy() },
                onRefresh: { appState.refreshPermissions() }
            )

            permissionCard(
                title: "Accessibility Trust",
                subtitle: "Required by Core Graphics to move the macOS system cursor and click across apps.",
                isGranted: appState.isAccessibilityTrusted,
                onOpen: { AccessibilityPermissionManager.shared.openAccessibilitySettings() },
                onRefresh: { appState.refreshPermissions() }
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Zero Data Retention Guarantee")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text("Swipy operates 100% locally on your Mac. Video frames captured by your camera are analyzed entirely in volatile RAM via Apple Vision and discarded immediately after joint detection. Zero photos, video frames, or biometric patterns are stored or transmitted.")
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

    private func permissionCard(
        title: String,
        subtitle: String,
        isGranted: Bool,
        onOpen: @escaping () -> Void,
        onRefresh: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(isGranted ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isGranted ? "Authorized" : "Required")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isGranted ? Color.green : Color.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isGranted ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
                .cornerRadius(6)
            }

            HStack(spacing: 8) {
                Button(action: onOpen) {
                    Text("Open System Settings")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "171717"))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: onRefresh) {
                    Text("Refresh Status")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "171717"))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}
