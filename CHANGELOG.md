# Changelog

All notable changes to the **Swipy** project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-30

### Added
- **Native macOS Computer Vision**: Real-time hand pose estimation powered exclusively by Apple's native `VNDetectHumanHandPoseRequest` via AVFoundation.
- **21-Joint Hand Skeleton Tracking**: Complete hand landmark representation with normalized coordinates, confidence thresholds, and spatial heuristics.
- **Complete Gesture Engine**:
  - Point to move cursor with One Euro adaptive jitter filter.
  - Quick pinch to Left Click (< 250ms).
  - Double pinch to Double Click (< 380ms).
  - Thumb + Middle Finger pinch for Contextual Right Click.
  - Sustained pinch for Drag & Drop with fail-safe auto-release on tracking loss.
  - Two-finger parallel extension for pixel-accurate vertical & horizontal scrolling.
  - Three-finger swipes for Mission Control, Show Desktop, and Spaces navigation.
  - Four-finger horizontal sweep for Application Switching.
- **Custom Pointer Overlay HUD**:
  - 4 styles: Vision Pro Ring, Glow Halo, Laser Dot, and Precision Crosshair.
  - 5 color palettes: Pure White, Electric Cyan, Apple Mint, Sunset Orange, and Obsidian.
  - Tactile pinch contraction animation ($0.78\times$ spring) and click ripple pulse.
  - Click-through `NSPanel` floating layer persisting across all Spaces and full-screen apps.
- **Adaptive Cursor Navigation & Sensitivity**:
  - Live sensitivity multiplier from $0.2\times$ to $4.0\times$ with quick preset chips.
  - Non-linear power curve acceleration damping micro-tremors and boosting fast sweeps.
  - 4% corner overscan margin for effortless access to menu bar and Dock corners.
  - Interactive Practice Pad with click counter and live feedback.
- **macOS System Integration & Security**:
  - App bundle code signed with `Swipy.entitlements` declaring `com.apple.security.device.camera`.
  - Asynchronous TCC camera permission flow with System Settings fallback.
  - Global emergency pause hotkey (`Option + Escape`).
  - Menu Bar `NSStatusItem` with dynamic tracking indicator and compact popover.
- **Official Branding & Design**:
  - Official squircle app icon (`AppIcon.icns`) for macOS Finder and Dock.
  - Pure-white Apple minimalist UI with glassmorphism cards and SF Pro typography.
  - Reusable `SwipyLogoView` component integrated across Sidebar, Dashboard, and Menu Bar.
- **Documentation Suite**:
  - Comprehensive `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, and `CHANGELOG.md`.
- **Automated Test Harness**:
  - 41 unit tests across 6 test suites covering coordinate mapping, gesture state transitions, motion smoothing, acceleration curves, and settings persistence.
