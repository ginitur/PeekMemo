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

- [ ] Left / Right / Top / Bottom collapsed frames
- [ ] Expand direction follows the edge
- [ ] Offset clamping against `visibleFrame`

## Phase 3 — Dragging + magnetic snapping

- [ ] Drag whole stack with 6 pt threshold
- [ ] Live follow, 24 pt magnet
- [ ] Mouse-up snaps to nearest legal edge
- [ ] Persist `{display, edge, offset}`

## Phase 4 — Notch Cloak positioning

- [ ] Derive notch from auxiliary areas + safe-area insets
- [ ] Allow snap into the notch (do not push away)
- [ ] Underside hover hit region
- [ ] No Notch Cloak UI on screens without a notch
- [ ] Escape hatches: drag handle, reset position

## Phase 5 — Hover expansion

- [ ] `HoverEngine` wired to AppKit tracking
- [ ] Open / close delays from settings
- [ ] Edge item + expanded panel are one region
- [ ] Click pin / unpin, double-click edit
- [ ] Peek does not steal key focus; edit may become key

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
