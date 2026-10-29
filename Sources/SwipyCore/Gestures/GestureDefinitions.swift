import Foundation
import CoreGraphics

/// Direction of a recognized hand or multi-finger swipe.
public enum SwipeDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

/// Dynamic active state of the gesture engine for a single frame.
public enum RecognizedGestureState: Equatable, Sendable {
    case idle
    case pointing(normalizedPoint: CGPoint)
    case pinchPending(normalizedPoint: CGPoint, duration: TimeInterval)
    case leftClicked(screenPoint: CGPoint)
    case doubleClicked(screenPoint: CGPoint)
    case dragging(screenPoint: CGPoint)
    case rightClicked(screenPoint: CGPoint)
    case scrolling(deltaY: Double, deltaX: Double)
    case swiping(direction: SwipeDirection, fingers: Int)
    case twoHandZooming(scaleDelta: Double)
    case paused
}
