import Foundation

/// Real-time metrics and diagnostic telemetry for Swipy tracking performance.
public final class DiagnosticsLogger: @unchecked Sendable {
    public static let shared = DiagnosticsLogger()

    private let lock = NSLock()
    private var frameTimestamps: [TimeInterval] = []
    private var inferenceDurations: [Double] = []
    private var dispatchedEventsCount: Int = 0
    private var droppedFramesCount: Int = 0

    public init() {}

    /// Logs an inference cycle.
    public func recordInference(durationMs: Double, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        lock.lock()
        defer { lock.unlock() }

        frameTimestamps.append(timestamp)
        inferenceDurations.append(durationMs)

        // Keep last 60 samples
        if frameTimestamps.count > 60 {
            frameTimestamps.removeFirst(frameTimestamps.count - 60)
        }
        if inferenceDurations.count > 60 {
            inferenceDurations.removeFirst(inferenceDurations.count - 60)
        }
    }

    /// Records dropped camera frame.
    public func recordDroppedFrame() {
        lock.lock()
        defer { lock.unlock() }
        droppedFramesCount += 1
    }

    /// Records dispatched mouse or keyboard event.
    public func recordEvent() {
        lock.lock()
        defer { lock.unlock() }
        dispatchedEventsCount += 1
    }

    /// Current processed frames per second.
    public var currentFPS: Double {
        lock.lock()
        defer { lock.unlock() }
        guard frameTimestamps.count >= 2,
              let first = frameTimestamps.first,
              let last = frameTimestamps.last,
              last > first else {
            return 0.0
        }
        return Double(frameTimestamps.count - 1) / (last - first)
    }

    /// Average inference duration in milliseconds.
    public var averageInferenceMs: Double {
        lock.lock()
        defer { lock.unlock() }
        guard !inferenceDurations.isEmpty else { return 0.0 }
        let total = inferenceDurations.reduce(0.0, +)
        return total / Double(inferenceDurations.count)
    }

    /// Total count of dispatched events.
    public var eventCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return dispatchedEventsCount
    }
}
