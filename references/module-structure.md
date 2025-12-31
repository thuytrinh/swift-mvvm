# Module Structure

## Feature Module Template
```
FeatureName/
├── Views/              # SwiftUI views for this feature
├── ViewModels/         # State management for views
├── Models/             # Data structures specific to this feature
├── Services/           # Business logic services
├── Protocols/          # Interfaces/contracts (optional, can also go in Services/)
├── Formatters/         # Presentation logic (optional)
├── Utilities/          # Feature-specific helpers (optional)
└── Persistence/        # Data access layer (optional, for features with storage)
```

## When to Create a New Module
Create a new top-level module when:
- ✅ The feature is substantial (multiple views, complex logic)
- ✅ The feature is relatively independent
- ✅ You anticipate future growth/complexity
- ❌ Don't create for simple utilities or single-file features

**Examples:**
- `CommandBar/` - Major UI feature ✅
- `Automations/` - Complete feature with CRUD ✅
- `Integrations/` - Multiple related integrations ✅
- `DateFormatter.swift` - Goes in `Shared/Extensions/` ❌
