import SwiftUI

struct ExampleView: View {
  @State private var viewModel: ExampleViewModel

  init(controller: ExamplesControlling, rowBuilder: ExampleRowBuilding, filter: ExampleFilter, fileRevealer: FileRevealing) {
    _viewModel = State(
      initialValue: ExampleViewModel(controller: controller, rowBuilder: rowBuilder, filter: filter, fileRevealer: fileRevealer)
    )
  }

  var body: some View {
    content
      .navigationTitle(viewModel.state.view.title)
      .task { viewModel.onAppear() }
      .refreshable { viewModel.refresh() }
      .searchable(text: Binding(
        get: { viewModel.state.view.query },
        set: { viewModel.setQuery($0) }
      ))
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
        Text(error.title).font(.headline)
        Text(error.message).font(.subheadline)
        Button("Retry") { viewModel.refresh() }
      }
      .padding()
    } else if let empty = viewModel.state.content.emptyMessage {
      Text(empty).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List(selection: Binding(
        get: { viewModel.state.content.selectedID },
        set: { newValue in if let id = newValue { viewModel.didSelectRow(id: id) } }
      )) {
        ForEach(viewModel.state.content.filteredRows) { row in
          VStack(alignment: .leading) {
            Text(row.title)
            if let subtitle = row.subtitle {
              Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
          }
          .tag(row.id)
        }
      }
    }
  }
}