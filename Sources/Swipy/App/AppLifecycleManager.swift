import Foundation
import SwiftUI
import AppKit
import CoreVideo
import SwipyCore

public enum NavigationSection: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "Overview"
    case gestures = "Gestures"
    case settings = "Settings"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .dashboard: return "macwindow"
        case .gestures: return "hand.point.up.left"
        case .settings: return "gearshape"
        }
    }
}

/// Thread-safe container synchronizing settings access across background capture queues.
private final class SettingsHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var value: SwipySettings

    init(value: SwipySettings) {
        self.value = value
    }

    func get() -> SwipySettings {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: SwipySettings) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
}

/// Central observable manager coordinating the camera, vision pipeline, gesture engine, and UI state.
@MainActor
public final class AppLifecycleManager: ObservableObject {
    public static let shared = AppLifecycleManager()

    @Published public var settings: SwipySettings
    @Published public var trackingState: TrackingState = .ready
    @Published public var currentFPS: Double = 0.0
    @Published public var currentInferenceMs: Double = 0.0
    @Published public var primaryHand: HandSkeleton?
    @Published public var activeGesture: RecognizedGestureState = .idle
    @Published public var isCameraAuthorized: Bool = false
    @Published public var isAccessibilityTrusted: Bool = false
    @Published public var isAccessibilityBannerDismissed: Bool = false
    @Published public var isCalibrating: Bool = false
    @Published public var showFloatingAppSwitcher: Bool = false
    @Published public var isOnboardingPresented: Bool = false
    @Published public var selectedNav: NavigationSection = .dashboard
    @Published public var practiceClickCount: Int = 0

    public weak var mainWindow: NSWindow?

    private let cameraManager = CameraManager.shared
    private let visionService = HandPoseService()
    private let gestureRecognizer = GestureRecognizer.shared
    private var telemetryTimer: Timer?
    private let settingsHolder: SettingsHolder
    private var trackingActivityToken: NSObjectProtocol?

    public init() {
        let initialSettings = SwipySettings.load()
        self.settings = initialSettings
        self.settingsHolder = SettingsHolder(value: initialSettings)
        self.isCameraAuthorized = CameraPermissionManager.shared.isAuthorized
        self.isAccessibilityTrusted = AccessibilityPermissionManager.shared.isTrusted

        setupSystemActionBindings()
        setupCameraPipeline()
        startTelemetryTimer()
        setupAppActivationObserver()
        AppUpdateManager.shared.startAutomaticUpdateChecks()
    }

    private func setupAppActivationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPermissions()
            }
        }
    }

    private func setupSystemActionBindings() {
        SystemActionController.shared.onToggleAppSwitcher = { [weak self] in
            Task { @MainActor in
                self?.showFloatingAppSwitcher.toggle()
            }
        }
    }

    private func setupCameraPipeline() {
        cameraManager.setFrameHandler { [weak self] pixelBuffer in
            guard let self = self else { return }
            self.processFrame(pixelBuffer)
        }

        gestureRecognizer.onCursorUpdate = { [weak self] point, gesture in
            guard let self = self else { return }
            let s = self.currentSettings()
            Task { @MainActor in
                PointerOverlayController.shared.update(
                    cursorPoint: point,
                    gesture: gesture,
                    settings: s.pointer,
                    isTrackingActive: s.isTrackingEnabled && !s.isPaused
                )
            }
        }
    }

    nonisolated private func currentSettings() -> SwipySettings {
        settingsHolder.get()
    }

    private func updateCachedSettings(_ newSettings: SwipySettings) {
        settingsHolder.set(newSettings)
    }

    nonisolated private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let pose = visionService.processPixelBuffer(pixelBuffer) else {
            DiagnosticsLogger.shared.recordDroppedFrame()
            return
        }

        DiagnosticsLogger.shared.recordInference(
            durationMs: pose.inferenceDurationMs,
            timestamp: pose.timestamp
        )

        let displayFrame = CursorController.shared.primaryDisplayFrame()
        gestureRecognizer.process(
            pose: pose,
            settings: currentSettings(),
            displayFrame: displayFrame
        )

        let gesture = gestureRecognizer.activeState

        Task { @MainActor in
            self.primaryHand = pose.primaryHand
            self.trackingState = pose.state
            self.activeGesture = gesture
        }
    }

    /// Toggles master gesture tracking.
    public func toggleTracking() {
        settings.isTrackingEnabled.toggle()
        settings.save()
        updateCachedSettings(settings)

        if settings.isTrackingEnabled {
            startTrackingSession()
        } else {
            stopTrackingSession()
        }
    }

    /// Toggles pause state.
    public func togglePause() {
        settings.isPaused.toggle()
        settings.save()
        updateCachedSettings(settings)
        if settings.isPaused {
            MouseEventController.shared.safetyReleaseHeldButtons()
            PointerOverlayController.shared.hide()
            trackingState = .paused
        } else {
            trackingState = .tracking
        }
    }

    public func startTrackingSession() {
        if trackingActivityToken == nil {
            trackingActivityToken = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .latencyCritical],
                reason: "Swipy Real-time Gesture Tracking"
            )
        }
        Task {
            let cameraOk = await CameraPermissionManager.shared.requestAccess()
            self.isCameraAuthorized = cameraOk
            self.isAccessibilityTrusted = AccessibilityPermissionManager.shared.isTrusted

            guard cameraOk else {
                self.trackingState = .permissionRequired
                return
            }

            do {
                try await cameraManager.startCapture()
                self.trackingState = .tracking
            } catch {
                self.trackingState = .error
            }
        }
    }

    public func stopTrackingSession() {
        if let token = trackingActivityToken {
            ProcessInfo.processInfo.endActivity(token)
            trackingActivityToken = nil
        }
        cameraManager.stopCapture()
        visionService.resetSequence()
        MouseEventController.shared.safetyReleaseHeldButtons()
        PointerOverlayController.shared.hide()
        trackingState = .ready
        primaryHand = nil
        activeGesture = .idle
    }

    /// Polls and updates current system privacy permissions in real time.
    @MainActor
    public func refreshPermissions() {
        let cameraOk = CameraPermissionManager.shared.isAuthorized
        let accessibilityOk = AccessibilityPermissionManager.shared.isTrusted

        self.isCameraAuthorized = cameraOk
        self.isAccessibilityTrusted = accessibilityOk

        // Automatically start or recover tracking session if user enabled it and permissions just cleared
        if cameraOk && accessibilityOk && settings.isTrackingEnabled && !settings.isPaused && trackingState != .tracking {
            startTrackingSession()
        }
    }

    private func startTelemetryTimer() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.refreshPermissions()
                self.currentFPS = DiagnosticsLogger.shared.currentFPS
                self.currentInferenceMs = DiagnosticsLogger.shared.averageInferenceMs
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.telemetryTimer = timer
    }

    /// Applies and persists a new profile preset.
    public func applyProfile(_ profile: GestureProfile) {
        settings.applyProfile(profile)
        settings.save()
        updateCachedSettings(settings)
    }

    /// Restores, activates, and presents the main Dashboard window.
    public func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        selectedNav = .dashboard
        if let window = mainWindow ?? NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
            window.setIsVisible(true)
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    /// Restores the main window and launches the bounds calibration sheet.
    public func openCalibration() {
        openDashboard()
        isCalibrating = true
    }
}
