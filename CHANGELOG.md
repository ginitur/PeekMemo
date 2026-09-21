# Changelog

All notable changes to PeekMemo are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows the project’s `0.1.0-dev` train until the first tagged release.

## [0.1.0-dev] — unreleased

### Added

- Project bootstrap: repository docs, MIT license, SPM package, CI workflow, release script.
- `PeekMemoCore` platform-agnostic models, layout metrics, edge geometry, notch detection, screen migration, and hover state machine.
- Unit tests for geometry, notch cloak ranges, offset clamping, and hover transitions (`swift run PeekMemoCoreTests`).
- Custom `PeekPanel` accessory window and a collapsed Edge Tab on the right screen edge (4 pt visible / 14 pt hit).
- Stub menu bar extra so the accessory app can be quit.
- Drag the Edge Tab to Left / Right / Top / Bottom with 6 pt drag threshold and 24 pt magnetic snap.
- Per-display `{edge, offset}` saved in UserDefaults (SQLite arrives in Phase 6).
- Menu Bar: Show, Hide, Reset Position, Quit.
- Notch Cloak: Top-edge drag into the notch range hides the tab in the camera housing. The window sits on a 14 pt underside hit strip (1 pt hairline). Dragging out restores a normal Edge Tab. Reset Position still works.
- Hover reveal: 160 ms open / 350 ms close, 80 ms grace across the tab–panel gap. Click pins; second click collapses. Preview panel is a local Today list (no database). Peeking never becomes the key window.
- Notch Cloak collapsed anchor is now inside the physical `notchRect` (occluded by the housing). A 3 pt invisible activation strip sits on the underside as fallback. DEBUG: Show Notch Geometry, Move to Notch Cloak, NotchHitProbe.
- Panel expansion is a single AppKit `animator().setFrame` with a fixed contact edge (maxX / minX / maxY / minY). Expand 200 ms ease-out, collapse 170 ms. Content fades 40 ms after the shell. Edge Tab default is 3×56 pt.
- In-memory memo prototype: add, edit, checkbox, delete. Peeking does not take key; editing does. ⌘↩ saves, Esc cancels. Data is not persisted.
- EdgeAnchor: the handle center is the stable offset. Expanded panels stay centered on it; near corners the body is clamped and the handle stays put.
- Tasks can nest one level of subtasks. Completing a parent completes children; completing all children completes the parent. Completed items move into a collapsed Completed section after a short delay.
- Smart views Today / Inbox / Completed plus custom lists (Work, Personal, Ideas). Default view is Today. New items without a list go to Inbox.
- Notch cloak visual panel is fully inside `notchRect`. Hit testing is a separate invisible sensor (3 pt fallback strip) plus mouse-location monitors.
- Inline `+ Add subtask` with continuous Enter. Parent rows show disclosure and `1/3`.
- Bottom nav is a fixed region. More is an AppKit `NSMenu` so it opens on the first click and is not clipped.
- Dragging never cloaks live; Top can be dragged to other edges. Notch sensor stays below the panel and hides during drag.
- Daily View: `selectedDate`, `scheduledDate` vs `dueDate` vs `completedAt`. Past completion uses `completedAt <= endOfDay`.

### Changed

- PeekMemo is a date + category + task tool, not a project manager. The expanded panel is always a Date View. Today means `selectedDate == today`.
- `UserList` / `listId` are now `Category` / `categoryId`. Default categories are Work and Personal. Filter with All ▾ next to the date.
- Inbox, Completed smart view, and bottom More navigation are withdrawn from v0.1 UI.
- Completed tasks stay in place (checkbox, strikethrough, lower opacity). There is no Completed section.
- Subtasks indent 18 pt under their parent. Only two levels.
- v0.1 edge snap is Left / Right / Bottom. Top and Notch Cloak are experimental (DEBUG menu) so ordinary drag cannot trap the tab on Top.
