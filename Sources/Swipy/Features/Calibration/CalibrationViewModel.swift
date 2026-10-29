import SwiftUI
import SwipyCore

/// View model driving the calibration wizard step sequence and click test counters.
@MainActor
public final class CalibrationViewModel: ObservableObject {
    @Published public var currentStep: Int = 1
    @Published public var testClickCount: Int = 0

    public init() {}

    public func nextStep() {
        if currentStep < 7 { currentStep += 1 }
    }

    public func previousStep() {
        if currentStep > 1 { currentStep -= 1 }
    }
}
