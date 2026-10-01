# TASKS

Progress is recorded with `[ ]` / `[x]`. If a feature cannot be finished reliably, mark `BLOCKED` or `PARTIAL` and explain.

## Phase 0 — Project bootstrap

- [x] Inspect environment and current directory
- [x] Create `PROJECT_SPEC.md`, `AGENTS.md`, `TASKS.md`, `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`
- [x] Create Swift package layout (`PeekMemoCore` + `PeekMemo`)
- [x] Add GitHub Actions workflow
- [x] Add `scripts/build-release.sh`
- [x] `git init` and initial commit

## Phase 1 — Floating NSPanel

- [x] Custom `PeekPanel` (borderless, transparent, nonactivating)
- [x] `AppDelegate` + `.accessory` activation policy
- [x] Show a collapsed Edge Tab on the **right** edge of the main display
- [x] Visual thickness ≠ hit thickness (4 pt visible, 14 pt hit)
- [x] `swift build --product PeekMemo` and `swift run PeekMemoCoreTests` pass
- [x] Runtime check: PeekMemo window 14×96 at the right edge of the main display
- [x] Stub menu bar item with Quit (full menu is Phase 9)

## Phase 2 — Edge placement

`ScreenEdge` still has a Top case for shared geometry. v0.1 snap and the release UI are Left, Right, and Bottom only.

- [x] Left / Right / Bottom collapsed frames (`EdgeGeometry` + Edge Tab shape). Top geometry remains in Core and is not a snap target.
- [x] Expand direction follows the edge (Core; UI expand is Phase 5)
- [x] Offset clamping against `visibleFrame`

## Phase 3 — Dragging + magnetic snapping

- [x] Drag whole stack with 6 pt threshold (`EdgeHostView`)
- [x] Live follow, 24 pt magnet
- [x] Mouse-up snaps to nearest legal edge
- [x] Persist `{display, edge, offset}` (UserDefaults for now; SQLite in Phase 6)
- [x] Menu Bar: Show / Hide / Reset Position

## Phase 4 — Notch Cloak positioning — withdrawn

Notch Cloak is not a current feature and is not on the roadmap. The runtime, sensor, debug menu, and notch tests were removed. Git history keeps the old implementation. Do not restore it.

- [x] Removed notch geometry, notch placement, notch snap threshold, notch sensor window, notch mouse monitors, and DEBUG notch controls
- [x] Supported snap edges are Left, Right, and Bottom. Top is not offered. A stored Top placement restores to Right

## Phase 5 — Hover expansion

- [x] `HoverEngine` wired through AppKit `HoverController` + `NSTrackingArea` (not SwiftUI `onHover`)
- [x] Open delay 160 ms, close delay 350 ms, 80 ms exit grace period
- [x] Edge Tab + Expanded Panel are one `HoverRegion` (union + 6 pt padding)
- [x] Click pins; second click collapses; pinned ignores pointer exit
- [x] Peek does not become key (`allowsKey = false`). Editing key window is Phase 7
- [x] Preview panel: Today + two example rows + Add Memo (visual only, no persistence)
- [x] Expand direction follows the supported edge
- [x] Debug: Show Hit Regions (DEBUG menu only)
- [x] PARTIAL: live Left / Right / Bottom hover could not be HID-injected in this environment (no Accessibility for synthetic mouse). Geometry, region union, and collapsed window were verified.

## Phase 5.5 — Interaction correction

- [x] Fixed-edge panel expansion via `PanelAnimator` + `NSAnimationContext` `animator().setFrame` (commit 2)
- [x] In-memory interactive memos (Add / Edit / Checkbox / Delete / ⌘↩ / Esc)
- [x] Peek vs Edit focus: hover stays non-key; Add/Edit calls `makeKey`

## Phase 5.6 — Product architecture

- [x] EdgeAnchor: expand/collapse does not change offset; corner clamp keeps handle on the original anchor
- [x] Hierarchical tasks + completed state
- [x] Smart views + custom lists
- [x] Notch collapsed frame and `NotchActivationSensor` were removed with Phase 4. Do not add them back.

## Phase 5.7 — Daily workflow & navigation

- [x] Inline continuous `+ Add subtask` (Enter keeps composing, ⌘↩ / Esc end)
- [x] Parent disclosure ▸/▾ with progress `1/3` on the row
- [x] Fixed bottom navigation; More uses `NSMenu.popUp` (first click opens, not clipped)
- [x] Live drag snaps to Left, Right, or Bottom. Top is not a snap target.
- [x] Daily View with `selectedDate`, `scheduledDate`, historical completion via `completedAt`

## Phase 5.8 — Simplify the product

- [x] Date view is the only main surface; Today is `selectedDate == today`
- [x] Category filter (All / Work / Personal / New), not a parallel navigation
- [x] Inbox, More, and Completed section removed from UI
- [x] Completed tasks stay in place (check + strikethrough)
- [x] Subtasks indent 18 pt
- [x] `UserList` / `listId` renamed to `Category` / `categoryId`
- [x] Top is not supported. Notch Cloak is removed, not hidden behind a debug flag.

## Phase 5.9 — Mouse interaction stabilization

