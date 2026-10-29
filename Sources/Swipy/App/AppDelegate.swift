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
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            },
            onOpenCalibration: {
                appState.isCalibrating = true
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

    public func applicationWillTerminate(_ notification: Notification) {
        CameraManager.shared.stopCapture()
        MouseEventController.shared.safetyReleaseHeldButtons()
    }
}
