---
title: Commands
parent: Claude Code plugin
nav_order: 1
---

# Plugin commands

All public slash commands are namespaced `/minlang:<command>`. There are **23**
commands across five families. Every command that produces or validates MinLang
loads the **authority-preflight** skill, reads the language bundle first, runs
real verification, and never touches `app/generated/` or `.env`.

The machine-readable inventory is `commands/commands.json` in the plugin; it is
the source of truth for the coverage tests. The `Produces` column below marks
whether a command writes MinLang source; `Verifies with` is the primary
verification each command runs before declaring success.

## Authoring

Build a new MinLang app or extend an existing one, model-first and test-first.

| Command | What it does | Produces | Verifies with |
|---|---|---|---|
| `/minlang:author-app` | Interview the user, draft the `.ml`, validate, fix, and compile a complete app | MinLang | `ml1 validate <file> && make compile && make test` |
| `/minlang:add-feature` | Make one product change by editing **only** MinLang source | MinLang | `ml1 validate <file> && make compile && make test` |
| `/minlang:model-domain` | Produce the entity/action/query model **before** any screens | MinLang | `ml1 validate <file>` |
| `/minlang:design-ui` | Sketch screens first, then generate or update MinLang `screen` blocks | MinLang | `ml1 design ui <sketch.mlui> --app <app.ml> --check` |
| `/minlang:validate-authority` | Run the Creator/Gatekeeper preflight plus `ml1 validate` on existing source | — | `ml1 validate <file>` |

## Migration

Move an existing application into MinLang slice by slice, with a durable ledger.

| Command | What it does | Produces | Verifies with |
|---|---|---|---|
| `/minlang:migrate-project` | Audit an existing app and create a phased migration map into MinLang | MinLang | `ml1 validate <file> \|\| make compile` |
| `/minlang:migrate-domain` | Extract entities, constraints, actions, and queries from one feature area | MinLang | `ml1 validate <file>` |
| `/minlang:migrate-screen` | Turn an existing UI route or component into MinLang `screen` blocks | MinLang | `ml1 validate <file> && make compile` |
| `/minlang:migrate-tests` | Convert existing unit/e2e expectations into MinLang tests | MinLang | `make test` |
| `/minlang:migration-ledger` | Track migrated slices, remaining shell code, blockers, and verification | — | none (reporting only) |

## Refactoring

Pull business logic out of shell code and keep generated output honest.

| Command | What it does | Produces | Verifies with |
|---|---|---|---|
| `/minlang:pull-domain-logic` | Find domain logic hiding in React/API/shell code and move it into MinLang | MinLang | `ml1 validate <file> && make compile` |
| `/minlang:dedupe-rules` | Detect duplicated validation, copy, and business rules across app code | MinLang | `ml1 validate <file>` |
| `/minlang:thin-shell` | Identify shell code that violates presentation-only boundaries | — | `make compile` |
| `/minlang:generated-drift` | Compare `.ml` intent against generated output and stale hand edits | — | `make compile` |

## Diagnostics

Understand failures, gaps, and release readiness.

| Command | What it does | Produces | Verifies with |
|---|---|---|---|
| `/minlang:explain-failure` | Translate `ml1 validate` and compile errors into concrete fixes | — | `ml1 validate <file>` |
| `/minlang:why-not-supported` | Map a desired feature to current language support gaps | — | `ml1 features` |
| `/minlang:inspect-graph` | Explain the project graph and compile closure | — | `ml1 graph <file>` |
| `/minlang:release-check` | Verify app compatibility with the latest compiler, bundle, runtime, and generated output | — | `ml1 update --check && make compile && make test` |

## Creative

Higher-level, conversational workflows that orchestrate the commands above.

| Command | What it does | Produces | Verifies with |
|---|---|---|---|
| `/minlang:product-interview` | Ask only the product questions needed to produce a valid MinLang app | — | none (interview only) |
| `/minlang:legacy-strangler` | Plan a slice-by-slice migration from a legacy app to MinLang | — | none (planning only) |
| `/minlang:boundary-police` | Scan for logic that belongs in `.ml` but leaked into generated or shell code | — | `make compile` |
| `/minlang:demo-from-idea` | Go from a one-paragraph idea to a compiled app, tests, and dev server | MinLang | `ml1 validate <file> && make compile && make test && make dev` |
| `/minlang:bundle-upgrade-coach` | Guide an app across bundle versions using `ml1 update` and migration notes | MinLang | `ml1 update --check` |

## How a producing command runs

Commands that write MinLang follow the Creator repair loop end to end:

1. Detect project shape (`minlang.json`, primary `.ml` file, `Makefile` targets).
2. Read project instructions (`AGENTS.md`, `CLAUDE.md`) when present.
3. Gather the missing product facts (or run a focused interview).
4. Draft or update the primary `.ml` file only — never `app/generated/`.
5. **GENERATE → VALIDATE → FIX → REVALIDATE** until zero violations remain.
6. Run the verification command(s) above before declaring success.
7. Report what changed, what was run, what is blocked, and the next command.

## See also

- [Agents & tooling](agents-and-tooling.md) — the sub-agents and the MCP bridge these commands can delegate to.
- [CLI reference](../cli.md) — the `ml1` commands invoked during verification.
- [Plugin overview](index.md) — install and authority discipline.
