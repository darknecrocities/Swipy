import AppKit
import SwiftUI
import SwipyCore

/// Manages the native macOS menu bar status item and its interactive popover.
@MainActor
public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    public override init() {
        super.init()
    }

    /// Initializes and mounts the menu bar item.
    public func setupStatusItem(
        appState: AppLifecycleManager,
        onOpenDashboard: @escaping () -> Void,
        onOpenCalibration: @escaping () -> Void
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "hand.point.up.left",
                accessibilityDescription: "Swipy"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(
                appState: appState,
                onOpenDashboard: { [weak self] in
                    self?.popover?.performClose(nil)
                    onOpenDashboard()
                },
                onOpenCalibration: { [weak self] in
                    self?.popover?.performClose(nil)
                    onOpenCalibration()
                }
            )
        )
        self.popover = popover
    }

    /// Updates status bar button icon depending on tracking state.
    public func updateIcon(for state: TrackingState) {
        guard let button = statusItem?.button else { return }
        let symbolName: String
        switch state {
        case .tracking:
            symbolName = "hand.point.up.left.fill"
        case .paused:
            symbolName = "pause.circle"
        case .permissionRequired, .accessibilityRequired, .error:
            symbolName = "exclamationmark.triangle"
        default:
            symbolName = "hand.point.up.left"
        }
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Swipy")
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
