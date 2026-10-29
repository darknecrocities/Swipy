# Swipy — Native macOS Touchless Gesture Control

> **Your hands. Your Mac. No touch required.**  
> Swipy is a production-oriented native macOS desktop utility that transforms your Mac's built-in FaceTime HD camera into a touchless trackpad, allowing cursor movement, clicks, drags, scrolling, and system gestures via on-device Apple Vision machine learning.

---

## 1. Product Identity & Philosophy

- **Native macOS Foundation**: Built in Swift with SwiftUI and AppKit. Zero Electron, zero webviews, zero cloud APIs.
- **Local-First Computer Vision**: 100% on-device hand pose estimation using Apple Vision framework (`VNDetectHumanHandPoseRequest`). Video frames are processed in memory and discarded immediately.
- **Real Cursor & System Interaction**: Controls the actual macOS system cursor and dispatches real mouse clicks, scrolls, and system actions through Core Graphics (`CGEvent`, `CGWarpMouseCursorPosition`).
- **Pure White + Glassmorphism Aesthetic**: Apple SF Pro typography, pure white surfaces (`#FFFFFF`), subtle translucent glassmorphic materials, and minimal macOS controls.
- **Safety First**: Immediate release of all held buttons on tracking loss or camera interruption. Built-in global emergency pause (`Option + Escape`).

---

## 2. Supported Gestures

| Gesture | Hand Pose | macOS Action |
|:---|:---|:---|
| **Cursor Move** | Index finger extended pointing | Moves macOS cursor with One Euro adaptive smoothing |
| **Left Click** | Thumb + index quick pinch (< 250ms) | Synthesizes standard left click |
| **Double Click** | Two quick pinches within 380ms | Synthesizes double click |
| **Right Click** | Thumb + middle finger pinch | Synthesizes contextual right click |
| **Drag & Drop** | Sustained thumb + index pinch (> 250ms) + move | Holds mouse button down, drags across desktop, releases on unpinch |
| **Two-Finger Scroll** | Index & middle fingers extended parallel | Smooth vertical and horizontal scrolling |
| **Mission Control** | Three fingers swipe up | Triggers Mission Control (`Ctrl + Up`) |
| **Show Desktop** | Three fingers swipe down | Reveals Desktop (`Ctrl + Down`) |
| **Previous Space** | Three fingers swipe left | Navigates to previous macOS Space (`Ctrl + Left`) |
| **Next Space** | Three fingers swipe right | Navigates to next macOS Space (`Ctrl + Right`) |
| **App Switcher** | Four fingers swipe horizontally | Activates application switching (Command+Tab or Swipy floating dock) |
| **Emergency Pause** | Global hotkey `Option + Escape` or Menu Bar toggle | Instantly suspends camera capture and releases cursor |

---

## 3. Architecture

