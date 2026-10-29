import Foundation

/// Supported pointer HUD / cursor visualization styles.
public enum CustomPointerStyle: String, Codable, CaseIterable, Sendable {
    case visionProRing = "Vision Pro Ring"
    case glowHalo = "Glow Halo"
    case laserDot = "Laser Dot"
    case crosshair = "Precision Crosshair"
}

/// Color theme palettes for custom pointer styling.
public enum PointerTheme: String, Codable, CaseIterable, Sendable {
    case pureWhite = "Pure White"
    case electricCyan = "Electric Cyan"
    case appleMint = "Apple Mint"
    case sunsetOrange = "Sunset Orange"
    case obsidian = "Obsidian"

    public var hexColor: String {
        switch self {
        case .pureWhite: return "FFFFFF"
        case .electricCyan: return "00E5FF"
        case .appleMint: return "30D158"
        case .sunsetOrange: return "FF9500"
        case .obsidian: return "171717"
        }
    }
}

/// Persistent configuration model for the customizable on-screen pointer overlay.
public struct PointerSettings: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var style: CustomPointerStyle
    public var theme: PointerTheme
    public var size: Double
    public var showClickRipple: Bool
    public var showMotionTrail: Bool
    public var opacity: Double

    public init(
        isEnabled: Bool = true,
        style: CustomPointerStyle = .visionProRing,
        theme: PointerTheme = .pureWhite,
        size: Double = 28.0,
        showClickRipple: Bool = true,
        showMotionTrail: Bool = false,
        opacity: Double = 0.85
    ) {
        self.isEnabled = isEnabled
        self.style = style
        self.theme = theme
        self.size = size
        self.showClickRipple = showClickRipple
        self.showMotionTrail = showMotionTrail
        self.opacity = opacity
    }

    public mutating func sanitize() {
        size = max(16.0, min(size, 64.0))
        opacity = max(0.2, min(opacity, 1.0))
    }
}
