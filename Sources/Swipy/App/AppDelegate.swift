import AppKit
import SwiftUI
import SwipyCore

/// Application lifecycle delegate handling status item setup and system termination safety.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppLifecycleManager.shared

        MenuBarController.shared.setupStatusItem(
            appState: appState,
            onOpenDashboard: {
                appState.openDashboard()
            },
            onOpenCalibration: {
                appState.openCalibration()
            }
        )

        // Global hotkey monitor for Emergency Stop (Option + Escape)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.option) && event.keyCode == 53 { // 53 = Escape
                Task { @MainActor in
                    AppLifecycleManager.shared.togglePause()
                }
            }
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppLifecycleManager.shared.openDashboard()
        return true
    }

    public func applicationWillTerminate(_ notification: Notification) {
        CameraManager.shared.stopCapture()
        MouseEventController.shared.safetyReleaseHeldButtons()
    }
}
