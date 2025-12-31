import Foundation

// MARK: - Domain models

struct ExampleModel: Equatable {
  let id: UUID
  let name: String
  let detail: String?
  let fileURL: URL?
}

// MARK: - Repository (IO)

protocol ExampleRepository {
  func fetchModels() async throws -> [ExampleModel]
}

// MARK: - Use case (business rule)

protocol LoadExamplesUseCase {
  func load() async throws -> [ExampleModel]
}

struct LoadExamplesUseCaseLive: LoadExamplesUseCase {
  let repository: ExampleRepository

  func load() async throws -> [ExampleModel] {
    try await repository.fetchModels()
  }
}

// MARK: - Side-effects controller (orchestrates multiple effects)

protocol ExamplesControlling {
  func loadExamples() async throws -> [ExampleModel]
  func trackOpenedExamplesScreen()
}

protocol AnalyticsTracking {
  func track(_ event: String)
}

struct ExamplesController: ExamplesControlling {
  let loadUseCase: LoadExamplesUseCase
  let analytics: AnalyticsTracking

  func loadExamples() async throws -> [ExampleModel] {
    try await loadUseCase.load()
  }

  func trackOpenedExamplesScreen() {
    analytics.track("examples_screen_opened")
  }
}

// MARK: - Pure logic (easy to test)

struct ExampleRow: Equatable, Identifiable {
  let id: UUID
  let title: String
  let subtitle: String?
  let fileURL: URL?
}

protocol ExampleRowBuilding {
  func makeRows(from models: [ExampleModel]) -> [ExampleRow]
}

struct ExampleRowBuilder: ExampleRowBuilding {
  func makeRows(from models: [ExampleModel]) -> [ExampleRow] {
    models.map { model in
      ExampleRow(id: model.id, title: model.name, subtitle: model.detail, fileURL: model.fileURL)
    }
  }
}

struct ExampleFilter {
  func filter(rows: [ExampleRow], query: String) -> [ExampleRow] {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return rows }
    return rows.filter { $0.title.lowercased().contains(q) || ($0.subtitle?.lowercased().contains(q) ?? false) }
  }
}