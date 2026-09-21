import PeekMemoCore
import SwiftUI

/// In-memory interactive prototype. No SQLite.
struct PreviewPanelView: View {
    @Bindable var state: AppState
    var accent: RGBAColor = .accent
    var onBeginEdit: () -> Void
    var onEndEdit: () -> Void
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(state.selectedGroup?.title ?? "Today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            ForEach(state.visibleMemos) { memo in
                memoRow(memo)
            }

            if state.isComposing {
                editorField(placeholder: "New memo")
            }

            if !state.isEditing {
                Button(action: addMemo) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add Memo")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(accent.color)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .accessibilityLabel("Add Memo")
            }
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
        .accessibilityLabel("\(state.selectedGroup?.title ?? "Today") memos")
    }

    @ViewBuilder
    private func memoRow(_ memo: Memo) -> some View {
        if state.editingMemoID == memo.id {
            editorField(placeholder: "Memo")
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button(action: { state.toggleCompleted(memo) }) {
                    Image(systemName: memo.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 13))
                        .foregroundStyle(memo.isCompleted ? accent.color : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(memo.isCompleted ? "Mark incomplete" : "Mark complete")

                Text(memo.text)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.primary)
                    .strikethrough(memo.isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { edit(memo) }
                    .accessibilityAddTraits(.isStaticText)
            }
            .contextMenu {
                Button("Edit") { edit(memo) }
                Button("Delete", role: .destructive) { state.delete(memo) }
            }
        }
    }

    private func editorField(placeholder: String) -> some View {
        TextField(placeholder, text: $state.draftText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
            .padding(6)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .focused($editorFocused)
            .onAppear { editorFocused = true }
            .onSubmit(of: .text) { /* return inserts newline in vertical field */ }
            .onKeyPress(.escape) {
                cancel()
                return .handled
            }
            .onKeyPress(keys: [.return]) { press in
                if press.modifiers.contains(.command) {
                    save()
                    return .handled
                }
                return .ignored
            }
            .accessibilityLabel(placeholder)
    }

    private func addMemo() {
        state.beginComposing()
        onBeginEdit()
    }

    private func edit(_ memo: Memo) {
        state.beginEditing(memo)
        onBeginEdit()
    }

    private func save() {
        state.saveDraft()
        onEndEdit()
    }

    private func cancel() {
        state.cancelEdit()
        onEndEdit()
    }
}
