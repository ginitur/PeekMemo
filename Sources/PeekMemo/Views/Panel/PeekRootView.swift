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
    var appState: AppState
    var onBeginEdit: () -> Void = {}
    var onEndEdit: () -> Void = {}
    var onPickerWillOpen: () -> Void = {}
    var onPickerDidClose: () -> Void = {}
    var handleOffsetInsidePanel: CGFloat = 0
    var stackLength: CGFloat = LayoutMetrics.defaultStackLength

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
                HitRegionOverlay(kind: .content, edge: edge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expandedBody: some View {
        let preview = PreviewPanelView(
            state: appState,
            accent: accent,
            onBeginEdit: onBeginEdit,
            onEndEdit: onEndEdit,
            onPickerWillOpen: onPickerWillOpen,
            onPickerDidClose: onPickerDidClose
        )
        return Group {
            switch edge {
            case .right:
                HStack(spacing: 0) {
                    preview.opacity(contentOpacity)
                    handleRail(vertical: true)
                }
            case .left:
                HStack(spacing: 0) {
                    handleRail(vertical: true)
                    preview.opacity(contentOpacity)
                }
            case .top:
                VStack(spacing: 0) {
                    if isNotchCloak, notchOccludedHeight > 0 {
                        Color.clear.frame(height: notchOccludedHeight)
                    }
                    handleRail(vertical: false)
                    preview.opacity(contentOpacity)
                }
            case .bottom:
                VStack(spacing: 0) {
                    preview.opacity(contentOpacity)
                    handleRail(vertical: false)
                }
            }
        }
    }

    @ViewBuilder
    private func handleRail(vertical: Bool) -> some View {
        let handle = DragHandleView(edge: edge, isNotchCloak: isNotchCloak, accent: accent)
        let thickness = LayoutMetrics.hoverHitThickness
        ZStack(alignment: vertical ? .top : .leading) {
            Color.clear
            handle
                .frame(
                    width: vertical ? thickness : stackLength,
                    height: vertical ? stackLength : thickness
                )
                .offset(
                    x: vertical ? 0 : handleOffsetInsidePanel - stackLength / 2,
                    y: vertical ? handleOffsetInsidePanel - stackLength / 2 : 0
                )
        }
        .frame(width: vertical ? thickness : nil, height: vertical ? nil : thickness)
        .overlay {
            if showHitRegions {
                HitRegionOverlay(kind: .dragHandle, edge: edge)
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