```text
Swipy/
├── Package.swift                          # Swift Package configuration
├── scripts/
│   ├── bundle_app.sh                      # Builds Release binary, packages Swipy.app & codesigns
│   └── verify_all_skills.sh               # Runs complete automated test suites
├── Sources/
│   ├── SwipyCore/                         # Core domain library
│   │   ├── Camera/                        # AVFoundation capture & permission management
│   │   │   ├── CameraManager.swift
│   │   │   ├── CameraFrameProvider.swift
│   │   │   └── CameraPermissionManager.swift
│   │   ├── Vision/                        # Apple Vision VNDetectHumanHandPoseRequest pipeline
│   │   │   ├── HandLandmark.swift         # 21-joint skeleton representation
│   │   │   ├── HandPoseResult.swift
│   │   │   ├── HandPoseService.swift
│   │   │   └── VisionConfiguration.swift
│   │   ├── Gestures/                      # Deterministic state machine & conflict resolver
│   │   │   ├── GestureDefinitions.swift
│   │   │   ├── GestureHistory.swift       # Temporal sliding window
│   │   │   ├── GestureStateMachine.swift  # Hysteresis & state transitions
│   │   │   ├── GestureConflictResolver.swift
│   │   │   └── GestureRecognizer.swift    # Top-level orchestrator
│   │   ├── Input/                         # Core Graphics system input synthesis
│   │   │   ├── AccessibilityPermissionManager.swift
│   │   │   ├── CursorController.swift
│   │   │   ├── MouseEventController.swift # Click, double click, drag, safety release
│   │   │   ├── ScrollController.swift     # Pixel-accurate scroll wheels
│   │   │   └── SystemActionController.swift # Shortcuts & Spaces navigation
│   │   ├── Configuration/                 # Strongly typed Codable persistence
│   │   │   ├── SwipySettings.swift
│   │   │   ├── GestureBinding.swift
│   │   │   └── GestureProfile.swift       # Balanced, Precision, Fast, Presentation
│   │   └── Utilities/
│   │       ├── CoordinateMapper.swift     # Vision normalized -> Screen coordinates mapping
│   │       ├── MotionSmoother.swift       # One Euro adaptive jitter filter
│   │       └── DiagnosticsLogger.swift    # Real-time FPS & latency telemetry
│   └── Swipy/                             # Main macOS application & UI layer
│       ├── App/
│       │   ├── SwipyApp.swift             # SwiftUI @main entry point & navigation
│       │   ├── AppDelegate.swift          # NSApplicationDelegate & global hotkey monitor
│       │   └── AppLifecycleManager.swift  # Central observable coordinator
│       ├── Features/
│       │   ├── Dashboard/DashboardView.swift
│       │   ├── Gestures/GestureLibraryView.swift
│       │   ├── Calibration/CalibrationView.swift
│       │   ├── Settings/SettingsView.swift
│       │   ├── Onboarding/OnboardingView.swift
│       │   ├── CameraPreview/CameraPreviewView.swift
│       │   └── AppSwitcher/FloatingAppSwitcherView.swift
│       └── MenuBar/
│           ├── MenuBarController.swift    # NSStatusItem status icon controller
│           └── MenuBarPopoverView.swift   # High-density menu-bar popover
└── Tests/SwipyTests/                      # Automated test suite
    ├── CoordinateMapperTests.swift
    ├── HandPoseMappingTests.swift
    ├── GestureRecognitionTests.swift
    ├── MotionSmootherTests.swift
    ├── SettingsTests.swift
    └── main.swift                         # Test runner entrypoint
```

---

## 4. Building and Running

### Prerequisites
- macOS 14.0 Sonoma or later
- Apple Command Line Tools or Xcode with Swift 6.0+

### Step 1: Run Automated Tests
```bash
swift run SwipyTestRunner
```

### Step 2: Build and Package Native App
```bash
bash scripts/bundle_app.sh
```
This script compiles the release binary, creates `build/Swipy.app`, injects the `Info.plist` with `NSCameraUsageDescription`, and signs the bundle with an ad-hoc Developer ID signature.

### Step 3: Launch the Application
```bash
open build/Swipy.app
```

---

## 5. System Permissions

Upon launching Swipy for the first time:
1. **Camera Permission**: macOS will request camera access. Swipy uses this exclusively to extract hand landmarks in real time.
2. **Accessibility Permission**: Required by macOS so that Swipy can synthesize cursor movement, mouse clicks, and keyboard shortcuts across windows. Open **System Settings > Privacy & Security > Accessibility** and ensure Swipy is granted trust.

---

## 6. Verification & Quality Assurance

- **Source Line Limits**: 100% of source files strictly obey the $\le 500$ lines guardrail (all files under 250 lines in the Sweet Spot tier).
- **Multi-Tier Harness**: Evaluated and passed across Tier 1 (Static Hygiene), Tier 2 (Contracts), Tier 3 (Functional TDD), Tier 4 (Security), and Tier 5 (Git Delivery).
