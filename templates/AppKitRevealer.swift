import AppKit
import Foundation

// Platform adapter implementation lives in the AppKit layer.

struct WorkspaceFileRevealer: FileRevealing {
  func reveal(_ url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}