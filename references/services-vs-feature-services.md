# Deciding Between `/Services` vs `/Feature/Services`

## The Golden Rule

**Ask yourself: "How many features will use this service?"**

- **One feature only** → `/Feature/Services`
- **Multiple features** → `/Services`

---

## Decision Framework

### Use `/Feature/Services` when:

1. ✅ **Feature-Specific Logic**
  - The service only makes sense within the context of this feature
  - Business logic is tightly coupled to feature models
  - No other feature would ever need this service
2. ✅ **Feature Encapsulation**
  - Keeps the feature self-contained
  - Can be understood without looking elsewhere
  - Could be extracted as a separate module/package
3. ✅ **Rapid Iteration**
  - Feature is experimental or changing rapidly
  - Don't want to affect other features

**Examples:**

```
Automations/
└── Services/
    ├── AutomationStorageService.swift       # Only Automations needs this
    ├── AutomationValidator.swift            # Validates Automation models
    ├── AutomationScheduler.swift            # Schedules Automation runs
    └── AutomationVariableResolver.swift     # Resolves Automation variables
```

None of these services make sense outside the Automations feature.

---

### Use `/Services` when:

1. ✅ **Cross-Feature Usage**
  - Multiple features need this service
  - Shared infrastructure or platform concerns
  - Foundation that features build upon
2. ✅ **Platform/Infrastructure**
  - Not specific to any business feature
  - Provides core capabilities (OAuth, Keychain, Networking)
  - Would exist even if all current features were removed
3. ✅ **External System Integration**
  - Wraps external SDKs or APIs
  - Multiple features need access to same external system

**Examples:**

```
Services/
├── OAuth/                      # Multiple integrations use OAuth
├── Keychain/                   # Multiple features store secrets
├── Voice/                      # Voice input used by CommandBar and maybe others
└── Runner/                     # Agent execution used across features
```

These are foundational services used by multiple parts of the app.

---

## Detailed Examples

### Example 1: Calendar Service

**Question:** Where does `CalendarService` go?

**Analysis:**

- Does it interact with external system (EventKit)? ✅ Yes
- Will multiple features need calendar access? ✅ Potentially yes
- Is it feature-specific? ❌ No - it's a platform capability

**Decision:** Could go either way, but let's consider:

**Option A: `/Services/EventKit/CalendarService.swift`**

- ✅ If multiple features might need calendar access
- ✅ Generic calendar operations
- ✅ Reusable across features

**Option B: `/Integrations/Calendar/CalendarService.swift`**

- ✅ Calendar is treated as an "integration" (external system)
- ✅ Bundled with CalendarIntegrationCoordinator
- ✅ Self-contained module

**Decision:**
Option B (`/Integrations/Calendar/`) is preferred because:

1. Calendar is an integration with connection state
2. Everything related to Calendar is in one place
3. The coordinator and service work together closely
4. Integrations is semantically clearer than Services/EventKit

---

### Example 2: Validation Service

**Question:** Where does validation logic go?

**Scenario 1: Automation Validation**

```swift
// Automations/Services/AutomationValidator.swift
final class AutomationValidator {
    func validate(_ automation: Automation) -> ValidationResult {
        // Validates Automation-specific rules
        // - Prompt has valid variable syntax
        // - Required fields present
        // - Schedule configuration valid
    }
}
```

**Decision:** `/Automations/Services/` ✅

- Only validates Automation models
- Business rules specific to Automations feature

**Scenario 2: General Input Validation**

```swift
// Services/Validation/InputValidator.swift
final class InputValidator {
    func validateEmail(_ email: String) -> Bool { /* ... */ }
    func validateURL(_ url: String) -> Bool { /* ... */ }
    func validatePhoneNumber(_ phone: String) -> Bool { /* ... */ }
}
```

**Decision:** `/Services/Validation/` ✅

- Generic validation used by multiple features
- Not tied to any specific feature model

---

### Example 3: Storage Service

