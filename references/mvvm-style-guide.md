# Swift MVVM Style Guide (SwiftUI + UIKit + AppKit)

## Prime directive

**Keep ViewModels UI-framework agnostic.**

- ViewModel files should not import `SwiftUI`, `UIKit`, or `AppKit`.
- If you need platform behavior, inject a tiny protocol and implement it in the platform layer.

## State modeling

Prefer a single `State` struct containing only UI-relevant values, split into nested structs.

### Typical layout

- `State.ViewState` (loading flags, title, enabled/disabled)
- `State.ContentState` (rows, selection, empty states)
- `State.AlertsState` (error, banners, confirmations)
- Optional: `State.NavigationState` or `State.Route` (pure values, not UI types)

### Error state

Use a presentable type:

```swift
struct ErrorState: Equatable {
  let title: String
  let message: String
}
```

## Intents & actions

- Simple screen: methods like `onAppear()`, `refresh()`, `didSelectRow(id:)`.
- Complex: `enum Action { ... }` + `send(_:)`.

## Keep ViewModel small

Best practice is to make a ViewModel mostly:

- **State**
- **Intent forwarding**
- **Dependency coordination**

Push everything else into smaller units:

- Pure logic: `RowBuilder`, `Reducer`, `Validator`, `Sorter`, `Formatter`
- Side effects: `UseCase`, `Controller`, `Repository`

## Refactor recipe for “massive ViewModel”

1. **Extract pure logic first** into structs/pure functions.
  - This shrinks the VM and makes logic directly testable.
2. **Extract side effects next** into controller/use-case objects.
  - Keep them behind protocols.
  - The VM coordinates them and assigns state.
3. Keep the VM as a thin layer:
  - intents → call pure logic/effects → update state

## Platform adapters

Any platform API in ViewModel is a smell. Define tiny protocols (Foundation-only) and implement them in the UI layer.

Example:

```swift
protocol FileRevealing {
  func reveal(_ url: URL)
}
```

AppKit implementation (in AppKit-only file):

```swift
import AppKit

struct WorkspaceFileRevealer: FileRevealing {
  func reveal(_ url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}
```

## Extensions

Extensions are encouraged for organization:

- Put protocol conformances in their own extensions.
- Group private helpers by concern.
- Keep the primary type definition short.

## Testing

Prefer Swift Testing for new code. Focus tests on:

- pure logic units (row building, reducers, sorting)
- state transitions (loading → success / error)
- cancellation behavior
- intent forwarding (didTapX calls controller/use case)

## Common pitfalls

- Using `@ObservedObject` for a ViewModel the view creates (re-init issues)
- Missing cancellation for search/refresh
- Updating observable state off-main
- Putting URLSession/JSONDecoder logic inside a ViewModel
- ViewModel importing UI frameworks
- “God” ViewModel that does everything

