import SwiftUI
import SwipyCore

/// Advanced diagnostics, configuration export, and factory reset tools.
public struct SettingsAdvancedTab: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            actionCard(
                title: "First-Launch Onboarding Walkthrough",
                subtitle: "Re-opens the 7-screen interactive orientation guide.",
                buttonText: "Launch Onboarding"
            ) {
                appState.isOnboardingPresented = true
            }

            actionCard(
                title: "Reset Smoothing Filters",
                subtitle: "Clears One Euro velocity history and resets jitter cutoffs.",
                buttonText: "Reset Filters"
            ) {
                GestureRecognizer.shared.smoother.reset()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Factory Defaults")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.red)
                Text("Restores all gesture bindings, sensitivities, and pointer styles back to factory initial state.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "777777"))

                Button(action: {
                    appState.settings = SwipySettings()
                    appState.settings.save()
                }) {
                    Text("Reset All Settings to Factory Defaults")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "FFF1F0"))
                        .foregroundColor(Color.red)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
    }

    private func actionCard(title: String, subtitle: String, buttonText: String, action: @escaping () -> Void) -> some View {
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
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "171717"))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}
