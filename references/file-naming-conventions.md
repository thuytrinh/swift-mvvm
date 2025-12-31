# File Naming Conventions

## Views
```swift
// SwiftUI Views
FeatureNameView.swift           // Main view
FeatureNameRowView.swift        // List row
FeatureNameDetailView.swift     // Detail view
FeatureNameEditorView.swift     // Editor/form
FeatureNameSheet.swift          // Modal sheet
FeatureNamePicker.swift         // Picker/selector
```

**Examples:**
- `CommandBarView.swift`
- `AutomationRowView.swift`
- `NotionConfigurationView.swift`

## ViewModels
```swift
// ViewModels
FeatureNameViewModel.swift              // Main ViewModel
FeatureNameViewModel+Extensions.swift   // ViewModel extensions
FeatureNameListViewModel.swift          // For list views
FeatureNameEditorViewModel.swift        // For editor views
```

**Examples:**
- `CommandBarViewModel.swift`
- `AutomationsListViewModel.swift`
- `AutomationEditorViewModel.swift`

## Models
```swift
// Data models
FeatureName.swift              // Core model
FeatureNameState.swift         // State enum/struct
FeatureNameError.swift         // Error types
FeatureNameSnapshot.swift      // Immutable snapshots
```

**Examples:**
- `Automation.swift`
- `AutomationTrigger.swift`
- `IntegrationStatus.swift`

## Services
```swift
// Services
FeatureNameService.swift           // General service
FeatureNameStorageService.swift    // Persistence operations
FeatureNameValidationService.swift // Validation logic
FeatureNameCoordinator.swift       // Workflow coordination
FeatureNameManager.swift           // Resource management
```

**Examples:**
- `CalendarService.swift`
- `AutomationStorageService.swift`
- `OAuthIntegrationManager.swift`

## Protocols
```swift
// Protocols
FeatureNameProtocol.swift          // General protocol
FeatureNameServicing.swift         // Service protocol (alternative suffix)
FeatureNameDelegate.swift          // Delegate pattern
```

**Examples:**
- `IntegrationCoordinatorProtocol.swift`
- `ActionHandlerProtocol.swift`
- `AgentClientProtocol.swift`
