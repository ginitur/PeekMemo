import PeekMemoCore
import SwiftUI

struct PeekRootView: View {
    var edge: ScreenEdge
    var isNotchCloak: Bool
    var phase: PeekMemoCore.HoverPhase
    var accent: RGBAColor = .accent
    var showHitRegions: Bool = false
    /// Height of the physical housing, in the expanded window’s top. Content starts below it.
    var notchOccludedHeight: CGFloat = 0
    var contentOpacity: Double = 1

    private var isExpanded: Bool {
        phase == .expanded || phase == .pinned || phase == .editing
    }

    var body: some View {
        ZStack {
            if isExpanded {
                expandedBody
            } else {
                CollapsedEdgeView(
                    edge: edge,
                    isNotchCloak: isNotchCloak,
                    accent: accent,
                    showHitRegions: showHitRegions
                )
            }

            if showHitRegions, isExpanded {
                HitRegionOverlay(kind: .expanded, edge: edge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expandedBody: some View {
        let handle = DragHandleView(edge: edge, isNotchCloak: isNotchCloak, accent: accent)
        let preview = PreviewPanelView(accent: accent)
        return Group {
            switch edge {
            case .right:
                HStack(spacing: 0) {
                    preview.opacity(contentOpacity)
                    handle.frame(width: LayoutMetrics.hoverHitThickness)
                }
            case .left:
                HStack(spacing: 0) {
                    handle.frame(width: LayoutMetrics.hoverHitThickness)
                    preview.opacity(contentOpacity)
                }
            case .top:
                VStack(spacing: 0) {
                    if isNotchCloak, notchOccludedHeight > 0 {
                        Color.clear.frame(height: notchOccludedHeight)
                    }
                    handle.frame(height: LayoutMetrics.hoverHitThickness)
                    preview.opacity(contentOpacity)
                }
            case .bottom:
                VStack(spacing: 0) {
                    preview.opacity(contentOpacity)
                    handle.frame(height: LayoutMetrics.hoverHitThickness)
                }
            }
        }
    }

}

struct DragHandleView: View {
    var edge: ScreenEdge
    var isNotchCloak: Bool
    var accent: RGBAColor

    var body: some View {
        ZStack {
            Color.clear
            Capsule()
                .fill(accent.color.opacity(isNotchCloak ? 0.7 : 0.45))
                .frame(
                    width: edge.isVertical ? 3 : 22,
                    height: edge.isVertical ? 22 : 3
                )
        }
        .accessibilityLabel("PeekMemo drag handle")
        .accessibilityHint("Drag to move PeekMemo")
        .accessibilityAddTraits(.isButton)
    }
}
