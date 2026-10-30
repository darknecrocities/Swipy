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

    /// Persisted-settings schema version. `nil` means the data predates versioning and needs migration.
    public var schemaVersion: Int?

    /// Bumped whenever previously saved values must be re-derived from current defaults.
    public static let currentSchemaVersion = 3

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
        swipeVelocityThreshold: Double = 0.55,
        swipeCooldownMs: Int = 350,
        useNativeAppSwitcher: Bool = false,
        launchAtLogin: Bool = false,
        menuBarOnlyMode: Bool = false,
        showCameraPreview: Bool = false,
        showJointOverlay: Bool = true,
        showDiagnosticsOverlay: Bool = false,
        bindings: [GestureBinding] = SwipySettings.defaultBindings,
        schemaVersion: Int? = SwipySettings.currentSchemaVersion
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
        self.schemaVersion = schemaVersion
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
            GestureBinding(gestureType: .threeFingerSwipeLeft, category: .spaceNavigation, action: .nextSpace),
            GestureBinding(gestureType: .threeFingerSwipeRight, category: .spaceNavigation, action: .previousSpace),
            GestureBinding(gestureType: .fourFingerSwipeLeft, category: .appSwitching, action: .nextSpace),
            GestureBinding(gestureType: .fourFingerSwipeRight, category: .appSwitching, action: .previousSpace),
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

    /// Re-derives values that older builds persisted from defaults that are now known to be unusable.
    ///
    /// v2: `swipeVelocityThreshold` was saved as 1.8 (a hand speed few people reach), `pinchThreshold` was
    /// clamped to an unintended 0.15, and the 3/4-finger left/right bindings advertised actions the engine
    /// never performed. Defaults only apply to fresh installs, so existing users must be migrated explicitly.
    public mutating func migrateIfNeeded() {
        guard (schemaVersion ?? 1) < Self.currentSchemaVersion || swipeVelocityThreshold > 0.8 else { return }

        if let preset = Self.preset(for: selectedProfileKind) {
            swipeVelocityThreshold = preset.swipeVelocityThreshold
            pinchThreshold = preset.pinchThreshold
        } else {
            swipeVelocityThreshold = min(swipeVelocityThreshold, 0.65)
        }

        let swipeDefaults = Dictionary(uniqueKeysWithValues: Self.defaultBindings.map { ($0.gestureType, $0.action) })
        let swipeTypes: Set<GestureType> = [
            .threeFingerSwipeLeft, .threeFingerSwipeRight, .fourFingerSwipeLeft, .fourFingerSwipeRight
        ]
        for index in bindings.indices where swipeTypes.contains(bindings[index].gestureType) {
            if let action = swipeDefaults[bindings[index].gestureType] {
                bindings[index].action = action
            }
        }
        schemaVersion = Self.currentSchemaVersion
    }

    private static func preset(for kind: ProfileKind) -> GestureProfile? {
        switch kind {
        case .balanced: return .balanced
        case .precision: return .precision
        case .fast: return .fast
        case .presentation: return .presentation
        case .custom: return nil
        }
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
            let needsMigration = (settings.schemaVersion ?? 1) < SwipySettings.currentSchemaVersion
            settings.migrateIfNeeded()
            settings.sanitize()
            if needsMigration { settings.save() }
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
