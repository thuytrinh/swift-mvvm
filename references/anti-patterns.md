# Anti-Patterns to Avoid

## ❌ Don't: Business Logic in Views
```swift
// Bad
struct TaskView: View {
    @State var task: Task

    var body: some View {
        Button("Complete") {
            task.isCompleted = true
            try? await database.save(task)  // ❌ Business logic in view
        }
    }
}
```

## ❌ Don't: ViewModels Importing SwiftUI
```swift
// Bad
import SwiftUI  // ❌ ViewModel shouldn't import SwiftUI

class TaskViewModel: ObservableObject {
    // ...
}
```

## ❌ Don't: Massive ViewModels
```swift
// Bad - 300+ lines in single file
class TaskViewModel: ObservableObject {
    // Tons of properties and methods
}

// Good - Split into extensions
class TaskViewModel: ObservableObject {
    // Core properties
}

extension TaskViewModel {
    // Validation logic
}

extension TaskViewModel {
    // Action handlers
}
```

## ❌ Don't: Services with State for Multiple Consumers
```swift
// Bad - Service with consumer-specific state
class TaskService {
    var currentTask: Task?  // ❌ State that multiple consumers might conflict over

    func loadTask() { /* ... */ }
}

// Good - Stateless service
class TaskService {
    func fetchTask(id: UUID) async throws -> Task { /* ... */ }
}
```

## ❌ Don't: Circular Dependencies
```swift
// Bad
class ServiceA {
    let serviceB: ServiceB  // ❌
}

class ServiceB {
    let serviceA: ServiceA  // ❌ Circular dependency
}

// Good - Use protocols or rethink design
protocol ServiceBDelegate {
    func didComplete()
}

class ServiceB {
    weak var delegate: ServiceBDelegate?
}

class ServiceA: ServiceBDelegate {
    let serviceB: ServiceB
}
```
