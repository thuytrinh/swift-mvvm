# Adding New Features

## Checklist for New Feature

1. **Determine feature scope**
   - Is it a major feature? → New top-level module
   - Is it an extension of existing feature? → Add to existing module
   - Is it a shared utility? → Add to `Shared/`

2. **Create module structure**
   ```bash
   mkdir -p FeatureName/{Views,ViewModels,Models,Services}
   ```

3. **Define models first**
   - What data structures do you need?
   - Create models in `FeatureName/Models/`

4. **Create protocols for services**
   - Define contracts before implementations
   - Helps with testing and dependency injection

5. **Implement services**
   - Business logic, data access, external integrations
   - Follow single responsibility principle

6. **Build ViewModels**
   - One ViewModel per view or closely related views
   - Inject service dependencies

7. **Create Views**
   - SwiftUI views that observe ViewModels
   - Pure presentation, no business logic

8. **Wire up dependencies**
   - Update dependency container/app initialization
   - Use dependency injection

## Example: Adding a "Tasks" Feature

**Step 1: Create structure**
```
Tasks/
├── Views/
├── ViewModels/
├── Models/
└── Services/
```

**Step 2: Define models**
```swift
// Tasks/Models/Task.swift
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
}
```

**Step 3: Create service protocol**
```swift
// Tasks/Services/TaskServiceProtocol.swift
protocol TaskServiceProtocol {
    func fetchTasks() async throws -> [Task]
    func createTask(_ task: Task) async throws
    func updateTask(_ task: Task) async throws
    func deleteTask(id: UUID) async throws
}
```

**Step 4: Implement service**
```swift
// Tasks/Services/TaskService.swift
final class TaskService: TaskServiceProtocol {
    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func fetchTasks() async throws -> [Task] {
        try await repository.fetchAll()
    }

    // ... other methods
}
```

**Step 5: Create ViewModel**
```swift
// Tasks/ViewModels/TasksListViewModel.swift
@MainActor
final class TasksListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false

    private let taskService: TaskServiceProtocol

    init(taskService: TaskServiceProtocol) {
        self.taskService = taskService
    }

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            tasks = try await taskService.fetchTasks()
        } catch {
            // Handle error
        }
    }
}
```

**Step 6: Create View**
```swift
// Tasks/Views/TasksListView.swift
struct TasksListView: View {
    @StateObject var viewModel: TasksListViewModel

    var body: some View {
        List(viewModel.tasks) { task in
            TaskRowView(task: task)
        }
        .task {
            await viewModel.loadTasks()
        }
    }
}
```
