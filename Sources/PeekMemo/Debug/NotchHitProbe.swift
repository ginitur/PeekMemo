import AppKit
import os
import PeekMemoCore

/// DEBUG-only classifier for pointer events against the physical notch.
@MainActor
enum NotchHitProbe {
    private static let log = Logger(subsystem: "com.peekmemo.app", category: "NotchHitProbe")
    private static var lastZone: NotchGeometry.HitZone?
    private static var moveReports = 0

    static func record(point: CGPoint, notch: NotchRegion?) {
        guard let notch else {
            return
        }
        let zone = NotchGeometry.hitZone(of: point, notch: notch)
        if zone != lastZone {
            lastZone = zone
            moveReports = 0
            switch zone {
            case .notchRect:
                log.notice("mouse entered notch rect")
                print("[NotchHitProbe] mouse entered notch rect \(notch.frame)")
            case .activationExtension:
                log.notice("mouse entered fallback activation strip")
                print("[NotchHitProbe] mouse entered fallback activation strip")
            case .outside:
                log.notice("mouse exited notch rect")
                print("[NotchHitProbe] mouse exited notch rect")
            }
        } else if zone == .notchRect, moveReports < 3 {
            moveReports += 1
            log.debug("mouse moved inside notch rect")
            print("[NotchHitProbe] mouse moved inside notch rect")
        }
    }

    static func reset() {
        lastZone = nil
    }
}
