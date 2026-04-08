# Where Does State Live in MVVM?

## The Core Principle

**Services should be stateless** (or manage only internal operational state), but **someone** needs to hold application/feature state. Here's where different types of state live:

---

## State Ownership Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                    Application State                     │
│                  (App-wide, long-lived)                  │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │           Feature State (Coordinators)          │    │
│  │        (Integration status, connection          │    │
│  │         state, feature-level concerns)          │    │
│  │                                                  │    │
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │     UI State (ViewModels)                │  │    │
│  │  │  (User input, presentation state,        │  │    │
│  │  │   loading indicators, validation)        │  │    │
│  │  │                                           │  │    │
│  │  │  ┌────────────────────────────────────┐  │  │    │
│  │  │  │    View State (@State, @Binding)   │  │  │    │
│  │  │  │  (Ephemeral, UI-only state)        │  │  │    │
│  │  │  └────────────────────────────────────┘  │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘

                          ↕
                    Services ⟷ Repositories
              (Stateless operations on data)
```

---

## Types of State and Where They Live

### 1. UI State → ViewModels

**What is UI State:**

- User input (text fields, toggles, selections)
- Loading/error states for UI feedback
- Validation states
- Presentation-specific state (expanded/collapsed, selected tab)

**Where it lives:**

- `@Published` properties in ViewModels
- `@State` in Views (for truly ephemeral state)

**Examples:**

```swift
// CommandBar/ViewModels/CommandBarViewModel.swift
@MainActor
final class CommandBarViewModel: ObservableObject {
    // UI State - lives in ViewModel
    @Published var inputText: String = ""           // User's current input
    @Published var isProcessing: Bool = false       // Loading indicator
    @Published var errorMessage: String?            // Error to display
    @Published var messages: [Message] = []         // Conversation history
    @Published var suggestions: [Suggestion] = []   // Current suggestions

    // ViewModels hold UI state, Services do the work
    private let agentClient: AgentClientProtocol
    private let suggestionBuilder: CommandBarSuggestionBuilder

    func sendMessage() async {
        isProcessing = true  // ← UI state
        errorMessage = nil   // ← UI state

        do {
            // Service does stateless work
            let response = try await agentClient.query(inputText)

            // ViewModel updates UI state with result
            messages.append(Message(role: .assistant, content: response))
            inputText = ""  // ← UI state
        } catch {
            errorMessage = error.localizedDescription  // ← UI state
        }

        isProcessing = false  // ← UI state
    }
}
```

**Why ViewModels hold UI state:**

- ✅ Views observe ViewModels
- ✅ ViewModels can be tested without UI
- ✅ Services remain reusable across features
- ✅ Clear separation: ViewModel = "What to show", Service = "How to do work"

---

### 2. Feature/Domain State → Coordinators

**What is Feature State:**

- Integration connection status
- Feature configuration/settings
- Workflow progress
- Cross-screen state
- Lifecycle state

**Where it lives:**

- Coordinators (often `ObservableObject`)
- Sometimes in dedicated state managers

**Examples:**

```swift
// Integrations/Calendar/CalendarIntegrationCoordinator.swift
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    // Feature State - lives in Coordinator
    @Published private(set) var status: IntegrationStatus = .disconnected

    private let calendarService: CalendarServiceProtocol  // ← Stateless
    private let userDefaults: UserDefaults                 // ← Persistence

    func connect() async throws {
        // Coordinator manages state transitions
        status = .connecting  // ← State change

        // Service does stateless work
        let granted = try await calendarService.requestAccess()

        if granted {
            status = .connected  // ← State change
            userDefaults.set(true, forKey: "calendarEnabled")
        } else {
            status = .authorizationDenied  // ← State change
        }
    }
}
```

**Why Coordinators hold feature state:**

- ✅ State outlives individual views
- ✅ Multiple views/ViewModels can observe same coordinator
- ✅ Encapsulates feature-level concerns
- ✅ Can be injected into ViewModels that need it

---

### 3. Application State → App-Level Managers/Registries

**What is Application State:**

- Global settings
- User preferences
- Available integrations
- App-wide configuration

**Where it lives:**

- Singleton managers
- Registries
- App-level coordinators

**Examples:**

```swift
// Integrations/IntegrationRegistry.swift
@MainActor
final class IntegrationRegistry: ObservableObject {
    // Application State - which integrations are registered
    private var coordinators: [IntegrationType: any IntegrationCoordinatorProtocol] = [:]

