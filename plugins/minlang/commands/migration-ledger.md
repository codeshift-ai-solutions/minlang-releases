---
description: Track migrated slices, remaining shell code, blockers, and verification
---

# /minlang:migration-ledger

Track migrated slices, remaining shell code, blockers, and verification

## Before you start

Load the **authority-preflight** skill and follow it exactly. Read the applicable
language bundle from the stable URL or the project's `minlang.json` pin before
producing or validating MinLang.

Stable bundle URL:
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md

## Required input

Ask the user for any missing facts needed to complete this workflow safely.
Detect whether `ml1` is installed; if not, point to the public install scripts
without claiming the plugin bundles the compiler.

## Workflow

1. Detect project shape (`minlang.json`, primary `.ml` file, Makefile targets).
2. Read project instructions (`AGENTS.md`, `CLAUDE.md`) when present.
3. Maintain a migration ledger (markdown or JSON) with slices tagged:
   `migrated`, `pending`, `blocked`, `unsupported`, or `verified`.
4. Update the ledger after each migration command; do not require a big-bang rewrite.
5. Report blockers with concrete next commands (`/minlang:migrate-domain`, etc.).

## Forbidden

- Do **not** hand-edit files under `app/generated/`. Recompile from MinLang source.
- Do **not** write or overwrite `.env`.
- Do **not** use zero-tolerance tokens: `now()`, `today()`, `random()`, `current_user`.

## Verify

Primary verification: `none`

Also run applicable project checks (`make compile`, `make test`) when the app shape
is clear.

## Report

Return a concise summary: what changed, verification commands run, remaining
blockers, and next recommended command.
