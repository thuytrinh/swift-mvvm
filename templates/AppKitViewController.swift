import AppKit
import Combine

final class ExampleViewController: NSViewController {
  // MARK: - UI
  @IBOutlet private weak var tableView: NSTableView!
  @IBOutlet private weak var progressIndicator: NSProgressIndicator!
  @IBOutlet private weak var errorLabel: NSTextField!

  // MARK: - Dependencies
  private let viewModel: ExampleCombineViewModel

  // MARK: - State
  private var cancellables = Set<AnyCancellable>()
  private var rows: [ExampleRow] = []

  init(viewModel: ExampleCombineViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("Use init(viewModel:)")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.dataSource = self
    tableView.delegate = self

    bind()
    viewModel.onAppear()
  }

  private func bind() {
    viewModel.$state
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.render(state)
      }
      .store(in: &cancellables)
  }

  private func render(_ state: ExampleCombineViewModel.State) {
    progressIndicator.isHidden = !state.view.isLoading
    errorLabel.isHidden = state.alerts.error == nil
    errorLabel.stringValue = state.alerts.error?.message ?? ""

    rows = state.content.rows
    tableView.reloadData()
  }

  @IBAction private func revealSelectedFile(_ sender: Any) {
    viewModel.revealSelectedFile()
  }
}

// Extensions are encouraged for organization and protocol conformances.
extension ExampleViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let item = rows[row]
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Cell"), owner: self) as? NSTableCellView
    cell?.textField?.stringValue = item.title
    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let idx = tableView.selectedRow
    guard idx >= 0, idx < rows.count else { return }
    viewModel.didSelectRow(id: rows[idx].id)
  }
}