    @Published private(set) var isInitialized = false

    func register<T: IntegrationCoordinatorProtocol>(
        _ coordinator: T,
        for type: IntegrationType
    ) {
        coordinators[type] = coordinator  // ← State
    }

    func coordinator(for type: IntegrationType) -> (any IntegrationCoordinatorProtocol)? {
        return coordinators[type]  // ← Access state
    }

    func setupAll() async {
        // Coordinators do the work, Registry tracks state
        for coordinator in coordinators.values {
            await coordinator.setup()
        }
        isInitialized = true  // ← State change
    }
}
```

---

### 4. Persistent State → Repositories/Storage

**What is Persistent State:**

- User data (automations, tasks, notes)
- Settings/preferences
- Cache
- Historical data

**Where it lives:**

- CoreData / SQLite / JSON files (via Repositories)
- UserDefaults (for simple settings)
- Keychain (for secure data)

**How it's accessed:**

- Services call Repositories
- Repositories abstract the storage mechanism
- State is loaded into memory (ViewModels/Coordinators) when needed

**Examples:**

```swift
// Automations/Persistence/AutomationRepository.swift
final class AutomationRepository {
    private let fileManager: FileManager
    private let fileURL: URL

    // NO @Published properties - Repository doesn't hold state
    // It's just a gateway to persistent storage

    func save(_ automation: Automation) async throws {
        let data = try JSONEncoder().encode(automation)
        try data.write(to: fileURL)
        // Doesn't keep automation in memory ✅
    }

    func fetchAll() async throws -> [Automation] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Automation].self, from: data)
        // Returns data, doesn't store it ✅
    }
}

// Automations/Services/AutomationStorageService.swift
final class AutomationStorageService {
    private let repository: AutomationRepository

    // NO state here either - just operations

    func save(_ automation: Automation) async throws {
        try await repository.save(automation)
    }

    func fetchAll() async throws -> [Automation] {
        return try await repository.fetchAll()
    }
}

// Automations/ViewModels/AutomationsListViewModel.swift
@MainActor
final class AutomationsListViewModel: ObservableObject {
    // STATE lives here - in the ViewModel
    @Published var automations: [Automation] = []
    @Published var isLoading = false

    private let storageService: AutomationStorageService

    func loadAutomations() async {
        isLoading = true

        // Service fetches data (stateless operation)
        automations = try await storageService.fetchAll()

        isLoading = false
    }
}
```

**The flow:**

```
User opens AutomationsListView
    ↓
View observes AutomationsListViewModel
    ↓
ViewModel calls AutomationStorageService.fetchAll()
    ↓
Service calls AutomationRepository.fetchAll()
    ↓
Repository reads from disk/database
    ↓
Returns [Automation] to Service
    ↓
Service returns [Automation] to ViewModel
    ↓
ViewModel stores in @Published var automations  ← STATE LIVES HERE
    ↓
View re-renders with data
```

---

### 5. Ephemeral View State → @State in Views

**What is Ephemeral View State:**

- Temporary UI state that doesn't need to persist
- Animation states
- Focus states
- Temporary selections

**Where it lives:**

- `@State` properties directly in SwiftUI Views
- Does NOT go in ViewModels if it's truly ephemeral

**Examples:**

```swift
struct AutomationEditorView: View {
    @ObservedObject var viewModel: AutomationEditorViewModel

