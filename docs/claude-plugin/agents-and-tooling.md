---
title: Agents & tooling
parent: Claude Code plugin
nav_order: 2
---

# Agents & tooling

Beyond the [slash commands](commands.md), the plugin ships optional sub-agents,
a shared skill, a non-destructive edit hook, and an optional local MCP bridge.
None of them replace verification — real `ml1`/`make` runs remain authoritative.

## Sub-agents

Deep workflows can delegate to a focused agent. Each loads the
**authority-preflight** skill before acting and reads the language bundle first.

| Agent | Role | Notes |
|---|---|---|
| `minlang-creator` | Generate or revise MinLang source using the Creator repair loop and bundle authority | Edits `.ml`/`.mlui` only — never `app/generated/` or `.env`; runs GENERATE → VALIDATE → FIX → REVALIDATE until zero violations |
| `minlang-gatekeeper` | Validate MinLang against bundle authority and return strict, sanitized JSON verdicts only | Reject-first; `Write`/`Edit` disabled so it cannot mutate source |
| `minlang-migration-architect` | Plan slice-by-slice migration from a legacy app to MinLang with a durable ledger | Inventories domains/screens/tests before proposing MinLang; prefers partial adoption over a big-bang rewrite |

Agents **supplement** commands; they do not bypass the verification step.

## Skill: authority-preflight

Every producing command and agent loads this skill first. It:

1. Detects project shape — `minlang.json` (compiler + bundle pin), the primary
   `.ml` application file, `AGENTS.md`/`CLAUDE.md`, and `Makefile` targets
   (`compile`, `test`, `validate`, `dev`).
2. Checks whether `ml1` is on `PATH`. The plugin does **not** bundle the
   compiler; when it is missing the skill points to the public install scripts
   rather than claiming otherwise.
3. Loads the language bundle from the stable URL or the project's pin, so all
   downstream generation and validation work against the canonical authority:

   ```text
   https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
   ```

## Post-edit hook

A `PostToolUse` hook matches `Write|Edit` and runs `hooks/post-edit-ml.sh`. When
a `.ml` file is touched it emits a **non-destructive** reminder to validate the
source — it never edits or reverts your file. It is the safety net that keeps
"edit the `.ml`, then validate" the default loop.

## Optional MCP bridge

When enabled, the plugin starts a local MCP server (`mcp/ml1-bridge.py`) that
exposes a small, **allowlisted, read-only** set of `ml1` tools to Claude Code:

- `features` — print the current language feature catalog.
- `validate` — validate a `.ml` file.
- `graph` — emit the project graph / compile closure.
- `update --check` — report available compiler/bundle/dependency updates.

The bridge is a convenience for tighter loops; the shell verification commands
inside each slash command remain authoritative. The MCP server is configured in
the plugin's `.mcp.json` and launched with `python3`.

## Monitors

The plugin manifest reserves an experimental `monitors` slot
(`monitors/monitors.json`). It currently ships empty — a placeholder for future
background watchers.

## See also

- [Commands](commands.md) — the 23 slash commands.
- [Plugin overview](index.md) — install and authority discipline.
- [CLI reference](../cli.md) — the `ml1` commands behind these tools.
