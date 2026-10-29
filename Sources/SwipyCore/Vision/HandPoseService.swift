import Foundation
import Vision
import CoreVideo

/// Service executing Apple Vision hand-pose detection requests on camera frames.
public final class HandPoseService: @unchecked Sendable {
    public var configuration: VisionConfiguration
    private let processingQueue = DispatchQueue(label: "com.swipy.vision.processing", qos: .userInteractive)
    private var isBusy = false
    private let lock = NSLock()

    public init(configuration: VisionConfiguration = VisionConfiguration()) {
        self.configuration = configuration
    }

    /// Processes a pixel buffer and extracts recognized hand skeletons.
    public func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> HandPoseResult? {
        lock.lock()
        if isBusy {
            lock.unlock()
            // Drop frame to preserve zero-latency processing
            return nil
        }
        isBusy = true
        lock.unlock()

        defer {
            lock.lock()
            isBusy = false
            lock.unlock()
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = configuration.maximumHandCount

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return HandPoseResult.empty(state: .error)
        }

        guard let observations = request.results, !observations.isEmpty else {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            return HandPoseResult(primaryHand: nil, secondaryHand: nil, state: .noHandDetected, inferenceDurationMs: duration)
        }

        var skeletons: [HandSkeleton] = []
        for observation in observations {
            if let skeleton = parseObservation(observation) {
                skeletons.append(skeleton)
            }
        }

        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        let primary = skeletons.first
        let secondary = skeletons.count > 1 ? skeletons[1] : nil
        let state: TrackingState = primary != nil ? .tracking : .noHandDetected

        return HandPoseResult(
            primaryHand: primary,
            secondaryHand: secondary,
            state: state,
            timestamp: ProcessInfo.processInfo.systemUptime,
            inferenceDurationMs: duration
        )
    }

    private func parseObservation(_ observation: VNHumanHandPoseObservation) -> HandSkeleton? {
        var jointsMap: [HandJointName: HandJoint] = [:]
        var totalConfidence: Float = 0
        var countedJoints = 0

        for jointName in HandJointName.allCases {
            guard let visionJoint = visionJointName(for: jointName),
                  let point = try? observation.recognizedPoint(visionJoint),
                  point.confidence >= configuration.minimumJointConfidence else {
                continue
            }

            // Normalization & horizontal mirroring for natural front-camera parity
            let xCoord = configuration.mirrorHorizontally ? (1.0 - Double(point.x)) : Double(point.x)
            let yCoord = Double(point.y)

            let joint = HandJoint(
                name: jointName,
                x: xCoord,
                y: yCoord,
                confidence: point.confidence
            )
            jointsMap[jointName] = joint
            totalConfidence += point.confidence
            countedJoints += 1
        }

        // Require at least wrist and index tip for viable tracking
        guard jointsMap[.wrist] != nil, jointsMap[.indexTip] != nil else {
            return nil
        }

        let chirality: HandChirality
        switch observation.chirality {
        case .left: chirality = .left
        case .right: chirality = .right
        default: chirality = .unknown
        }

        let avgConfidence = countedJoints > 0 ? (totalConfidence / Float(countedJoints)) : 0.0
        return HandSkeleton(chirality: chirality, joints: jointsMap, overallConfidence: avgConfidence)
    }

    private func visionJointName(for name: HandJointName) -> VNHumanHandPoseObservation.JointName? {
        switch name {
        case .wrist: return .wrist
        case .thumbCMC: return .thumbCMC
        case .thumbMP: return .thumbMP
        case .thumbIP: return .thumbIP
        case .thumbTip: return .thumbTip
        case .indexMCP: return .indexMCP
        case .indexPIP: return .indexPIP
        case .indexDIP: return .indexDIP
        case .indexTip: return .indexTip
        case .middleMCP: return .middleMCP
        case .middlePIP: return .middlePIP
        case .middleDIP: return .middleDIP
        case .middleTip: return .middleTip
        case .ringMCP: return .ringMCP
        case .ringPIP: return .ringPIP
        case .ringDIP: return .ringDIP
        case .ringTip: return .ringTip
        case .littleMCP: return .littleMCP
        case .littlePIP: return .littlePIP
        case .littleDIP: return .littleDIP
        case .littleTip: return .littleTip
        }
    }
}
