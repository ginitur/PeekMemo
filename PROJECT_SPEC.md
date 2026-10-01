# PeekMemo project spec

Status: living document. Update this when an architecture decision lands.

## Product

PeekMemo is intentionally simple. It is a macOS accessory app: a thin tab on a screen edge that expands into a daily memo. It is not Todoist, Things, Notion, or a project manager.

Core model: **Date, Category, Note, Task, Subtask, Completion.**

Nothing else is part of v0.1: no priority, tags, projects, reminders, recurrence, notifications, calendar sync, kanban, statistics, charts, Markdown, attachments, iCloud, or accounts.

Version: `0.1.0-dev`  
Bundle identifier: `com.peekmemo.app`  
Deployment target: macOS 14+

## Current development environment (2026-09-21)

| Item | Status |
| --- | --- |
| Host | macOS 27.0, arm64 |
| Swift | 6.4 (Command Line Tools) |
| SDK | `MacOSX.sdk` via CLT — AppKit, SwiftUI, ServiceManagement present |
| Xcode.app | **Not installed.** `xcodebuild` is unavailable locally. |
| Git | 2.54.0 |
| Workspace | The user home directory is not a git repository. The app lives in `/Users/weijiaren/PeekMemo`. |

Decision: **Swift Package Manager is the canonical build.** GitHub Actions runs `swift build --product PeekMemo` and `swift run PeekMemoCoreTests` on a macOS runner. A generated `.xcodeproj` is not required for v0.1. Installing Xcode.app is a system-level change and will not be done unless the user asks.

## Module split

```
PeekMemo/                        # git root
  Sources/PeekMemoCore/          # no AppKit, no SwiftUI, no SMAppService
  Sources/PeekMemo/              # app executable, AppKit adapters, SwiftUI views
  Tests/PeekMemoCoreTests/       # Swift Testing
```

Folder mapping versus the original sketch:

| Sketch | Lives in |
| --- | --- |
| `App/` | `Sources/PeekMemo/App/` |
| `Models/` | `Sources/PeekMemoCore/Models/` |
| `Core/AppState.swift` | `Sources/PeekMemo/App/AppState.swift` |
| `Window/` | `Sources/PeekMemo/Window/` |
| Geometry / hover | `Sources/PeekMemoCore/Geometry/`, `Hover/` |
| `Persistence/` | `Sources/PeekMemoCore/Persistence/` (GRDB). Window placement stays in `Sources/PeekMemo/Persistence/` (UserDefaults). |
| `Views/` | `Sources/PeekMemo/Views/` |
| `Utilities/` | `Sources/PeekMemo/Utilities/` |
| `Resources/` | `Sources/PeekMemo/Resources/` |

Windows is **not** being built. The split exists so a future Windows adapter can reuse Core without dragging AppKit into domain code.

## Coordinate system

All geometry uses AppKit’s bottom-left origin (`CGRect` in screen space). Core never calls `NSScreen`.

`ScreenGeometry` is the portable snapshot:

- `identifier` — stable per-display id (`CGDirectDisplayID` as a string on macOS)
- `frame`
- `visibleFrame`
- `safeAreaInsets`
- `auxiliaryTopLeft` / `auxiliaryTopRight` — nil when the screen has no top auxiliary areas

`ScreenManager` (app target) is the only type that reads `NSScreen`.

## Placement

`DisplayPlacement` stores `{displayIdentifier, edge, offset}`, never an absolute x/y as the source of truth.

Offset origin:

- Left / Right: from the **top** of `visibleFrame`, increasing downward
- Top / Bottom: from the **leading** (minX) of `visibleFrame`, increasing rightward

On mouse-up the stack always snaps to the nearest legal edge. Magnet range while dragging is `LayoutMetrics.magnetRange` (24 pt).

Dock / menu bar: the **along-edge** span is clamped to `visibleFrame`. The **perpendicular** position uses `frame` unless that edge is inset by the Dock, in which case `visibleFrame` is used so the tab stays hittable.

## Notch Cloak

The MacBook notch is a hide anchor, not an obstacle.

