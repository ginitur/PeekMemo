import CoreGraphics
import Foundation

public enum EdgeGeometry: Sendable {
    public static func collapsedWindowSize(edge: ScreenEdge, stackLength: CGFloat) -> CGSize {
        switch edge {
        case .left, .right:
            CGSize(width: LayoutMetrics.hoverHitThickness, height: stackLength)
        case .top, .bottom:
            CGSize(width: stackLength, height: LayoutMetrics.hoverHitThickness)
        }
    }

    public static func usableSpan(edge: ScreenEdge, screen: ScreenGeometry) -> CGFloat {
        switch edge {
        case .left, .right:
            screen.visibleFrame.height
        case .top, .bottom:
            screen.visibleFrame.width
        }
    }

    public static func clampOffset(
        _ offset: CGFloat,
        edge: ScreenEdge,
        screen: ScreenGeometry,
        stackLength: CGFloat
    ) -> CGFloat {
        let maxOffset = max(0, usableSpan(edge: edge, screen: screen) - stackLength)
        return min(max(offset, 0), maxOffset)
    }

    /// Outer coordinate of an edge, in screen space.
    /// Uses `visibleFrame` when the Dock insets that edge so the tab stays hittable.
    public static func outerCoordinate(edge: ScreenEdge, screen: ScreenGeometry) -> CGFloat {
        let frame = screen.frame
        let visible = screen.visibleFrame
        switch edge {
        case .left:
            return visible.minX - frame.minX > 1 ? visible.minX : frame.minX
        case .right:
            return frame.maxX - visible.maxX > 1 ? visible.maxX : frame.maxX
        case .bottom:
            return visible.minY - frame.minY > 1 ? visible.minY : frame.minY
        case .top:
            // Menu bar always insets the top. Normal Top mode sits under it.
            return visible.maxY
        }
    }

    public static func collapsedPlacement(
        screen: ScreenGeometry,
        edge: ScreenEdge,
        offset: CGFloat,
        stackLength: CGFloat,
        allowNotchCloak: Bool = true
    ) -> PanelPlacement {
        let cloak = allowNotchCloak
            && NotchGeometry.shouldCloak(
                edge: edge,
                offset: offset,
                stackLength: stackLength,
                screen: screen
            )

        if cloak, let notch = NotchGeometry.region(on: screen) {
            return notchCloakPlacement(screen: screen, notch: notch, stackLength: stackLength)
        }

        let clamped = clampOffset(offset, edge: edge, screen: screen, stackLength: stackLength)
        let size = collapsedWindowSize(edge: edge, stackLength: stackLength)
        let frame = collapsedFrame(
            screen: screen,
            edge: edge,
            offset: clamped,
            size: size
        )
        return PanelPlacement(
            displayIdentifier: screen.identifier,
            edge: edge,
            offset: clamped,
            frame: frame,
            isNotchCloak: false,
            isSnapped: true
        )
    }

    public static func placement(
        from stored: DisplayPlacement,
        screen: ScreenGeometry,
        stackLength: CGFloat
    ) -> PanelPlacement {
        let allowCloak = stored.isNotchCloak || stored.edge == .top
        return collapsedPlacement(
            screen: screen,
            edge: stored.edge,
            offset: stored.offset,
            stackLength: stackLength,
            allowNotchCloak: allowCloak
        )
    }

    /// Live placement while the pointer is down.
    /// Follows the cursor until within `magnetRange` of an edge, then snaps.
    public static func draggingPlacement(
        pointer: CGPoint,
        screen: ScreenGeometry,
        stackLength: CGFloat,
        grabSize: CGSize,
        magnetRange: CGFloat = LayoutMetrics.magnetRange
    ) -> PanelPlacement {
        let (edge, distance) = nearestEdge(to: pointer, on: screen)
        if distance <= magnetRange {
            let offset = offsetAlongEdge(pointer: pointer, edge: edge, stackLength: stackLength, screen: screen)
            return collapsedPlacement(
                screen: screen,
                edge: edge,
                offset: offset,
                stackLength: stackLength,
                allowNotchCloak: true
            )
        }

        let frame = CGRect(
            x: pointer.x - grabSize.width / 2,
            y: pointer.y - grabSize.height / 2,
            width: grabSize.width,
            height: grabSize.height
        )
        let offset = offsetAlongEdge(pointer: pointer, edge: edge, stackLength: stackLength, screen: screen)
        return PanelPlacement(
            displayIdentifier: screen.identifier,
            edge: edge,
            offset: offset,
            frame: frame,
            isNotchCloak: false,
            isSnapped: false
        )
    }

