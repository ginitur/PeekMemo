# Changelog

All notable changes to PeekMemo are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows the project’s `0.1.0-dev` train until the first tagged release.

## [0.1.0-dev] — unreleased

### Added

- Project bootstrap: repository docs, MIT license, SPM package, CI workflow, release script.
- `PeekMemoCore` platform-agnostic models, layout metrics, edge geometry, screen migration, and hover state machine.
- Unit tests for geometry, offset clamping, and hover transitions (`swift run PeekMemoCoreTests`).
- Custom `PeekPanel` accessory window and a collapsed Edge Tab on the right screen edge (4 pt visible / 14 pt hit).
- Stub menu bar extra so the accessory app can be quit.
- Drag the Edge Tab to Left / Right / Bottom with 6 pt drag threshold and 24 pt magnetic snap. Top is not a snap target.
- Per-display `{edge, offset}` saved in UserDefaults (SQLite arrives in Phase 6).
- Menu Bar: Show, Hide, Reset Position, Quit.
- Hover reveal: 160 ms open / 350 ms close, 80 ms grace across the tab–panel gap. Click pins; second click collapses. Preview panel is a local Today list (no database). Peeking never becomes the key window.
- Panel expansion is a single AppKit `animator().setFrame` with a fixed contact edge (maxX / minX / maxY / minY). Expand 200 ms ease-out, collapse 170 ms. Content fades 40 ms after the shell. Edge Tab default is 3×56 pt.
- In-memory memo prototype: add, edit, checkbox, delete. Peeking does not take key; editing does. ⌘↩ saves, Esc cancels. Data is not persisted.
- EdgeAnchor: the handle center is the stable offset. Expanded panels stay centered on it; near corners the body is clamped and the handle stays put.
- Tasks can nest one level of subtasks. Completing a parent completes children; completing all children completes the parent. Completed items move into a collapsed Completed section after a short delay.
- Smart views Today / Inbox / Completed plus custom lists (Work, Personal, Ideas). Default view is Today. New items without a list go to Inbox.
- Inline `+ Add subtask` with continuous Enter. Parent rows show disclosure and `1/3`.
- Bottom nav is a fixed region. More is an AppKit `NSMenu` so it opens on the first click and is not clipped.
- Daily View: `selectedDate`, `scheduledDate` vs `dueDate` vs `completedAt`. Past completion uses `completedAt <= endOfDay`.
- Settings window with General, Appearance, and Behavior. Theme, panel opacity, width, maximum height, wedge thickness / length / opacity / color, hover delays, and Reduce Motion. Values live in UserDefaults and apply without a restart.
- Panel background can be the system material, a solid color, or a picture. The picture is copied into Application Support. Fill or Fit, opacity, and a light overlay are settings. Remove deletes only that copy.
- Launch at Login via `SMAppService.mainApp`. Settings… is in the menu bar. The icon stays visible.
- Category rename, color, order, and archive from Settings. Reset Appearance does not touch SQLite.

### Fixed

- Expanded-panel hit testing no longer mirrors clicks into the task list. The drag handle is the only drag origin.
- Hover collapse follows the live panel frame. Editing, the date picker, and the category menu pause collapse without pinning.
- Category All ▾ is an AppKit menu with a 32 pt target and opens on the first click.
- Static task titles do not take the I-beam cursor. The text field exists only while editing.

### Changed

- PeekMemo is a date + category + task tool, not a project manager. The expanded panel is always a Date View. Today means `selectedDate == today`.
- `UserList` / `listId` are now `Category` / `categoryId`. Default categories are Work and Personal. Filter with All ▾ next to the date.
- Inbox, Completed smart view, and bottom More navigation are withdrawn from v0.1 UI.
- Completed tasks stay in place (checkbox, strikethrough, lower opacity). There is no Completed section.
- Subtasks indent 18 pt under their parent. Only two levels.
- v0.1 edge snap is Left / Right / Bottom. Top is not currently supported. A stored Top placement restores to Right.
- The expanded memo defaults to 340×460 pt with 16 pt corners. It no longer shrinks when the day is short. Dragging the free corner saves a custom size without moving the edge anchor. Older width and height presets migrate once.
- The resize grip is a 22×22 pt corner target. The three ticks are drawn in 14×14 pt and no longer cover the memo.
- Unfinished root tasks from earlier days appear above Today as “未完成 · N”. Their `scheduledDate` is not rewritten. Other dates show only that day’s items.
- Items with no category have no badge. Right-click + Add Task to add a plain Note. Notes never enter the completion count.
- Local SQLite (GRDB) at `~/Library/Application Support/PeekMemo/PeekMemo.sqlite`. Migration `v1_initial_schema` seeds Work and Personal once and does not recreate deleted rows. A failed open or migration leaves the file in place.
- Daily items, categories, notes, subtasks, completion, and Past Unfinished survive quit and relaunch. `selectedDate` still starts at today. Window placement stays in UserDefaults.

### Removed

- Notch Cloak, including hide-in-notch placement, the notch activation sensor, notch hit probe, notch debug overlay, notch mouse monitors, and the DEBUG controls (Show Notch Geometry, Move to Notch Cloak, Experimental Top / Notch).
- Notch-only geometry, UserDefaults flags, and tests. Git history still has the old implementation. It is not on the current roadmap.
