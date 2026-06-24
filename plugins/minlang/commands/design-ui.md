---
description: Sketch screens first, then generate or update MinLang screen blocks
---

# /minlang:design-ui

Sketch screens first, then generate or update MinLang screen blocks

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
3. Use the sketch-first path: create or update `ui/design/screens.mlui` before
   touching screen declarations in the `.ml` file.
4. Run `ml1 design ui ui/design/screens.mlui --app <app.ml> --check` before applying.
5. Apply with `--apply` only after check passes; then GENERATE → VALIDATE → FIX → REVALIDATE.
6. Run verification before declaring success.

## Forbidden

- Do **not** hand-edit files under `app/generated/`. Recompile from MinLang source.
- Do **not** write or overwrite `.env`.
- Do **not** use zero-tolerance tokens: `now()`, `today()`, `random()`, `current_user`.

## Verify

Primary verification: `ml1 design ui <sketch.mlui> --app <app.ml> --check`

Also run applicable project checks (`make compile`, `make test`) when the app shape
is clear.

## Report

Return a concise summary: what changed, verification commands run, remaining
blockers, and next recommended command.
