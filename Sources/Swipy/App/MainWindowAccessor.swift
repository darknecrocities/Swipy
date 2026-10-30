import AppKit
import SwiftUI

/// Hooks the primary application NSWindow and attaches a lifecycle delegate preventing window destruction on close.
public struct MainWindowAccessor: NSViewRepresentable {
    public let onWindowAttached: (NSWindow) -> Void

    public init(onWindowAttached: @escaping (NSWindow) -> Void) {
        self.onWindowAttached = onWindowAttached
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            // Ensure window delegates hide on close instead of destroying
            if window.delegate == nil {
                let delegate = MainWindowDelegate.shared
                window.delegate = delegate
            }
            window.isReleasedWhenClosed = false
            self.onWindowAttached(window)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Window delegate that hides the dashboard window on red close button press instead of deallocating it.
@MainActor
public final class MainWindowDelegate: NSObject, NSWindowDelegate {
    public static let shared = MainWindowDelegate()

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
