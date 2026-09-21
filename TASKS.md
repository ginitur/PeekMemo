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

## Phase 2 — Four-edge placement

- [x] Left / Right / Top / Bottom collapsed frames (`EdgeGeometry` + Edge Tab shape)
- [x] Expand direction follows the edge (Core; UI expand is Phase 5)
- [x] Offset clamping against `visibleFrame`

## Phase 3 — Dragging + magnetic snapping

- [x] Drag whole stack with 6 pt threshold (`EdgeHostView`)
- [x] Live follow, 24 pt magnet
- [x] Mouse-up snaps to nearest legal edge
- [x] Persist `{display, edge, offset}` (UserDefaults for now; SQLite in Phase 6)
- [x] Menu Bar: Show / Hide / Reset Position

## Phase 4 — Notch Cloak positioning

- [x] Derive notch from auxiliary areas + safe-area insets (`NotchGeometry.region`)
- [x] Allow snap into the notch (do not push away); 26 pt `notchSnapThreshold` with smoothstep pull
- [x] Collapsed cloak anchor sits **inside** `notchRect` (center = notch mid). Housing occludes it.
- [x] Fallback activation extension: **3 pt** below `notchRect.minY` (not a 14 pt bar)
- [ ] Native notch hit testing: **unconfirmed** in this environment (no HID injection). `NotchHitProbe` logs `notchRect` vs `activationExtension`. Treat as PARTIAL until a live mouse enter is observed.
- [x] No Notch Cloak UI on screens without a notch
- [x] Escape hatches: drag out of the notch, Reset Position
- [x] Geometry tests: no notch, notch, enter L/R, exit L/R, offset clamp, screen size change
- [x] Drag handle after hover — shown on the expanded panel (Phase 5)

## Phase 5 — Hover expansion

- [x] `HoverEngine` wired through AppKit `HoverController` + `NSTrackingArea` (not SwiftUI `onHover`)
- [x] Open delay 160 ms, close delay 350 ms, 80 ms exit grace period
- [x] Edge Tab + Expanded Panel are one `HoverRegion` (union + 6 pt padding)
- [x] Click pins; second click collapses; pinned ignores pointer exit
- [x] Peek does not become key (`allowsKey = false`). Editing key window is Phase 7
- [x] Preview panel: Today + two example rows + Add Memo (visual only, no persistence)
- [x] Expand direction follows edge; Notch Cloak expands downward
- [x] Debug: Show Hit Regions (DEBUG menu only)
- [x] PARTIAL: live four-edge + notch hover could not be HID-injected in this environment (no Accessibility for synthetic mouse). Geometry, region union, and collapsed window were verified.

## Phase 5.5 — Interaction correction

- [x] Notch cloak collapsed frame inside `notchRect` (commit 1)
- [x] Fixed-edge panel expansion via `PanelAnimator` + `NSAnimationContext` `animator().setFrame` (commit 2)
- [x] In-memory interactive memos (Add / Edit / Checkbox / Delete / ⌘↩ / Esc)
- [x] Peek vs Edit focus: hover stays non-key; Add/Edit calls `makeKey`

## Phase 6 — Memo persistence

- [ ] GRDB.swift
- [ ] `MemoGroup` / `Memo` / settings / placement tables
- [ ] First-launch seed (once)
- [ ] Backward-compatible migrations

## Phase 7 — Memo CRUD + checklist

- [ ] Notes and checklists
- [ ] Add / edit / delete / complete
- [ ] Drag reorder
- [ ] Group context menu

## Phase 8 — Appearance settings

- [ ] System / Light / Dark
- [ ] Opacity 0.5–1.0
- [ ] Item shape and size
- [ ] Per-group color as RGBA

## Phase 9 — Menu Bar + Launch at Login

- [ ] Status item menu
- [ ] `SMAppService.mainApp`
- [ ] Show / Hide / Reposition / Preferences / Quit

## Phase 10 — Multi-display

- [ ] Per-display placement
- [ ] Screen configuration observer
- [ ] Migrate to main screen when a display disappears

## Phase 11 — Polish + testing

- [ ] Four-edge + notch + multi-display verification
- [ ] Accessibility labels
- [ ] Reduced motion
- [ ] Idle CPU check (no polling)

## Phase 12 — GitHub packaging

- [ ] README screenshots
- [ ] `scripts/build-release.sh` produces `.app` + `.zip`
- [ ] CI green on push / PR
