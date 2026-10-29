import SwiftUI
import SwipyCore

/// View model driving the 7-screen onboarding sequence.
@MainActor
public final class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: Int = 1

    public init() {}

    public func nextStep() {
        if currentStep < 7 { currentStep += 1 }
    }

    public func previousStep() {
        if currentStep > 1 { currentStep -= 1 }
    }
}
