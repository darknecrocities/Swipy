import Foundation

/// Action that can be executed when a gesture is triggered.
public enum GestureAction: String, Codable, CaseIterable, Sendable {
    case moveCursor = "Point & Glide Cursor"
    case leftClick = "Left Click"
    case doubleClick = "Double Click"
    case rightClick = "Right Click"
    case startOrUpdateDrag = "Drag and Drop"
    case scroll = "Scroll"
    case zoom = "Zoom In / Out"
    case missionControl = "Mission Control"
    case showDesktop = "Show Desktop"
    case previousSpace = "Previous Space"
    case nextSpace = "Next Space"
    case nextApplication = "Next Application"
    case previousApplication = "Previous Application"
    case toggleAppSwitcher = "Toggle App Switcher"
    case toggleTrackingPause = "Pause / Resume"
    case none = "No Action"
}

/// Identifies the recognized hand gesture or pose.
public enum GestureType: String, Codable, CaseIterable, Sendable {
    case indexPointing = "Index Pointing"
    case thumbIndexPinch = "Thumb-Index Pinch"
    case pinchAndDrag = "Pinch & Drag"
    case thumbMiddlePinch = "Thumb-Middle Pinch"
    case thumbMiddleZoom = "Thumb-Middle Zoom"
    case doublePinch = "Double Pinch"
    case twoFingerScroll = "Two-Finger Scroll"
    case threeFingerSwipeUp = "Three-Finger Swipe Up"
    case threeFingerSwipeDown = "Three-Finger Swipe Down"
    case threeFingerSwipeLeft = "Three-Finger Swipe Left"
    case threeFingerSwipeRight = "Three-Finger Swipe Right"
    case fourFingerSwipeLeft = "Four-Finger Swipe Left"
    case fourFingerSwipeRight = "Four-Finger Swipe Right"
    case twoHandZoom = "Two-Hand Zoom"
    case openPalmsPause = "Open Palms Hold"
    case twoFingerTap = "Two-Finger Tap"
    case victorySign = "Peace / V-Sign"
    case fistHold = "Closed Fist Freeze"
}

/// Categorization of gestures for library organization and UI display.
public enum GestureCategory: String, Codable, CaseIterable, Sendable {
    case cursorAndClick = "Cursor & Clicks"
    case scrolling = "Scrolling"
    case spaceNavigation = "Space Navigation"
    case appSwitching = "App Switching"
    case twoHand = "Two-Hand Controls"
    case safety = "Safety Controls"
}

/// Binding between a gesture trigger and its assigned system action.
public struct GestureBinding: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public var gestureType: GestureType
    public var category: GestureCategory
    public var action: GestureAction
    public var isEnabled: Bool
    public var cooldownMs: Int

    public init(
        id: String = UUID().uuidString,
        gestureType: GestureType,
        category: GestureCategory,
        action: GestureAction,
        isEnabled: Bool = true,
        cooldownMs: Int = 300
    ) {
        self.id = id
        self.gestureType = gestureType
        self.category = category
        self.action = action
        self.isEnabled = isEnabled
        self.cooldownMs = cooldownMs
    }
}
