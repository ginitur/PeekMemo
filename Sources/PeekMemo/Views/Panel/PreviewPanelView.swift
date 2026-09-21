import PeekMemoCore
import SwiftUI

struct PreviewPanelView: View {
    @Bindable var state: AppState
    var accent: RGBAColor = .accent
    var onBeginEdit: () -> Void
    var onEndEdit: () -> Void
    var onPickerWillOpen: () -> Void = {}
    var onPickerDidClose: () -> Void = {}
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(state.visibleDayItems) { item in
                        itemBlock(item)
                    }
                    if state.isComposing, state.composingParentID == nil {
                        editorField(placeholder: "New task", isSubtask: false)
                    } else if !state.isEditing {
                        Button(action: addRoot) {
                            Text("+ Add Task")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(accent.color)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add Task")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                cornerRadius: 10
            )
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button(action: state.goToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous day")

            Button {
                state.showDatePicker = true
            } label: {
                VStack(spacing: 1) {
                    Text(state.dateTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    let stats = state.dailyStats
                    if stats.total > 0 {
                        Text("\(stats.completed)/\(stats.total)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $state.showDatePicker, arrowEdge: .bottom) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { state.selectedDate },
                        set: {
                            state.selectedDate = DailyView.startOfDay($0)
                            state.showDatePicker = false
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(8)
            }

            Button(action: state.goToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next day")

            Spacer(minLength: 8)

            CategoryPickerButton(
                label: state.filterLabel,
                categories: state.activeCategories,
                onSelectAll: { state.categoryFilter = .all },
                onSelect: { state.categoryFilter = .category($0) },
                onNew: { state.addCategory() },
                onWillOpen: onPickerWillOpen,
                onDidClose: onPickerDidClose
            )
            .frame(minWidth: 44, maxHeight: 18)
            .fixedSize()
        }
    }

    @ViewBuilder
    private func itemBlock(_ item: MemoItem) -> some View {
        let kids = state.children(of: item)
        let showDisclosure = !kids.isEmpty || TaskHierarchy.canAddSubtask(item)
        HStack(alignment: .top, spacing: 6) {
            if showDisclosure {
                Button {
                    state.toggleTaskExpanded(item.id)
                } label: {
                    Image(systemName: state.isTaskExpanded(item.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: 16)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isTaskExpanded(item.id) ? "Collapse subtasks" : "Expand subtasks")
            }
            VStack(alignment: .leading, spacing: 3) {
                parentContent(item)
                if state.isTaskExpanded(item.id) || (kids.isEmpty && state.composingParentID == item.id) {
                    ForEach(kids) { child in
                        itemRow(child, isSubtask: true)
                    }
                    if TaskHierarchy.canAddSubtask(item), !item.isCompleted {
                        if state.isComposing, state.composingParentID == item.id {
                            editorField(placeholder: "Subtask", isSubtask: true)
                                .padding(.leading, LayoutMetrics.subtaskIndent)
                        } else if !state.isEditing {
                            Button(action: { addSubtask(item) }) {
                                Text("+ Add subtask")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(accent.color)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, LayoutMetrics.subtaskIndent)
                            .accessibilityLabel("Add subtask")
                        }
                    }
                }
            }
        }
    }

    private func parentContent(_ item: MemoItem) -> some View {
        let progress = state.progress(of: item)
        return HStack(alignment: .center, spacing: 6) {
            itemRow(item, isSubtask: false)
            if progress.total > 0 {
                Text("\(progress.done)/\(progress.total)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: MemoItem, isSubtask: Bool) -> some View {
        if state.editingItemID == item.id {
            editorField(placeholder: isSubtask ? "Subtask" : "Task", isSubtask: isSubtask)
                .padding(.leading, isSubtask ? LayoutMetrics.subtaskIndent : 0)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if item.type == .task {
                    Button(action: { state.toggleCompleted(item) }) {
                        Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                            .font(.system(size: isSubtask ? 12 : 13))
                            .foregroundStyle(item.isCompleted ? accent.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")
                }

                Text(item.title)
                    .font(.system(size: isSubtask ? 11.5 : 12.5))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .opacity(item.isCompleted ? 0.55 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { edit(item) }

                if !isSubtask, state.categoryFilter == .all {
                    Text(state.categoryForItem(item)?.name ?? "Uncategorized")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, isSubtask ? LayoutMetrics.subtaskIndent : 0)
            .contextMenu {
                Button("Edit") { edit(item) }
                Button("Delete", role: .destructive) { state.delete(item) }
            }
        }
    }

    private func editorField(placeholder: String, isSubtask: Bool) -> some View {
        TextField(placeholder, text: $state.draftText)
            .textFieldStyle(.plain)
            .font(.system(size: isSubtask ? 11.5 : 12.5))
            .padding(6)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .focused($editorFocused)
            .onAppear { editorFocused = true }
            .onSubmit {
                if isSubtask {
                    let keep = state.saveDraft(continueSubtask: true)
                    if keep {
                        editorFocused = true
                    } else {
                        onEndEdit()
                    }
                } else {
                    save()
                }
            }
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
        state.saveDraft(continueSubtask: false)
        onEndEdit()
    }

    private func cancel() {
        state.cancelEdit()
        onEndEdit()
    }
}
