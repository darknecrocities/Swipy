import Foundation

/// Interaction style for mapping hand motion to cursor coordinates.
public enum TrackingMode: String, Codable, CaseIterable, Sendable {
    case trackpad = "Virtual Trackpad (Relative)"
    case directPointer = "Direct Pointer (Absolute)"
}

/// Core persistent configuration model for Swipy.
public struct SwipySettings: Codable, Equatable, Sendable {
    // Master State
    public var isTrackingEnabled: Bool
    public var isPaused: Bool
    public var selectedProfileKind: ProfileKind

    // Cursor & Motion
    public var trackingMode: TrackingMode
    public var cursorSensitivity: Double
    public var isAdaptiveAcceleration: Bool
    public var smoothingMinCutoff: Double
    public var smoothingBeta: Double
    public var deadZoneRadius: Double
    public var activeRegionX: Double
    public var activeRegionY: Double
    public var activeRegionWidth: Double
    public var activeRegionHeight: Double

    // Pointer Customization
    public var pointer: PointerSettings

    // Mouse & Clicks
    public var pinchThreshold: Double
    public var dragDelayMs: Int
    public var doubleClickWindowMs: Int

    // Scrolling
    public var scrollSpeed: Double
    public var isNaturalScroll: Bool
    public var isHorizontalScrollEnabled: Bool

    // Navigation & Swipes
    public var swipeVelocityThreshold: Double
    public var swipeCooldownMs: Int
    public var useNativeAppSwitcher: Bool

    // UI & System
    public var launchAtLogin: Bool
    public var menuBarOnlyMode: Bool
    public var showCameraPreview: Bool
    public var showJointOverlay: Bool
    public var showDiagnosticsOverlay: Bool

    // Bindings
    public var bindings: [GestureBinding]

    public init(
        isTrackingEnabled: Bool = false,
        isPaused: Bool = false,
        selectedProfileKind: ProfileKind = .balanced,
        trackingMode: TrackingMode = .trackpad,
        cursorSensitivity: Double = 1.15,
        isAdaptiveAcceleration: Bool = true,
        smoothingMinCutoff: Double = 1.0,
        smoothingBeta: Double = 0.007,
        deadZoneRadius: Double = 0.003,
        activeRegionX: Double = 0.15,
        activeRegionY: Double = 0.15,
        activeRegionWidth: Double = 0.70,
        activeRegionHeight: Double = 0.70,
        pointer: PointerSettings = PointerSettings(),
        pinchThreshold: Double = 0.32,
        dragDelayMs: Int = 250,
        doubleClickWindowMs: Int = 380,
        scrollSpeed: Double = 1.0,
        isNaturalScroll: Bool = true,
        isHorizontalScrollEnabled: Bool = true,
        swipeVelocityThreshold: Double = 0.60,
        swipeCooldownMs: Int = 350,
        useNativeAppSwitcher: Bool = false,
        launchAtLogin: Bool = false,
        menuBarOnlyMode: Bool = false,
        showCameraPreview: Bool = false,
        showJointOverlay: Bool = true,
        showDiagnosticsOverlay: Bool = false,
        bindings: [GestureBinding] = SwipySettings.defaultBindings
    ) {
        self.isTrackingEnabled = isTrackingEnabled
        self.isPaused = isPaused
        self.selectedProfileKind = selectedProfileKind
        self.trackingMode = trackingMode
        self.cursorSensitivity = cursorSensitivity
        self.isAdaptiveAcceleration = isAdaptiveAcceleration
        self.smoothingMinCutoff = smoothingMinCutoff
        self.smoothingBeta = smoothingBeta
        self.deadZoneRadius = deadZoneRadius
        self.activeRegionX = activeRegionX
        self.activeRegionY = activeRegionY
        self.activeRegionWidth = activeRegionWidth
        self.activeRegionHeight = activeRegionHeight
        self.pointer = pointer
        self.pinchThreshold = pinchThreshold
        self.dragDelayMs = dragDelayMs
        self.doubleClickWindowMs = doubleClickWindowMs
        self.scrollSpeed = scrollSpeed
        self.isNaturalScroll = isNaturalScroll
        self.isHorizontalScrollEnabled = isHorizontalScrollEnabled
        self.swipeVelocityThreshold = swipeVelocityThreshold
        self.swipeCooldownMs = swipeCooldownMs
        self.useNativeAppSwitcher = useNativeAppSwitcher
        self.launchAtLogin = launchAtLogin
        self.menuBarOnlyMode = menuBarOnlyMode
        self.showCameraPreview = showCameraPreview
        self.showJointOverlay = showJointOverlay
        self.showDiagnosticsOverlay = showDiagnosticsOverlay
        self.bindings = bindings
    }

