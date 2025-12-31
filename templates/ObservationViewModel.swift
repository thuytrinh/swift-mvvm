import Foundation
import Observation

// MARK: - ViewModel (Observation)
// NOTE: No SwiftUI/UIKit/AppKit imports.

@MainActor
@Observable
final class ExampleViewModel {
  struct State: Equatable {
    var view = ViewState()
    var content = ContentState()
    var alerts = AlertsState()

    struct ViewState: Equatable {
      var isLoading: Bool = false
      var title: String = "Examples"
      var query: String = ""
    }

    struct ContentState: Equatable {
      var rows: [ExampleRow] = []
      var filteredRows: [ExampleRow] = []
      var selectedID: UUID? = nil
      var emptyMessage: String? = nil
    }

    struct AlertsState: Equatable {
      var error: ErrorState? = nil
    }
  }

  struct ErrorState: Equatable {
    let title: String
    let message: String
  }

  // Public observable state
  var state = State()

  // Dependencies (small units)
  private let controller: ExamplesControlling
  private let rowBuilder: ExampleRowBuilding
  private let filter: ExampleFilter
  private let fileRevealer: FileRevealing

  @ObservationIgnored private var loadTask: Task<Void, Never>?

  init(
    controller: ExamplesControlling,
    rowBuilder: ExampleRowBuilding,
    filter: ExampleFilter,
    fileRevealer: FileRevealing
  ) {
    self.controller = controller
    self.rowBuilder = rowBuilder
    self.filter = filter
    self.fileRevealer = fileRevealer
  }

  // MARK: - Intents

  func onAppear() {
    controller.trackOpenedExamplesScreen()
    _ = load()
  }

  func refresh() { _ = load() }

  func setQuery(_ query: String) {
    state.view.query = query
    state.content.filteredRows = filter.filter(rows: state.content.rows, query: query)
    state.content.emptyMessage = state.content.filteredRows.isEmpty ? "No results." : nil
  }

  func didSelectRow(id: UUID) {
    state.content.selectedID = id
  }

  func revealSelectedFile() {
    guard let selectedID = state.content.selectedID,
          let row = state.content.filteredRows.first(where: { $0.id == selectedID }),
          let url = row.fileURL else {
      return
    }
    fileRevealer.reveal(url)
  }

  // MARK: - Loading

  @discardableResult
  func load() -> Task<Void, Never> {
    loadTask?.cancel()

    let task = Task { [weak self] in
      guard let self else { return }
      await self.loadImpl()
    }

    loadTask = task
    return task
  }

  private func loadImpl() async {
    state.view.isLoading = true
    state.alerts.error = nil

    do {
      let models = try await controller.loadExamples()
      let rows = rowBuilder.makeRows(from: models)

      state.content.rows = rows
      state.content.filteredRows = filter.filter(rows: rows, query: state.view.query)
      state.content.emptyMessage = state.content.filteredRows.isEmpty ? "No results." : nil
      state.view.isLoading = false
    } catch {
      state.view.isLoading = false
      state.alerts.error = ErrorState(
        title: "Couldn’t Load",
        message: (error as NSError).localizedDescription
      )
    }
  }
}