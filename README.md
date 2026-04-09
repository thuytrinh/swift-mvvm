# swift-mvvm skill

## Install

- Claude Code:
  - project: `.claude/skills/swift-mvvm/`
  - user: `~/.claude/skills/swift-mvvm/`

- Codex:
  - project: `.codex/skills/swift-mvvm/`
  - user: `~/.codex/skills/swift-mvvm/`

Copy `SKILL.md` plus optional `references/` and `templates/`.

## What it does

- Helps refactor view/controller logic into a small ViewModel.
- Keeps ViewModels UI-framework agnostic (no SwiftUI/UIKit/AppKit imports).
- Uses protocol adapters for platform actions (e.g., NSWorkspace reveal).
- Splits state into nested structs to reduce ViewModel sprawl.
- Extracts pure logic into structs/functions first.
- Extracts side-effects controllers/services next (still testable via protocols).
- Adds cancellation, DI, and **Swift Testing** examples.
