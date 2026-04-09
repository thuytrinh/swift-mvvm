# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A distributable **Swift MVVM skill** for AI coding agents (Claude Code, Codex). It consists of:

- `SKILL.md` — the skill definition loaded by agents at runtime
- `references/` — in-depth guide docs referenced on demand from `SKILL.md`
- `templates/` — copy-paste Swift templates referenced from `SKILL.md`

There is no build system, test runner, or compiled code in this repo. All files are Markdown or Swift source used as reference material.

## Architecture

The skill is structured as a single entry point (`SKILL.md`) with lazy references:

1. **`SKILL.md`** — authoritative skill loaded by agents. Defines MVVM rules, preferred patterns, and points to templates and references.
2. **`references/*.md`** — detailed guides on specific topics (patterns, testing, state, naming, etc.). Agents load these only when needed.
3. **`templates/*.swift`** — concrete Swift code templates. Not compiled; used as copy-paste starting points.

### Key MVVM rules enforced by this skill

- ViewModels must **not** import `SwiftUI`, `UIKit`, or `AppKit`
- Platform actions go through tiny **protocol adapters** defined in Foundation-only files
- State lives in a nested `State` struct (not 30 loose `@Published` vars)
- Extraction priority: **pure logic first → side-effect controllers → ViewModel as thin state+intents**
- New tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`)

## How to install the skill

Copy `SKILL.md` plus optional `references/` and `templates/` to:
- Claude Code (project): `.claude/skills/swift-mvvm/`
- Claude Code (user): `~/.claude/skills/swift-mvvm/`
- Codex (project): `.codex/skills/swift-mvvm/`
- Codex (user): `~/.codex/skills/swift-mvvm/`

## Editing guidelines

- Changes to **`SKILL.md`** are high-impact — it is the file agents actually load. Keep it concise and prescriptive.
- **`references/`** files are loaded lazily; they can be more detailed.
- **`templates/`** files must be valid Swift. Keep them minimal and illustrative.
- When adding a new reference or template, add a pointer to it in the relevant section of `SKILL.md`.
