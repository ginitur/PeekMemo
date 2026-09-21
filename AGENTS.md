# Agent rules for PeekMemo

PeekMemo is a long-lived native macOS application. Follow these rules on every change.

1. PeekMemo is a macOS native app. Swift, SwiftUI, and AppKit only for the shipped UI.
2. Do not introduce Electron, Tauri, or a WebView as the main UI.
3. Avoid unnecessary dependencies. GRDB.swift is the approved SQLite layer. Do not add a package to save a few dozen lines.
4. Do not use private macOS APIs.
5. Do not hard-code screen resolutions, notch sizes, or Mac models.
6. Notch geometry must be derived at runtime from `NSScreen` (`frame`, `visibleFrame`, `safeAreaInsets`, `auxiliaryTopLeftArea`, `auxiliaryTopRightArea`) through the AppKit adapter. Core geometry takes generic rectangles, never `NSScreen`.
7. After changing window behavior, verify all four edges: Left, Right, Top, Bottom.
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
- Notch Cloak is a hide-in-notch feature, not a “push away from the notch” feature.
- Visual size and hit-testing size are not the same. Do not make the Edge Tab as thick as its hover region.
- Hover across Edge Item and Expanded Panel is one interaction region, owned by `HoverEngine`. Do not rely on a lone SwiftUI `onHover`.
- Editing may become key. Peeking must not steal keyboard focus from the front app.

## Quality bar

Stability > native macOS behavior > data safety > simple architecture > visual polish > feature count.

If a feature cannot be implemented reliably, mark it `BLOCKED` or `PARTIAL` in `TASKS.md` with the reason. Do not pretend it is done.
