import SwiftUI
import AppKit
import AVFoundation
import SwipyCore

/// NSViewRepresentable hosting hardware-accelerated AVCaptureVideoPreviewLayer for live camera display.
public struct CameraVideoFeedView: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> CameraVideoPreviewNSView {
        let view = CameraVideoPreviewNSView()
        view.session = CameraManager.shared.session
        return view
    }

    public func updateNSView(_ nsView: CameraVideoPreviewNSView, context: Context) {
        nsView.session = CameraManager.shared.session
        nsView.applyMirroringIfNeeded()
    }
}

/// Custom AppKit view hosting an AVCaptureVideoPreviewLayer with horizontal mirroring.
public final class CameraVideoPreviewNSView: NSView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public var session: AVCaptureSession? {
        didSet {
            guard let session = session else {
                previewLayer?.session = nil
                return
            }
            if let existing = previewLayer {
                existing.session = session
            } else {
                setupLayer(with: session)
            }
        }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }

    private func setupLayer(with session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer = layer
        self.previewLayer = layer
        applyMirroringIfNeeded()
    }

    public func applyMirroringIfNeeded() {
        if let connection = previewLayer?.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    public override func layout() {
        super.layout()
        previewLayer?.frame = bounds
        applyMirroringIfNeeded()
    }
}
