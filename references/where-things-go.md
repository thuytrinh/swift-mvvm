# Where Things Go

## Views

**Location:** `FeatureName/Views/`

**What goes here:**

- SwiftUI view structs
- View-specific components
- Layout logic only

**What doesn't go here:**

- Business logic → ViewModels
- Data fetching → Services
- Formatting → Formatters

```swift
// ✅ Good - View
struct AutomationEditorView: View {
    @ObservedObject var viewModel: AutomationEditorViewModel

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            // Just UI composition
        }
    }
}
```

See `references/anti-patterns.md` for examples of what not to do.

## ViewModels

**Location:** `FeatureName/ViewModels/`

**What goes here:**

- `@Published` state properties
- User interaction handlers
- Coordination between services
- Presentation state transformation

**What is a ViewModel:**

- Manages state for a specific view
- Contains zero UIKit/SwiftUI imports (except `Combine`, `Foundation`)
- Marked with `@MainActor` for SwiftUI
- Uses dependency injection for services

```swift
// ✅ Good ViewModel
@MainActor
final class AutomationEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var prompt: String = ""
    @Published var isValid: Bool = false

    private let storageService: AutomationStorageService
    private let validator: AutomationValidator

    init(
        storageService: AutomationStorageService,
        validator: AutomationValidator
    ) {
        self.storageService = storageService
        self.validator = validator
    }

    func save() async throws {
        guard validator.validate(name: name, prompt: prompt) else {
            throw ValidationError.invalid
        }
        try await storageService.save(name: name, prompt: prompt)
    }
}
```

**ViewModel Extensions:**
When a ViewModel gets large, split into extensions:

```
AutomationEditorViewModel.swift              # Core properties and init
AutomationEditorViewModel+Validation.swift   # Validation logic
AutomationEditorViewModel+Actions.swift      # Action handlers
```

## Services

**Location:** `FeatureName/Services/` or `Services/FeatureName/`

**What is a Service:**
A service encapsulates business logic, data operations, or coordinates external resources. Services are stateless (or manage their own internal state independently).

**Service Types:**

### 1. Data Services

Handle CRUD operations, API calls, persistence.

```swift
// Example: AutomationStorageService.swift
protocol AutomationStorageServiceProtocol {
    func save(_ automation: Automation) async throws
    func fetch(id: UUID) async throws -> Automation?
    func fetchAll() async throws -> [Automation]
    func delete(id: UUID) async throws
}

final class AutomationStorageService: AutomationStorageServiceProtocol {
    private let repository: AutomationRepository
    // Implementation
}
```

### 2. Business Logic Services

Execute business rules, validation, calculations.

```swift
// Example: AutomationValidator.swift
final class AutomationValidator {
    func validate(automation: Automation) -> ValidationResult {
        // Business rules
    }
}
```

### 3. Integration Services

Interact with external systems (APIs, EventKit, etc.).

```swift
// Example: CalendarService.swift
protocol CalendarServiceProtocol {
    func fetchEvents(from: Date, to: Date) async throws -> [Event]
    func createEvent(_ event: Event) async throws -> String
}

final class CalendarService: CalendarServiceProtocol {
    private let eventStore: EKEventStore
    // Implementation
}
```

### 4. Coordinators

Orchestrate complex workflows involving multiple services or state.

```swift
// Example: CalendarIntegrationCoordinator.swift
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus

    private let calendarService: CalendarServiceProtocol
    private let userDefaults: UserDefaults

    func connect() async throws { /* ... */ }
    func disconnect() async throws { /* ... */ }
}
```

**What counts as a Coordinator vs Service:**

- **Coordinator**: Manages stateful workflows, integration lifecycle, complex multi-step processes. Often `ObservableObject`.
- **Service**: Stateless operations, single responsibility, pure business logic. Rarely `ObservableObject`.

### 5. Managers

Manage resources or singleton concerns.

```swift
// Example: HotKeyManager.swift
final class HotKeyManager {
    static let shared = HotKeyManager()

    func register(hotkey: String, handler: @escaping () -> Void) { /* ... */ }
}
```

## Models

**Location:** `FeatureName/Models/` or `Shared/Models/`

**What goes here:**

- Data structures (`struct`, `enum`, `class`)
- No business logic
- May include computed properties for derived data
- Conform to `Codable`, `Identifiable`, `Equatable` as needed

**Feature-specific vs Shared:**

- Feature-specific: `Automations/Models/Automation.swift`
- Shared across features: `Shared/Models/OAuthToken.swift`

```swift
// ✅ Good Model
struct Automation: Identifiable, Codable {
    let id: UUID
    var name: String
    var prompt: String
    var variables: [AutomationVariable]
    var createdAt: Date

    // Computed properties are OK
    var isValid: Bool {
        !name.isEmpty && !prompt.isEmpty
    }
}

// ❌ Bad Model with business logic
struct Automation: Identifiable, Codable {
    let id: UUID
    var name: String

    // ❌ Don't put business logic in models
    func save() async throws {
        await storageService.save(self)
    }
}
```

