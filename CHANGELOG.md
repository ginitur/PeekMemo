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
