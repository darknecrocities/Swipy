# Learned Conventions & Architectural Invariants — Swipy

## 1. Environment & SDK Invariants
- **SDK & Swift Version**: macOS 27 SDK with Swift 6.4. Command Line Tools (`/Library/Developer/CommandLineTools`) is active without full Xcode.app.
- **SwiftUI Macros in CLT**: In macOS 27 CLT, the `@State` property wrapper was migrated by Apple to an external macro `SwiftUIMacros.StateMacro` whose dylib is only bundled in Xcode.app. In CLT, view state is cleanly modeled using `@ObservedObject` / `@StateObject` with dedicated `@MainActor` ViewModels (`ObservableObject`).
- **XCTest in CLT**: CLT does not bundle `XCTest.framework`. Automated test suites are structured as a lightweight executable test runner `SwipyTestRunner` verifying all domain logic with zero external dependencies.

## 2. Computer Vision & Input Conventions
- **Local-Only Processing**: Apple Vision (`VNDetectHumanHandPoseRequest`) runs on background dispatch queue (`com.swipy.vision.processing`). Never perform inference synchronously on `@MainActor`.
- **Coordinate Mapping**: Vision coordinates $(0..1, 0..1)$ use a bottom-left origin; screen coordinates use a top-left origin. $Y$ must be inverted ($1.0 - y$). Front cameras require horizontal mirroring ($1.0 - x$).
- **One Euro Filter**: Standard parameters $\beta = 0.007$, $f_{c,\min} = 1.0\text{ Hz}$ eliminate stationary hand tremor while responding immediately to high-speed directional sweeps.
- **Fail-Safe Release**: On any tracking interruption, camera pause, or low confidence, `MouseEventController.shared.safetyReleaseHeldButtons()` must be immediately called to guarantee no mouse buttons remain stuck down.

## 3. UI Invariants
- **Visual Aesthetic**: Pure white (`#FFFFFF`) with subtle translucent glassmorphic materials, Apple SF Pro typography, and minimal native macOS controls. Zero neon gradients or decorative badges.
