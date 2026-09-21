import PeekMemoCore
import SwiftUI

struct CollapsedEdgeView: View {
    var edge: ScreenEdge

    var body: some View {
        GeometryReader { proxy in
            let visual = visualSize(in: proxy.size)
            EdgeTabShape(edge: edge)
                .fill(.primary.opacity(0.42))
                .frame(width: visual.width, height: visual.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: outerAlignment)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PeekMemo")
        .accessibilityHint("Hover to peek at your notes")
        .accessibilityAddTraits(.isButton)
    }

    private var outerAlignment: Alignment {
        switch edge {
        case .right: .trailing
        case .left: .leading
        case .top: .top
        case .bottom: .bottom
        }
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