- Detected only when both auxiliary top areas exist and `safeAreaInsets.top > 0`.
- If the user drops the Top-edge stack onto the notch’s horizontal range, placement is Notch Cloak.
- Collapsed visuals may occupy zero pixels inside the physical notch. A transparent hover strip sits on the notch underside (`LayoutMetrics.hoverHitThickness`).
- Hover expands the panel **downward** from the notch.
- Screens without a notch never expose Notch Cloak.
- No model names, no hard-coded notch sizes.

Exiting cloak: drag handle after hover, Preferences → Reset Position, and Menu Bar → Show / Reposition (Phase 9).

## Collapsed modes

1. **Edge Tab** (default) — 4 pt visible wedge, 14 pt hit region.
2. **Cloak** — hidden until the pointer enters the edge hit region.
3. **Notch Cloak** — Top edge + notched display only.

Visual thickness and hit thickness are independent constants in `LayoutMetrics`.

## Window

`PeekPanel` is a custom `NSPanel`:

- borderless, transparent, not movable by the system
- `.nonactivatingPanel` so peeking does not steal key focus
- `canBecomeKey` is gated and enabled only in editing
- `collectionBehavior` includes `.canJoinAllSpaces` and `.fullScreenAuxiliary`
- activation policy: `.accessory` (no Dock icon)

Hover is owned by `HoverEngine` (Core) plus an AppKit `HoverController` that feeds pointer enter/exit for the **union** of the edge item and expanded panel (`HoverRegion`, 6 pt padding, 80 ms grace). SwiftUI `onHover` is not the source of truth.

Live drag never cloaks. Notch Cloak is committed only on mouse-up. The Notch sensor is hidden while dragging and sits below the main panel’s window level.

## Product model

PeekMemo is intentionally not a project-management application.

Core model:

- **Date** (`selectedDate` / `scheduledDate`) — which day a task is for
- **Category** (`Category`, `categoryId`) — Work, Personal, or user-created. Not a separate page
- **Note** — plain text, no checkbox, no subtasks, not in the completion count
- **Task / Subtask** — one extra indent level only
- **Completion** — stays in place with strikethrough

`Today` is not a list. It only means `selectedDate` is the current calendar day.

There is no Inbox page, no Completed smart view, and no bottom More navigation.

`dueDate` exists on the domain model but is not shown in v0.1 UI.

## Daily View

The expanded panel is always a date view. Default `selectedDate` is today.

- `scheduledDate` — the day the user plans to work on the item
- `dueDate` — deadline; hidden in v0.1
- `completedAt` — when it was actually finished

Historical daily view is derived from current `scheduledDate` + `completedAt`.
Full activity history / event log is a future enhancement.

Completed tasks remain in the day’s list (checked + strikethrough). They are not moved to a Completed section.

Notes with a `scheduledDate` appear on that day but never enter the task completion ratio. A note cannot have a subtask. Add a note from the context menu on + Add Task.

On Today only, unfinished root tasks whose `scheduledDate` is before today appear above the day’s list as “未完成 · N”. Completing one does not change its date. Looking at a past day shows only items scheduled for that day.

A nil `categoryId` is valid and included in All. The row does not show an Uncategorized badge.

## Edge snapping (v0.1)

Default snap targets: **Left, Right, Bottom**.

**Top** and **Notch Cloak** are experimental. Code is kept. Enable via DEBUG → Experimental Top / Notch. Ordinary drag will not snap to Top, so users are not trapped there. A stored Top or Notch placement restores to Right while experimental snapping is off.

Collapsed Notch Cloak uses only the underside hit strip (`notchCloakHitThickness`). The housing rectangle is never a drawing surface. Top-edge drag uses `notchSnapThreshold` (26 pt) with a smoothstep pull so cloak does not teleport.

The Core type `HoverPhase` must be spelled `PeekMemoCore.HoverPhase` in SwiftUI files; SwiftUI also defines `HoverPhase`.

## Persistence (Phase 6)

SQLite via GRDB.swift. The file is `~/Library/Application Support/PeekMemo/PeekMemo.sqlite`. It is never stored in the source tree. Tests open a database under the system temporary directory and must not touch Application Support.

Window configuration stays in UserDefaults: edge, position, panel size, hover delays, appearance, experimental flags. `selectedDate` is UI state and defaults to today on every launch. It is not stored.

### Migration policy

