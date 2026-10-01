import Foundation

/// Reduce Motion is preference OR the system setting. Movement duration becomes 0.
/// Content fade durations stay on `LayoutMetrics` and are not part of this policy.
public enum MotionPolicy: Sendable {
    public static func shouldReduce(preference: Bool, systemEnabled: Bool) -> Bool {
        preference || systemEnabled
    }

    public static func movementDuration(_ duration: TimeInterval, reduce: Bool) -> TimeInterval {
        reduce ? 0 : duration
    }
}
