import AppKit
import PeekMemoCore
import SwiftUI

struct PreviewPanelView: View {
    @Bindable var state: AppState
    var edge: ScreenEdge = .right
    var accent: RGBAColor = .accent
    var showInteractionRegions: Bool = false
    var onBeginEdit: () -> Void
    var onEndEdit: () -> Void
    var onInteractionBegan: () -> Void = {}
    var onInteractionEnded: () -> Void = {}
    var onEditorFrameChange: (CGRect) -> Void = { _ in }
    var onResizeBegan: () -> Void = {}
    var onResizeChanged: () -> Void = {}
    var onResizeEnded: () -> Void = {}
    @FocusState private var editorFocused: Bool

    private var gripCorner: ResizeGripCorner {
        PanelResizeGeometry.corner(for: edge)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.leading, 12)
                .padding(.trailing, gripCorner == .topRight || gripCorner == .topLeft ? gripClearance : 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                memoBody
                    .padding(.horizontal, 12)
                    .padding(.bottom, gripCorner == .bottomLeft || gripCorner == .bottomRight ? gripClearance : 8)
            }
            .textSelection(.disabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if state.isComposing, state.composingParentID == nil {
                editorField(
                    placeholder: state.composingType == .note ? "New note" : "New task",
                    isSubtask: false
                )
                .padding(.leading, footerLeading)
                .padding(.trailing, footerTrailing)
                .padding(.bottom, 12)
            } else if !state.isEditing {
                addTaskBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .textSelection(.disabled)
        .background {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                cornerRadius: PanelSizeMetrics.cornerRadius
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: PanelSizeMetrics.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PanelSizeMetrics.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.16), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
        .overlay(alignment: gripAlignment) {
            PanelResizeGrip(
                corner: gripCorner,
                showRegion: showInteractionRegions,
                onBegan: onResizeBegan,
                onChanged: onResizeChanged,
                onEnded: onResizeEnded
            )
            .padding(PanelResizeGeometry.gripInset)
        }
    }

    private var gripClearance: CGFloat {
        PanelResizeGeometry.gripInset + PanelResizeGeometry.gripSize + 4
    }

    private var footerLeading: CGFloat {
        gripCorner == .bottomLeft ? gripClearance : 12
    }

    private var footerTrailing: CGFloat {
        gripCorner == .bottomRight ? gripClearance : 12
    }

    private var gripAlignment: Alignment {
        switch gripCorner {
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topLeft: .topLeading
        case .topRight: .topTrailing
        }
    }

    private var addTaskBar: some View {
        Button(action: addRoot) {
            Text("+ Add Task")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accent.color)
                .textSelection(.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.leading, footerLeading)
        .padding(.trailing, footerTrailing)
        .padding(.bottom, 12)
        .accessibilityLabel("Add Task")
        .contextMenu {
            Button("Add Task") { addRoot() }
            Button("Add Note") { addNote() }
        }
    }

    private var memoBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if state.isViewingToday, !state.pastUnfinishedItems.isEmpty {
                Text("未完成 · \(state.pastUnfinishedItems.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textSelection(.disabled)
                ForEach(state.pastUnfinishedItems) { item in
                    itemBlock(item)
                }
                Divider()
                    .opacity(0.45)
                    .padding(.vertical, 2)
                Text(state.dateTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textSelection(.disabled)
            }
            ForEach(state.visibleDayItems) { item in
                itemBlock(item)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 6) {
            Button(action: state.goToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: LayoutMetrics.categoryHitHeight)
            .accessibilityLabel("Previous day")

            Button {
                state.showDatePicker = true
            } label: {
                VStack(spacing: 1) {
                    Text(state.dateTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .textSelection(.disabled)
                    let stats = state.dailyStats
                    if stats.total > 0 {
                        Text("\(stats.completed)/\(stats.total)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .textSelection(.disabled)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: LayoutMetrics.categoryHitHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            .overlay {
                if showInteractionRegions {
                    HitRegionOverlay(kind: .headerDate)
                }
            }
            .popover(isPresented: $state.showDatePicker, arrowEdge: .bottom) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { state.selectedDate },
                        set: {
                            state.selectDate($0)
                            state.showDatePicker = false
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(8)
            }
            .onChange(of: state.showDatePicker) { _, presented in
                if presented {
                    onInteractionBegan()
                } else {
                    onInteractionEnded()
                }
            }

            Button(action: state.goToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: LayoutMetrics.categoryHitHeight)
            .accessibilityLabel("Next day")

            CategoryPickerButton(
                label: state.filterLabel,
                categories: state.activeCategories,
                onSelectAll: { state.categoryFilter = .all },
                onSelect: { state.categoryFilter = .category($0) },
                onNew: { state.addCategory() },
                onWillOpen: onInteractionBegan,
                onDidClose: onInteractionEnded
            )
            .frame(minWidth: 64, minHeight: LayoutMetrics.categoryHitHeight, maxHeight: LayoutMetrics.categoryHitHeight)
            .fixedSize(horizontal: true, vertical: true)
            .overlay {
                if showInteractionRegions {
                    HitRegionOverlay(kind: .category)
                }
            }
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
                        .frame(width: 16, height: 16)
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
                                    .textSelection(.disabled)
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
                    .textSelection(.disabled)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: MemoItem, isSubtask: Bool) -> some View {
        if state.editingItemID == item.id {
            editorField(placeholder: isSubtask ? "Subtask" : "Task", isSubtask: isSubtask)
                .padding(.leading, isSubtask ? LayoutMetrics.subtaskIndent : 0)
        } else {
            HStack(alignment: .center, spacing: 8) {
                if item.type == .task {
                    Button(action: { state.toggleCompleted(item) }) {
                        Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                            .font(.system(size: isSubtask ? 12 : 13))
                            .foregroundStyle(item.isCompleted ? accent.color : .secondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")
                } else {
                    Image(systemName: "note.text")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                        .accessibilityLabel("Note")
                }

                NonInteractiveLabel(
                    text: item.title,
                    font: .systemFont(ofSize: isSubtask ? 11.5 : 12.5),
                    color: item.isCompleted ? .secondaryLabelColor : .labelColor,
                    strikethrough: item.isCompleted,
                    onClick: { edit(item) }
                )
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .opacity(item.isCompleted ? 0.55 : 1)

                if !isSubtask, state.categoryFilter == .all, let badge = DailyView.categoryBadgeName(for: item, in: state.categories) {
                    let tint = state.categoryForItem(item)?.color.color ?? Color.secondary
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tint)
                            .frame(width: 6, height: 6)
                        Text(badge)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(tint.opacity(0.85))
                            .textSelection(.disabled)
                    }
                    .allowsHitTesting(false)
                    .fixedSize()
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
            .background {
                ScreenFrameReader { onEditorFrameChange($0) }
            }
            .overlay {
                if showInteractionRegions {
                    HitRegionOverlay(kind: .editor)
                }
            }
            .focused($editorFocused)
            .onAppear { editorFocused = true }
            .onDisappear { onEditorFrameChange(.null) }
            .onChange(of: editorFocused) { _, focused in
                if !focused {
                    endFromBlur()
                }
            }
            .onSubmit {
                if isSubtask {
                    let keep = state.saveDraft(continueSubtask: true)
                    if keep || state.isEditing {
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
        state.beginComposing(type: .task)
        onBeginEdit()
    }

    private func addNote() {
        state.beginComposing(type: .note)
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
        if !state.isEditing {
            onEndEdit()
        }
    }

    private func cancel() {
        state.cancelEdit()
        onEndEdit()
    }

    private func endFromBlur() {
        guard state.isEditing else { return }
        state.commitComposerIfNeeded()
        onEndEdit()
    }
}
