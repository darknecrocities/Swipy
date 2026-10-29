import Foundation
import SwipyCore

@MainActor
public struct HandPoseMappingTests {
    public static func run() {
        testJointDistanceCalculation()
        testFingerExtensionLogic()
    }

    private static func testJointDistanceCalculation() {
        let p1 = HandJoint(name: .thumbTip, x: 0.1, y: 0.1, confidence: 0.9)
        let p2 = HandJoint(name: .indexTip, x: 0.4, y: 0.5, confidence: 0.9)

        // Euclidean distance = sqrt(0.3^2 + 0.4^2) = 0.5
        let dist = p1.distance(to: p2)
        TestHarness.assertEqual(dist, 0.5, accuracy: 0.0001, "Euclidean joint distance")
    }

    private static func testFingerExtensionLogic() {
        let wrist = HandJoint(name: .wrist, x: 0.5, y: 0.1, confidence: 1.0)

        // Extended index finger (tip is furthest from wrist)
        let indexMCP = HandJoint(name: .indexMCP, x: 0.5, y: 0.3, confidence: 1.0)
        let indexPIP = HandJoint(name: .indexPIP, x: 0.5, y: 0.5, confidence: 1.0)
        let indexTip = HandJoint(name: .indexTip, x: 0.5, y: 0.7, confidence: 1.0)

        // Curled middle finger (tip curls back towards wrist, closer than PIP)
        let middleMCP = HandJoint(name: .middleMCP, x: 0.6, y: 0.3, confidence: 1.0)
        let middlePIP = HandJoint(name: .middlePIP, x: 0.6, y: 0.5, confidence: 1.0)
        let middleTip = HandJoint(name: .middleTip, x: 0.6, y: 0.35, confidence: 1.0)

        let skeleton = HandSkeleton(
            chirality: .right,
            joints: [
                .wrist: wrist,
                .indexMCP: indexMCP,
                .indexPIP: indexPIP,
                .indexTip: indexTip,
                .middleMCP: middleMCP,
                .middlePIP: middlePIP,
                .middleTip: middleTip
            ]
        )

        TestHarness.assertTrue(skeleton.isFingerExtended(.index), "Index finger extended")
        TestHarness.assertFalse(skeleton.isFingerExtended(.middle), "Middle finger curled")
    }
}
