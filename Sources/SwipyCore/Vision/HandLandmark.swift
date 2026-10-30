import Foundation

/// Canonical hand joint identifiers corresponding to standard anatomical landmarks.
public enum HandJointName: String, Codable, CaseIterable, Sendable {
    case wrist = "wrist"

    case thumbCMC = "thumbCMC"
    case thumbMP = "thumbMP"
    case thumbIP = "thumbIP"
    case thumbTip = "thumbTip"

    case indexMCP = "indexMCP"
    case indexPIP = "indexPIP"
    case indexDIP = "indexDIP"
    case indexTip = "indexTip"

    case middleMCP = "middleMCP"
    case middlePIP = "middlePIP"
    case middleDIP = "middleDIP"
    case middleTip = "middleTip"

    case ringMCP = "ringMCP"
    case ringPIP = "ringPIP"
    case ringDIP = "ringDIP"
    case ringTip = "ringTip"

    case littleMCP = "littleMCP"
    case littlePIP = "littlePIP"
    case littleDIP = "littleDIP"
    case littleTip = "littleTip"
}

/// Handedness classification.
public enum HandChirality: String, Codable, Sendable {
    case left = "Left"
    case right = "Right"
    case unknown = "Unknown"
}

/// Normalized 2D hand landmark joint with confidence score.
public struct HandJoint: Codable, Equatable, Sendable {
    public let name: HandJointName
    public let x: Double // 0.0 ... 1.0 (Vision bottom-left origin)
    public let y: Double // 0.0 ... 1.0
    public let confidence: Float // 0.0 ... 1.0

    public init(name: HandJointName, x: Double, y: Double, confidence: Float) {
        self.name = name
        self.x = x
        self.y = y
        self.confidence = confidence
    }

