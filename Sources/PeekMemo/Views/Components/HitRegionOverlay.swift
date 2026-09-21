import PeekMemoCore
import SwiftUI

enum HitRegionKind {
    case edge
    case notch
    case expanded
}

struct HitRegionOverlay: View {
    var kind: HitRegionKind
    var edge: ScreenEdge = .right

    var body: some View {
        Rectangle()
            .fill(tint.opacity(0.28))
            .overlay(
                Rectangle()
                    .strokeBorder(tint.opacity(0.9), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(3)
            }
            .allowsHitTesting(false)
    }

    private var tint: Color {
        switch kind {
        case .edge: Color.blue
        case .notch: Color.orange
        case .expanded: Color.green
        }
    }

    private var label: String {
        switch kind {
        case .edge: "Edge Hit"
        case .notch: "Notch Hit"
        case .expanded: "Expanded Hover"
        }
    }
}
