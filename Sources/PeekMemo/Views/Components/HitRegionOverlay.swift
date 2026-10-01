import PeekMemoCore
import SwiftUI

enum HitRegionKind {
    case edge
    case notch
    case content
    case dragHandle
    case sensor
    case headerDate
    case category
    case editor
    case panelHover
    case resizeHandle
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
        case .content: Color.green
        case .dragHandle: Color.pink
        case .sensor: Color.yellow
        case .headerDate: Color.cyan
        case .category: Color.orange
        case .editor: Color.mint
        case .panelHover: Color.green
        case .resizeHandle: Color.purple
        }
    }

    private var label: String {
        switch kind {
        case .edge: "Edge Hit"
        case .notch: "Notch Hit"
        case .content: "Panel Content"
        case .dragHandle: "Drag Handle"
        case .sensor: "Edge Sensor"
        case .headerDate: "Header Date"
        case .category: "Category Button"
        case .editor: "Editor"
        case .panelHover: "Panel Hover Region"
        case .resizeHandle: "Resize Handle"
        }
    }
}
