import PeekMeowCore
import SwiftUI

/// Thin trapezoid / wedge that sits on a screen edge.
struct EdgeTabShape: Shape {
    var edge: ScreenEdge

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let taper = min(6, max(2, (edge.isVertical ? rect.height : rect.width) * 0.12))
        switch edge {
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - taper))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + taper))
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - taper))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + taper))
        case .top:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - taper, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + taper, y: rect.minY))
        case .bottom:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - taper, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + taper, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}
