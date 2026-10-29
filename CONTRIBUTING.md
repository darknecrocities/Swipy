# Contributing to Swipy

Thank you for your interest in contributing to **Swipy**! This document provides engineering standards, architecture invariants, and testing practices to help maintain production quality across the repository.

---

## 1. Code of Engineering Discipline

All contributions to Swipy adhere to strict macOS craftsmanship standards:

1. **Native macOS Focus**: Swipy is built strictly in native Swift using **SwiftUI**, **AppKit**, **AVFoundation**, **Apple Vision**, and **Core Graphics**. No Electron, web containers, or third-party computer vision models (MediaPipe, OpenCV, ML Kit) are permitted in the initial core.
2. **Local-First & Zero Telemetry Leakage**: Hand poses and camera frames must always be processed in volatile memory on-device and immediately discarded. Never record, persist, or transmit video frames.
3. **Physical Line Limit Guardrail**:
   - **Ceiling**: No source file may exceed **500 physical lines**.
   - **Sweet Spot**: Target **150–250 lines** per file. Decompose any file entering the 350-line warning threshold into focused domain components.
   - **Function Budget**: Functions must not exceed **40 physical lines** or **3 levels of nesting**.
   - Verify line limits before submitting:
     ```bash
     python3 ~/.gemini/config/plugins/skill-builder/skills/world-class-engineering/scripts/check_source_line_limits.py --path Sources/ --show-tiers
     ```
4. **Anti-AI-Slop & Clean Craftsmanship**:
   - Avoid decorative neon gradients, fake mock databases, or synthetic marketing fluff.
   - Maintain a pure-white (`#FFFFFF`), minimal macOS glassmorphic aesthetic aligned with Apple Human Interface Guidelines (HIG).

---

## 2. Git & Branching Workflow

Swipy follows the Conventional Commits specification:

### Branch Naming Conventions
- `feat/<feature-name>`: New capabilities (e.g. `feat/custom-pointer-hud`)
- `fix/<issue-name>`: Bug fixes (e.g. `fix/camera-permission-tcc`)
- `refactor/<module>`: Architectural restructuring (e.g. `refactor/dashboard-cards`)
- `docs/<subject>`: Documentation enhancements (e.g. `docs/architecture-guide`)

### Commit Guidelines
Every commit must include:
- A descriptive Conventional title: `<type>(<scope>): <summary>`
- A structured commit body detailing **Why**, **What**, and **Verification**.
- Stay within the 1,000-line modification budget per atomic commit.

---

## 3. Development Environment & Building

### Requirements
- macOS 14 Sonoma or later (macOS 15 Sequoia / macOS 27 supported)
- Apple Command Line Tools or Xcode 15+
- Swift 6.0+ toolchain

### Building the Project
```bash
# Debug build
swift build

# Run automated unit tests
swift run SwipyTestRunner

# Package release .app bundle with camera entitlements
bash scripts/bundle_app.sh
```

---

## 4. Testing & Verification

Every functional change must include corresponding unit tests under `Tests/SwipyTests/`:
- **Coordinate Mapping**: Verify normalized Vision coords map accurately to macOS screens with overscan.
- **Hand Pose Mapping**: Verify 21-joint skeleton extraction and confidence thresholds.
- **Gesture State Machine**: Verify state transitions (Pointing $\to$ Pinch $\to$ Drag $\to$ Release) and hysteresis bands.
- **Motion Filtering & Acceleration**: Verify One Euro jitter reduction and non-linear velocity curves.
- **Settings Persistence**: Verify Codable serialization and fallback defaults.

Run the test suite:
```bash
swift run SwipyTestRunner
```

---

## 5. Pull Request Checklist

Before submitting a Pull Request:
- [ ] Code builds cleanly with zero compiler warnings (`swift build`).
- [ ] All automated unit tests pass (`swift run SwipyTestRunner`).
- [ ] Source files strictly respect the 500-line ceiling.
- [ ] Release `.app` bundle builds and passes code signature verification (`bash scripts/bundle_app.sh`).
- [ ] PR title follows Conventional Commits format with a detailed description.
