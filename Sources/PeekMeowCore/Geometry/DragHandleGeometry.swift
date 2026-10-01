import CoreGraphics
import Foundation

public enum DragHandleGeometry: Sendable {
    /// AppKit view coordinates, origin bottom-left.
    public static func rect(
        in bounds: CGRect,
        edge: ScreenEdge,
        handleOffsetInsidePanel: CGFloat,
        stackLength: CGFloat,
        thickness: CGFloat = LayoutMetrics.hoverHitThickness
    ) -> CGRect {
        let length = stackLength
        let offset = handleOffsetInsidePanel
        switch edge {
        case .right:
            return CGRect(
                x: bounds.width - thickness,
                y: bounds.height - offset - length / 2,
                width: thickness,
                height: length
            )
        case .left:
            return CGRect(
                x: 0,
                y: bounds.height - offset - length / 2,
                width: thickness,
                height: length
            )
        case .top:
            return CGRect(
                x: offset - length / 2,
                y: bounds.height - thickness,
                width: length,
                height: thickness
            )
        case .bottom:
            return CGRect(
                x: offset - length / 2,
                y: 0,
                width: length,
                height: thickness
            )
        }
    }
}


