# Controller vs Coordinator: Understanding the Difference

## Quick Answer

In modern Swift/iOS development, these terms are often used interchangeably, but they have distinct historical contexts and subtle semantic differences:

- **Controller**: Broad term, can mean many things (legacy UIKit pattern, access control, input handling)
- **Coordinator**: Specific pattern for managing navigation flow or orchestrating complex workflows

**In Maestro's architecture:**

- **Coordinator**: Manages integration lifecycle, navigation flows, or multi-step workflows
- **Controller**: Manages access, input handling, or simpler state management
- Both are types of **services** in the MVVM context

---

## Historical Context

### UIKit Era (Controllers)

In UIKit, **ViewController** was the dominant pattern:

```swift
// UIKit - ViewController does EVERYTHING
class TaskViewController: UIViewController {
    // View management
    override func viewDidLoad() { /* ... */ }

    // Navigation
    func showDetail() {
        let detailVC = DetailViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // Business logic (bad practice, but common)
    func saveTask() { /* ... */ }

    // Networking
    func fetchTasks() { /* ... */ }
}
```

**Problem:** ViewControllers became "Massive View Controllers" doing too much.

### SwiftUI Era (Coordinators)

SwiftUI doesn't have ViewControllers. The **Coordinator pattern** emerged to:

1. **Separate navigation from views** (since SwiftUI views are structs)
2. **Manage complex flows** across multiple screens
3. **Handle side effects** that don't belong in views

---

## Semantic Differences

### Coordinator

**What it means:**

- Orchestrates a workflow or process
- Coordinates between multiple components
- Manages state transitions or navigation flow
- Often has a lifecycle (setup, start, stop, cleanup)

**Characteristics:**

- Usually `ObservableObject` or `@Observable`
- Often `@MainActor` for UI coordination
- Has `@Published` properties for state
- Manages complex, multi-step processes
- May coordinate multiple services

**When to use "Coordinator":**

- ✅ Managing integration connection/disconnection flow
- ✅ Orchestrating multi-screen navigation
- ✅ Coordinating multiple services for a complex workflow
- ✅ Managing stateful processes with lifecycle

**Examples:**

```swift
// Example 1: Integration Coordinator
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus = .disconnected

    private let calendarService: CalendarServiceProtocol
    private let userDefaults: UserDefaults

    // Orchestrates the connection flow
    func connect() async throws {
        status = .connecting
        let granted = try await calendarService.requestAccess()
        if granted {
            status = .connected
            userDefaults.set(true, forKey: "calendarEnabled")
        } else {
            status = .authorizationDenied
        }
    }

    // Orchestrates disconnection
    func disconnect() async throws {
        status = .disconnecting
        userDefaults.set(false, forKey: "calendarEnabled")
        status = .disconnected
    }

    // Monitors state changes
    func observeChanges() { /* ... */ }
}
```

```swift
// Example 2: Navigation Coordinator (if we had one)
@MainActor
final class SettingsCoordinator: ObservableObject {
    enum Route {
        case integrations
        case automations
        case notionConfiguration
    }

    @Published var currentRoute: Route?

    // Coordinates navigation between settings screens
    func navigate(to route: Route) {
        currentRoute = route
    }

    func goBack() {
        currentRoute = nil
    }
}
```

```swift
// Example 3: Command Approval Coordinator
@MainActor
final class CommandApprovalCoordinator: ObservableObject {
    @Published var pendingActions: [PendingAction] = []
    @Published var currentApprovalRequest: PendingAction?

    private let executionService: CommandExecutionService

    // Coordinates the approval workflow
    func requestApproval(for action: PendingAction) {
        pendingActions.append(action)
        if currentApprovalRequest == nil {
            presentNextApproval()
        }
    }

    func approve(_ action: PendingAction) async {
        // Execute approved action
        try? await executionService.execute(action)
        removeFromQueue(action)
        presentNextApproval()
    }

    func deny(_ action: PendingAction) {
        removeFromQueue(action)
        presentNextApproval()
    }

    private func presentNextApproval() {
        currentApprovalRequest = pendingActions.first
    }
}
```

---

### Controller

**What it means:**