    // Ephemeral state - lives in View
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedVariableIndex: Int?
    @FocusState private var focusedField: Field?

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)  // ← ViewModel state
                .focused($focusedField, equals: .name) // ← View state

            Button("Delete") {
                isShowingDeleteConfirmation = true  // ← View state
            }
        }
        .confirmationDialog("Delete?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.delete() }  // ← ViewModel action
            }
        }
    }
}
```

**When to use @State vs ViewModel @Published:**

- Use `@State` if: Only this view cares, doesn't need testing, purely UI concern
- Use ViewModel `@Published` if: Multiple views need it, affects business logic, needs testing

---

## Services Are Stateless (Mostly)

### What "Stateless Service" Means

A service can have **operational state** (internal implementation details) but should NOT have **application state** (data that consumers depend on).

**OK Internal State (Implementation Details):**

```swift
final class CalendarService: CalendarServiceProtocol {
    // ✅ OK - Internal operational state
    private let eventStore = EKEventStore()
    private var isInitialized = false

    private func ensureInitialized() async {
        guard !isInitialized else { return }
        // Initialize eventStore
        isInitialized = true
    }

    func fetchEvents(from: Date, to: Date) async throws -> [EKEvent] {
        await ensureInitialized()
        // Fetch and return events (doesn't store them)
        return eventStore.events(...)
    }
}
```

**NOT OK Application State:**

```swift
final class CalendarService: CalendarServiceProtocol {
    // ❌ BAD - Application state in service
    @Published var events: [EKEvent] = []  // ❌ Consumers depend on this
    @Published var isConnected: Bool = false  // ❌ Should be in Coordinator

    func fetchEvents() async {
        events = eventStore.events(...)  // ❌ Storing application data
    }
}
```

**Why this is bad:**

- Multiple consumers might have conflicting needs
- Service becomes singleton (hard to test)
- Violates single responsibility (fetching + storing)
- State lifecycle unclear (when is it cleared?)

---

## Real-World Examples from Maestro

### Example 1: Calendar Integration

**State Distribution:**

```swift
// 1. Feature State - CalendarIntegrationCoordinator
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus  // ← STATE

    private let calendarService: CalendarServiceProtocol   // ← Stateless

    func connect() async throws {
        status = .connecting  // ← Manages state
        let granted = try await calendarService.requestAccess()
        status = granted ? .connected : .authorizationDenied
    }
}

// 2. Stateless Operations - CalendarService
final class CalendarService: CalendarServiceProtocol {
    private let eventStore = EKEventStore()  // ← Internal, operational

    // No @Published properties ✅
    // Doesn't store events ✅
    // Just executes operations ✅

    func fetchEvents(from: Date, to: Date) async throws -> [EKEvent] {
        return try await eventStore.events(...)  // Returns, doesn't store
    }
}

// 3. UI State - CalendarEventsViewModel (hypothetical)
@MainActor
final class CalendarEventsViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []  // ← UI State
    @Published var isLoading = false

    private let calendarService: CalendarServiceProtocol
    private let coordinator: CalendarIntegrationCoordinator

    func loadEvents() async {
        guard coordinator.isAuthorized() else { return }

        isLoading = true

        // Service does work, ViewModel holds result
        events = try await calendarService.fetchEvents(...)
            .map { CalendarEvent(from: $0) }

        isLoading = false
    }
}
```

---

### Example 2: Automations

**State Distribution:**

```swift
// 1. Persistent State - AutomationRepository
final class AutomationRepository {
    // No state - just storage gateway ✅
    func save(_ automation: Automation) async throws { /* ... */ }
    func fetchAll() async throws -> [Automation] { /* ... */ }
}

// 2. Business Operations - AutomationStorageService
final class AutomationStorageService {
    private let repository: AutomationRepository

    // No state - just operations ✅
    func save(_ automation: Automation) async throws {
        try await repository.save(automation)
    }
}

// 3. UI State - AutomationsListViewModel
@MainActor
final class AutomationsListViewModel: ObservableObject {
    @Published var automations: [Automation] = []  // ← STATE lives here
    @Published var searchQuery: String = ""

    var filteredAutomations: [Automation] {
        // Derived state
        automations.filter { $0.name.contains(searchQuery) }
    }

    private let storageService: AutomationStorageService

    func loadAutomations() async {
        automations = try await storageService.fetchAll()
    }
}

// 4. Ephemeral UI State - AutomationsListView
struct AutomationsListView: View {
    @StateObject var viewModel: AutomationsListViewModel

    @State private var selectedAutomation: Automation?  // ← Ephemeral state

