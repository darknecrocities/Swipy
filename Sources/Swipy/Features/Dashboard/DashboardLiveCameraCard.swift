import SwiftUI
import AppKit
import SwipyCore

/// Live camera feed card in the Dashboard with real-time hand skeleton and pointer reticle plotting.
public struct DashboardLiveCameraCard: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.settings.isTrackingEnabled ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(appState.settings.isTrackingEnabled ? "Live Camera & Gesture Feed" : "Camera Stream Offline")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                }

                Spacer()

                if appState.settings.isTrackingEnabled {
                    Text(appState.primaryHand != nil ? "Hand Locked" : "Searching for Hand...")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(appState.primaryHand != nil ? Color.green : Color(hex: "777777"))
                }
            }

            ZStack {
                // 1. Live Camera or Standby Card
                if appState.settings.isTrackingEnabled && appState.isCameraAuthorized {
                    CameraVideoFeedView()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    standbyCard
                }

                // 2. Real-Time Hand Skeleton & Finger Joints Plotting
                if let skeleton = appState.primaryHand, appState.settings.isTrackingEnabled {
                    skeletonOverlay(skeleton: skeleton)
                }

                // 3. Pointer Reticle Plotted on Index Tip
                if let skeleton = appState.primaryHand, let indexTip = skeleton[.indexTip], appState.settings.isTrackingEnabled {
                    pointerReticleOverlay(indexTip: indexTip)
                }

                // 4. Floating Header Telemetry Overlay
                VStack {
                    HStack {
                        if appState.settings.isTrackingEnabled {
                            telemetryBadge
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(height: 220)
            .background(Color.black.opacity(0.04))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var standbyCard: some View {
        ZStack {
            Color(hex: "171717").opacity(0.05)
                .cornerRadius(12)

            VStack(spacing: 10) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: "999999"))
                Text("Camera tracking is currently offline")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "777777"))

                Button(action: {
                    appState.toggleTracking()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("Start Live Camera & Tracking")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "171717"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var telemetryBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text(String(format: "30 FPS • %.1f ms", appState.currentInferenceMs))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.65))
        .cornerRadius(6)
    }

    private func skeletonOverlay(skeleton: HandSkeleton) -> some View {
        GeometryReader { geo in
            Path { path in
                drawBones(path: &path, skeleton: skeleton, joints: [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip], size: geo.size)
                drawBones(path: &path, skeleton: skeleton, joints: [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip], size: geo.size)
                drawBones(path: &path, skeleton: skeleton, joints: [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip], size: geo.size)
                drawBones(path: &path, skeleton: skeleton, joints: [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip], size: geo.size)
                drawBones(path: &path, skeleton: skeleton, joints: [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip], size: geo.size)
                drawBones(path: &path, skeleton: skeleton, joints: [.indexMCP, .middleMCP, .ringMCP, .littleMCP], size: geo.size)
            }
            .stroke(Color.white.opacity(0.85), lineWidth: 2)

            ForEach(HandJointName.allCases, id: \.self) { name in
                if let joint = skeleton[name] {
                    let pt = point(for: joint, in: geo.size)
                    Circle()
                        .fill(joint.confidence > 0.65 ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .position(pt)
                }
            }
        }
    }

    private func pointerReticleOverlay(indexTip: HandJoint) -> some View {
        GeometryReader { geo in
            let pt = point(for: indexTip, in: geo.size)
            ZStack {
                Circle()
                    .stroke(Color(hex: appState.settings.pointer.theme.hexColor), lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(Color(hex: appState.settings.pointer.theme.hexColor))
                    .frame(width: 6, height: 6)
            }
            .position(pt)
        }
    }

    private func drawBones(path: inout Path, skeleton: HandSkeleton, joints: [HandJointName], size: CGSize) {
        var start: CGPoint?
        for name in joints {
            guard let joint = skeleton[name] else { continue }
            let pt = point(for: joint, in: size)
            if let s = start {
                path.move(to: s)
                path.addLine(to: pt)
            }
            start = pt
        }
    }

    private func point(for joint: HandJoint, in size: CGSize) -> CGPoint {
        // Mirrored X for selfie webcam, inverted Y for AppKit to SwiftUI coordinates
        CGPoint(x: (1.0 - joint.x) * size.width, y: (1.0 - joint.y) * size.height)
    }
}
