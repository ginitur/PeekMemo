import AppKit
import PeekMeowCore
import SwiftUI

struct PeekRootView: View {
    var edge: ScreenEdge
    var phase: PeekMeowCore.HoverPhase
    var appearance: AppearancePreferences = .default
    var backgroundImage: NSImage? = nil
    var accent: RGBAColor = .accent
    var tabColor: RGBAColor = .accent
    var tabThickness: CGFloat = LayoutMetrics.visibleTabThickness
    var tabOpacity: Double = AppearancePreferences.defaultEdgeTabOpacity
    var showHitRegions: Bool = false
    var showInteractionRegions: Bool = false
    @ObservedObject var reveal: RevealChrome
    var appState: AppState
    var onBeginEdit: () -> Void = {}
    var onEndEdit: () -> Void = {}
    var onInteractionBegan: () -> Void = {}
    var onInteractionEnded: () -> Void = {}
    var onEditorFrameChange: (CGRect) -> Void = { _ in }
    var onResizeBegan: () -> Void = {}
    var onResizeChanged: () -> Void = {}
    var onResizeEnded: () -> Void = {}
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
                    color: tabColor,
                    thickness: tabThickness,
                    opacity: tabOpacity,
                    showHitRegions: showHitRegions
                )
            }

            if showHitRegions, isExpanded {
                HitRegionOverlay(kind: .content, edge: edge)
            }
            if showInteractionRegions, isExpanded {
                HitRegionOverlay(kind: .panelHover, edge: edge)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expandedBody: some View {
        let preview = PreviewPanelView(
            state: appState,
            edge: edge,
            appearance: appearance,
            backgroundImage: backgroundImage,
            accent: accent,
            showInteractionRegions: showInteractionRegions,
            onBeginEdit: onBeginEdit,
            onEndEdit: onEndEdit,
            onInteractionBegan: onInteractionBegan,
            onInteractionEnded: onInteractionEnded,
            onEditorFrameChange: onEditorFrameChange,
            onResizeBegan: onResizeBegan,
            onResizeChanged: onResizeChanged,
            onResizeEnded: onResizeEnded
        )
        return Group {
            switch edge {
            case .right:
                HStack(spacing: 0) {
                    revealed(preview)
                    handleRail(vertical: true)
                }
            case .left:
                HStack(spacing: 0) {
                    handleRail(vertical: true)
                    revealed(preview)
                }
            case .top:
                VStack(spacing: 0) {
                    handleRail(vertical: false)
                    revealed(preview)
                }
            case .bottom:
                VStack(spacing: 0) {
                    revealed(preview)
                    handleRail(vertical: false)
                }
            }
        }
    }

    private var scaleAnchor: UnitPoint {
        switch edge {
        case .right: .trailing
        case .left: .leading
        case .bottom: .bottom
        case .top: .top
        }
    }

    private func revealed(_ preview: PreviewPanelView) -> some View {
        preview
            .scaleEffect(
                RevealMotion.contentScale(opacity: reveal.opacity, reduceMotion: reveal.reduceMotion),
                anchor: scaleAnchor
            )
            .opacity(reveal.opacity)
            .animation(reveal.animation, value: reveal.opacity)
    }

    @ViewBuilder
    private func handleRail(vertical: Bool) -> some View {
        let handle = DragHandleView(edge: edge, accent: tabColor)
        let thickness = LayoutMetrics.hoverHitThickness
        ZStack(alignment: vertical ? .top : .leading) {
            Color.clear.allowsHitTesting(false)
            handle
                .allowsHitTesting(false)
                .frame(
                    width: vertical ? thickness : stackLength,
                    height: vertical ? stackLength : thickness
                )
                .overlay {
                    if showInteractionRegions || showHitRegions {
                        HitRegionOverlay(kind: .dragHandle, edge: edge)
                    }
                }
                .offset(
                    x: vertical ? 0 : handleOffsetInsidePanel - stackLength / 2,
                    y: vertical ? handleOffsetInsidePanel - stackLength / 2 : 0
                )
            if showInteractionRegions {
                HitRegionOverlay(kind: .sensor, edge: edge)
                    .frame(
                        width: vertical ? thickness : nil,
                        height: vertical ? nil : thickness
                    )
                    .allowsHitTesting(false)
            }
        }
        .frame(width: vertical ? thickness : nil, height: vertical ? nil : thickness)
        .allowsHitTesting(false)
    }

}

struct DragHandleView: View {
    var edge: ScreenEdge
    var accent: RGBAColor

    var body: some View {
        ZStack {
            Color.clear
            Capsule()
                .fill(accent.color.opacity(0.45))
                .frame(
                    width: edge.isVertical ? 3 : 22,
                    height: edge.isVertical ? 22 : 3
                )
        }
        .accessibilityLabel("PeekMeow drag handle")
        .accessibilityHint("Drag to move PeekMeow")
        .accessibilityAddTraits(.isButton)
    }
}
