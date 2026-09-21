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
            HStack {
                Text(state.viewTitle)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if !state.isEditing, state.navigation != .smart(.completed) {
                    Button(action: addRoot) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent.color)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Memo")
                }
            }

            ForEach(visibleOpenItems) { item in
                itemBlock(item)
            }

            if state.isComposing, state.composingParentID == nil {
                editorField(placeholder: "New task")
            }

            completedSection
            viewSwitcher
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
    }

    private var visibleOpenItems: [MemoItem] {
        let pending = state.items.filter { $0.parentId == nil && state.pendingHideIDs.contains($0.id) }
        var seen = Set<UUID>()
        return (state.openItems + pending).filter { seen.insert($0.id).inserted }
    }

    private var completedSection: some View {
        let count = state.completedItems.count
        return VStack(alignment: .leading, spacing: 6) {
            if count > 0 || !state.pendingHideIDs.isEmpty {
                Button {
                    state.completedExpanded.toggle()
                } label: {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(state.completedExpanded ? 90 : 0))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Completed \(count)")

                if state.completedExpanded {
                    ForEach(state.completedItems) { item in
                        itemRow(item, indent: 0)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func itemBlock(_ item: MemoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            itemRow(item, indent: 0)
            let kids = state.children(of: item)
            let progress = state.progress(of: item)
            if progress.total > 0 {
                Text("\(progress.done) / \(progress.total)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 22)
            }
            ForEach(kids.filter { !$0.isCompleted || state.completedExpanded }) { child in
                itemRow(child, indent: 1)
            }
            if state.isComposing, state.composingParentID == item.id {
                editorField(placeholder: "Subtask").padding(.leading, 22)
            }
        }
        .opacity(item.isCompleted && state.pendingHideIDs.contains(item.id) ? 0.35 : 1)
        .onChange(of: item.isCompleted) { _, completed in
            guard completed, item.parentId == nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                state.finishHideAnimation(for: item.id)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: MemoItem, indent: Int) -> some View {
        if state.editingItemID == item.id {
            editorField(placeholder: "Task").padding(.leading, CGFloat(indent) * 18)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button(action: { state.toggleCompleted(item) }) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 13))
                        .foregroundStyle(item.isCompleted ? accent.color : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")

                Text(item.title)
                    .font(.system(size: 12.5))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { edit(item) }
            }
            .padding(.leading, CGFloat(indent) * 18)
            .contextMenu {
                Button("Edit") { edit(item) }
                if TaskHierarchy.canAddSubtask(item) {
                    Button("Add Subtask") { addSubtask(item) }
                }
                Button("Delete", role: .destructive) { state.delete(item) }
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
    }

    private var viewSwitcher: some View {
        HStack(spacing: 8) {
            switchChip("Today", selected: state.navigation == .smart(.today)) {
                state.select(.smart(.today))
            }
            switchChip("Inbox", selected: state.navigation == .smart(.inbox)) {
                state.select(.smart(.inbox))
            }
            ForEach(state.customLists.prefix(2)) { list in
                switchChip(list.name, selected: state.navigation == .list(list.id)) {
                    state.select(.list(list.id))
                }
            }
            Menu("More") {
                Button("Completed") { state.select(.smart(.completed)) }
                Divider()
                ForEach(state.customLists) { list in
                    Button(list.name) { state.select(.list(list.id)) }
                }
                Divider()
                Button("New List") { state.addList() }
                if case .list(let id) = state.navigation {
                    Button("Rename List") { state.renameList(id, to: "Renamed") }
                    Button("Move Up") { state.moveList(id, by: -1) }
                    Button("Move Down") { state.moveList(id, by: 1) }
                    Button("Archive List", role: .destructive) { state.archiveList(id) }
                }
            }
            .font(.system(size: 11, weight: .medium))
        }
        .padding(.top, 8)
    }

    private func switchChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? accent.color : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func addRoot() {
        state.beginComposing()
        onBeginEdit()
    }

    private func addSubtask(_ parent: MemoItem) {
        state.beginComposing(parent: parent)
        onBeginEdit()
    }

    private func edit(_ item: MemoItem) {
        state.beginEditing(item)
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
