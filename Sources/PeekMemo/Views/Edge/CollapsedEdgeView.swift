import PeekMemoCore
import SwiftUI

struct CollapsedEdgeView: View {
    var edge: ScreenEdge
    var isNotchCloak: Bool = false
    var accent: RGBAColor = .accent
    var showHitRegions: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: visualAlignment) {
                if showHitRegions {
                    HitRegionOverlay(
                        kind: isNotchCloak ? .notch : .edge,
                        edge: edge
                    )
                }

                if isNotchCloak {
                    cloakHairline
                } else {
                    EdgeTabShape(edge: edge)
                        .fill(accent.color.opacity(0.55))
                        .frame(width: visualSize(in: proxy.size).width, height: visualSize(in: proxy.size).height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: visualAlignment)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isNotchCloak ? "PeekMemo, hidden in notch" : "PeekMemo")
        .accessibilityHint("Hover to peek at your notes")
        .accessibilityAddTraits(.isButton)
    }

    private var visualAlignment: Alignment {
        if isNotchCloak { return .top }
        switch edge {
        case .right: return .trailing
        case .left: return .leading
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    private var cloakHairline: some View {
        Rectangle()
            .fill(accent.color.opacity(0.22))
            .frame(height: LayoutMetrics.notchCloakVisibleThickness)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private func visualSize(in window: CGSize) -> CGSize {
        switch edge {
        case .left, .right:
            CGSize(width: LayoutMetrics.visibleTabThickness, height: window.height)
        case .top, .bottom:
            CGSize(width: window.width, height: LayoutMetrics.visibleTabThickness)
        }
    }
}
