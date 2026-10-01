import AppKit
import PeekMemoCore
import SwiftUI

/// Material, solid color, and image share the panel's rounded clip. The image is not stretched.
struct PanelBackgroundView: View {
    var appearance: AppearancePreferences
    var image: NSImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                cornerRadius: PanelSizeMetrics.cornerRadius
            )
            switch appearance.backgroundMode {
            case .systemMaterial:
                EmptyView()
            case .solidColor:
                appearance.backgroundSolidColor.color
                    .opacity(appearance.backgroundSolidOpacity)
            case .image:
                if let image {
                    fittedImage(image)
                    Rectangle()
                        .fill(overlayTint.opacity(appearance.backgroundOverlayOpacity))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Dark theme dims with black. Light theme lifts with white. The user's opacity wins.
    private var overlayTint: Color {
        colorScheme == .dark ? .black : .white
    }

    private func fittedImage(_ image: NSImage) -> some View {
        GeometryReader { geo in
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: appearance.backgroundImageContentMode == .fill ? .fill : .fit)
                .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
                .clipped()
        }
        .opacity(appearance.backgroundImageOpacity)
    }

    private var alignment: Alignment {
        switch appearance.backgroundImagePosition {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
    }
}
