import Foundation

// Tiny protocol adapters keep ViewModels UI-framework agnostic.

protocol FileRevealing {
  func reveal(_ url: URL)
}

protocol NowProviding {
  func now() -> Date
}

struct SystemNowProvider: NowProviding {
  func now() -> Date { Date() }
}