import AppKit
import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = false
        if cornerRadius > 0 {
            view.wantsLayer = true
            view.layer?.cornerRadius = cornerRadius
            view.layer?.masksToBounds = true
        }
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        if cornerRadius > 0 {
            view.wantsLayer = true
            view.layer?.cornerRadius = cornerRadius
        }
    }
}
