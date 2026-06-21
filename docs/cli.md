---
title: CLI reference
nav_order: 7
---

# `ml1` CLI reference

The MinLang compiler ships as a single binary, `ml1`. Install it via the channels in [Getting started](getting-started.md). Running `ml1` with no arguments prints usage.

```text
ml1 <command>
```

| Command | Purpose |
|---|---|
| [`validate`](#ml1-validate) | Validate a `.ml` file against the language rules |
| [`compile`](#ml1-compile) | Full pipeline: validate + generate the app |
| [`features`](#ml1-features) | Print the current language feature catalog for LLMs |
| [`support`](#ml1-support) | Write an agent-facing language support brief |
| [`package`](#ml1-package-v6) | Resolve lockfiles, graph closure, registry/vendor/cache/update workflows |
| [`explain`](#ml1-explain-v6) | Graph-backed project/module/dependency/edit/review context reports |
| [`llm`](#ml1-llm-v6) | Minimized sidecar generation/check workflows |
| [`ai`](#ml1-ai-v6) | `.mlai` index/search/context/patch-plan workflows |
| [`update`](#ml1-update) | Update the compiler, runtime pins, and generated output |
| [`design tokens`](#ml1-design-tokens) | Figma/Tokens Studio/W3C export → `theme` block |
| [`tokens` / `parse` / `ir`](#inspection-commands) | Inspect the token stream / AST / IR |
| [`assets`](#ml1-assets) | Realize or verify declared assets (game targets) |

Exit codes are uniform: `0` on success, non-zero on any error (one exception for `update --check`, noted below).

## `ml1 validate`

```bash
ml1 validate <file>
```

Runs the full validator and prints either `validation ok` or the diagnostics — each names the rule, the offending line, and the source span:

```text
error[E0200]: unknown field `message`
 --> guestbook.ml:21:16
```

This is the mechanical version of the language's detector set ([reference](language-reference.md#the-validator-27-detectors)). Exits non-zero on errors. Use it as your inner loop while authoring: edit → validate → fix → revalidate until clean.

## `ml1 compile`

```bash
ml1 compile <file> --target web|godot [--out <dir>] [--check]
```

Full pipeline: lex → parse → validate → lower to IR → generate → write. Nothing is written if any stage fails.

| Flag | Meaning |
|---|---|
| `--target web` | Emit a Next.js app: domain types + Zod, pure reducers and queries, screen schemas, server actions, App Router pages, Vitest tests, and ASCII wireframes (`ui/wire/*.mlui`) |
| `--target godot` | Emit the C#/Godot game host pipeline |
| `--out <dir>` | Output directory (default `generated/`). Scaffolded apps use `--out app`, putting output under `app/generated/` |
| `--check` | Dry run: report what would change **without writing**, and fail (non-zero) on changed *or* stale files, naming them. This is the CI drift gate |

Web-target specifics:

- A `theme` block is gated before anything is planned: unmapped keys, malformed hex values, and WCAG AA contrast violations fail the compile.
- Output is **deterministic** — same `.ml`, same bytes. An inventory lands in `generated/manifest.json`; the web target also emits `generated/MINLANG_LANGUAGE_SUPPORT.md` for language-gap tracking.
- **Pruning:** after a successful write, files listed in the *previous* `manifest.json` that the new plan no longer produces are deleted (plus emptied directories). Only manifest-listed paths are ever deleted — handwritten files in the output tree are never touched.

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
           [--skip-self] [--skip-deps] [--skip-compile]
```

Three steps, in order:

1. **Self-update** — replace the `ml1` binary from the latest GitHub release of the releases repo (tokenless; uses the public `releases/latest` redirect). On Windows it prints the PowerShell reinstall one-liner instead of replacing the running exe.
2. **Dependencies** — bump the `@minlang/*` (and `create-minlang-app`) pins in `<app-dir>/package.json` to `^<npm latest>`, then `pnpm install --no-frozen-lockfile`.
3. **Recompile** — recompile the repo's root `.ml` with `--target web --out <app-dir>`.

| Flag | Meaning |
|---|---|
| `--check` | Report the plan (current → latest per item) without mutating anything. **Exit code 1 when updates are available, 0 when current** — gate CI on it |
| `--app-dir <dir>` | App directory (default `app`) |
| `--repo <owner/repo>` | Releases repo (default `codeshift-ai-solutions/minlang-releases`; the `MINLANG_REPO` env var overrides the default, `--repo` beats both) |
| `--skip-self` / `--skip-deps` / `--skip-compile` | Limit the steps |

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

## Inspection commands

For debugging and tooling:

```bash
ml1 tokens <file>    # dump the lexed token stream
ml1 parse <file>     # parse and dump the AST
ml1 ir <file>        # lower to canonical IR JSON on stdout
```

## `ml1 assets`

```bash
ml1 assets [--game <name>] [--out <dir>] [--provider <id>] [--verify]
```

Realizes declared `asset` intents into bytes via a pluggable provider, or verifies committed assets offline. Providers: `fake` (default, deterministic) and `openai`/`gpt`/`live` (Images API for sprites, procedural WAV for audio; credentials via `ML_ASSETS_API_KEY`, loaded from a repo-root `.env`). `--verify` checks committed files against `manifest.lock` without network. Asset realization is out-of-band by design — the language itself stays a pure function of its source. Primarily used by the Godot game target.
