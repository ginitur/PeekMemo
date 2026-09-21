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
        let span = usableSpan(edge: edge, screen: screen)
        let half = stackLength / 2
        let minOffset = min(half, span / 2)
        let maxOffset = max(span - half, minOffset)
        return min(max(offset, minOffset), maxOffset)
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
        if stored.isNotchCloak,
           PlacementPolicy.allowNotchCloak,
           let notch = NotchGeometry.region(on: screen)
        {
            return notchCloakPlacement(screen: screen, notch: notch, stackLength: stackLength)
        }
        let edge: ScreenEdge = (stored.edge == .top && !PlacementPolicy.allowTopEdgeSnap)
            ? .right
            : stored.edge
        return collapsedPlacement(
            screen: screen,
            edge: edge,
            offset: stored.offset,
            stackLength: stackLength,
            allowNotchCloak: edge == .top && PlacementPolicy.allowNotchCloak
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
        let (edge, distance) = nearestSnappableEdge(to: pointer, on: screen)
        // Live drag is always a visible tab. Cloak only commits on mouse-up.
        if distance <= magnetRange {
            let offset = offsetAlongEdge(pointer: pointer, edge: edge, stackLength: stackLength, screen: screen)
            return collapsedPlacement(
                screen: screen,
                edge: edge,
                offset: offset,
                stackLength: stackLength,
                allowNotchCloak: false
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
        let (edge, _) = nearestSnappableEdge(to: pointer, on: screen)
        if edge == .top,
           PlacementPolicy.allowNotchCloak,
           NotchGeometry.pointerCommitsCloak(pointer, screen: screen)
        {
            if let notch = NotchGeometry.region(on: screen) {
                return notchCloakPlacement(screen: screen, notch: notch, stackLength: stackLength)
            }
        }
        let offset = offsetAlongEdge(pointer: pointer, edge: edge, stackLength: stackLength, screen: screen)
        return collapsedPlacement(
            screen: screen,
            edge: edge,
            offset: offset,
            stackLength: stackLength,
            allowNotchCloak: false
        )
    }

    public static func nearestEdge(to point: CGPoint, on screen: ScreenGeometry) -> (ScreenEdge, CGFloat) {
        nearestEdge(to: point, on: screen, excluding: [])
    }

    public static func nearestSnappableEdge(to point: CGPoint, on screen: ScreenGeometry) -> (ScreenEdge, CGFloat) {
        var excluded: Set<ScreenEdge> = []
        if !PlacementPolicy.allowTopEdgeSnap {
            excluded.insert(.top)
        }
        return nearestEdge(to: point, on: screen, excluding: excluded)
    }

    public static func nearestEdge(
        to point: CGPoint,
        on screen: ScreenGeometry,
        excluding: Set<ScreenEdge>
    ) -> (ScreenEdge, CGFloat) {
        let frame = screen.frame
        var candidates: [(ScreenEdge, CGFloat)] = [
            (.left, abs(point.x - frame.minX)),
            (.right, abs(point.x - frame.maxX)),
            (.bottom, abs(point.y - frame.minY)),
            (.top, abs(point.y - frame.maxY)),
        ]
        candidates.removeAll { excluding.contains($0.0) }
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
            visible.maxY - pointer.y
        case .top, .bottom:
            pointer.x - visible.minX
        }
        return clampOffset(raw, edge: edge, screen: screen, stackLength: stackLength)
    }

    public static func expandedFrame(
        collapsed: PanelPlacement,
        screen: ScreenGeometry,
        panelSize: CGSize
    ) -> CGRect {
        if collapsed.isNotchCloak, let notch = NotchGeometry.region(on: screen) {
            return expandedNotchFrame(notch: notch, screen: screen, panelSize: panelSize)
        }

        let stack = collapsed.edge.isVertical ? collapsed.frame.height : collapsed.frame.width
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: screen,
            panelSize: panelSize,
            stackLength: stack
        )
        return layout.panelFrame
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
            let anchorY = visible.maxY - offset
            let y = min(max(anchorY - size.height / 2, visible.minY), visible.maxY - size.height)
            return CGRect(x: outer - size.width, y: y, width: size.width, height: size.height)
        case .left:
            let anchorY = visible.maxY - offset
            let y = min(max(anchorY - size.height / 2, visible.minY), visible.maxY - size.height)
            return CGRect(x: outer, y: y, width: size.width, height: size.height)
        case .top:
            let anchorX = visible.minX + offset
            let x = min(max(anchorX - size.width / 2, visible.minX), visible.maxX - size.width)
            return CGRect(x: x, y: outer - size.height, width: size.width, height: size.height)
        case .bottom:
            let anchorX = visible.minX + offset
            let x = min(max(anchorX - size.width / 2, visible.minX), visible.maxX - size.width)
            return CGRect(x: x, y: outer, width: size.width, height: size.height)
        }
    }

    /// Expanded cloak window keeps `maxY` at the top of the housing and grows downward
    /// so content slides out from behind the notch. The occluded band is `notch.height`.
    public static func expandedNotchFrame(
        notch: NotchRegion,
        screen: ScreenGeometry,
        panelSize: CGSize
    ) -> CGRect {
        let width = min(max(panelSize.width, notch.frame.width), screen.visibleFrame.width)
        let x = notch.frame.midX - width / 2
        let clampedX = min(max(x, screen.visibleFrame.minX), screen.visibleFrame.maxX - width)
        let height = notch.frame.height + panelSize.height
        return CGRect(
            x: clampedX,
            y: notch.frame.maxY - height,
            width: width,
            height: height
        )
    }

    private static func notchCloakPlacement(
        screen: ScreenGeometry,
        notch: NotchRegion,
        stackLength: CGFloat
    ) -> PanelPlacement {
        let frame = NotchGeometry.collapsedWindowFrame(for: notch)
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
