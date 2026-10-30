import Foundation

/// Preset configuration profiles tailored for distinct usage scenarios.
public enum ProfileKind: String, Codable, CaseIterable, Sendable {
    case balanced = "Balanced"
    case precision = "Precision"
    case fast = "Fast"
    case presentation = "Presentation"
    case custom = "Custom"
}

/// Parameters bundled into a selectable gesture profile.
public struct GestureProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: String { kind.rawValue }
    public var kind: ProfileKind
    public var description: String
    public var cursorSensitivity: Double
    public var smoothingMinCutoff: Double
    public var smoothingBeta: Double
    public var scrollSpeed: Double
    public var pinchThreshold: Double
    public var dragDelayMs: Int
    public var swipeVelocityThreshold: Double

    public init(
        kind: ProfileKind,
        description: String,
        cursorSensitivity: Double,
        smoothingMinCutoff: Double,
        smoothingBeta: Double,
        scrollSpeed: Double,
        pinchThreshold: Double = 0.32,
        dragDelayMs: Int = 260,
        swipeVelocityThreshold: Double = 0.60
    ) {
        self.kind = kind
        self.description = description
        self.cursorSensitivity = cursorSensitivity
        self.smoothingMinCutoff = smoothingMinCutoff
        self.smoothingBeta = smoothingBeta
        self.scrollSpeed = scrollSpeed
        self.pinchThreshold = pinchThreshold
        self.dragDelayMs = dragDelayMs
        self.swipeVelocityThreshold = swipeVelocityThreshold
    }

    /// Standard preset profiles.
    public static let balanced = GestureProfile(
        kind: .balanced,
        description: "Optimal balance of precision and fluid responsiveness for everyday use.",
        cursorSensitivity: 1.15,
        smoothingMinCutoff: 1.0,
        smoothingBeta: 0.007,
        scrollSpeed: 1.0,
        pinchThreshold: 0.32,
        dragDelayMs: 250,
        swipeVelocityThreshold: 0.60
    )

    public static let precision = GestureProfile(
        kind: .precision,
        description: "Higher jitter reduction and relaxed speed for detailed point-and-click work.",
        cursorSensitivity: 0.85,
        smoothingMinCutoff: 0.6,
        smoothingBeta: 0.003,
        scrollSpeed: 0.75,
        pinchThreshold: 0.28,
        dragDelayMs: 320,
        swipeVelocityThreshold: 0.75
    )

    public static let fast = GestureProfile(
        kind: .fast,
        description: "Aggressive responsiveness and minimal smoothing for fast screen sweeps.",
        cursorSensitivity: 1.60,
        smoothingMinCutoff: 1.5,
        smoothingBeta: 0.015,
        scrollSpeed: 1.4,
        pinchThreshold: 0.35,
        dragDelayMs: 200,
        swipeVelocityThreshold: 0.50
    )

    public static let presentation = GestureProfile(
        kind: .presentation,
        description: "Prioritizes high-confidence navigation and macro gestures with safe margins.",
        cursorSensitivity: 1.0,
        smoothingMinCutoff: 1.2,
        smoothingBeta: 0.005,
        scrollSpeed: 0.9,
        pinchThreshold: 0.30,
        dragDelayMs: 350,
        swipeVelocityThreshold: 0.55
    )
}
