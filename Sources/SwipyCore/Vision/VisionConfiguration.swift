import Foundation

/// Operational tuning parameters for Apple Vision hand pose processing.
public struct VisionConfiguration: Codable, Equatable, Sendable {
    public var maximumHandCount: Int
    public var minimumJointConfidence: Float
    public var targetFrameRate: Int
    public var mirrorHorizontally: Bool

    public init(
        maximumHandCount: Int = 1,
        minimumJointConfidence: Float = 0.40,
        targetFrameRate: Int = 30,
        mirrorHorizontally: Bool = true
    ) {
        self.maximumHandCount = maximumHandCount
        self.minimumJointConfidence = minimumJointConfidence
        self.targetFrameRate = targetFrameRate
        self.mirrorHorizontally = mirrorHorizontally
    }
}