**Question:** Where does storage logic go?

**Scenario 1: Automation Storage**

```swift
// Automations/Services/AutomationStorageService.swift
protocol AutomationStorageServiceProtocol {
    func save(_ automation: Automation) async throws
    func fetchAll() async throws -> [Automation]
}
```

**Decision:** `/Automations/Services/` ✅

- Only stores Automation models
- Part of Automations feature CRUD

**Scenario 2: Generic Key-Value Storage**

```swift
// Services/Storage/UserDefaultsService.swift
final class UserDefaultsService {
    func set<T: Codable>(_ value: T, forKey key: String) { /* ... */ }
    func get<T: Codable>(forKey key: String) -> T? { /* ... */ }
}
```

**Decision:** `/Services/Storage/` ✅

- Generic storage mechanism
- Used by multiple features
- Infrastructure concern

---

### Example 4: Formatters

**Question:** Where do formatters go?

**Scenario 1: Feature-Specific Formatter**

```swift
// CommandBar/Formatters/CommandBarStatusTextFormatter.swift
final class CommandBarStatusTextFormatter {
    func format(_ status: AgentStatus) -> String {
        // Formats status text specific to CommandBar UI
        switch status {
        case .thinking: return "✨ Analyzing your request..."
        case .executing: return "⚙️ Executing..."
        }
    }
}
```

**Decision:** `/CommandBar/Formatters/` ✅

- Only used by CommandBar
- Status messages specific to CommandBar UX

**Scenario 2: Shared Formatter**

```swift
// Shared/Formatters/RelativeDateFormatter.swift
final class RelativeDateFormatter {
    func format(_ date: Date) -> String {
        // "2 minutes ago", "Just now", etc.
        // Used by CommandBar, Automations history, etc.
    }
}
```

**Decision:** `/Shared/Formatters/` ✅

- Used by multiple features
- Generic date formatting

---

## Common Patterns

### Pattern 1: Start Feature-Specific, Extract Later

**Start Here:**

```
Automations/
└── Services/
    └── AutomationNotificationService.swift  # Send notifications for automation runs
```

**Later, when Tasks feature also needs notifications:**

```
Services/
└── Notifications/
    └── NotificationService.swift  # Generic notification service

Automations/
└── Services/
    └── AutomationNotificationCoordinator.swift  # Uses generic NotificationService
```

**Lesson:** It's easier to extract than to predict. Start feature-specific, refactor when second use case emerges.

---

### Pattern 2: Adapters in Feature Services

When a feature needs to customize how it uses a shared service:

```
Services/
└── OAuth/
    └── OAuthClient.swift  # Generic OAuth flow

Integrations/
└── Notion/
    └── NotionOAuthAdapter.swift  # Customizes OAuth for Notion specifics
```

The **adapter** lives in the feature, the **core logic** lives in `/Services`.

---

### Pattern 3: Feature Service Using Multiple Shared Services

```
Services/
├── Keychain/
│   └── KeychainService.swift
└── OAuth/
    └── OAuthClient.swift

Integrations/
└── Slack/
    └── SlackIntegrationCoordinator.swift  # Uses both Keychain and OAuth
```

The **coordinator** is feature-specific (lives in feature), but it **composes** shared services.

---

## Edge Cases

### Edge Case 1: Should Voice Service be in CommandBar or Services?

**Current Structure:**

```
Services/
└── Voice/
    ├── VoiceInputService.swift
    └── VoiceInputController.swift
```

**Why `/Services` and not `/CommandBar/Services`?**

1. ✅ Voice input could be used elsewhere (Siri shortcuts, voice commands outside CommandBar)
2. ✅ Wraps platform API (Speech Recognition)
3. ✅ Not tightly coupled to CommandBar UI

**When to reconsider:** If voice is ONLY ever used by CommandBar and tightly coupled to its UI, consider moving to `/CommandBar/Services/VoiceInputService.swift`.

