import SwiftUI
import SwipyCore

/// 7-Step guided interactive calibration interface.
public struct CalibrationView: View {
    @ObservedObject var appState: AppLifecycleManager
    @Binding var isPresented: Bool
    @StateObject private var viewModel = CalibrationViewModel()

    public init(appState: AppLifecycleManager, isPresented: Binding<Bool>) {
        self.appState = appState
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 24) {
            headerBar
            stepIndicator
            contentCard
            footerButtons
        }
        .padding(32)
        .frame(width: 580, height: 500)
        .background(Color.white)
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calibration Wizard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text("Step \(viewModel.currentStep) of 7")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "CCCCCC"))
            }
            .buttonStyle(.plain)
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color(hex: "171717") : Color(hex: "EAEAEA"))
                    .frame(height: 4)
            }
        }
    }

    @ViewBuilder
    private var contentCard: some View {
        VStack(spacing: 16) {
            switch viewModel.currentStep {
            case 1: step1HandComfort
            case 2: step2InteractionBounds
            case 3: step3TopLeftTarget
            case 4: step4BottomRightTarget
            case 5: step5Sensitivity
            case 6: step6PinchTest
            default: step7Complete
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var step1HandComfort: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 36))
                .foregroundColor(appState.primaryHand != nil ? .green : Color(hex: "777777"))
            Text("Position Your Hand")
                .font(.system(size: 16, weight: .semibold))
            Text("Raise your dominant hand 1 to 2 feet in front of your Mac's camera. Ensure good ambient lighting.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
            statusBadge(title: appState.primaryHand != nil ? "Hand Detected" : "Waiting for Hand...")
        }
    }

    private var step2InteractionBounds: some View {
        VStack(spacing: 12) {
            Text("Active Interaction Region")
                .font(.system(size: 16, weight: .semibold))
            Text("Controls the normalized rectangular zone of the camera mapped across your screen.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
            Slider(value: $appState.settings.activeRegionWidth, in: 0.4...0.9) {
                Text("Region Width")
            }
            Text("Width Coverage: \(Int(appState.settings.activeRegionWidth * 100))%")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "777777"))
        }
    }

    private var step3TopLeftTarget: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.left.circle")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "171717"))
            Text("Reach Upper-Left")
                .font(.system(size: 16, weight: .semibold))
            Text("Extend your index finger comfortably toward the upper-left of your natural gesture field.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var step4BottomRightTarget: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.right.circle")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "171717"))
            Text("Reach Lower-Right")
                .font(.system(size: 16, weight: .semibold))
            Text("Extend your index finger toward the lower-right of your comfort zone.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var step5Sensitivity: some View {
        VStack(spacing: 12) {
            Text("Cursor Sensitivity")
                .font(.system(size: 16, weight: .semibold))
            Text("Adjust cursor tracking speed and One Euro filter jitter reduction.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
            Slider(value: $appState.settings.cursorSensitivity, in: 0.5...2.5)
            Text(String(format: "Sensitivity: %.2fx", appState.settings.cursorSensitivity))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(hex: "777777"))
        }
    }

    private var step6PinchTest: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.pinch")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "171717"))
            Text("Pinch-to-Click Test")
                .font(.system(size: 16, weight: .semibold))
            Text("Tap your index finger and thumb together to test click registration.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
            Button("Test Click Target (\(viewModel.testClickCount))") {
                viewModel.testClickCount += 1
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "171717"))
        }
    }

    private var step7Complete: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)
            Text("Calibration Complete")
                .font(.system(size: 18, weight: .semibold))
            Text("Your custom calibration profile has been saved. You're ready to control your Mac touchlessly.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private func statusBadge(title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private var footerButtons: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button("Previous") { viewModel.previousStep() }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            if viewModel.currentStep < 7 {
                Button("Next Step") { viewModel.nextStep() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Button("Finish") {
                    appState.settings.save()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}
