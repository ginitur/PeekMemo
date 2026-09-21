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
