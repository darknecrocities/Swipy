import SwiftUI
import SwipyCore

/// Live interactive pointer studio preview box displaying real-time styles, themes, and click animations.
public struct PointerStudioPreview: View {
    @ObservedObject var appState: AppLifecycleManager
    @StateObject private var model = PointerViewModel()

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Pointer Studio Preview")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    Text("Interactive visual demonstration of the selected HUD reticle.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
                Spacer()

                Button(action: {
                    model.isPinched = true
                    model.triggerRipple()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        model.isPinched = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 10))
                        Text("Simulate Click & Pinch")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Interactive Preview Canvas
            ZStack {
                // Subtle dark backdrop to make glow, ring, dot, and crosshairs pop
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1E1E24"))

                // Crosshair target grid lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 75))
                    path.addLine(to: CGPoint(x: 340, y: 75))
                    path.move(to: CGPoint(x: 170, y: 0))
                    path.addLine(to: CGPoint(x: 170, y: 150))
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)

                // The dynamic pointer reticle
                PointerOverlayView(model: model)
            }
            .frame(height: 150)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            .onAppear {
                model.settings = appState.settings.pointer
            }
            .onChange(of: appState.settings.pointer) {
                model.settings = appState.settings.pointer
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}