---

### Edge Case 2: Runner Service - Feature or Infrastructure?

**Current Structure:**

```
Services/
└── Runner/
    ├── Execution/
    └── Parsing/
```

**Why `/Services`?**

1. ✅ Runs the Python agent - core infrastructure
2. ✅ Used by CommandBar, potentially by Automations
3. ✅ Platform-level concern (process execution, IPC)

**Alternative:** Could be `/Agent/Services/` if it's strictly agent-related, but `/Services/Runner/` signals it's a broader infrastructure service.

---

### Edge Case 3: AgentBridge Handlers - Services or AgentBridge?

**Current Structure:**

```
AgentBridge/
└── Handlers/
    ├── CalendarActionHandler.swift
    └── NotionTokenProvider.swift
```

**Why `/AgentBridge/Handlers` and not `/Services`?**

1. ✅ Handlers are specific to AgentBridge request/response protocol
2. ✅ They translate between Python agent and Swift services
3. ✅ They're adapters, not core services
4. ✅ Bundling them with AgentBridge makes the bridge module self-contained

**When they use services:**

```swift
final class CalendarActionHandler: ActionHandlerProtocol {
    private let calendarService: CalendarServiceProtocol  // ← Uses shared service

    func handleAction(...) async throws {
        // Translates agent request → service call
    }
}
```

The handler lives in `/AgentBridge`, but it **depends on** `/Integrations/Calendar/CalendarService.swift`.

---

## Quick Decision Tree

```
Is this service used by multiple features?
├─ Yes → Consider /Services
│  └─ Is it infrastructure/platform?
│     ├─ Yes → /Services (OAuth, Keychain, etc.)
│     └─ No → Is it an external integration?
│        ├─ Yes → /Integrations (Calendar, Notion)
│        └─ No → /Shared or /Services
│
└─ No (used by only one feature)
   └─ Is it generic and reusable?
      ├─ Yes → /Services (might be used later)
      │  └─ Refactor to feature when it becomes clear it won't be shared
      └─ No → /Feature/Services ✅
```

---

## Practical Guidelines

### 1. **When Starting a New Feature**

**Default to feature-specific** (`/Feature/Services`) unless you KNOW it will be shared.

**Why?**

- Keeps feature self-contained
- Faster to iterate
- Easier to understand
- Can always extract later

**Example:**

```
// First version - feature-specific
Automations/
└── Services/
    └── AutomationExecutionService.swift

// Later, if needed elsewhere
Services/
└── Execution/
    └── ExecutionService.swift  # Generic

Automations/
└── Services/
    └── AutomationExecutionCoordinator.swift  # Uses generic service
```

---

### 2. **The "Two Feature Rule"**

When a **second feature** needs the same service:

1. Evaluate if it's truly the same concern
2. Extract to `/Services` or `/Shared`
3. Refactor both features to use shared service

**Example:**

```
// Before (Tasks and Automations both have their own)
Tasks/Services/TaskNotificationService.swift
Automations/Services/AutomationNotificationService.swift

// After (extract common logic)
Services/Notifications/NotificationService.swift

Tasks/Services/TaskNotificationCoordinator.swift         # Uses NotificationService
Automations/Services/AutomationNotificationCoordinator.swift  # Uses NotificationService
```

---

### 3. **Integration = External System**

If the service wraps an external system (API, SDK, OS framework):

- **Multiple features use it** → `/Integrations/ServiceName/`
- **Infrastructure (OAuth, Keychain)** → `/Services/ServiceName/`

**Examples:**

- Calendar (EventKit) → `/Integrations/Calendar/`
- Notion (API) → `/Integrations/Notion/`
- OAuth (multiple integrations use) → `/Services/OAuth/`
- Keychain (platform) → `/Services/Keychain/`

---

### 4. **Adapters vs Core Services**

**Core Service** (in `/Services`):

- Generic implementation
- No feature-specific logic
- Reusable

