import Foundation

print("==================================================")
print("🚀 Launching Swipy Automated Test Suite")
print("==================================================")

let startTime = CFAbsoluteTimeGetCurrent()

print("\n[1/7] Running CoordinateMapperTests...")
CoordinateMapperTests.run()

print("\n[2/7] Running HandPoseMappingTests...")
HandPoseMappingTests.run()

print("\n[3/7] Running GestureRecognitionTests...")
GestureRecognitionTests.run()

print("\n[4/7] Running MotionSmootherTests...")
MotionSmootherTests.run()

print("\n[5/7] Running SettingsTests...")
SettingsTests.run()

print("\n[6/7] Running CursorAccelerationTests...")
CursorAccelerationTests.run()

print("\n[7/7] Running TrackpadMotionTests...")
TrackpadMotionTests.run()

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
