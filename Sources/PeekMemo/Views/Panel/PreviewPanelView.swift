import PeekMemoCore
import SwiftUI

/// Minimal preview used to verify window behavior. No persistence.
struct PreviewPanelView: View {
    var accent: RGBAColor = .accent
    var groupTitle: String = "Today"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(groupTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            previewRow(done: false, text: "Example task")
            previewRow(done: false, text: "Another memo")

            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add Memo")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(accent.color)
            .padding(.top, 4)
            .accessibilityLabel("Add Memo")
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                cornerRadius: 10
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(groupTitle) memos")
    }

    private func previewRow(done: Bool, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: done ? "checkmark.square" : "square")
                .font(.system(size: 13))
                .foregroundStyle(done ? accent.color : .secondary)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary)
                .strikethrough(done)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(done ? "Completed, \(text)" : text)
        .accessibilityAddTraits(.isStaticText)
    }
}
