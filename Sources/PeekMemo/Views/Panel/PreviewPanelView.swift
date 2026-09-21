import PeekMemoCore
import SwiftUI

/// In-memory interactive prototype. No SQLite.
struct PreviewPanelView: View {
    @Bindable var state: AppState
    var accent: RGBAColor = .accent
    var onBeginEdit: () -> Void
    var onEndEdit: () -> Void
    var onMoreWillOpen: () -> Void = {}
    var onMoreDidClose: () -> Void = {}
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(visibleOpenItems) { item in
                        itemBlock(item)
                    }
                    if state.isComposing, state.composingParentID == nil {
                        editorField(placeholder: "New task", isSubtask: false)
                    }
                    completedSection
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            Divider()
            bottomNavigation
                .frame(height: BottomNavLayout.height)
                .padding(.horizontal, 12)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if state.isDailyView {
                    Button(action: state.goToPreviousDay) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous day")

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { state.selectedDate },
                            set: { state.selectedDate = DailyView.startOfDay($0); state.navigation = .smart(.today) }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Button(action: state.goToNextDay) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next day")
                }

                Text(state.viewTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .frame(maxWidth: state.isDailyView ? nil : .infinity, alignment: .leading)

                if !state.isDailyView, !state.isEditing, state.navigation != .smart(.completed) {
                    Button(action: addRoot) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent.color)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Memo")
                }
            }

            if state.isDailyView {
                HStack {
                    let stats = state.dailyStats
                    Text("\(stats.completed) / \(stats.total) completed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !DailyView.isSameDay(state.selectedDate, Date()) {
                        Button("今天", action: state.goToToday)
                            .font(.system(size: 11, weight: .medium))
                            .buttonStyle(.plain)
                            .foregroundStyle(accent.color)
                    }
                    if !state.isEditing {
                        Button(action: addRoot) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(accent.color)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add Task")
                    }
                }
            }
        }
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
        let kids = state.children(of: item)
        let expanded = state.isTaskExpanded(item.id) || kids.isEmpty == false && state.composingParentID == item.id
        let showBody = kids.isEmpty ? true : state.isTaskExpanded(item.id)
        VStack(alignment: .leading, spacing: 4) {
            parentRow(item, childCount: kids.count)
            if showBody || expanded {
                let progress = state.progress(of: item)
                if progress.total > 0, state.isTaskExpanded(item.id) {
                    ForEach(kids.filter { !$0.isCompleted || state.completedExpanded }) { child in
                        itemRow(child, indent: 1)
                    }
                    if TaskHierarchy.canAddSubtask(item), !item.isCompleted {
                        if state.isComposing, state.composingParentID == item.id {
                            editorField(placeholder: "Subtask", isSubtask: true)
                                .padding(.leading, 22)
                        } else if !state.isEditing || state.composingParentID == item.id {
                            Button(action: { addSubtask(item) }) {
                                Text("+ Add subtask")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(accent.color)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 22)
                            .accessibilityLabel("Add subtask")
                        }
                    }
                } else if TaskHierarchy.canAddSubtask(item), state.isTaskExpanded(item.id), !item.isCompleted {
                    if state.isComposing, state.composingParentID == item.id {
                        editorField(placeholder: "Subtask", isSubtask: true)
                            .padding(.leading, 22)
                    } else if !state.isEditing {
                        Button(action: { addSubtask(item) }) {
                            Text("+ Add subtask")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(accent.color)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 22)
                    }
                }
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

    private func parentRow(_ item: MemoItem, childCount: Int) -> some View {
        let progress = state.progress(of: item)
        return HStack(alignment: .center, spacing: 6) {
            if childCount > 0 || TaskHierarchy.canAddSubtask(item) {
                Button {
                    state.toggleTaskExpanded(item.id)
                } label: {
                    Image(systemName: state.isTaskExpanded(item.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isTaskExpanded(item.id) ? "Collapse" : "Expand")
            }
            itemRow(item, indent: 0)
            if progress.total > 0 {
                Text("\(progress.done)/\(progress.total)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: MemoItem, indent: Int) -> some View {
        if state.editingItemID == item.id {
            editorField(placeholder: "Task", isSubtask: false).padding(.leading, CGFloat(indent) * 18)
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
                Button("Delete", role: .destructive) { state.delete(item) }
            }
        }
    }

    private func editorField(placeholder: String, isSubtask: Bool) -> some View {
        TextField(placeholder, text: $state.draftText)
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
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
            .onChange(of: editorFocused) { _, focused in
                if !focused, state.isComposing {
                    state.commitComposerIfNeeded()
                    onEndEdit()
                }
            }
    }

    private var bottomNavigation: some View {
        HStack(spacing: 10) {
            switchChip("Today", selected: state.navigation == .smart(.today)) {
                state.goToToday()
            }
            switchChip("Inbox", selected: state.navigation == .smart(.inbox)) {
                state.select(.smart(.inbox))
            }
            let listCount = BottomNavLayout.visibleCustomListCount(panelWidth: LayoutMetrics.previewPanelWidth)
            ForEach(state.customLists.prefix(listCount)) { list in
                switchChip(list.name, selected: state.navigation == .list(list.id)) {
                    state.select(.list(list.id))
                }
            }
            MoreMenuButton(
                lists: state.customLists,
                onSelect: { state.select($0) },
                onNewList: { state.addList() },
                onWillOpen: onMoreWillOpen,
                onDidClose: onMoreDidClose
            )
            .frame(width: 40, height: 18)
            .accessibilityLabel("More")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func switchChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? accent.color : .secondary)
                .lineLimit(1)
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
        state.saveDraft(continueSubtask: false)
        onEndEdit()
    }

    private func cancel() {
        state.cancelEdit()
        onEndEdit()
    }
}
