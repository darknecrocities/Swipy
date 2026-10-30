import AppKit
import SwiftUI
import SwipyCore

/// Manages a system-level floating click-through NSPanel rendering the custom pointer HUD.
@MainActor
public final class PointerOverlayController: NSObject {
    public static let shared = PointerOverlayController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<PointerOverlayContainerView>?
    private let model = PointerViewModel()

    public override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        let overlaySize: CGFloat = 160
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: overlaySize, height: overlaySize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let rootView = PointerOverlayContainerView(model: model)
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = panel.contentView?.bounds ?? .zero
        panel.contentView = hosting

        self.panel = panel
        self.hostingView = hosting
    }

    /// Repositions the custom pointer HUD to follow smoothed cursor coordinates.
    public func update(
        cursorPoint: CGPoint,
        gesture: RecognizedGestureState,
        settings: PointerSettings,
        isTrackingActive: Bool
    ) {
        guard settings.isEnabled && isTrackingActive else {
            panel?.orderOut(nil)
            return
        }

        model.settings = settings
        model.activeGesture = gesture
        model.isPinched = isPinching(gesture)

        if case .leftClicked = gesture {
            model.triggerRipple()
        }

        if let panel = panel {
            let overlaySize: CGFloat = 160
            // Convert to Cocoa coordinates (bottom-left origin)
            let primaryHeight = NSScreen.main?.frame.height ?? 900
            let originX = cursorPoint.x - (overlaySize / 2.0)
            let originY = (primaryHeight - cursorPoint.y) - (overlaySize / 2.0)

            panel.setFrameOrigin(NSPoint(x: originX, y: originY))
            if !panel.isVisible {
                panel.orderFrontRegardless()
            }
        }
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    private func isPinching(_ gesture: RecognizedGestureState) -> Bool {
        switch gesture {
        case .pinchPending, .dragging, .zooming: return true
        default: return false
        }
    }
}

/// Observable state driving pointer animation frames.
@MainActor
public final class PointerViewModel: ObservableObject {
    @Published public var settings = PointerSettings()
    @Published public var activeGesture: RecognizedGestureState = .idle
    @Published public var isPinched = false
    @Published public var rippleScale: CGFloat = 1.0
    @Published public var rippleOpacity: Double = 0.0

    public init() {}

    public func triggerRipple() {
        rippleScale = 1.0
        rippleOpacity = 0.85
        withAnimation(.easeOut(duration: 0.32)) {
            self.rippleScale = 2.4
            self.rippleOpacity = 0.0
        }
    }
}

/// SwiftUI container hosting the dynamic pointer overlay.
struct PointerOverlayContainerView: View {
    @ObservedObject var model: PointerViewModel

    var body: some View {
        PointerOverlayView(model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
