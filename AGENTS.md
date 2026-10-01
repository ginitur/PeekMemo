# Agent rules for PeekMemo

PeekMemo is a long-lived native macOS application. Follow these rules on every change.

1. PeekMemo is a macOS native app. Swift, SwiftUI, and AppKit only for the shipped UI.
2. Do not introduce Electron, Tauri, or a WebView as the main UI.
3. Avoid unnecessary dependencies. GRDB.swift is the approved SQLite layer. Do not add a package to save a few dozen lines.
4. Do not use private macOS APIs.
5. Do not hard-code screen resolutions or Mac models.
6. Core geometry takes generic rectangles (`frame`, `visibleFrame`), never `NSScreen`. `ScreenManager` is the only `NSScreen` reader. Do not reintroduce Notch Cloak, a notch sensor, or notch hit-testing.
7. After changing window behavior, verify Left, Right, and Bottom. Top is not a supported snap edge.
8. After changing layout or placement, consider multiple displays and display disconnect.
9. Idle CPU must stay near zero. No polling timers for mouse position, no continuous window refresh.
10. Data migrations must be backward compatible.
11. Do not delete user memo data. Seed content is created once; never regenerated after the user deletes it.
12. Do not `git push` unless the user explicitly asks.
13. Do not change system settings, install system-level software, log into accounts, or touch signing certificates unless the user asks.
14. Record important architecture decisions in `PROJECT_SPEC.md`.
15. After finishing a phase: build, test, inspect the diff, update `TASKS.md` and `CHANGELOG.md`, then commit with `feat:` / `fix:` / `refactor:` / `docs:` / `test:` / `chore:`.

## Architecture constraints

- Keep domain models, persistence, settings, hover state, and edge geometry free of AppKit.
- AppKit / SwiftUI adapters live in the `PeekMemo` target: `NSScreen`, `NSPanel`, `NSEvent`, `SMAppService`.
- Supported snap edges are Left, Right, and Bottom. `ScreenEdge.top` stays only so shared geometry switches compile. Do not offer Top in the UI, and do not snap to it. A stored Top placement restores to Right.
- Visual size and hit-testing size are not the same. Do not make the Edge Tab as thick as its hover region.
- Hover across Edge Item and Expanded Panel is one interaction region, owned by `HoverEngine`. Do not rely on a lone SwiftUI `onHover`.
- Editing may become key. Peeking must not steal keyboard focus from the front app.

## Quality bar

Stability > native macOS behavior > data safety > simple architecture > visual polish > feature count.

If a feature cannot be implemented reliably, mark it `BLOCKED` or `PARTIAL` in `TASKS.md` with the reason. Do not pretend it is done.
