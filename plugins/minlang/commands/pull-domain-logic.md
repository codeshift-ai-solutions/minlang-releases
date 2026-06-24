---
description: Find domain logic hiding in React/API/shell code and move it into MinLang
---

# /minlang:pull-domain-logic

Find domain logic hiding in React/API/shell code and move it into MinLang

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
3. Execute the command-specific work described in the design doc for **pull-domain-logic**.
4. For generation tasks: GENERATE → VALIDATE → FIX → REVALIDATE until zero violations.
5. Run verification before declaring success.

## Forbidden

- Do **not** hand-edit files under `app/generated/`. Recompile from MinLang source.
- Do **not** write or overwrite `.env`.
- Do **not** use zero-tolerance tokens: `now()`, `today()`, `random()`, `current_user`.

## Verify

Primary verification: `ml1 validate <file> && make compile`

Also run applicable project checks (`make compile`, `make test`) when the app shape
is clear.

## Report

Return a concise summary: what changed, verification commands run, remaining
blockers, and next recommended command.