    var body: some View {
        List(viewModel.filteredAutomations) { automation in
            Button(automation.name) {
                selectedAutomation = automation  // ← View-only state
            }
        }
        .searchable(text: $viewModel.searchQuery)  // ← ViewModel state
    }
}
```

---

### Example 3: Command Bar

**State Distribution:**

```swift
// 1. Session State - AgentSession (in Agent module)
final class AgentSession {
    let id: UUID
    private(set) var messages: [Message] = []  // ← Session state

    func addMessage(_ message: Message) {
        messages.append(message)
    }
}

// 2. Session Management - AgentSessionManager
@MainActor
final class AgentSessionManager: ObservableObject {
    @Published private(set) var sessions: [AgentSession] = []  // ← Manager state
    @Published private(set) var currentSession: AgentSession?

    func createSession() -> AgentSession {
        let session = AgentSession(id: UUID())
        sessions.append(session)
        currentSession = session
        return session
    }
}

// 3. Business Operations - AgentClient
final class AgentClient: AgentClientProtocol {
    // No @Published state ✅
    // Just executes queries ✅

    func query(_ text: String) async throws -> String {
        // Make HTTP request to Python agent
        return response
    }
}

// 4. UI State - CommandBarViewModel
@MainActor
final class CommandBarViewModel: ObservableObject {
    @Published var inputText: String = ""           // ← UI state
    @Published var isProcessing: Bool = false
    @Published var statusText: String = ""

    private let agentClient: AgentClientProtocol
    private let sessionManager: AgentSessionManager

    var currentMessages: [Message] {
        sessionManager.currentSession?.messages ?? []
    }

    func sendMessage() async {
        isProcessing = true
        statusText = "Thinking..."

        let response = try await agentClient.query(inputText)

        sessionManager.currentSession?.addMessage(
            Message(role: .assistant, content: response)
        )

        inputText = ""
        isProcessing = false
        statusText = ""
    }
}
```

---

## State Flow Patterns

### Pattern 1: Load Data from Service → Store in ViewModel

```swift
// ViewModel loads and holds state
@MainActor
final class TasksListViewModel: ObservableObject {
    @Published var tasks: [Task] = []  // ← State lives here

    private let taskService: TaskServiceProtocol  // ← Stateless

    func loadTasks() async {
        tasks = try await taskService.fetchTasks()
    }
}
```

### Pattern 2: Coordinator Holds Feature State → ViewModel Observes

```swift
// Coordinator holds integration state
@MainActor
final class SlackIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus

    func connect() async throws {
        status = .connecting
        // ...
    }
}

// ViewModel observes coordinator
@MainActor
final class IntegrationsViewModel: ObservableObject {
    @Published var slackStatus: IntegrationStatus = .disconnected

    private let slackCoordinator: SlackIntegrationCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(slackCoordinator: SlackIntegrationCoordinator) {
        self.slackCoordinator = slackCoordinator

        // Observe coordinator state
        slackCoordinator.$status
            .assign(to: &$slackStatus)
    }

    func connectSlack() async throws {
        try await slackCoordinator.connect()
    }
}
```

### Pattern 3: Multiple ViewModels Share Coordinator

```swift
// Single coordinator
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus
}

// Multiple ViewModels observe same coordinator
@MainActor
final class SettingsViewModel: ObservableObject {
    private let calendarCoordinator: CalendarIntegrationCoordinator

    var calendarStatus: IntegrationStatus {
        calendarCoordinator.status
    }
}

@MainActor
final class CommandBarViewModel: ObservableObject {
    private let calendarCoordinator: CalendarIntegrationCoordinator

    var canAccessCalendar: Bool {
        calendarCoordinator.status == .connected
    }
}
```

---

## Common Questions

### Q: Can a Service have ANY state?

**A:** Yes, but only **internal operational state**, not **application state**.

**OK:**

```swift
final class CacheService {
    private var cache: [String: Data] = [:]  // ✅ Internal cache