- Controls access to a resource
- Handles input from a source
- Manages a specific capability
- Usually more narrowly scoped than coordinator

**Characteristics:**

- May or may not be `ObservableObject`
- Often manages a single concern
- Typically simpler than coordinators
- May be stateless or have minimal state

**When to use "Controller":**

- ✅ Managing access to a system resource (permissions, files)
- ✅ Handling input from external source (voice, keyboard, gestures)
- ✅ Controlling a specific capability (escape key handling, hotkeys)
- ✅ Simpler, more focused responsibility than a coordinator

**Examples:**

```swift
// Example 1: Access Controller
final class RemindersAccessController {
    private let eventStore = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    // Controls access to reminders
    func requestAccess() async throws -> Bool {
        try await eventStore.requestAccess(to: .reminder)
    }
}
```

```swift
// Example 2: Input Controller
final class VoiceInputController {
    private let recognizer = SFSpeechRecognizer()

    var isAvailable: Bool {
        recognizer?.isAvailable ?? false
    }

    // Controls voice input
    func startListening(completion: @escaping (String?) -> Void) {
        // Handle voice input
    }

    func stopListening() {
        // Stop voice recognition
    }
}
```

```swift
// Example 3: Escape Key Controller
final class CommandBarEscapeController {
    private var escapePolicy: EscapeKeyPolicy = .dismissOnEmpty

    // Controls escape key behavior
    func handleEscapeKey(inputText: String) -> Bool {
        switch escapePolicy {
        case .alwaysDismiss:
            return true
        case .dismissOnEmpty:
            return inputText.isEmpty
        case .clearThenDismiss:
            // Clear first, dismiss second press
            return false
        }
    }
}
```

```swift
// Example 4: Workspace Access Controller
final class WorkspaceAccessController {
    // Controls file system access
    func requestWorkspaceAccess(for url: URL) -> Bool {
        // Request sandboxed file access
    }

    func hasAccess(to url: URL) -> Bool {
        // Check if we have access
    }
}
```

---

## Key Differences


| Aspect             | Coordinator                           | Controller                           |
| ------------------ | ------------------------------------- | ------------------------------------ |
| **Scope**          | Broader, orchestrates workflows       | Narrower, controls specific resource |
| **Complexity**     | Often complex, multi-step             | Usually simpler, focused             |
| **State**          | Usually stateful (`ObservableObject`) | May be stateless or minimal state    |
| **Lifecycle**      | Has setup/teardown                    | May not have lifecycle               |
| **Dependencies**   | Often coordinates multiple services   | Usually wraps single resource/API    |
| **Responsibility** | "How do these pieces work together?"  | "How do we access/control this?"     |


---

## In Maestro's Codebase

### We Use "Coordinator" For:

1. **Integration Lifecycle Management**
  ```
   Integrations/
   ├── Calendar/
   │   └── CalendarIntegrationCoordinator.swift    ✅ Orchestrates connection flow
   ├── Reminders/
   │   └── RemindersIntegrationCoordinator.swift   ✅ Orchestrates connection flow
   └── Notion/
       └── NotionIntegrationCoordinator.swift      ✅ Orchestrates OAuth + connection
  ```
2. **Complex Workflows**
  ```
   CommandBar/Services/
   └── CommandApprovalCoordinator.swift            ✅ Orchestrates approval flow
  ```
3. **OAuth Flows** (existing)
  ```
   Services/OAuth/
   └── OAuthCoordinator.swift                      ✅ (Hypothetical, you might have this)
  ```

### We Use "Controller" For:

1. **Access Management**
  ```
   Settings/ViewModels/
   └── WorkspaceAccessController.swift             ✅ Controls file access

   Integrations/Reminders/
   └── RemindersAccessController.swift             ✅ Controls reminder access
  ```
2. **Input Handling**
  ```
   Services/Voice/
   └── VoiceInputController.swift                  ✅ Controls voice input

   CommandBar/ViewModels/
   └── CommandBarEscapeController.swift            ✅ Controls escape key
  ```

---

## When the Lines Blur

Sometimes the distinction is subjective. Here are cases where either term works:

### Case 1: OAuth Management

