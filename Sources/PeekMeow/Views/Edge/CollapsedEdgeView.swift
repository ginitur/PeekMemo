import PeekMeowCore
import SwiftUI

struct CollapsedEdgeView: View {
    var edge: ScreenEdge
    var color: RGBAColor = .accent
    var thickness: CGFloat = LayoutMetrics.visibleTabThickness
    var opacity: Double = AppearancePreferences.defaultEdgeTabOpacity
    var showHitRegions: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: visualAlignment) {
                if showHitRegions {
                    HitRegionOverlay(kind: .edge, edge: edge)
                }

                EdgeTabShape(edge: edge)
                    .fill(color.color.opacity(opacity))
                    .frame(width: visualSize(in: proxy.size).width, height: visualSize(in: proxy.size).height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: visualAlignment)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PeekMeow")
        .accessibilityHint("Hover to peek at your notes")
        .accessibilityAddTraits(.isButton)
    }

    private var visualAlignment: Alignment {
        switch edge {
        case .right: return .trailing
        case .left: return .leading
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    private func visualSize(in window: CGSize) -> CGSize {
        let visible = min(max(thickness, AppearancePreferences.thicknessRange.lowerBound), AppearancePreferences.thicknessRange.upperBound)
        return switch edge {
        case .left, .right:
            CGSize(width: visible, height: window.height)
        case .top, .bottom:
            CGSize(width: window.width, height: visible)
        }
    }
}
