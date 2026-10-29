import SwiftUI
import SwipyCore

/// Custom interactive on-screen pointer HUD rendering selected styles and click animations.
public struct PointerOverlayView: View {
    @ObservedObject public var model: PointerViewModel

    public init(model: PointerViewModel) {
        self.model = model
    }

    private var themeColor: Color {
        Color(hex: model.settings.theme.hexColor)
    }

    public var body: some View {
        ZStack {
            // Click Ripple Pulse
            if model.settings.showClickRipple {
                Circle()
                    .stroke(themeColor, lineWidth: 2)
                    .frame(
                        width: model.settings.size * model.rippleScale,
                        height: model.settings.size * model.rippleScale
                    )
                    .opacity(model.rippleOpacity)
            }

            // Main Pointer Glyphs
            switch model.settings.style {
            case .visionProRing:
                visionProRing
            case .glowHalo:
                glowHalo
            case .laserDot:
                laserDot
            case .crosshair:
                precisionCrosshair
            }
        }
        .frame(width: model.settings.size * 2.5, height: model.settings.size * 2.5)
        .opacity(model.settings.opacity)
        .scaleEffect(model.isPinched ? 0.78 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: model.isPinched)
    }

    private var visionProRing: some View {
        ZStack {
            Circle()
                .stroke(themeColor.opacity(0.85), lineWidth: 2.2)
                .frame(width: model.settings.size, height: model.settings.size)
                .background(Circle().fill(Color.white.opacity(0.12)))
                .shadow(color: themeColor.opacity(0.35), radius: 4, x: 0, y: 0)

            Circle()
                .fill(themeColor)
                .frame(width: model.settings.size * 0.28, height: model.settings.size * 0.28)
        }
    }

    private var glowHalo: some View {
        ZStack {
            Circle()
                .fill(themeColor.opacity(0.35))
                .frame(width: model.settings.size * 1.4, height: model.settings.size * 1.4)
                .blur(radius: 6)

            Circle()
                .fill(themeColor)
                .frame(width: model.settings.size * 0.45, height: model.settings.size * 0.45)
        }
    }

    private var laserDot: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 1.2)
                .frame(width: model.settings.size * 0.65, height: model.settings.size * 0.65)

            Circle()
                .fill(themeColor)
                .frame(width: model.settings.size * 0.45, height: model.settings.size * 0.45)
        }
    }

    private var precisionCrosshair: some View {
        ZStack {
            Circle()
                .stroke(themeColor.opacity(0.5), lineWidth: 1.0)
                .frame(width: model.settings.size * 0.75, height: model.settings.size * 0.75)

            // Crosshair tick marks
            Rectangle().fill(themeColor).frame(width: 1.5, height: model.settings.size * 0.35)
                .offset(y: -model.settings.size * 0.5)
            Rectangle().fill(themeColor).frame(width: 1.5, height: model.settings.size * 0.35)
                .offset(y: model.settings.size * 0.5)
            Rectangle().fill(themeColor).frame(width: model.settings.size * 0.35, height: 1.5)
                .offset(x: -model.settings.size * 0.5)
            Rectangle().fill(themeColor).frame(width: model.settings.size * 0.35, height: 1.5)
                .offset(x: model.settings.size * 0.5)
        }
    }
}