    /// Default bindings matching product identity specification.
    public static var defaultBindings: [GestureBinding] {
        [
            GestureBinding(gestureType: .indexPointing, category: .cursorAndClick, action: .none),
            GestureBinding(gestureType: .thumbIndexPinch, category: .cursorAndClick, action: .leftClick),
            GestureBinding(gestureType: .doublePinch, category: .cursorAndClick, action: .doubleClick),
            GestureBinding(gestureType: .thumbMiddlePinch, category: .cursorAndClick, action: .rightClick),
            GestureBinding(gestureType: .twoFingerScroll, category: .scrolling, action: .scroll),
            GestureBinding(gestureType: .threeFingerSwipeUp, category: .spaceNavigation, action: .missionControl),
            GestureBinding(gestureType: .threeFingerSwipeDown, category: .spaceNavigation, action: .showDesktop),
            GestureBinding(gestureType: .threeFingerSwipeLeft, category: .spaceNavigation, action: .previousSpace),
            GestureBinding(gestureType: .threeFingerSwipeRight, category: .spaceNavigation, action: .nextSpace),
            GestureBinding(gestureType: .fourFingerSwipeLeft, category: .appSwitching, action: .previousApplication),
            GestureBinding(gestureType: .fourFingerSwipeRight, category: .appSwitching, action: .nextApplication),
            GestureBinding(gestureType: .openPalmsPause, category: .safety, action: .toggleTrackingPause)
        ]
    }

    /// Applies a preset profile's tuning parameters.
    public mutating func applyProfile(_ profile: GestureProfile) {
        selectedProfileKind = profile.kind
        if profile.kind != .custom {
            cursorSensitivity = profile.cursorSensitivity
            smoothingMinCutoff = profile.smoothingMinCutoff
            smoothingBeta = profile.smoothingBeta
            scrollSpeed = profile.scrollSpeed
            pinchThreshold = profile.pinchThreshold
            dragDelayMs = profile.dragDelayMs
            swipeVelocityThreshold = profile.swipeVelocityThreshold
        }
    }

    /// Validates and sanitizes values into safe operational bounds.
    public mutating func sanitize() {
        cursorSensitivity = max(0.2, min(cursorSensitivity, 4.0))
        smoothingMinCutoff = max(0.1, min(smoothingMinCutoff, 5.0))
        smoothingBeta = max(0.0001, min(smoothingBeta, 0.1))
        deadZoneRadius = max(0.0, min(deadZoneRadius, 0.05))
        activeRegionX = max(0.0, min(activeRegionX, 0.5))
        activeRegionY = max(0.0, min(activeRegionY, 0.5))
        activeRegionWidth = max(0.3, min(activeRegionWidth, 1.0 - activeRegionX))
        activeRegionHeight = max(0.3, min(activeRegionHeight, 1.0 - activeRegionY))
        pinchThreshold = max(0.15, min(pinchThreshold, 0.50))
        dragDelayMs = max(100, min(dragDelayMs, 1000))
        doubleClickWindowMs = max(150, min(doubleClickWindowMs, 800))
        scrollSpeed = max(0.2, min(scrollSpeed, 4.0))
        swipeVelocityThreshold = max(0.3, min(swipeVelocityThreshold, 4.0))
        swipeCooldownMs = max(150, min(swipeCooldownMs, 1500))
        pointer.sanitize()
    }

    // Persistence key
    private static let userDefaultsKey = "com.swipy.settings.v1"

    /// Loads settings from standard UserDefaults with safe default fallback.
    public static func load() -> SwipySettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return SwipySettings()
        }
        do {
            var settings = try JSONDecoder().decode(SwipySettings.self, from: data)
            settings.sanitize()
            return settings
        } catch {
            return SwipySettings()
        }
    }

    /// Saves the current configuration to UserDefaults.
    public func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: SwipySettings.userDefaultsKey)
        } catch {
            // Silently retain in-memory state on persistence failure
        }
    }
}
