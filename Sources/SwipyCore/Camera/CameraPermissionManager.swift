import Foundation
import AVFoundation
import AppKit

/// Manages camera permission queries and prompts following macOS security guidelines.
public final class CameraPermissionManager: @unchecked Sendable {
    public static let shared = CameraPermissionManager()

    public init() {}

    /// Current camera authorization status.
    public var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Whether the application currently holds camera access.
    public var isAuthorized: Bool {
        status == .authorized
    }

    /// Asynchronously requests camera authorization from the user.
    public func requestAccess() async -> Bool {
        let current = status
        if current == .authorized { return true }
        if current == .denied || current == .restricted { return false }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Opens the macOS System Settings Camera Privacy pane.
    public func openSystemSettingsCameraPrivacy() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Prompts system authorization dialog if not determined; opens System Settings if denied.
    @discardableResult
    public func promptOrOpenSettings() async -> Bool {
        let current = status
        if current == .notDetermined {
            let granted = await requestAccess()
            if granted {
                return true
            }
        }
        openSystemSettingsCameraPrivacy()
        return false
    }
}
