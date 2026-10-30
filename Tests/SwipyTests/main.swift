import Foundation

print("==================================================")
print("🚀 Launching Swipy Automated Test Suite")
print("==================================================")

let startTime = CFAbsoluteTimeGetCurrent()

print("\n[1/8] Running CoordinateMapperTests...")
CoordinateMapperTests.run()

print("\n[2/8] Running HandPoseMappingTests...")
HandPoseMappingTests.run()

print("\n[3/8] Running GestureRecognitionTests...")
GestureRecognitionTests.run()

print("\n[4/8] Running MotionSmootherTests...")
MotionSmootherTests.run()

print("\n[5/8] Running SettingsTests...")
SettingsTests.run()

print("\n[6/8] Running CursorAccelerationTests...")
CursorAccelerationTests.run()

print("\n[7/8] Running TrackpadMotionTests...")
TrackpadMotionTests.run()

print("\n[8/8] Running PointerStabilityTests...")
PointerStabilityTests.run()

let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

print("\n==================================================")
print("📊 Test Summary:")
print("   Passed Assertions: \(TestHarness.passCount)")
print("   Failed Assertions: \(TestHarness.failCount)")
print(String(format: "   Execution Time   : %.2f ms", elapsedMs))
print("==================================================")

if TestHarness.failCount > 0 {
    print("❌ SOME TESTS FAILED!")
    exit(1)
} else {
    print("✅ ALL TESTS PASSED SUCCESSFULLY!")
    exit(0)
}