**Adapter** (in `/Feature/Services`):

- Customizes core service for feature needs
- Translates between feature models and service interface

**Example:**

```swift
// Core service - /Services/Notifications/NotificationService.swift
final class NotificationService {
    func send(title: String, body: String) { /* ... */ }
}

// Adapter - /Automations/Services/AutomationNotificationAdapter.swift
final class AutomationNotificationAdapter {
    private let notificationService: NotificationService

    func notifyAutomationCompleted(_ automation: Automation) {
        notificationService.send(
            title: "Automation Completed",
            body: "\(automation.name) finished running"
        )
    }
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Everything in /Services

```
Services/
├── AutomationValidator.swift        # ❌ Only used by Automations
├── AutomationStorageService.swift   # ❌ Only used by Automations
├── CommandBarSuggestionBuilder.swift # ❌ Only used by CommandBar
└── TaskCompletionService.swift      # ❌ Only used by Tasks
```

**Problem:** `/Services` becomes a dumping ground. Hard to understand what's actually shared.

**Fix:** Move feature-specific services to their features.

---

### ❌ Anti-Pattern 2: Deep Nesting in /Services

```
Services/
└── Data/
    └── Storage/
        └── Automation/
            └── AutomationStorageService.swift  # ❌ Too deep
```

**Problem:** Over-organization makes it hard to find things.

**Fix:** Keep hierarchy shallow. If it's automation-specific, put it in `Automations/Services/`.

---

### ❌ Anti-Pattern 3: Shared Service with Feature-Specific Logic

```swift
// Services/NotificationService.swift
final class NotificationService {
    func sendNotification(type: NotificationType) {
        switch type {
        case .automationCompleted(let automation):  // ❌ Feature-specific
            // ...
        case .taskCompleted(let task):              // ❌ Feature-specific
            // ...
        }
    }
}
```

**Problem:** Shared service knows about specific features. Violates dependency inversion.

**Fix:** Use protocol or make service generic, let features provide adapters.

```swift
// Services/NotificationService.swift
final class NotificationService {
    func send(title: String, body: String, data: [String: Any]?) { /* ... */ }
}

// Automations/Services/AutomationNotificationAdapter.swift
final class AutomationNotificationAdapter {
    func notifyCompleted(_ automation: Automation) {
        notificationService.send(
            title: "Completed",
            body: automation.name,
            data: ["automation_id": automation.id.uuidString]
        )
    }
}
```

---

## Summary Table


| Scenario                                                     | Location                     | Reasoning                      |
| ------------------------------------------------------------ | ---------------------------- | ------------------------------ |
| Service used by **one feature only**                         | `/Feature/Services/`         | Feature encapsulation          |
| Service used by **multiple features**                        | `/Services/`                 | Shared infrastructure          |
| Service wrapping **external integration** (Calendar, Notion) | `/Integrations/ServiceName/` | External system abstraction    |
| Service providing **platform capability** (OAuth, Keychain)  | `/Services/ServiceName/`     | Foundation/infrastructure      |
| **Adapter** customizing shared service                       | `/Feature/Services/`         | Feature-specific customization |
| **Generic utility** (date formatting, validation)            | `/Shared/`                   | Pure utility, no state         |
| **AgentBridge handler**                                      | `/AgentBridge/Handlers/`     | Part of bridge protocol        |


---

## Final Advice

**When in doubt:**

1. **Start feature-specific** (`/Feature/Services/`)
2. **Extract when second use case emerges** (move to `/Services/`)
3. **Keep the dependency direction right:**
  - `/Services` should NOT depend on `/Feature`
  - `/Feature` CAN depend on `/Services`
4. **Ask: "Could this exist in a separate framework?"**
  - Yes → `/Services` (it's infrastructure)
  - No → `/Feature/Services` (it's feature-specific)

Remember: It's easier to extract a shared service later than to prematurely generalize. **Optimize for clarity and locality first**, **extract for reuse second**.