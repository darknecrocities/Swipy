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
                    case "Cursor":
                        SettingsCursorTab(appState: appState)
                    case "Pointer":
                        SettingsPointerTab(appState: appState)
                    case "Gestures":
                        SettingsGesturesTab(appState: appState)
                    case "Scrolling":
                        SettingsScrollingTab(appState: appState)
                    case "System":
                        SettingsSystemTab(appState: appState)
                    case "Privacy":
                        SettingsPrivacyTab(appState: appState)
                    default:
                        SettingsAdvancedTab(appState: appState)
                    }
                }
                .padding(28)
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
        .padding(.horizontal, 28)
        .padding(.top, 14)
    }
}
