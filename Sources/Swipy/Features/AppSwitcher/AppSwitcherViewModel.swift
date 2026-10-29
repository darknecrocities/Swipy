import SwiftUI
import AppKit

/// View model tracking running applications for the gesture-controlled floating switcher.
@MainActor
public final class AppSwitcherViewModel: ObservableObject {
    @Published public var runningApps: [NSRunningApplication] = []
    @Published public var selectedIndex: Int = 0

    public init() {
        refreshRunningApps()
    }

    public func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        }
    }

    public func activate(app: NSRunningApplication) {
        app.activate()
    }
}
