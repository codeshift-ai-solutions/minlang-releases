---
title: Claude Code plugin
nav_order: 9
has_children: true
---

# Claude Code plugin

The **MinLang Claude Code plugin** turns Claude Code into a MinLang-aware
authoring, migration, refactoring, and release tool. It ships a namespaced set
of slash commands (`/minlang:*`), optional sub-agents, a non-destructive edit
hook, and an optional local `ml1` MCP bridge — all wired to load the canonical
language bundle **before** producing or validating any MinLang.

The plugin does **not** bundle the compiler. It drives the `ml1` CLI you install
separately (see [Getting started](../getting-started.md) and the
[CLI reference](../cli.md)) and treats real `ml1`/`make` runs as the
authoritative verification step.

- **23 slash commands** across five families — see [Commands](commands.md).
- **3 optional agents**, a shared skill, an edit hook, and an MCP bridge — see
  [Agents & tooling](agents-and-tooling.md).
- **Bundle authority discipline** on every producing command: read the bundle,
  generate, validate, fix, revalidate, confirm zero violations, then output.

## Install

From the public marketplace (mirrored to
[`minlang-releases`](https://github.com/codeshift-ai-solutions/minlang-releases)
on every release):

```text
/plugin marketplace add codeshift-ai-solutions/minlang-releases
/plugin install minlang@minlang-releases
```

From a local checkout of this repository:

```text
/plugin marketplace add ./packaging/claude-plugin
/plugin install minlang@minlang-releases
```

Or load the plugin directory for a single session:

```text
claude --plugin-dir ./packaging/claude-plugin/plugins/minlang
```

`ml1` can print these install commands for any agent without Claude Code:

```bash
ml1 language claude-plugin
```

## Command families at a glance

| Family | Commands | Page |
|---|---|---|
| Authoring | `author-app`, `add-feature`, `model-domain`, `design-ui`, `validate-authority` | [Commands → Authoring](commands.md#authoring) |
| Migration | `migrate-project`, `migrate-domain`, `migrate-screen`, `migrate-tests`, `migration-ledger` | [Commands → Migration](commands.md#migration) |
| Refactoring | `pull-domain-logic`, `dedupe-rules`, `thin-shell`, `generated-drift` | [Commands → Refactoring](commands.md#refactoring) |
| Diagnostics | `explain-failure`, `why-not-supported`, `inspect-graph`, `release-check` | [Commands → Diagnostics](commands.md#diagnostics) |
| Creative | `product-interview`, `legacy-strangler`, `boundary-police`, `demo-from-idea`, `bundle-upgrade-coach` | [Commands → Creative](commands.md#creative) |

## What every producing command guarantees

Each command that produces or validates MinLang follows the same contract:

1. Load the **authority-preflight** skill first.
2. Read the applicable language bundle (stable URL or the project's pin) before output.
3. Detect project shape (`minlang.json`, primary `.ml`, `Makefile` targets) and `ml1` availability.
4. Run validation before declaring success when MinLang is produced or changed.
5. Never hand-edit `app/generated/` and never write `.env`.
6. Never emit the zero-tolerance tokens `now()`, `today()`, `random()`, `current_user`.
7. Return a concise report: changes, verification run, blockers, next step.

## Components

| Directory | Purpose |
|---|---|
| `commands/` | The 23 slash command definitions and their `commands.json` inventory |
| `skills/authority-preflight/` | Shared bundle-load + project-detection + verification workflow |
| `agents/` | Optional creator, gatekeeper, and migration-architect sub-agents |
| `hooks/` | Non-destructive post-edit `.ml` validation reminder |
| `mcp/` | Optional local `ml1` MCP bridge (allowlisted read-only commands) |

## Authority

Every producing command loads the **authority-preflight** skill and reads the
stable language bundle before output:

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

The bundle is the single source of truth. If anything in the plugin (or on this
site) disagrees with the bundle, the bundle wins.

## Source and validation

The plugin lives in this repository under
[`packaging/claude-plugin/`](https://github.com/codeshift-ai-solutions/minlang-releases).
Maintainers validate it with:

```text
make check-claude-plugin
make test-claude-plugin
make verify-claude-plugin-release
```

## Where to go next

- [Commands](commands.md) — every slash command, what it does, and how it verifies.
- [Agents & tooling](agents-and-tooling.md) — sub-agents, the skill, the hook, and the MCP bridge.
- [CLI reference](../cli.md) — the `ml1` commands these workflows run.
- [Getting started](../getting-started.md) — install `ml1` and scaffold an app.
