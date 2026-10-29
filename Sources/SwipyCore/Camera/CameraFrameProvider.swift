import Foundation
import CoreVideo

/// Protocol enabling decoupled camera frame capture and synthetic testing pipelines.
public protocol CameraFrameProvider: AnyObject, Sendable {
    var isRunning: Bool { get }
    func startCapture() async throws
    func stopCapture()
    func setFrameHandler(_ handler: @escaping @Sendable (CVPixelBuffer) -> Void)
}
