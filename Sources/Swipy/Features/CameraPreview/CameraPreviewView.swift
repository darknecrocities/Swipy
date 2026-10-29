import SwiftUI
import SwipyCore

/// Live visualizer rendering the 21 recognized hand joints and skeletal connections.
public struct CameraPreviewView: View {
    @ObservedObject var appState: AppLifecycleManager

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Hand Pose Skeleton")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(appState.primaryHand != nil ? "Tracked" : "No Hand")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appState.primaryHand != nil ? .green : Color(hex: "777777"))
            }

            ZStack {
                Color(hex: "171717").opacity(0.04)
                    .cornerRadius(12)

                // Active Region Outline
                activeRegionOutline

                // Skeleton Canvas
                if let skeleton = appState.primaryHand {
                    skeletonCanvas(skeleton: skeleton)
                } else {
                    Text("Place hand in camera view")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "999999"))
                }
            }
            .frame(height: 240)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var activeRegionOutline: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let rect = CGRect(
                x: appState.settings.activeRegionX * w,
                y: appState.settings.activeRegionY * h,
                width: appState.settings.activeRegionWidth * w,
                height: appState.settings.activeRegionHeight * h
            )
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundColor(Color(hex: "BBBBBB"))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }

    private func skeletonCanvas(skeleton: HandSkeleton) -> some View {
        GeometryReader { geo in
            Path { path in
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip], size: geo.size)
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip], size: geo.size)
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip], size: geo.size)
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip], size: geo.size)
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip], size: geo.size)
                drawFingerBones(path: &path, skeleton: skeleton, joints: [.indexMCP, .middleMCP, .ringMCP, .littleMCP], size: geo.size)
            }
            .stroke(Color(hex: "171717"), lineWidth: 2)

            // Draw joints
            ForEach(HandJointName.allCases, id: \.self) { name in
                if let joint = skeleton[name] {
                    let pt = point(for: joint, in: geo.size)
                    Circle()
                        .fill(joint.confidence > 0.7 ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .position(pt)
                }
            }
        }
    }

    private func drawFingerBones(path: inout Path, skeleton: HandSkeleton, joints: [HandJointName], size: CGSize) {
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
        // Invert Y for UI display
        CGPoint(x: joint.x * size.width, y: (1.0 - joint.y) * size.height)
    }
}
