import SwiftUI
import SwipyCore

/// 7-Screen first-launch onboarding experience.
public struct OnboardingView: View {
    @ObservedObject var appState: AppLifecycleManager
    @Binding var isPresented: Bool
    @StateObject private var viewModel = OnboardingViewModel()

    public init(appState: AppLifecycleManager, isPresented: Binding<Bool>) {
        self.appState = appState
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 24) {
            progressIndicator
            contentSection
            footerControls
        }
        .padding(36)
        .frame(width: 520, height: 440)
        .background(Color.white)
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color(hex: "171717") : Color(hex: "EAEAEA"))
                    .frame(height: 3)
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 16) {
            switch viewModel.currentStep {
            case 1: welcomeStep
            case 2: cameraPermissionStep
            case 3: accessibilityPermissionStep
            case 4: handPositioningStep
            case 5: cursorCalibrationStep
            case 6: gestureTutorialStep
            default: readyStep
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            SwipyLogoView(size: 64, showShadow: true)
            Text("Welcome to Swipy")
                .font(.system(size: 22, weight: .bold))
            Text("Your hands. Your Mac. No touch required.\nTransform your built-in camera into a touchless trackpad.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var cameraPermissionStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(appState.isCameraAuthorized ? .green : Color(hex: "171717"))
            Text("Camera Permission")
                .font(.system(size: 18, weight: .semibold))
            Text("Swipy uses your camera strictly for local hand pose recognition. Video frames are never recorded or transmitted.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
            Button(appState.isCameraAuthorized ? "Camera Access Granted" : "Enable Camera Access") {
                Task {
                    let granted = await CameraPermissionManager.shared.requestAccess()
                    appState.isCameraAuthorized = granted
                    if !granted {
                        CameraPermissionManager.shared.openSystemSettingsCameraPrivacy()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(appState.isCameraAuthorized ? .green : Color(hex: "171717"))
        }
    }

    private var accessibilityPermissionStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "accessibility")
                .font(.system(size: 40))
                .foregroundColor(appState.isAccessibilityTrusted ? .green : Color(hex: "171717"))
            Text("Accessibility Privileges")
                .font(.system(size: 18, weight: .semibold))
            Text("macOS requires Accessibility permission so Swipy can synthesize cursor movement and clicks across your applications.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
            Button(appState.isAccessibilityTrusted ? "Accessibility Granted" : "Open System Settings") {
                AccessibilityPermissionManager.shared.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(appState.isAccessibilityTrusted ? .green : Color(hex: "171717"))
        }
    }

    private var handPositioningStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(appState.primaryHand != nil ? .green : Color(hex: "777777"))
            Text("Hand Positioning")
                .font(.system(size: 18, weight: .semibold))
            Text("Hold your hand comfortably 1.5 to 2 feet away from the screen, within your camera's field of view.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var cursorCalibrationStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "171717"))
            Text("Cursor Mapping")
                .font(.system(size: 18, weight: .semibold))
            Text("Extending your index finger smoothly controls the macOS cursor. The One Euro filter prevents hand tremor.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var gestureTutorialStep: some View {
        VStack(spacing: 10) {
            Text("Essential Gestures")
                .font(.system(size: 18, weight: .semibold))
            tutorialRow(icon: "hand.point.up.left", title: "Index Finger", desc: "Moves cursor smoothly")
            tutorialRow(icon: "hand.pinch", title: "Index Pinch", desc: "Left click or drag")
            tutorialRow(icon: "hand.tap", title: "Middle Pinch", desc: "Right click")
            tutorialRow(icon: "arrow.up.and.down", title: "Two Fingers", desc: "Scrolls documents")
        }
    }

    private func tutorialRow(icon: String, title: String, desc: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 24)
            Text(title).font(.system(size: 13, weight: .medium))
            Spacer()
            Text(desc).font(.system(size: 12)).foregroundColor(Color(hex: "777777"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(8)
    }

    private var readyStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)
            Text("You're All Set!")
                .font(.system(size: 20, weight: .semibold))
            Text("Press Emergency Pause or the Menu Bar icon at any time to temporarily suspend tracking.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
                .multilineTextAlignment(.center)
        }
    }

    private var footerControls: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button("Back") { viewModel.previousStep() }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            if viewModel.currentStep < 7 {
                Button("Continue") { viewModel.nextStep() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(hex: "171717"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Button("Start Using Swipy") {
                    appState.settings.isTrackingEnabled = true
                    appState.settings.save()
                    appState.startTrackingSession()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}
