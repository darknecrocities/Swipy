import Foundation

/// Lightweight test assertion framework providing deterministic verification without external XCTest dylib dependencies.
@MainActor
public struct TestHarness {
    public static var passCount = 0
    public static var failCount = 0

    public static func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if a == b {
            passCount += 1
        } else {
            failCount += 1
            print("❌ Assertion Failed [\(file):\(line)]: '\(a)' is not equal to '\(b)'. \(message)")
        }
    }

    public static func assertEqual(_ a: Double, _ b: Double, accuracy: Double, _ message: String = "", file: String = #file, line: Int = #line) {
        if abs(a - b) <= accuracy {
            passCount += 1
        } else {
            failCount += 1
            print("❌ Assertion Failed [\(file):\(line)]: '\(a)' is not within \(accuracy) of '\(b)'. \(message)")
        }
    }

    public static func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if condition {
            passCount += 1
        } else {
            failCount += 1
            print("❌ Assertion Failed [\(file):\(line)]: Expected true but got false. \(message)")
        }
    }

    public static func assertFalse(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if !condition {
            passCount += 1
        } else {
            failCount += 1
            print("❌ Assertion Failed [\(file):\(line)]: Expected false but got true. \(message)")
        }
    }

    public static func fail(_ message: String, file: String = #file, line: Int = #line) {
        failCount += 1
        print("❌ Test Failed [\(file):\(line)]: \(message)")
    }
}