    /// Euclidean distance to another joint.
    public func distance(to other: HandJoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

/// Identifies the five human fingers.
public enum Finger: String, CaseIterable, Sendable {
    case thumb
    case index
    case middle
    case ring
    case little
}

/// High-level discrete classification of the number of extended fingers for deterministic gesture gating.
public enum ExtendedFingerState: String, Codable, CaseIterable, Sendable {
    case zeroFingers = "Fist (Idle)"
    case oneFinger   = "1 Finger (Pointer)"
    case twoFingers  = "2 Fingers (Scroll)"
    case threeFingers = "3 Fingers (Spaces)"
    case fourFingers = "4 Fingers (Open Palm)"
}

/// Complete normalized representation of a single recognized hand.
public struct HandSkeleton: Codable, Equatable, Sendable {
    public let chirality: HandChirality
    public let joints: [HandJointName: HandJoint]
    public let overallConfidence: Float

    public init(
        chirality: HandChirality = .unknown,
        joints: [HandJointName: HandJoint],
        overallConfidence: Float = 1.0
    ) {
        self.chirality = chirality
        self.joints = joints
        self.overallConfidence = overallConfidence
    }

    /// Accessor for a specific joint.
    public subscript(name: HandJointName) -> HandJoint? {
        joints[name]
    }

    /// Computes distance between two joints if both are present.
    public func distance(between first: HandJointName, and second: HandJointName) -> Double? {
        guard let p1 = joints[first], let p2 = joints[second] else { return nil }
        return p1.distance(to: p2)
    }

    /// Anatomical palm scale: rigid distance from wrist to base of middle finger (metacarpal bone reference).
    public var palmScale: Double {
        guard let wrist = joints[.wrist], let middleMCP = joints[.middleMCP] else { return 0.20 }
        return max(0.05, wrist.distance(to: middleMCP))
    }

    /// Scale-invariant pinch ratio (distance between thumb and index tips divided by rigid palm length).
    public var pinchRatio: Double {
        guard let dist = distance(between: .thumbTip, and: .indexTip) else { return 1.0 }
        return dist / palmScale
    }

    /// Scale-invariant middle-finger pinch ratio for secondary / right clicks.
    public var middlePinchRatio: Double {
        guard let dist = distance(between: .thumbTip, and: .middleTip) else { return 1.0 }
        return dist / palmScale
    }

    /// Evaluates whether thumb and middle finger are actively engaging in a pinch/spread zoom gesture.
    /// Crucially requires the index finger to NOT be extended, preventing any pointing interference.
    public var isThumbMiddleZooming: Bool {
        guard !isFingerExtended(.index) else { return false }
        guard let dist = distance(between: .thumbTip, and: .middleTip) else { return false }
        let ratio = dist / palmScale
        let isRingCurled = !isFingerExtended(.ring)
        let isLittleCurled = !isFingerExtended(.little)
        return ratio <= 0.35 && isRingCurled && isLittleCurled
    }

    /// Evaluates whether thumb and index finger are pinching together, tolerant of natural index flexion.
    public var isThumbIndexPinching: Bool {
        guard !isFist else { return false }
        guard let dist = distance(between: .thumbTip, and: .indexTip) else { return false }
        let ratio = dist / palmScale
        let isMiddleCurled = !isFingerExtended(.middle)
        let isRingCurled = !isFingerExtended(.ring)
        return ratio <= 0.35 && (isMiddleCurled || ratio <= 0.22) && isRingCurled
    }

    /// Evaluates whether index and middle fingers are extended apart in a Peace / V-Sign pose.
    public var isVictoryPose: Bool {
        guard isFingerExtended(.index),
              isFingerExtended(.middle),
              !isFingerExtended(.ring),
              !isFingerExtended(.little) else { return false }
        guard let tipDist = distance(between: .indexTip, and: .middleTip) else { return false }
        let mcpDist = distance(between: .indexMCP, and: .middleMCP) ?? (palmScale * 0.25)
        return tipDist >= mcpDist * 1.30 && tipDist >= palmScale * 0.20
    }

    /// Evaluates whether index and middle fingertips are touching together for a two-finger tap.
    public var isTwoFingerTapping: Bool {
        guard isFingerExtended(.index),
              isFingerExtended(.middle),
              !isFingerExtended(.ring),
              !isFingerExtended(.little) else { return false }
        guard let tipDist = distance(between: .indexTip, and: .middleTip) else { return false }
        return tipDist <= palmScale * 0.14
    }

    /// Evaluates whether the hand is in a closed fist posture (all non-thumb fingers curled, not pinching).
    public var isFist: Bool {
        let allCurled = !isFingerExtended(.index) &&
                        !isFingerExtended(.middle) &&
                        !isFingerExtended(.ring) &&
                        !isFingerExtended(.little)
        guard allCurled else { return false }
        // If thumb and index tips are pinched together, it is an active pinch rather than a resting fist
        if let dist = distance(between: .thumbTip, and: .indexTip), dist / palmScale <= 0.30 {
            return false
        }
        return true
    }

    /// Evaluates which non-thumb fingers are extended to classify the macro gesture mode.
    public var fingerPoseState: ExtendedFingerState {
        // If thumb and index are actively pinching, preserve .oneFinger pointing/pinching mode even when index curls
        if isThumbIndexPinching {
            return .oneFinger
        }

        let isIndex = isFingerExtended(.index)
        let isMiddle = isFingerExtended(.middle)
        let isRing = isFingerExtended(.ring)
        let isLittle = isFingerExtended(.little)

        if isIndex && isMiddle && isRing && isLittle {
            return .fourFingers
        } else if isIndex && isMiddle && isRing {
            return .threeFingers
        } else if isIndex && isMiddle {
            return .twoFingers
        } else if isIndex && !isMiddle {
            // Dominant pointing: index extended while middle is curled.
            // Noise-free: unaffected by natural partial curling of ring/little fingers.
            return .oneFinger
        } else if isIndex && !isRing && !isLittle {
            return .oneFinger
        } else {
            return .zeroFingers
        }
    }

    /// Evaluates whether a given finger is extended based on joint hierarchy geometry.
    public func isFingerExtended(_ finger: Finger) -> Bool {
        guard let wrist = joints[.wrist] else { return false }

        switch finger {
        case .thumb:
            guard let tip = joints[.thumbTip],
                  let ip = joints[.thumbIP],
                  let mp = joints[.thumbMP] else { return false }
            return tip.distance(to: wrist) > mp.distance(to: wrist) &&
                   tip.distance(to: mp) > ip.distance(to: mp)

        case .index:
            return isPhalanxExtended(tip: .indexTip, pip: .indexPIP, mcp: .indexMCP, wrist: wrist)

        case .middle:
            return isPhalanxExtended(tip: .middleTip, pip: .middlePIP, mcp: .middleMCP, wrist: wrist)

        case .ring:
            return isPhalanxExtended(tip: .ringTip, pip: .ringPIP, mcp: .ringMCP, wrist: wrist)

        case .little:
            return isPhalanxExtended(tip: .littleTip, pip: .littlePIP, mcp: .littleMCP, wrist: wrist)
        }
    }

    private func isPhalanxExtended(
        tip: HandJointName,
        pip: HandJointName,
        mcp: HandJointName,
        wrist: HandJoint
    ) -> Bool {
        guard let tipPt = joints[tip] else { return false }
        let tipToWrist = tipPt.distance(to: wrist)

        if let pipPt = joints[pip], let mcpPt = joints[mcp] {
            let pipToWrist = pipPt.distance(to: wrist)
            let mcpToWrist = mcpPt.distance(to: wrist)

            // Standard upright hand: monotonic distance progression from wrist
            if tipToWrist > pipToWrist && pipToWrist > mcpToWrist {
                return true
            }

            // Foreshortened hand (tilted towards/away from camera):
            // Check directional projection along hand axis (MCP - wrist)
            let palmDx = mcpPt.x - wrist.x
            let palmDy = mcpPt.y - wrist.y
            let fingerDx = tipPt.x - mcpPt.x
            let fingerDy = tipPt.y - mcpPt.y
            let dot = palmDx * fingerDx + palmDy * fingerDy

            // Finger must extend in positive palm direction and tip must be beyond MCP
            return dot > 0.02 && tipToWrist > mcpToWrist * 1.15
        } else if let mcpPt = joints[mcp] {
            return tipToWrist > mcpPt.distance(to: wrist) * 1.12
        } else {
            return tipToWrist > palmScale * 1.05
        }
    }
}
