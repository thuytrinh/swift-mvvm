# Common Patterns

## Pattern 1: CRUD Feature
When building a feature with Create, Read, Update, Delete operations:

```
FeatureName/
├── Views/
│   ├── FeatureNameListView.swift       # List all items
│   ├── FeatureNameRowView.swift        # Single item in list
│   ├── FeatureNameDetailView.swift     # View item details
│   └── FeatureNameEditorView.swift     # Create/edit item
├── ViewModels/
│   ├── FeatureNameListViewModel.swift
│   ├── FeatureNameDetailViewModel.swift
│   └── FeatureNameEditorViewModel.swift
├── Models/
│   ├── FeatureName.swift               # Core model
│   └── FeatureNameError.swift
├── Services/
│   ├── FeatureNameStorageService.swift
│   └── FeatureNameValidator.swift
└── Persistence/
    └── FeatureNameRepository.swift
```

**Example:** See `Automations/` module

## Pattern 2: External Integration
When integrating with external service (Calendar, Notion, Slack):

```
Integrations/
└── ServiceName/
    ├── ServiceNameIntegrationCoordinator.swift  # Manages connection state
    ├── ServiceNameService.swift                  # Actual API/SDK calls
    └── ServiceNameAuthorizationObserver.swift    # Monitor auth changes (if needed)
```

Register in `IntegrationRegistry.swift`.

**Example:** See `Integrations/Calendar/` and `Integrations/Notion/`

## Pattern 3: OAuth Integration
For integrations requiring OAuth:

1. Configuration in `Services/OAuth/OAuthProviderConfiguration.swift`
2. Token storage handled by `Services/OAuth/OAuthTokenStore.swift`
3. Integration coordinator in `Integrations/ServiceName/`
4. Token provider in `AgentBridge/Handlers/` if Python agent needs access

**Example:** Notion integration

## Pattern 4: Agent Bridge Handler
When Python agent needs to execute actions in Swift:

```
AgentBridge/
├── Handlers/
│   ├── ServiceNameActionHandler.swift    # For native integrations (Calendar, Reminders)
│   └── ServiceNameTokenProvider.swift    # For OAuth integrations (Notion)
└── Models/
    └── ServiceNameAction.swift           # Action types
```

**Action Handler** = Python → Swift, Swift executes and returns result
**Token Provider** = Python → Swift, Swift returns OAuth token, Python executes
