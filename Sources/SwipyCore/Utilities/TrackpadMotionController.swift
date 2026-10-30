import Foundation
import CoreGraphics
import AppKit

/// Translates hand motion into smooth relative cursor navigation mimicking a MacBook trackpad.
public final class TrackpadMotionController: @unchecked Sendable {
    private let lock = NSLock()
    private var previousNormalizedPoint: CGPoint?
    private var internalScreenPosition: CGPoint?
    private let deadZoneRadius: Double

    public init(deadZoneRadius: Double = 0.002) {
        self.deadZoneRadius = deadZoneRadius
    }

    /// Resets trackpad reference frame when tracking is lost, interrupted, or paused.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        previousNormalizedPoint = nil
        internalScreenPosition = nil
    }

    /// Re-anchors trackpad reference baseline to prevent cursor jumps after a pinch or gesture transition.
    public func resetReference(to normalizedPoint: CGPoint? = nil) {
        lock.lock()
        defer { lock.unlock() }
        previousNormalizedPoint = normalizedPoint
        internalScreenPosition = CursorController.shared.currentQuartzCursorPosition
    }

    /// Computes relative cursor displacement from hand movement in camera space.
    /// - Parameters:
    ///   - normalizedPoint: Hand landmark in Vision coordinates (0..1).
    ///   - sensitivity: User sensitivity multiplier.
    ///   - screenFrame: Target display bounds in Quartz coordinates.
    ///   - isAdaptive: Whether to apply non-linear trackpad acceleration curves.
    ///   - pinchRatio: Current distance ratio between thumb and index for pre-pinch damping.
    ///   - isPinching: Whether fingers are actively touching/pinched (click stabilization).
    ///   - isDragging: Whether user is actively dragging (smooth glide, no freeze).
    /// - Returns: New target cursor position in Quartz screen coordinates.
    public func update(
        normalizedPoint: CGPoint,
        sensitivity: Double,
        screenFrame: CGRect,
        isAdaptive: Bool = true,
        pinchRatio: Double = 1.0,
        isPinching: Bool = false,
        isDragging: Bool = false
    ) -> CGPoint {
        lock.lock()
        defer { lock.unlock() }

        // Initialize internal position from current macOS cursor if fresh, clamped to target screen.
        // In headless CI environments where no physical mouse exists, currentQuartzCursorPosition is .zero;
        // fall back to the display center so directional displacement tests are never clamped at x = 0.
        let currentSysPos = CursorController.shared.currentQuartzCursorPosition
        let fallbackPos = (currentSysPos.x <= 1.0 && currentSysPos.y <= 1.0)
            ? CGPoint(x: screenFrame.midX, y: screenFrame.midY)
            : currentSysPos
        let initialClamped = CGPoint(
            x: max(screenFrame.minX, min(screenFrame.maxX - 1, fallbackPos.x)),
            y: max(screenFrame.minY, min(screenFrame.maxY - 1, fallbackPos.y))
        )
        let activePos = internalScreenPosition ?? initialClamped

        // Stationary pinch stabilization: firmly lock cursor on target icon for click aiming
        if isPinching && !isDragging {
            previousNormalizedPoint = normalizedPoint
            return activePos
        }

        guard let prev = previousNormalizedPoint else {
            previousNormalizedPoint = normalizedPoint
            internalScreenPosition = activePos
            return activePos
        }

        previousNormalizedPoint = normalizedPoint

        // Invert X for selfie camera parity (moving hand right decreases sensor x)
        let dx = -Double(normalizedPoint.x - prev.x)
        // Invert Y because Vision is bottom-left (y increases up), Quartz is top-left (y decreases up)
        let dy = -Double(normalizedPoint.y - prev.y)

        let dist = (dx * dx + dy * dy).squareRoot()
        if dist < deadZoneRadius {
            return activePos
        }

        // Scale normalized displacement to physical screen pixel space
        let baseTravelMultiplier = 1.8
        var pixelDx = dx * Double(screenFrame.size.width) * sensitivity * baseTravelMultiplier
        var pixelDy = dy * Double(screenFrame.size.height) * sensitivity * baseTravelMultiplier

        // Pre-pinch damping: as fingers approach each other to prepare for a click, decelerate velocity.
        // Bypassed during active dragging so dragged items follow the hand fluidly.
        if pinchRatio < 0.60 && !isDragging {
            let damping = max(0.12, min(1.0, (pinchRatio - 0.30) / 0.30))
            pixelDx *= damping
            pixelDy *= damping
        }

        let moveX: Double
        let moveY: Double
        if isAdaptive {
            let speed = (pixelDx * pixelDx + pixelDy * pixelDy).squareRoot()
            // Authentic macOS MouseTracker ballistics:
            // 1. Precision zone: micro-dampened for surgical aiming at icons/links
            // 2. Linear zone: predictable 1:1 finger tracking
            // 3. Ballistic sweep zone: swift cross-display reach with minimal physical effort
            let accel: Double
            if speed < 12.0 {
                accel = 0.55 + 0.45 * (speed / 12.0)
            } else if speed < 50.0 {
                accel = 1.0 + 0.5 * ((speed - 12.0) / 38.0)
            } else {
                accel = min(3.2, 1.5 + ((speed - 50.0) / 45.0))
            }
            moveX = pixelDx * accel
            moveY = pixelDy * accel
        } else {
            moveX = pixelDx
            moveY = pixelDy
        }

        let clampedX = max(Double(screenFrame.minX), min(Double(screenFrame.maxX - 1), Double(activePos.x) + moveX))
        let clampedY = max(Double(screenFrame.minY), min(Double(screenFrame.maxY - 1), Double(activePos.y) + moveY))
        let newScreenPos = CGPoint(x: clampedX, y: clampedY)

        internalScreenPosition = newScreenPos
        return newScreenPos
    }
}
