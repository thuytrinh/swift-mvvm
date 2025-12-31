import Foundation
import Testing

@MainActor
@Suite
struct ExampleViewModelTests {
  @Test
  func load_success_updatesRows() async {
    let controller = ExamplesControllerMock(result: .success([
      ExampleModel(id: UUID(), name: "A", detail: nil, fileURL: nil),
      ExampleModel(id: UUID(), name: "B", detail: "Detail", fileURL: URL(fileURLWithPath: "/tmp/b")),
    ]))

    let vm = ExampleViewModel(
      controller: controller,
      rowBuilder: ExampleRowBuilder(),
      filter: ExampleFilter(),
      fileRevealer: FileRevealerSpy()
    )

    let task = vm.load()
    await task.value

    #expect(vm.state.view.isLoading == false)
    #expect(vm.state.alerts.error == nil)
    #expect(vm.state.content.rows.count == 2)
    #expect(vm.state.content.filteredRows.count == 2)
    #expect(vm.state.content.rows[0].title == "A")
  }

  @Test
  func load_failure_setsError() async {
    let controller = ExamplesControllerMock(result: .failure(TestError.any))

    let vm = ExampleViewModel(
      controller: controller,
      rowBuilder: ExampleRowBuilder(),
      filter: ExampleFilter(),
      fileRevealer: FileRevealerSpy()
    )

    let task = vm.load()
    await task.value

    #expect(vm.state.view.isLoading == false)
    #expect(vm.state.alerts.error != nil)
  }

  @Test
  func revealSelectedFile_forwardsToAdapter() async {
    let url = URL(fileURLWithPath: "/tmp/x")
    let model = ExampleModel(id: UUID(), name: "X", detail: nil, fileURL: url)

    let controller = ExamplesControllerMock(result: .success([model]))
    let spy = FileRevealerSpy()

    let vm = ExampleViewModel(
      controller: controller,
      rowBuilder: ExampleRowBuilder(),
      filter: ExampleFilter(),
      fileRevealer: spy
    )

    let task = vm.load()
    await task.value

    vm.didSelectRow(id: model.id)
    vm.revealSelectedFile()

    #expect(spy.revealedURLs == [url])
  }
}

// MARK: - Test doubles

private enum TestError: Error { case any }

private struct ExamplesControllerMock: ExamplesControlling {
  let result: Result<[ExampleModel], Error>

  func loadExamples() async throws -> [ExampleModel] {
    switch result {
    case .success(let models): return models
    case .failure(let error): throw error
    }
  }

  func trackOpenedExamplesScreen() {
    // no-op
  }
}

private final class FileRevealerSpy: FileRevealing {
  private(set) var revealedURLs: [URL] = []
  func reveal(_ url: URL) { revealedURLs.append(url) }
}