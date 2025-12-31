# Testing Considerations

When following this architecture, testing becomes straightforward:

## ViewModels
```swift
func testTaskCompletion() async {
    let mockService = MockTaskService()
    let viewModel = TaskViewModel(taskService: mockService)

    await viewModel.completeTask(id: testTaskID)

    XCTAssertTrue(mockService.completeCalled)
}
```

## Services
```swift
func testTaskValidation() {
    let validator = TaskValidator()

    let validTask = Task(title: "Valid", dueDate: Date())
    XCTAssertTrue(validator.validate(validTask))

    let invalidTask = Task(title: "", dueDate: nil)
    XCTAssertFalse(validator.validate(invalidTask))
}
```

## Repositories
```swift
func testTaskPersistence() async throws {
    let repository = InMemoryTaskRepository()
    let task = Task(title: "Test")

    try await repository.save(task)
    let fetched = try await repository.fetch(id: task.id)

    XCTAssertEqual(task, fetched)
}
```

---

## Summary

**Key Takeaways:**
1. **Feature-based organization** - Group by feature, not by type
2. **Clear separation** - Views, ViewModels, Services, Models have distinct roles
3. **Protocols for abstraction** - Use when you need flexibility or testability
4. **Dependency injection** - Pass dependencies, don't create them
5. **Single responsibility** - Each file/class does one thing well

**When in doubt:**
1. Does it display UI? → View
2. Does it manage state for a view? → ViewModel
3. Does it contain business logic? → Service
4. Does it access data storage? → Repository
5. Does it transform data for display? → Formatter
6. Is it a data structure? → Model

Follow these guidelines and your code will be maintainable, testable, and scalable. Happy coding! 🚀