```swift
// Could be either:
OAuthCoordinator.swift       // ✅ Coordinates OAuth flow (multi-step)
OAuthController.swift        // ✅ Controls OAuth access

// In practice: "Coordinator" is better because OAuth is a multi-step flow
```

### Case 2: Integration Management

```swift
// Could be either:
IntegrationCoordinator.swift // ✅ Coordinates setup/teardown
IntegrationController.swift  // ✅ Controls integration access

// In practice: "Coordinator" is better because it manages lifecycle + state
```

### Case 3: Simple Access Management

```swift
// Could be either:
PermissionCoordinator.swift  // If it orchestrates requesting multiple permissions
PermissionController.swift   // ✅ If it just controls access to one permission

// In practice: "Controller" is better for simple access checks
```

---

## Decision Framework

Use this flowchart to decide:

```
Does it manage a multi-step workflow or coordinate multiple components?
├─ Yes → Use "Coordinator"
│  └─ Examples:
│     - CalendarIntegrationCoordinator (setup → request → observe → teardown)
│     - CommandApprovalCoordinator (queue → present → approve/deny → execute)
│
└─ No → Does it control access or handle input?
   ├─ Yes → Use "Controller"
   │  └─ Examples:
   │     - VoiceInputController (start/stop voice input)
   │     - WorkspaceAccessController (check/request file access)
   │
   └─ No → It's probably a Service, Manager, or Helper
      └─ Examples:
         - CalendarService (execute calendar operations)
         - AutomationValidator (validate automation)
         - HotKeyManager (manage hotkeys)
```

---

## Naming Conventions in Maestro

Based on the patterns we've established:

### Use "Coordinator" suffix for:

```swift
// Integration lifecycle
CalendarIntegrationCoordinator.swift
NotionIntegrationCoordinator.swift

// Complex workflows
CommandApprovalCoordinator.swift
AutomationExecutionCoordinator.swift  // If orchestrating execution flow

// Navigation (if we add it)
SettingsCoordinator.swift
OnboardingCoordinator.swift

// OAuth flows
OAuthCoordinator.swift
```

### Use "Controller" suffix for:

```swift
// Access management
WorkspaceAccessController.swift
RemindersAccessController.swift
FileAccessController.swift

// Input handling
VoiceInputController.swift
KeyboardShortcutController.swift
GestureController.swift

// Behavior control
CommandBarEscapeController.swift
WindowDragController.swift
```

### Use neither (other names) for:

```swift
// Data operations
AutomationStorageService.swift         // Not "StorageCoordinator"
CalendarService.swift                  // Not "CalendarController"

// Validation
AutomationValidator.swift              // Not "ValidationController"

// Formatting
StatusTextFormatter.swift              // Not "FormattingController"

// Resource management
HotKeyManager.swift                    // "Manager" for singleton/shared resource
TokenManager.swift                     // "Manager" for token lifecycle
```

---

## Real-World Examples from Maestro

### Example 1: Reminders Access

**Current (Good):**

```
Integrations/Reminders/
├── RemindersAccessController.swift      ✅ Controls access to reminders
├── RemindersIntegrationCoordinator.swift ✅ Coordinates integration flow
└── RemindersService.swift               ✅ Executes reminder operations
```

**Why this works:**

- `Controller` → Simple access checking/requesting
- `Coordinator` → Orchestrates connection lifecycle
- `Service` → Actual reminder CRUD operations

**Alternative (Less Clear):**

```
Integrations/Reminders/
└── RemindersCoordinator.swift  # ❌ Unclear: access OR integration OR both?
```

---

### Example 2: Command Bar Escape Handling

**Current (Good):**

```
CommandBar/ViewModels/
└── CommandBarEscapeController.swift  ✅ Controls escape key behavior
```

**Why this works:**

- Simple, focused responsibility
- Controls how escape key is handled
- Not coordinating multiple components

**Alternative (Wrong):**

```
CommandBar/Services/
└── CommandBarEscapeCoordinator.swift  # ❌ Overkill, it's not coordinating anything
```

---

### Example 3: Voice Input

**Current (Good):**

```
Services/Voice/
└── VoiceInputController.swift  ✅ Controls voice input start/stop
```

**Why this works:**

- Handles input from microphone
- Controls when recognition starts/stops
- Simple interface to voice capability