`DatabaseMigrator` starts with `v1_initial_schema`. Later schema changes are new migrations. A mismatch, a failed migration, or a database that will not open must not delete or recreate the file. DEBUG builds print `[Persistence]`. A failed write does not update the UI as if it had succeeded.

The first migration inserts Work and Personal and no sample tasks. That seed runs only inside the migration, so deleting or archiving those categories is permanent across launches.

### Schema

`categories`: `id` TEXT PK, `name` TEXT NOT NULL, `icon` TEXT NULL, `color` TEXT NULL, `sort_order` INTEGER NOT NULL, `is_archived` INTEGER NOT NULL DEFAULT 0, `created_at` DATETIME NOT NULL, `updated_at` DATETIME NOT NULL.

`memo_items`: `id` TEXT PK, `category_id` TEXT NULL → `categories.id`, `parent_id` TEXT NULL → `memo_items.id`, `type` TEXT NOT NULL (`task` | `note`), `title` TEXT NOT NULL, `body` TEXT NULL, `is_completed` INTEGER NOT NULL DEFAULT 0, `completed_at` DATETIME NULL, `sort_order` INTEGER NOT NULL, `scheduled_date` DATETIME NULL, `due_date` DATETIME NULL, `is_archived` INTEGER NOT NULL DEFAULT 0, `created_at` DATETIME NOT NULL, `updated_at` DATETIME NOT NULL.

There is no `forToday` column. `PRAGMA foreign_keys = ON`. Indexes: `scheduled_date`, `category_id`, `parent_id`, `is_completed`, and `(scheduled_date, category_id)`.

Color is stored as an RGBA hex string, never as a SwiftUI `Color`.

### Date semantics

Values are absolute timestamps. A civil day is `[dayStart, nextDayStart)` from `Calendar.current` / `TimeZone.current`. Queries use `scheduled_date >= dayStart AND scheduled_date < nextDayStart`, not `DATE(scheduled_date)`.

`scheduledDate` is the day the item appears. `dueDate` is a reserved deadline and is not shown in v0.1. `completedAt` is when a task was actually completed.

### Queries

Views do not run SQL. `CategoryRepository` and `MemoRepository` do.

A daily query returns root rows (`parent_id IS NULL`, not archived) scheduled on the selected day, including completed tasks. A category filter adds `category_id = selected`. A nil `categoryId` still appears in All. Subtasks are loaded with their parent and are not roots.

Past Unfinished runs only for Today: `scheduled_date < todayStart AND is_completed = 0 AND is_archived = 0 AND parent_id IS NULL AND type = 'task'`, ordered by `scheduled_date DESC, sort_order ASC`. The query does not rewrite `scheduledDate`. A past day shows only that day's rows.

Completing a parent completes its children, completing the last child completes the parent, uncompleting a child reopens the parent, and uncompleting a parent leaves children as they were. Those updates are one SQLite transaction. Deleting a parent deletes its children in one transaction. Archiving a category hides it from the picker and leaves its items in place.

A note may have a `scheduledDate` and a `categoryId`. It cannot have a parent or a subtask, and it has no completion state. Daily progress counts root tasks only.

## Settings (Phase 8–9)

Preferences windows: General, Appearance, Behavior.

Launch at Login uses `SMAppService.mainApp` only.

Hide-in-fullscreen is **experimental** and off by default. No private APIs.

## Animation

Duration window: 120–220 ms for expansion, 100–180 ms for handle reveal. No bounce. Direction follows the edge (right opens left, and so on).

## Testing policy

Anything that does not need AppKit UI is a unit test: edge placement, offset clamping, notch range, screen migration, color serialization, hover transitions, later database CRUD.

Tests live in the `PeekMemoCoreTests` **executable** (`swift run PeekMemoCoreTests`). Command Line Tools does not ship XCTest, and a CLT-built Swift Testing `.xctest` cannot `dlopen` `Testing.framework`. The harness is a few dozen lines in `Tests/PeekMemoCoreTests/Harness.swift` and covers the same geometry / hover / color cases. GitHub Actions runs the same command so local and CI stay aligned.

## Out of scope for v0.1

iCloud, AI, agents, Workbench integration, plugins, a full Markdown editor, mobile, Windows, analytics, telemetry, crash SDKs, accounts, cloud sync, notarization, Developer ID signing.
