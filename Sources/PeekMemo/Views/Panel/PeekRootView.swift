import PeekMemoCore
import SwiftUI

struct PeekRootView: View {
    var edge: ScreenEdge
    var isNotchCloak: Bool
    var phase: PeekMemoCore.HoverPhase
    var accent: RGBAColor = .accent
    var showHitRegions: Bool = false

    private var isExpanded: Bool {
        phase == .expanded || phase == .pinned || phase == .editing
    }

    var body: some View {
        ZStack {
            if isExpanded {
                expandedBody
                    .transition(.opacity)
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
        .scaleEffect(isExpanded ? 1 : 0.98, anchor: scaleAnchor)
        .animation(motion, value: isExpanded)
        .animation(motion, value: phase)
    }

    private var expandedBody: some View {
        let handle = DragHandleView(edge: edge, isNotchCloak: isNotchCloak, accent: accent)
        let preview = PreviewPanelView(accent: accent)
        return Group {
            switch edge {
            case .right:
                HStack(spacing: 0) {
                    preview
                    handle.frame(width: LayoutMetrics.hoverHitThickness)
                }
            case .left:
                HStack(spacing: 0) {
                    handle.frame(width: LayoutMetrics.hoverHitThickness)
                    preview
                }
            case .top:
                VStack(spacing: 0) {
                    handle.frame(height: LayoutMetrics.hoverHitThickness)
                    preview
                }
            case .bottom:
                VStack(spacing: 0) {
                    preview
                    handle.frame(height: LayoutMetrics.hoverHitThickness)
                }
            }
        }
    }

    private var scaleAnchor: UnitPoint {
        if isNotchCloak { return .top }
        switch edge {
        case .right: return .trailing
        case .left: return .leading
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    private var motion: Animation {
        .easeInOut(duration: LayoutMetrics.panelAnimationDuration)
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