    func get(key: String) -> Data? {
        return cache[key]
    }
}
```

**Not OK:**

```swift
final class TaskService {
    @Published var tasks: [Task] = []  // ❌ Application state consumers depend on
}
```

---

### Q: Where does UserDefaults state go?

**A:** UserDefaults is persistent storage, accessed through Coordinators/ViewModels.

```swift
@MainActor
final class CalendarIntegrationCoordinator: ObservableObject {
    @Published private(set) var status: IntegrationStatus

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.status = loadStatus()
    }

    private func loadStatus() -> IntegrationStatus {
        let isEnabled = userDefaults.bool(forKey: "calendarEnabled")
        return isEnabled ? .connected : .disconnected
    }

    func connect() async throws {
        // ...
        userDefaults.set(true, forKey: "calendarEnabled")  // Persist
        status = .connected  // Update in-memory state
    }
}
```

---

### Q: What about caching?

**A:** Caching is **operational state**, can live in Services or dedicated Cache layer.

**Option 1: Service-level cache**

```swift
final class CalendarService {
    private var eventCache: [String: [EKEvent]] = [:]  // ✅ Internal cache

    func fetchEvents(from: Date, to: Date) async throws -> [EKEvent] {
        let key = "\(from)-\(to)"
        if let cached = eventCache[key] {
            return cached
        }

        let events = try await eventStore.events(...)
        eventCache[key] = events
        return events
    }
}
```

**Option 2: Separate cache service**

```swift
final class CacheService<T> {
    private var storage: [String: T] = [:]

    func get(key: String) -> T? { storage[key] }
    func set(key: String, value: T) { storage[key] = value }
}

final class CalendarService {
    private let cache: CacheService<[EKEvent]>

    func fetchEvents(...) async throws -> [EKEvent] {
        if let cached = cache.get(key: "events") {
            return cached
        }

        let events = try await eventStore.events(...)
        cache.set(key: "events", value: events)
        return events
    }
}
```

Both are fine - the key is that consumers don't directly observe the cache.

---

### Q: What if multiple features need the same data?

**A:** Options:

1. **Shared Coordinator** - Both features inject same coordinator
2. **Pass data** - One ViewModel loads, passes to another
3. **Shared State Manager** - Dedicated state manager for that domain

**Example: Shared Coordinator**

```swift
// One coordinator, two ViewModels observe it
@MainActor
final class AutomationsListViewModel: ObservableObject {
    private let registry: IntegrationRegistry

    var calendarConnected: Bool {
        registry.calendarCoordinator()?.status == .connected
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    private let registry: IntegrationRegistry

    var calendarConnected: Bool {
        registry.calendarCoordinator()?.status == .connected
    }
}
```

---

## Summary

### State Lives In:


| State Type                     | Where It Lives                                     | Example                                        |
| ------------------------------ | -------------------------------------------------- | ---------------------------------------------- |
| **UI State**                   | ViewModels (`@Published`)                          | Input text, loading state, validation errors   |
| **Feature State**              | Coordinators (`@Published`)                        | Integration status, workflow progress          |
| **Application State**          | Managers/Registries                                | Available integrations, global settings        |
| **Persistent State**           | Repositories → Loaded into ViewModels/Coordinators | User data, preferences                         |
| **Ephemeral View State**       | Views (`@State`)                                   | Animation states, temporary selections         |
| **Internal Operational State** | Services (private)                                 | Caches, connection pools, initialization flags |


### The Rules:

1. ✅ **ViewModels hold UI state** - What the user sees/interacts with
2. ✅ **Coordinators hold feature state** - Integration/workflow lifecycle
3. ✅ **Services are stateless** - No `@Published`, no consumer-facing state
4. ✅ **Repositories are gateways** - Don't cache data, just provide access
5. ✅ **Views hold ephemeral state** - Temporary UI concerns with `@State`

### The Flow:

```
View observes ViewModel
    ↓
ViewModel calls Service
    ↓
Service calls Repository
    ↓
Repository reads from disk/API
    ↓
Data flows back up the chain
    ↓
ViewModel stores in @Published property ← STATE LIVES HERE
    ↓
View updates
```

**Key Insight:** State lives at the **consumption layer** (ViewModels, Coordinators), not the **operation layer** (Services, Repositories).