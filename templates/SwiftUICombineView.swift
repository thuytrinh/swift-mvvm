import SwiftUI

struct ExampleCombineView: View {
  @StateObject private var viewModel: ExampleCombineViewModel

  init(controller: ExamplesControlling, rowBuilder: ExampleRowBuilding, fileRevealer: FileRevealing) {
    _viewModel = StateObject(
      wrappedValue: ExampleCombineViewModel(controller: controller, rowBuilder: rowBuilder, fileRevealer: fileRevealer)
    )
  }

  var body: some View {
    content
      .navigationTitle(viewModel.state.view.title)
      .task { viewModel.onAppear() }
      .refreshable { viewModel.refresh() }
      .toolbar {
        Button("Reveal") { viewModel.revealSelectedFile() }
          .disabled(viewModel.state.content.selectedID == nil)
      }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.state.view.isLoading {
      ProgressView()
    } else if let error = viewModel.state.alerts.error {
      VStack(spacing: 12) {
        Text(error.title)
        Text(error.message)
        Button("Retry") { viewModel.refresh() }
      }
      .padding()
    } else if let empty = viewModel.state.content.emptyMessage {
      Text(empty).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List(viewModel.state.content.rows) { row in
        Button {
          viewModel.didSelectRow(id: row.id)
        } label: {
          VStack(alignment: .leading) {
            Text(row.title)
            if let subtitle = row.subtitle {
              Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }
}