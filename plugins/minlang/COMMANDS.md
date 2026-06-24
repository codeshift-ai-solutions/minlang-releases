# MinLang plugin commands

All public slash commands are namespaced as `/minlang:<command>`. Each command file
lives in `commands/` and is listed in `commands/commands.json`.

## Shared command contract

Every command that produces or validates MinLang must:

1. Load the **authority-preflight** skill first.
2. Read the applicable language bundle (stable URL or project pin) before output.
3. Detect project shape and `ml1` availability.
4. Run validation before declaring success when MinLang is produced or changed.
5. Never hand-edit `app/generated/` or write `.env`.
6. Return a concise report: changes, verification run, blockers, next step.

## Command families

| Family | Commands |
|--------|----------|
| Migration | `migrate-project`, `migrate-domain`, `migrate-screen`, `migrate-tests`, `migration-ledger` |
| Authoring | `author-app`, `add-feature`, `model-domain`, `design-ui`, `validate-authority` |
| Refactoring | `pull-domain-logic`, `dedupe-rules`, `thin-shell`, `generated-drift` |
| Diagnostics | `explain-failure`, `why-not-supported`, `inspect-graph`, `release-check` |
| Creative | `product-interview`, `legacy-strangler`, `boundary-police`, `demo-from-idea`, `bundle-upgrade-coach` |

## File naming

Physical files use kebab-case (`author-app.md`) and map to slash commands
(`/minlang:author-app`). The machine-readable inventory in `commands/commands.json`
is the source of truth for coverage tests.

## Agents

Optional deep workflows may delegate to:

- `minlang-creator` — generation with Creator repair loop
- `minlang-gatekeeper` — strict JSON validation verdicts
- `minlang-migration-architect` — phased migration planning

Agents supplement commands; they do not replace verification.

## Stable bundle URL

`https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md`