**Alternative (Could Work):**

```
Services/Voice/
└── VoiceInputCoordinator.swift  # ⚠️ Could work if it coordinated voice + transcription + processing
```

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Controller Doing Too Much

```swift
// Bad - Controller orchestrating complex flow
final class CalendarController {
    func setupCalendar() async {
        // ❌ This is coordination, not control
        await requestPermission()
        await fetchCalendars()
        await observeChanges()
        await updateUI()
    }
}

// Good - Split into Controller + Coordinator
final class CalendarAccessController {
    func requestPermission() async -> Bool { /* ... */ }
}

final class CalendarIntegrationCoordinator {
    func setup() async {
        let granted = await accessController.requestPermission()
        if granted {
            await fetchAndObserve()
        }
    }
}
```

---

### ❌ Anti-Pattern 2: Coordinator Doing Too Little

```swift
// Bad - Coordinator with single simple responsibility
final class FileAccessCoordinator {
    func checkAccess(to url: URL) -> Bool {
        // ❌ This is just control, not coordination
        return url.startAccessingSecurityScopedResource()
    }
}

// Good - Just use Controller
final class FileAccessController {
    func checkAccess(to url: URL) -> Bool { /* ... */ }
}
```

---

### ❌ Anti-Pattern 3: Mixing Both Terms Inconsistently

```swift
// Bad - Inconsistent naming for similar things
CalendarIntegrationCoordinator.swift   // Manages calendar integration
RemindersIntegrationController.swift   // ❌ Manages reminders integration (should also be Coordinator)

// Good - Consistent naming
CalendarIntegrationCoordinator.swift
RemindersIntegrationCoordinator.swift
NotionIntegrationCoordinator.swift
```

---

## Migration Guide

If you have existing files that don't follow these conventions:

### Step 1: Identify the Actual Responsibility

```swift
// What does this file actually do?
SomeController.swift

// Ask:
1. Does it orchestrate multiple steps? → Rename to Coordinator
2. Does it control access/input? → Keep as Controller
3. Does it execute operations? → Rename to Service
```

### Step 2: Rename if Needed

```bash
# Example: Renaming misnamed files
git mv IntegrationController.swift IntegrationCoordinator.swift
git mv PermissionCoordinator.swift PermissionController.swift
git mv AuthorizationManager.swift AuthorizationController.swift
```

### Step 3: Update Imports and References

Search and replace across codebase for the old name.

---

## Summary

### Use "Coordinator" when:

- 📊 Orchestrating workflows
- 🔄 Managing state transitions
- 🎯 Coordinating multiple services
- 🏗️ Complex, multi-step processes
- 🔌 Integration lifecycle management

### Use "Controller" when:

- 🔐 Managing access to resources
- ⌨️ Handling input from sources
- 🎮 Controlling specific capabilities
- ✅ Simple, focused responsibilities
- 🚪 Permission/access checking

### Use other names when:

- 💾 Data operations → **Service**
- ✅ Validation → **Validator**
- 🎨 Formatting → **Formatter**
- 🔧 Utilities → **Helper** or **Utility**
- 🏪 Persistence → **Repository**
- 🌐 Singletons → **Manager**

---

## Quick Reference Card


| If it...                            | Call it...  | Example                          |
| ----------------------------------- | ----------- | -------------------------------- |
| Manages multi-step integration flow | Coordinator | `CalendarIntegrationCoordinator` |
| Handles approval workflow           | Coordinator | `CommandApprovalCoordinator`     |
| Checks/requests permissions         | Controller  | `RemindersAccessController`      |
| Handles keyboard/voice input        | Controller  | `VoiceInputController`           |
| Controls escape key behaviour       | Controller  | `EscapeController`               |
| Executes business operations        | Service     | `CalendarService`                |
| Stores/retrieves data               | Repository  | `AutomationRepository`           |
| Validates data                      | Validator   | `AutomationValidator`            |
| Formats for display                 | Formatter   | `StatusTextFormatter`            |
| Manages shared resource             | Manager     | `HotKeyManager`                  |


**When in doubt:** If it's stateful and orchestrates → Coordinator. If it's focused and controls → Controller. If it just does work → Service.