## Formatters

**Location:** `FeatureName/Formatters/` or `Shared/Formatters/`

**What goes here:**

- Presentation logic that transforms data for display
- No state, pure functions or stateless classes
- Examples: Date formatting, currency formatting, status text generation

```swift
// Example: CommandBarStatusTextFormatter.swift
final class CommandBarStatusTextFormatter {
    func format(status: AgentStatus) -> String {
        switch status {
        case .thinking:
            return "✨ Analyzing your request..."
        case .executing:
            return "⚙️ Executing..."
        }
    }
}
```

## Repositories

**Location:** `FeatureName/Persistence/`

**What is a Repository:**
A repository abstracts the data access layer. It's the only component that knows about CoreData, SQLite, JSON files, etc.

```swift
// Example: AutomationRepository.swift
protocol AutomationRepositoryProtocol {
    func save(_ automation: Automation) async throws
    func fetch(id: UUID) async throws -> Automation?
    func fetchAll() async throws -> [Automation]
    func delete(id: UUID) async throws
}

final class AutomationRepository: AutomationRepositoryProtocol {
    private let persistentContainer: NSPersistentContainer

    // CoreData implementation details hidden here
}
```

**Repository vs Service:**

- **Repository**: Pure data access, knows about storage mechanism
- **Service**: Business logic, uses repository for data, doesn't know about storage details

## Protocols

**Location:** `FeatureName/Protocols/` or alongside the implementations in `Services/`

**When to create protocols:**

- ✅ Multiple implementations exist or planned
- ✅ Need to mock for testing
- ✅ Dependency Inversion Principle requires abstraction
- ❌ Only one implementation, no plans for alternatives

```swift
// ✅ Good use of protocol - multiple implementations possible
protocol CalendarServiceProtocol {
    func fetchEvents() async throws -> [Event]
}

class AppleCalendarService: CalendarServiceProtocol { /* ... */ }
class GoogleCalendarService: CalendarServiceProtocol { /* ... */ }

// ❌ Unnecessary protocol - only one implementation
protocol AutomationNameValidator {
    func validate(name: String) -> Bool
}

// Just use the concrete class
final class AutomationValidator {
    func validate(name: String) -> Bool { /* ... */ }
}
```

## Utilities

**Location:** `FeatureName/Utilities/` or `Shared/Extensions/`

**What goes here:**

- Helper functions
- Extensions
- Small, reusable components

**Feature-specific vs Shared:**

- Feature-specific: `CommandBar/Utilities/WindowPositionCalculator.swift`
- Shared: `Shared/Extensions/String+Extensions.swift`

---

## Quick Reference

### "Where does X go?"

| What                 | Where                                             | Example                                |
| -------------------- | ------------------------------------------------- | -------------------------------------- |
| SwiftUI View         | `FeatureName/Views/`                              | `CommandBarView.swift`                 |
| ViewModel            | `FeatureName/ViewModels/`                         | `CommandBarViewModel.swift`            |
| Data Model           | `FeatureName/Models/` or `Shared/Models/`         | `Automation.swift`                     |
| Business Logic       | `FeatureName/Services/`                           | `AutomationValidator.swift`            |
| Data Access          | `FeatureName/Persistence/`                        | `AutomationRepository.swift`           |
| External Integration | `Integrations/ServiceName/`                       | `CalendarIntegrationCoordinator.swift` |
| Formatter            | `FeatureName/Formatters/` or `Shared/Formatters/` | `StatusTextFormatter.swift`            |
| Extension            | `Shared/Extensions/`                              | `String+Extensions.swift`              |
| Protocol             | `FeatureName/Protocols/` or with implementation   | `IntegrationCoordinatorProtocol.swift` |
| Utility              | `FeatureName/Utilities/` or `Shared/Extensions/`  | `WindowPositionCalculator.swift`       |

### "What is X?"

| Term            | Definition                  | Characteristics                                           |
| --------------- | --------------------------- | --------------------------------------------------------- |
| **View**        | SwiftUI UI component        | No business logic, observes ViewModel                     |
| **ViewModel**   | State + presentation logic  | `@MainActor`, `ObservableObject`, uses services           |
| **Model**       | Data structure              | `struct`/`enum`, `Codable`, no logic                      |
| **Service**     | Business logic              | Stateless, single responsibility                          |
| **Coordinator** | Workflow orchestration      | Stateful, manages complex flows, often `ObservableObject` |
| **Repository**  | Data access layer           | Abstracts storage (CoreData, SQLite, etc.)                |
| **Formatter**   | Presentation transformation | Pure functions, data → display format                     |
| **Manager**     | Resource management         | Often singleton, manages shared resources                 |
| **Handler**     | Request/response handling   | Processes incoming requests (AgentBridge)                 |
| **Provider**    | Supplies resources          | Provides tokens, configuration, etc.                      |
