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
                    FloatingAppSwitcherView(isPresented: $appState.showFloatingAppSwitcher)
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }

    private var sidebarView: some View {
        List(NavigationSection.allCases, selection: $appState.selectedNav) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("Swipy")
        .frame(minWidth: 180)
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
