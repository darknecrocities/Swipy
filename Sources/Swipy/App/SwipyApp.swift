import SwiftUI
import AppKit
import SwipyCore

@main
struct SwipyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppLifecycleManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                sidebarView
            } detail: {
                detailView
            }
            .frame(minWidth: 840, minHeight: 580)
            .sheet(isPresented: $appState.isOnboardingPresented) {
                OnboardingView(appState: appState, isPresented: $appState.isOnboardingPresented)
            }
            .sheet(isPresented: $appState.isCalibrating) {
                CalibrationView(appState: appState, isPresented: $appState.isCalibrating)
            }
            .overlay(alignment: .bottomTrailing) {
                if appState.settings.showCameraPreview {
                    CameraPreviewView(appState: appState)
                        .frame(width: 300)
                        .padding(24)
                }
            }
            .overlay {
                if appState.showFloatingAppSwitcher {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                            .onTapGesture {
                                appState.showFloatingAppSwitcher = false
                            }
                        FloatingAppSwitcherView(isPresented: $appState.showFloatingAppSwitcher)
                    }
                    .transition(.opacity)
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                SwipyLogoView(size: 26, showShadow: true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Swipy")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("v1.0.0")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "999999"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().background(Color(hex: "F0F0F0"))

            List(NavigationSection.allCases, selection: $appState.selectedNav) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .font(.system(size: 13, weight: .medium))
                    .tag(section)
            }
            .listStyle(.sidebar)

            Spacer()

            sidebarStatusFooter
        }
        .frame(minWidth: 200)
    }

    private var sidebarStatusFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.settings.isTrackingEnabled ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(appState.settings.isTrackingEnabled ? "Tracking Active" : "Paused")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "777777"))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "FAFAFA"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "F0F0F0")), alignment: .top)
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNav {
        case .dashboard:
            DashboardView(appState: appState)
        case .gestures:
            GestureLibraryView(appState: appState)
        case .settings:
            SettingsView(appState: appState)
        }
    }
}