- [x] Drag hits only the edge handle. `EdgeHostView.hitTest` no longer mirrors Y into the flipped hosting view.
- [x] Static titles are non-selectable labels. No hidden full-panel text field. I-beam is limited to a real `TextField`.
- [x] Hover uses the live edge frame and the live panel frame separately. Leaving schedules collapse (350 ms). Edit and menus do not pin.
- [x] Category control is an `NSMenu` with a 32 pt hit target. Choosing a category does not pin.
- [x] DEBUG: Show Interaction Regions, `[Hover]` / `[Interaction]` logs on state changes only.
- [ ] PARTIAL: live pointer paths (hover leave, one-click All, drag vs content) were checked with an on-screen hit dump, not a full HID script. Needs a hands-on pass.

## Phase 5.10 — Final product cleanup

- [x] Past Unfinished root tasks appear only on Today, without rewriting `scheduledDate`
- [x] Historical dates show only that day's schedule
- [x] Nil category has no Uncategorized badge
- [x] Notes stay simple text; context menu can add a note
- [x] Daily progress counts root tasks only

## Phase 6 — Local persistence

- [x] GRDB.swift, `~/Library/Application Support/PeekMemo/PeekMemo.sqlite`
- [x] `v1_initial_schema` only. Never delete the database on failure
- [x] `categories` and `memo_items`. No `forToday` column. Seed Work and Personal once
- [x] `CategoryRepository` and `MemoRepository`. Views do not run SQL
- [x] Daily query, Past Unfinished, two-level subtasks, completion transaction
- [x] Notes persist without completion or subtasks. Progress counts root tasks only
- [x] AppState reloads after a successful write. `selectedDate` stays UI state
- [x] Window placement stays in UserDefaults
- [x] Temporary-database tests, including restart

## Phase 7 — Appearance and preferences

The product model stays frozen. This phase does not add task-management features.

- [x] Settings window: General, Appearance, Behavior
- [x] `PreferencesStore` and `peekmemo.preferences.*` in UserDefaults. Not SQLite
- [x] Theme System / Light / Dark. Panel opacity 0.70–1.00, default 0.94
- [x] Width Compact / Medium / Wide and maximum height Small / Medium / Large. Superseded by Phase 7.1; short lists no longer shrink the panel
- [x] Edge tab stays one Wedge: thickness, length, opacity, System Accent or custom hex color
- [x] Hit region stays 14 pt when the wedge gets thinner
- [x] Hover open / close delays apply to `HoverEngine` immediately
- [x] Reduce Motion follows the preference or the system setting. Movement duration becomes 0; the content fade stays
- [x] Categories: rename, color, Move Up / Down, Archive, New Category. Color is only a small label
- [x] Reset Appearance to Defaults does not touch SQLite or Launch at Login
- [x] Launch at Login via `SMAppService.mainApp`. The menu bar icon cannot be hidden
- [x] No new timers, display link, or mouse polling
- [ ] PARTIAL: live edge, opacity, theme, and delay changes need a hands-on pass. `swift run` is not an installed app, so Login Items often reports not registered

## Phase 7.1 — Panel layout and background

Still not a new task-management feature. SQLite, hover, and the edge anchor stay as they were.

- [x] Default memo is Medium, 340×460 pt, taller than it is wide. Minimum 280×300. Short lists do not shrink the panel
- [x] Small 300×360, Medium 340×460, Large 420×560, plus Custom. A drag stores the exact size and becomes Custom
- [x] Resize grip on the free corner. Right is bottom-left, Left is bottom-right, Bottom is top-right. The edge anchor does not move
- [x] Saved size is `panelWidth` / `panelHeight` in UserDefaults. A smaller display clamps the window only; it does not overwrite the saved size
- [x] Old Compact / Medium / Wide and height presets migrate once. The old default becomes 340×460, not 280×120
- [x] Expanded panel corner radius is 16 pt. Material, image, and the hairline border share that clip. A light window shadow shows only while expanded
- [x] Background: System Material, Solid Color, or Image. Image is copied to `~/Library/Application Support/PeekMemo/Backgrounds/`. Preferences store the filename only
- [x] Fill / Fit, top / center / bottom, image opacity 0.20–1.00 (default 0.60), overlay 0–0.80 (default 0.25). Remove deletes only the copied file
- [x] A missing image falls back to System Material. Header stays put; the list scrolls; Add Task stays under the list
- [ ] PARTIAL: dragging the grip and choosing a photo still need a hands-on pass. Background blur was not added

## Phase 7.2 — Resize handle hit testing

- [x] The grip view is fixed at 22×22 pt. A card-sized frame still hit-tests only that corner square
- [x] The three ticks draw inside 14×14 pt. Date, category, tasks, and Add Task are outside the rect
- [ ] PARTIAL: click-through on a running panel still needs a hands-on pass

## Phase 8 — not started

Folded into Phase 7. Do not start a new phase. Circle, pill, and rounded-square edge items were not added. The edge tab remains a wedge.

## Phase 9 — Menu bar and Launch at Login

- [x] Status item menu: Show, Hide, Reset Position, Settings…, Quit
- [x] `SMAppService.mainApp`
- [x] The menu bar icon stays visible so Settings and Quit remain reachable

## Phase 10 — Multi-display

- [ ] Per-display placement
- [ ] Screen configuration observer
- [ ] Migrate to main screen when a display disappears

## Phase 11 — Polish + testing

- [ ] Left / Right / Bottom + multi-display verification. Top is not in scope.
- [ ] Accessibility labels
- [x] Reduced motion (Phase 7). Movement is skipped; the content fade stays
- [ ] Idle CPU check (no polling). Phase 7 added no timer; not yet measured in Instruments

## Phase 12 — GitHub packaging

- [ ] README screenshots
- [ ] `scripts/build-release.sh` produces `.app` + `.zip`
- [ ] CI green on push / PR