    /// Mouse-up always commits to the nearest legal edge.
    public static func committedPlacement(
        pointer: CGPoint,
        screen: ScreenGeometry,
        stackLength: CGFloat
    ) -> PanelPlacement {
        let (edge, _) = nearestEdge(to: pointer, on: screen)
        let offset = offsetAlongEdge(pointer: pointer, edge: edge, stackLength: stackLength, screen: screen)
        return collapsedPlacement(
            screen: screen,
            edge: edge,
            offset: offset,
            stackLength: stackLength,
            allowNotchCloak: true
        )
    }

    public static func nearestEdge(to point: CGPoint, on screen: ScreenGeometry) -> (ScreenEdge, CGFloat) {
        let frame = screen.frame
        let candidates: [(ScreenEdge, CGFloat)] = [
            (.left, abs(point.x - frame.minX)),
            (.right, abs(point.x - frame.maxX)),
            (.bottom, abs(point.y - frame.minY)),
            (.top, abs(point.y - frame.maxY)),
        ]
        return candidates.min(by: { $0.1 < $1.1 }) ?? (.right, 0)
    }

    public static func offsetAlongEdge(
        pointer: CGPoint,
        edge: ScreenEdge,
        stackLength: CGFloat,
        screen: ScreenGeometry
    ) -> CGFloat {
        let visible = screen.visibleFrame
        let raw: CGFloat = switch edge {
        case .left, .right:
            visible.maxY - pointer.y - stackLength / 2
        case .top, .bottom:
            pointer.x - visible.minX - stackLength / 2
        }
        return clampOffset(raw, edge: edge, screen: screen, stackLength: stackLength)
    }

    public static func expandedFrame(
        collapsed: PanelPlacement,
        screen: ScreenGeometry,
        panelSize: CGSize
    ) -> CGRect {
        if collapsed.isNotchCloak, let notch = NotchGeometry.region(on: screen) {
            let width = min(panelSize.width, screen.visibleFrame.width)
            let x = notch.frame.midX - width / 2
            let clampedX = min(max(x, screen.visibleFrame.minX), screen.visibleFrame.maxX - width)
            return CGRect(
                x: clampedX,
                y: notch.frame.minY - panelSize.height,
                width: width,
                height: panelSize.height
            )
        }

        let origin = collapsed.frame
        switch collapsed.edge {
        case .right:
            return CGRect(
                x: origin.maxX - panelSize.width,
                y: origin.maxY - panelSize.height,
                width: panelSize.width,
                height: panelSize.height
            )
        case .left:
            return CGRect(
                x: origin.minX,
                y: origin.maxY - panelSize.height,
                width: panelSize.width,
                height: panelSize.height
            )
        case .top:
            return CGRect(
                x: origin.minX,
                y: origin.maxY - panelSize.height,
                width: panelSize.width,
                height: panelSize.height
            )
        case .bottom:
            return CGRect(
                x: origin.minX,
                y: origin.minY,
                width: panelSize.width,
                height: panelSize.height
            )
        }
    }

    private static func collapsedFrame(
        screen: ScreenGeometry,
        edge: ScreenEdge,
        offset: CGFloat,
        size: CGSize
    ) -> CGRect {
        let visible = screen.visibleFrame
        let outer = outerCoordinate(edge: edge, screen: screen)
        switch edge {
        case .right:
            return CGRect(
                x: outer - size.width,
                y: visible.maxY - offset - size.height,
                width: size.width,
                height: size.height
            )
        case .left:
            return CGRect(
                x: outer,
                y: visible.maxY - offset - size.height,
                width: size.width,
                height: size.height
            )
        case .top:
            return CGRect(
                x: visible.minX + offset,
                y: outer - size.height,
                width: size.width,
                height: size.height
            )
        case .bottom:
            return CGRect(
                x: visible.minX + offset,
                y: outer,
                width: size.width,
                height: size.height
            )
        }
    }

    private static func notchCloakPlacement(
        screen: ScreenGeometry,
        notch: NotchRegion,
        stackLength: CGFloat
    ) -> PanelPlacement {
        let hit = LayoutMetrics.hoverHitThickness
        // Window covers the notch plus an underside tracking strip.
        // Visual content in the notch may be empty; interaction lives in the strip.
        let width = max(stackLength, notch.frame.width)
        let x = notch.frame.midX - width / 2
        let frame = CGRect(
            x: x,
            y: notch.frame.minY - hit,
            width: width,
            height: notch.frame.height + hit
        )
        let offset = NotchGeometry.cloakOffset(stackLength: stackLength, screen: screen)
        return PanelPlacement(
            displayIdentifier: screen.identifier,
            edge: .top,
            offset: offset,
            frame: frame,
            isNotchCloak: true,
            isSnapped: true
        )
    }
}
