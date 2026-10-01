# PeekMemo

PeekMemo is a lightweight edge memo tool. It lives as a thin tab on a screen edge, expands a memo group on hover, and stays out of the way the rest of the time.

macOS is a native Swift / SwiftUI / AppKit app. Windows is a separate native C# / .NET 8 / WPF app. Neither is an Electron, Tauri, or WebView shell.

## Features

macOS v0.1:

- Thin **Edge Tab** on Left, Right, or Bottom. Top is not currently supported.
- Hover to peek a memo group; click to pin; double-click to edit
- Drag the stack to another edge with magnetic snapping
- Local notes and checklists
- Per-display placement
- Menu bar extra + Launch at Login
- Settings for theme, panel size, wedge, hover delay, and Reduce Motion
- Accessory app: no Dock icon

## Screenshots

_Screenshots will be added after the first visual milestone._

## macOS

### Requirements

- macOS 14 or later
- Swift 6.0 or later
- Xcode 16+ is optional for day-to-day builds. Command Line Tools are enough for `swift build` / `swift test`.
- A full Xcode.app install is required only for `xcodebuild` and Interface Builder.

### Build

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

### Privacy

Notes, tasks, and categories are stored locally in SQLite. Appearance settings are stored locally in UserDefaults. A panel background image, if you choose one, is copied into Application Support and is not uploaded.

PeekMemo does not upload note contents anywhere.

There is no analytics, telemetry, crash-reporting SDK, account system, or cloud sync in this version.

## Roadmap

See [TASKS.md](TASKS.md) for the phase plan and [CHANGELOG.md](CHANGELOG.md) for what has landed.

v0.1 focuses on a stable edge panel, hover peek, local SQLite storage, and settings.

Supported macOS edges are Left, Right, and Bottom. Top is not currently supported.

Explicitly out of scope for v0.1: iCloud, AI, plugins, a full Markdown editor, and mobile.

## Windows

Status: **under development**. The Windows version has not been verified on a Windows machine. This repository is developed on macOS, which cannot run the WPF UI. Build and test on Windows with the commands below. GitHub Actions on `windows-latest` runs the same commands.

Requirements:

- Windows 10 22H2 or later, or Windows 11
- .NET 8 SDK

```sh
cd windows
dotnet build PeekMemo.Windows.sln
dotnet test PeekMemo.Windows.sln
```

`windows/scripts/build.ps1` runs the same restore, Release build, and test. `windows/scripts/package.ps1` publishes an unpackaged build to `windows/dist`. There is no MSIX, signing, or Store package.

The product model matches macOS: Date, Category, Note, Task, Subtask, Completion. Supported edges are Left, Right, and Bottom. Top is not a snap target. Phase 0 is the solution, the testable core library, and settings JSON under `%LOCALAPPDATA%\PeekMemo\`. The tray and the edge window are not in the bootstrap commit.

Startup, when enabled later, is one per-user `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` value named `PeekMemo`. It does not need administrator rights and it does not write `HKLM`. Memo data is not stored in the registry. SQLite (`PeekMemo.sqlite`) is not opened yet.

## License

[MIT](LICENSE)
