# PeekMemo

PeekMemo is a lightweight macOS edge memo tool. It lives as a thin tab on a screen edge, expands a memo group on hover, and stays out of the way the rest of the time.

This is a native Swift / SwiftUI / AppKit app. It is not an Electron, Tauri, or WebView shell.

## Features

- Thin **Edge Tab** on Left, Right, Top, or Bottom
- Hover to peek a memo group; click to pin; double-click to edit
- Drag the stack to another edge with magnetic snapping
- **Notch Cloak Mode** on notched MacBooks: hide in the camera housing and reveal from the notch underside
- Local notes and checklists
- Per-display placement
- Menu bar extra + Launch at Login
- Settings for theme, panel size, wedge, hover delay, and Reduce Motion
- Accessory app: no Dock icon

## Screenshots

_Screenshots will be added after the first visual milestone._

## Requirements

- macOS 14 or later
- Swift 6.0 or later
- Xcode 16+ is optional for day-to-day builds. Command Line Tools are enough for `swift build` / `swift test`.
- A full Xcode.app install is required only for `xcodebuild` and Interface Builder.

## Build

```sh
git clone https://github.com/ginitur/PeekMemo.git
cd PeekMemo
swift build
swift run PeekMemoCoreTests
```

Run from the command line during development:

```sh
swift run PeekMemo
```

Quit from the menu bar extra (note icon) → **Quit PeekMemo**.

Package a local `.app` and zip (ad-hoc signed, not notarized):

```sh
./scripts/build-release.sh
```

The app bundle is written to `dist/PeekMemo.app` and `dist/PeekMemo.zip`.

## Privacy

Notes, tasks, and categories are stored locally in SQLite. Appearance settings are stored locally in UserDefaults. A panel background image, if you choose one, is copied into Application Support and is not uploaded.

PeekMemo does not upload note contents anywhere.

There is no analytics, telemetry, crash-reporting SDK, account system, or cloud sync in this version.

## Roadmap

See [TASKS.md](TASKS.md) for the phase plan and [CHANGELOG.md](CHANGELOG.md) for what has landed.

v0.1 focuses on a stable edge panel, hover peek, local SQLite storage, and settings.

Explicitly out of scope for v0.1: iCloud, AI, plugins, a full Markdown editor, mobile, and Windows.

## License

[MIT](LICENSE)
