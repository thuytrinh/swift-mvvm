# Integration Patterns

## Adding a New Integration (e.g., Slack)

**Step 1: Create integration module**

```
Integrations/
└── Slack/
    ├── SlackIntegrationCoordinator.swift
    ├── SlackService.swift
    └── SlackAuthorizationObserver.swift  (if needed)
```

**Step 2: Conform to protocol**

```swift
// Integrations/Slack/SlackIntegrationCoordinator.swift
@MainActor
final class SlackIntegrationCoordinator: ObservableObject, IntegrationCoordinatorProtocol {
    let integrationName = "Slack"
    @Published private(set) var status: IntegrationStatus = .disconnected

    func setup() async { /* ... */ }
    func connect() async throws { /* ... */ }
    func disconnect() async throws { /* ... */ }
    func isAuthorized() -> Bool { /* ... */ }
}
```

**Step 3: Register in IntegrationRegistry**

```swift
// In app setup
let slackCoordinator = SlackIntegrationCoordinator(...)
integrationRegistry.register(slackCoordinator, for: .slack)
```

**Step 4: Add AgentBridge handler (if needed by Python agent)**

For OAuth integrations (Python needs token):

```swift
// AgentBridge/Handlers/SlackTokenProvider.swift
final class SlackTokenProvider: TokenProviderProtocol {
    let toolName = "slack"
    private let coordinator: SlackIntegrationCoordinator

    func getAccessToken() async throws -> String { /* ... */ }
}
```

For native integrations (Swift executes actions):

```swift
// AgentBridge/Handlers/SlackActionHandler.swift
final class SlackActionHandler: ActionHandlerProtocol {
    let toolName = "slack"

    func handleAction(action: String, parameters: [String: Any]) async throws -> [String: Any] {
        // Execute Slack actions
    }
}
```

