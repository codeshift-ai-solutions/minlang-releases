---
title: CLI reference
nav_order: 8
---

# `ml1` CLI reference

The MinLang compiler ships as a single binary, `ml1`. Install it via the channels in [Getting started](getting-started.md). Running `ml1` with no arguments prints usage.

```text
ml1 <command>
```

**Authoring & compile**

| Command | Purpose |
|---|---|
| [`init`](#ml1-init) | Scaffold a new MinLang repository |
| [`validate`](#ml1-validate) | Validate a `.ml` file against the language rules |
| [`compile`](#ml1-compile) | Full pipeline: validate + generate the app (single file or project) |
| [`watch`](#ml1-watch) | Recompile the affected slice once on demand |
| [`daemon`](#ml1-daemon) | Manage warm background compile state (start/stop/status) |
| [`test`](#ml1-test) | Select impacted tests/modules for a change |
| [`build`](#ml1-build) | Probe a platform toolchain and initialize the runtime |

**Graph, packages & dependencies**

| Command | Purpose |
|---|---|
| [`graph`](#ml1-graph) | Emit the canonical project graph JSON |
| [`package`](#ml1-package-v6) | Resolve lockfiles, graph closure, registry/vendor/cache/update workflows |
| [`deps`](#ml1-deps) | Verify dependency capsules in the cache |
| [`cache`](#ml1-cache) | Incremental compile cache maintenance (verify/prune/stats) |
| [`migrate`](#ml1-migrate) | Migrate single-file apps to modules, or migrate a Godot fixture |
| [`refactor`](#ml1-refactor) | Plan/preview/apply/verify/rollback graph-wide refactors in waves |

**LLM & agent context**

| Command | Purpose |
|---|---|
| [`features`](#ml1-features) | Print the current language feature catalog for LLMs |
| [`support`](#ml1-support) | Write an agent-facing language support brief |
| [`explain`](#ml1-explain-v6) | Graph-backed project/module/dependency/edit/review context reports |
| [`llm`](#ml1-llm-v6) | Minimized sidecar generation/check workflows |
| [`ai`](#ml1-ai-v6) | `.mlai` index/search/context/patch-plan workflows |
| [`editor`](#ml1-editor) | LSP-style graph payloads: diagnostics, completion, definition, rename |
| [`language claude-plugin`](#ml1-language-claude-plugin) | Print Claude Code plugin install guidance |

**Design, assets, performance & updates**

| Command | Purpose |
|---|---|
| [`design tokens`](#ml1-design-tokens) | Figma/Tokens Studio/W3C export → `theme` block |
| [`design ui`](#ml1-design-ui) | Source `.mlui` → MinLang `screen` declarations |
| [`assets`](#ml1-assets) | Realize or verify declared assets (game targets) |
| [`perf`](#ml1-perf) | Compile/generated performance budgets and audits |
| [`update`](#ml1-update) | Update the compiler, language pin, runtime deps, and generated output |
| [`tokens` / `parse` / `ir`](#inspection-commands) | Inspect the token stream / AST / IR |

Running `ml1` with no arguments prints the full usage summary. Exit codes are uniform: `0` on success, non-zero on any error (one exception for `update --check`, noted below). Most commands accept `--project <dir>` to operate on a manifest-backed project graph instead of a single file.

Driving these commands from Claude Code? The [MinLang Claude Code plugin](claude-plugin/index.md) wraps the most common workflows (`validate`, `compile`, `graph`, `update --check`, and more) in [slash commands](claude-plugin/commands.md) with bundle-authority discipline.

## `ml1 init`

```bash
ml1 init <name> [--target web|godot]
```

Scaffolds a new MinLang repository named `<name>`. The default target is `web`; pass `--target godot` for a game project. The scaffold writes a starter `.ml`, the project pin (`minlang.json`), and the `Makefile` targets (`compile`, `test`, `validate`, `dev`) the rest of the workflow relies on.

## `ml1 validate`

```bash
ml1 validate <file>
ml1 validate --project <dir>
```

Runs the full validator and prints either `validation ok` or the diagnostics — each names the rule, the offending line, and the source span:

```text
error[E0200]: unknown field `message`
 --> guestbook.ml:21:16
```

This is the mechanical version of the language's detector set ([reference](language-reference.md#the-validator-49-detectors)). Exits non-zero on errors. Use it as your inner loop while authoring: edit → validate → fix → revalidate until clean.

## `ml1 compile`

```bash
ml1 compile <file> --target web|godot [--out <dir>] [--check]
```

Full pipeline: lex → parse → validate → lower to IR → generate → write. Nothing is written if any stage fails.

| Flag | Meaning |
|---|---|
| `--target web` | Emit a Next.js app: domain types + Zod, pure reducers and queries, screen schemas, trigger handlers, schedule API routes, server actions, App Router pages, Vitest tests, and ASCII wireframes (`ui/wire/*.mlui`) |
| `--target godot` | Emit the C#/Godot game host pipeline |
| `--out <dir>` | Output directory (default `generated/`). Scaffolded apps use `--out app`, putting output under `app/generated/` |
| `--check` | Dry run: report what would change **without writing**, and fail (non-zero) on changed *or* stale files, naming them. This is the CI drift gate |

Web-target specifics:

- A `theme` block is gated before anything is planned: unmapped keys, malformed hex values, and WCAG AA contrast violations fail the compile.
- Output is **deterministic** — same `.ml`, same bytes. An inventory lands in `generated/manifest.json`; the web target also emits `generated/MINLANG_LANGUAGE_SUPPORT.md` for language-gap tracking.
- **Pruning:** after a successful write, files listed in the *previous* `manifest.json` that the new plan no longer produces are deleted (plus emptied directories). Only manifest-listed paths are ever deleted — handwritten files in the output tree are never touched.

## `ml1 watch`

```bash
ml1 watch --project <dir>
```

Recompiles the **affected slice once** for a project graph: it detects what changed and rebuilds only the impacted modules, then exits. Use it as a fast, single-shot incremental compile rather than a long-running file watcher (for a persistent warm process, use `ml1 daemon`).

## `ml1 daemon`

```bash
ml1 daemon start  [--project <dir>]
ml1 daemon stop   [--project <dir>]
ml1 daemon status [--project <dir>]
```

Manages a warm background compile process that keeps the project graph and incremental cache hot between edits, so subsequent compiles are faster. `start` launches it, `stop` tears it down, and `status` reports whether it is running.

## `ml1 test`

```bash
ml1 test affected [--project <dir>]
```

Selects the tests and modules impacted by the current change set, so a large project can run only the relevant slice of its suite. It reports the selection; run the chosen tests through your `make test` / runtime test harness.

## `ml1 graph`

```bash
ml1 graph [--project <dir>]
```

Emits the **canonical project graph JSON** — modules, exports, imports, and the closed compile closure. This is the machine-readable form behind `/minlang:inspect-graph` and the basis for explain/editor/refactor reports.

## `ml1 build`

```bash
ml1 build --platform desktop|web-wasm|ios-arm64|android [--project <dir>] [--headless]
```

Probes the toolchain for a target platform and initializes the runtime for it. `--headless` runs without launching a UI (useful in CI). Missing toolchains are reported as actionable diagnostics rather than hard failures where possible.

## `ml1 deps`

```bash
ml1 deps precompile [--project <dir>]
```

Verifies that the dependency capsules referenced by `minlang.lock` are present and valid in the local cache, precompiling them so a later `compile`/`watch` does not have to. Imports are compile dependencies; this warms them ahead of time.

## `ml1 cache`

```bash
ml1 cache verify [--project <dir>]
ml1 cache prune  [--project <dir>]
ml1 cache stats  [--project <dir>]
```

Maintains the content-addressed incremental compile cache used by `compile --incremental`, `watch`, and the daemon. `verify` checks integrity, `prune` removes unreferenced entries, and `stats` prints cache usage.

## `ml1 migrate`

```bash
ml1 migrate modules <source.ml> [--project <dir>] [--dry-run|--write]
ml1 migrate analyze --from godot --project <dir>
ml1 migrate --from godot --project <dir> --dry-run
ml1 migrate verify --project <dir>
```

Two migration paths:

- **`migrate modules`** splits a single-file app into a manifest-backed module project. `--dry-run` plans the writes without touching disk; `--write` performs them.
- **`migrate ... --from godot`** analyzes, plans (dry-run), and verifies migration of a Godot fixture. The Godot migration path refuses dirty git trees and creates a branch/commits on clean repos.

## `ml1 refactor`

```bash
ml1 refactor plan --intent <text> --scope <selector> [--project <dir>] [--out <plan.json>]
ml1 refactor preview <plan.json>
ml1 refactor apply <plan.json> --wave <id> [--project <dir>] [--check]
ml1 refactor verify <plan.json> [--wave <id>] [--project <dir>]
ml1 refactor rollback <plan.json> --wave <id> [--project <dir>] [--check]
ml1 refactor status <plan.json>
ml1 refactor shard <plan.json> --max-tokens <n>
```

Graph-aware refactoring for large changes, organized into **waves** so an agent can apply, verify, and roll back one bounded step at a time:

| Subcommand | Purpose |
|---|---|
| `plan` | Produce a refactor plan from an intent and a scope selector |
| `preview` | Summarize waves, API impact, checks, and risks before applying |
| `apply` | Apply one wave (`--check` for a dry run) |
| `verify` | Verify a wave (or the whole plan) compiles and passes checks |
| `rollback` | Undo a wave (`--check` for a dry run) |
| `status` | Print wave statuses and blockers |
| `shard` | Emit token-bounded patch shards for tiny-context agent loops |

## `ml1 package` (v6)

```bash
ml1 package resolve [--manifest <path>] [--lockfile <path>] [--check]
ml1 package graph [--manifest <path>]
ml1 package discover --package <name> [--registry <file://...>]
ml1 package publish --version <x.y.z> [--registry <file://...>] [--dry-run]
ml1 package audit [--manifest <path>] [--lockfile <path>] [--json]
ml1 package vendor [--manifest <path>] [--lockfile <path>] [--dir <vendor-dir>]
ml1 package cache verify|gc [--manifest <path>] [--lockfile <path>] [--check]
ml1 package update [--manifest <path>] [--lockfile <path>] [--check]
```

`resolve` computes a deterministic closed compile graph and writes `minlang.lock`. Imports are compile dependencies; after resolve, compile/check use pinned local/cache bytes rather than runtime source links or live fetch.

## `ml1 explain` (v6)

```bash
ml1 explain project [--project <dir>]
ml1 explain module <name> [--project <dir>]
ml1 explain dependency <name> [--project <dir>]
ml1 explain edit <name> [--project <dir>]
ml1 explain review [--project <dir>]
```

Writes graph-backed LLM/human context artifacts (`generated/minlang.graph.json`, `generated/minlang.graph.ai.md`, per-module `.ai.md`) and prints deterministic scope reports for safe edits and reviews.

## `ml1 llm` (v6)

```bash
ml1 llm sidecars [--project <dir>] [--write|--check]
ml1 llm patch --sidecar <file>.ml.min --patch <patch.json> [--check]
```

Generates/checks minimized sidecars (`.ml.min` + `.ml.map.json`) as derivative artifacts bound to canonical `.ml` sources.

## `ml1 ai` (v6)

```bash
ml1 ai index [--project <dir>] [--check]
ml1 ai search <intent> [--project <dir>] [--budget 1000|2000|4000|8000|16000]
ml1 ai context <decl-id> [--project <dir>] [--budget 1000|2000|4000|8000|16000]
ml1 ai patch-plan <decl-id> --intent <text> [--project <dir>]
ml1 ai apply-patch <patch.json> [--project <dir>]
```

Provides `.mlai` index/search/context-pack workflows for tiny-token agent loops. Outputs are deterministic derivatives of the same compile graph.

## `ml1 editor`

```bash
ml1 editor diagnostics [--project <dir>]
ml1 editor completion  [--project <dir>]
ml1 editor definition <symbol> [--project <dir>]
ml1 editor references <symbol> [--project <dir>]
ml1 editor rename-preview --from <a> --to <b> [--write] [--project <dir>]
ml1 editor ai-context <module> [--project <dir>]
ml1 editor graph [--project <dir>]
```

LSP-style, graph-backed payloads for editors and tooling (the VS Code extension under `editor/minlang/` consumes these):

| Subcommand | Output |
|---|---|
| `diagnostics` | Cross-module diagnostics JSON for the whole graph |
| `completion` | Module + export completion payload |
| `definition <symbol>` | Exported declaration locations for a symbol |
| `references <symbol>` | Word-boundary references to a symbol |
| `rename-preview --from --to` | Preview a rename (`--write` to apply it) |
| `ai-context <module>` | The same safe-edit context as `explain edit` |
| `graph` | Canonical graph JSON preview |

## `ml1 features`

```bash
ml1 features [--out <path>]
# alias:
ml1 language features [--out <path>]
```

Prints or writes an LLM-facing catalog of the language features this `ml1`
knows: core declarations, supported field shapes, deterministic rules,
presentation blocks, screen controls, derive builtins, deterministic deal, web
target support, and explicit non-features. Use this as the first quick context
load before writing MinLang; the published bundle remains authoritative.

## `ml1 language claude-plugin`

```bash
ml1 language claude-plugin [--out <path>]
```

Prints the Claude Code plugin install commands (marketplace add + install) without requiring Claude Code itself — handy for other agents or for copy-paste into onboarding docs. See the [Claude Code plugin](claude-plugin/index.md) pages for the full plugin reference.

## `ml1 support`

```bash
ml1 support <file> [--out <path>]
```

Scans source text and writes `MINLANG_LANGUAGE_SUPPORT.md` (or the given
`--out` path) without parsing, validating, or compiling. Use it when a project
is experimenting with future MinLang syntax that the current bundle cannot
accept yet, but you still want an agent-readable gap brief and follow-up prompt.

## `ml1 update`

```bash
ml1 update [--check] [--app-dir <dir>] [--repo <owner/repo>]
           [--skip-self] [--skip-language] [--skip-deps] [--skip-compile]
```

Steps, in order:

1. **Self-update** — replace the `ml1` binary from the latest GitHub release of the releases repo (tokenless; uses the public `releases/latest` redirect). On Windows it prints the PowerShell reinstall one-liner instead of replacing the running exe.
2. **Language pin** — advance the project's language-bundle pin and surface migration notes.
3. **Dependencies** — bump the `@minlang/*` (and `create-minlang-app`) pins in `<app-dir>/package.json` to `^<npm latest>`, then `pnpm install --no-frozen-lockfile`.
4. **Recompile** — recompile the repo's root `.ml` with `--target web --out <app-dir>`.

| Flag | Meaning |
|---|---|
| `--check` | Report the plan (current → latest per item) without mutating anything. **Exit code 1 when updates are available, 0 when current** — gate CI on it |
| `--app-dir <dir>` | App directory (default `app`) |
| `--repo <owner/repo>` | Releases repo (default `codeshift-ai-solutions/minlang-releases`; the `MINLANG_REPO` env var overrides the default, `--repo` beats both) |
| `--skip-self` / `--skip-language` / `--skip-deps` / `--skip-compile` | Limit the steps |

Missing tools/files and `workspace:` pins degrade to one-line skip notes rather than errors. Output is one line per item plus a `summary:` line. Scaffolded apps alias this as `make update`.

## `ml1 design tokens`

```bash
ml1 design tokens <export.json> [--apply <app.ml>]
```

Converts a Figma Variables, Tokens Studio, or W3C design-tokens JSON export into a canonical `theme Default { ... }` block (mapping and alias table: [UI & UX](ui-ux.md#figma-tokens-import)).

- **Default:** the block prints to stdout; notes (unmapped tokens, duplicate-target picks) go to stderr, so piped stdout stays the pure block.
- **`--apply <app.ml>`:** splice the block into the `.ml` — replaces an existing `theme Default` block byte-exactly or appends at EOF. **Idempotent**: a second run reports "already up to date" and changes nothing.
- Unmapped tokens are `note:` lines, never errors. Alias cycles, invalid JSON, zero mapped tokens, and a non-lexing `--apply` target exit non-zero.
- Never touches the network. The web compile gate (vocabulary + AA contrast) remains the enforcement point.

## `ml1 design ui`

```bash
ml1 design ui <sketch.mlui> --app <app.ml>
ml1 design ui <sketch.mlui> --app <app.ml> --check
ml1 design ui <sketch.mlui> --app <app.ml> --apply
```

Imports a source `.mlui` file (structured headers + freehand ASCII preview) and generates MinLang `screen` declarations against an existing `.ml` app.

The source `.mlui` format uses `--- screen <Name>` sections with a YAML-like header block between `---` delimiters:

```text
--- screen Board
when: Workspace.view == 'board'
title: Task board
hint: Manage tasks.
board: TaskList
primary: { label: Add task  action: CreateTask }
button: { label: Projects  action: OpenProjects }
---
... freehand ASCII preview for human review ...
```

| Flag | Meaning |
|---|---|
| *(default)* | Print the generated `screen` blocks to stdout |
| `--check` | Verify the `.ml` already has matching blocks between `// mlui:begin screens` / `// mlui:end screens` markers; exit non-zero on mismatch or missing markers |
| `--apply` | Splice generated blocks into the `.ml` between the markers (idempotent); if no markers exist, append with a reminder comment |

The importer validates all referenced actions, effects, queries, and enum fields against the existing `.ml` before emitting anything. It never generates entities, constraints, actions, queries, or tests. The compile gate (`ml1 validate`) remains the enforcement point.

See [UI & UX](ui-ux.md#reviewing-ui-wireframes-and-previews) for the authoring workflow.

## `ml1 perf`

```bash
ml1 perf compile [--project <dir>] [--scenario <name>] [--changed <n>] [--budget-ms <n>] [--json]
ml1 perf generated [--manifest <path>] [--max-full-scans <n>] [--max-fallbacks <n>]
ml1 perf audit [--manifest <path>]
```

Performance budgets for the compiler and the generated runtime:

- **`perf compile`** measures compile time for a scenario (optionally simulating `--changed <n>` modules) against a `--budget-ms` ceiling; `--json` emits machine-readable results for CI.
- **`perf generated`** inspects the generated output for full-scan / fallback hotspots against `--max-full-scans` and `--max-fallbacks` thresholds.
- **`perf audit`** fails on generated full-scan regressions — the CI gate for runtime query performance.

## Inspection commands

For debugging and tooling:

```bash
ml1 tokens <file>    # dump the lexed token stream
ml1 parse <file>     # parse and dump the AST
ml1 ir <file>        # lower to canonical IR JSON on stdout
```

Each also accepts `--project <dir>` to operate on a project graph.

## `ml1 assets`

```bash
ml1 assets [--game <name>] [--out <dir>] [--provider <id>] [--verify]
```

Realizes declared `asset` intents into bytes via a pluggable provider, or verifies committed assets offline. Providers: `fake` (default, deterministic) and `openai`/`gpt`/`live` (Images API for sprites, procedural WAV for audio; credentials via `ML_ASSETS_API_KEY`, loaded from a repo-root `.env`). `--verify` checks committed files against `manifest.lock` without network. Asset realization is out-of-band by design — the language itself stays a pure function of its source. Primarily used by the Godot game target.
