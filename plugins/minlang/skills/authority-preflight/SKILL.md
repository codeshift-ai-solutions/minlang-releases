---
name: authority-preflight
description: Load MinLang authority, detect project shape, and choose verification commands before producing or validating MinLang
---

# Authority preflight

Use this skill before any MinLang generation, migration, validation, or refactor.

## Project detection

1. Look for `minlang.json` (compiler and language-bundle pin).
2. Locate the primary `.ml` application file (often `<app-name>.ml` at repo root).
3. Read `AGENTS.md` and `CLAUDE.md` when present.
4. Detect Makefile targets (`compile`, `test`, `validate`, `dev`).
5. Check whether `ml1` is on PATH. The plugin does **not** bundle `ml1`; point users to:
   - macOS/Linux: `bash <(curl -fsSL https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.sh)`
   - Windows: `iwr -useb https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.ps1`

## Bundle authority

1. Read the project's `minlang.json` pin when available.
2. Fetch or read the applicable language bundle before producing MinLang:
   `https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md`
3. Do **not** copy the full bundle into responses. Cite the URL and read what you need.
4. Follow Creator packet discipline for generation and Gatekeeper JSON discipline for validation verdicts.

## Creator loop (generation)

GENERATE → VALIDATE → LIST VIOLATIONS → FIX → REVALIDATE → CONFIRM ZERO VIOLATIONS → OUTPUT

Never emit MinLang while violations remain.

## Forbidden

- Do **not** hand-edit `app/generated/`. Recompile from `.ml` source.
- Do **not** write or overwrite `.env`.
- Do **not** use: `now()`, `today()`, `random()`, `current_user`.

## Verification command selection

| Situation | Command |
|-----------|---------|
| Single file check | `ml1 validate <file>` |
| Feature catalog | `ml1 features` or `ml1 language features` |
| Project compile | `make compile` |
| Tests | `make test` |
| Graph / closure | `ml1 graph <file>` |
| Bundle / compiler update check | `ml1 update --check` |
| Apply updates | `ml1 update` (only when user asks) |
| UI sketch check | `ml1 design ui <sketch.mlui> --app <app.ml> --check` |

Skip commands that do not match the detected project shape and say why.

## Generated output rules

Generated files under `app/generated/` are compiler output. Commit them with source
changes but never hand-edit them. If drift is suspected, recompile and compare.

## Migration notes

When crossing bundle versions, read `ml1 update --check` output and migration ledger
recommendations before editing MinLang source.

## Optional MCP bridge

When the plugin MCP bridge is enabled and `ml1` is available, structured validate
and features calls may be used. Shell verification remains authoritative.
