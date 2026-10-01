import AppKit
import PeekMemoCore
import SwiftUI

struct PreferencesView: View {
    var model: PreferencesModel
    @FocusState private var focusedCategoryID: UUID?

    var body: some View {
        Form {
            switch model.page {
            case .general:
                general
            case .appearance:
                appearance
            case .behavior:
                behavior
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: focusedCategoryID) { previous, _ in
            if let previous {
                model.commitRename(previous)
            }
        }
    }

    private var general: some View {
        Group {
            Section {
                Toggle("Launch at Login", isOn: launchAtLogin)
                if let message = model.launchAtLoginMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } footer: {
                Text("Uses the system Login Items list. PeekMemo does not install a launch agent.")
            }
            Section {
                LabeledContent("Menu Bar Icon") {
                    Text("Shown")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("The menu bar icon stays available so Settings and Quit remain reachable.")
            }
        }
    }

    private var appearance: some View {
        Group {
            Section {
                Picker("Theme", selection: theme) {
                    Text("System").tag(ThemePreference.system)
                    Text("Light").tag(ThemePreference.light)
                    Text("Dark").tag(ThemePreference.dark)
                }
                .pickerStyle(.segmented)
                opacityRow(
                    "Panel Opacity",
                    value: binding(\.panelOpacity),
                    range: AppearancePreferences.opacityRange
                )
            }
            Section {
                Picker("Size", selection: sizeMode) {
                    Text("Small").tag(PanelSizeMode.small)
                    Text("Medium").tag(PanelSizeMode.medium)
                    Text("Large").tag(PanelSizeMode.large)
                    Text("Custom").tag(PanelSizeMode.custom)
                }
                LabeledContent("Current") {
                    Text(model.snapshot.sizeLabel)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } footer: {
                Text("Default is a tall note. Short lists stay at this size and scroll when they grow. Drag the panel corner for a custom size.")
            }
            Section {
                LabeledContent("Style") {
                    Text("Wedge")
                        .foregroundStyle(.secondary)
                }
                sliderRow(
                    "Thickness",
                    value: thickness,
                    range: 2...6,
                    step: 1,
                    label: "\(Int(model.snapshot.edgeTabThickness.rounded())) pt"
                )
                sliderRow(
                    "Length",
                    value: length,
                    range: 32...96,
                    step: 2,
                    label: "\(Int(model.snapshot.edgeTabLength.rounded())) pt"
                )
                opacityRow(
                    "Opacity",
                    value: binding(\.edgeTabOpacity),
                    range: AppearancePreferences.edgeOpacityRange
                )
                Picker("Color", selection: colorMode) {
                    Text("System Accent").tag(EdgeTabColorMode.systemAccent)
                    Text("Custom").tag(EdgeTabColorMode.custom)
                }
                if model.snapshot.edgeTabColorMode == .custom {
                    ColorPicker("Custom Color", selection: customColor, supportsOpacity: true)
                }
            } header: {
                Text("Edge Tab")
            } footer: {
                Text("The hit region stays \(Int(LayoutMetrics.hoverHitThickness)) pt, even when the wedge is thinner.")
            }
            categories
            reset
        }
    }

    private var behavior: some View {
        Group {
            Section {
                Picker("Hover Open Delay", selection: openDelay) {
                    ForEach(AppearancePreferences.openDelayChoices, id: \.self) { delay in
                        Text(delayLabel(delay)).tag(delay)
                    }
                }
                Picker("Hover Close Delay", selection: closeDelay) {
                    ForEach(AppearancePreferences.closeDelayChoices, id: \.self) { delay in
                        Text(delayLabel(delay)).tag(delay)
                    }
                }
            }
            Section {
                Toggle("Reduce Motion", isOn: reduceMotion)
            } footer: {
                Text("Also follows the macOS Reduce Motion setting. The panel still fades, but it does not travel.")
            }
            reset
        }
    }

    private var categories: some View {
        Section {
            let rows = model.appState.activeCategories
            ForEach(rows) { category in
                categoryRow(category, in: rows)
            }
            Button("New Category") {
                model.appState.addCategory()
            }
        } header: {
            Text("Categories")
        }
    }

    private var reset: some View {
        Section {
            Button("Reset Appearance to Defaults") {
                model.resetAppearanceAndBehavior()
            }
        } footer: {
            Text("Resets appearance and behavior only. Tasks, notes, and categories stay.")
        }
    }

    private func categoryRow(_ category: PeekMemoCore.Category, in rows: [PeekMemoCore.Category]) -> some View {
        let index = rows.firstIndex(where: { $0.id == category.id }) ?? 0
        return HStack(spacing: 8) {
            ColorPicker(
                category.name,
                selection: categoryColor(category),
                supportsOpacity: false
            )
            .labelsHidden()
            .frame(width: 32)
            TextField("Name", text: categoryName(category))
                .focused($focusedCategoryID, equals: category.id)
                .onSubmit { model.commitRename(category.id) }
            Button {
                model.moveCategory(category.id, by: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(index == 0)
            .accessibilityLabel("Move \(category.name) up")
            Button {
                model.moveCategory(category.id, by: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(index == rows.count - 1)
            .accessibilityLabel("Move \(category.name) down")
        }
        .contextMenu {
            Button("Archive") {
                model.archiveCategory(category.id)
            }
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { model.snapshot.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        )
    }

    private var theme: Binding<ThemePreference> {
        Binding(get: { model.snapshot.theme }, set: { value in model.update { $0.theme = value } })
    }

    private var sizeMode: Binding<PanelSizeMode> {
        Binding(get: { model.snapshot.panelSizeMode }, set: { value in model.update { $0.panelSizeMode = value } })
    }

    private var thickness: Binding<Double> {
        Binding(
            get: { Double(model.snapshot.edgeTabThickness) },
            set: { newValue in model.update { $0.edgeTabThickness = CGFloat(newValue) } }
        )
    }

    private var length: Binding<Double> {
        Binding(
            get: { Double(model.snapshot.edgeTabLength) },
            set: { newValue in model.update { $0.edgeTabLength = CGFloat(newValue) } }
        )
    }

    private var colorMode: Binding<EdgeTabColorMode> {
        Binding(get: { model.snapshot.edgeTabColorMode }, set: { value in model.update { $0.edgeTabColorMode = value } })
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { model.snapshot.edgeTabCustomColor.color },
            set: { color in
                model.update { $0.edgeTabCustomColor = rgba(color) }
            }
        )
    }

    private var openDelay: Binding<TimeInterval> {
        Binding(get: { model.snapshot.hoverOpenDelay }, set: { value in model.update { $0.hoverOpenDelay = value } })
    }

    private var closeDelay: Binding<TimeInterval> {
        Binding(get: { model.snapshot.hoverCloseDelay }, set: { value in model.update { $0.hoverCloseDelay = value } })
    }

    private var reduceMotion: Binding<Bool> {
        Binding(get: { model.snapshot.reduceMotion }, set: { value in model.update { $0.reduceMotion = value } })
    }

    private func categoryName(_ category: PeekMemoCore.Category) -> Binding<String> {
        Binding(
            get: { model.draftName(for: category) },
            set: { model.setDraftName($0, for: category.id) }
        )
    }

    private func categoryColor(_ category: PeekMemoCore.Category) -> Binding<Color> {
        Binding(
            get: { category.color.color },
            set: { model.recolorCategory(category.id, color: rgba($0)) }
        )
    }

    private func rgba(_ color: Color) -> RGBAColor {
        let resolved = color.resolve(in: EnvironmentValues())
        return RGBAColor(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        )
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppearancePreferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.snapshot[keyPath: keyPath] },
            set: { newValue in
                model.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private func opacityRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        sliderRow(
            title,
            value: value,
            range: range,
            step: 0.01,
            label: String(format: "%.2f", value.wrappedValue)
        )
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        label: String
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Slider(value: value, in: range, step: step)
                Text(label)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }
        }
    }

    private func delayLabel(_ value: TimeInterval) -> String {
        if value == 0 { return "Immediate" }
        return String(format: "%.2f s", value)
    }
}
