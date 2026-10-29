import Foundation
import AVFoundation
import CoreVideo

/// High-performance AVFoundation camera capture engine.
public final class CameraManager: NSObject, CameraFrameProvider, @unchecked Sendable {
    public static let shared = CameraManager()

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.swipy.camera.session", qos: .userInitiated)
    private let outputQueue = DispatchQueue(label: "com.swipy.camera.output", qos: .userInteractive)
    private var videoOutput: AVCaptureVideoDataOutput?

    private var frameHandler: (@Sendable (CVPixelBuffer) -> Void)?
    private let lock = NSLock()
    private var _isRunning = false

    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isRunning
    }

    /// Provides access to the underlying AVCaptureSession for live video rendering layers.
    public var session: AVCaptureSession {
        captureSession
    }

    public override init() {
        super.init()
    }

    public func setFrameHandler(_ handler: @escaping @Sendable (CVPixelBuffer) -> Void) {
        lock.lock()
        self.frameHandler = handler
        lock.unlock()
    }

    /// Discovers preferred built-in FaceTime camera or standard external camera.
    public func discoverBestCamera() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external
            ],
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.first(where: { $0.position == .front }) ?? discovery.devices.first
    }

    /// Starts camera capture asynchronously.
    public func startCapture() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if self.captureSession.isRunning {
                    continuation.resume()
                    return
                }

                do {
                    try self.configureSession()
                    self.captureSession.startRunning()
                    self.lock.lock()
                    self._isRunning = self.captureSession.isRunning
                    self.lock.unlock()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .vga640x480

        // Clear existing inputs and outputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }

        guard let camera = discoverBestCamera() else {
            throw NSError(domain: "Swipy.CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera found."])
        }

        let input = try AVCaptureDeviceInput(device: camera)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.setSampleBufferDelegate(self, queue: outputQueue)

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            self.videoOutput = output
        }
    }

    /// Stops camera capture and powers down sensor.
    public func stopCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.lock.lock()
            self._isRunning = false
            self.lock.unlock()
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        lock.lock()
        let handler = self.frameHandler
        lock.unlock()

        handler?(pixelBuffer)
    }
}
