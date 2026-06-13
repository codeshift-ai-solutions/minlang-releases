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
| `--target web` | Emit a Next.js app: domain types + Zod, pure reducers and queries, screen schemas, server actions, App Router pages, Vitest tests, and ASCII wireframes (`ui/wire/*.txt`) |
| `--target godot` | Emit the C#/Godot game host pipeline |
| `--out <dir>` | Output directory (default `generated/`). Scaffolded apps use `--out app`, putting output under `app/generated/` |
| `--check` | Dry run: report what would change **without writing**, and fail (non-zero) on changed *or* stale files, naming them. This is the CI drift gate |

Web-target specifics:

- A `theme` block is gated before anything is planned: unmapped keys, malformed hex values, and WCAG AA contrast violations fail the compile.
- Output is **deterministic** — same `.ml`, same bytes. An inventory lands in `generated/manifest.json`.
- **Pruning:** after a successful write, files listed in the *previous* `manifest.json` that the new plan no longer produces are deleted (plus emptied directories). Only manifest-listed paths are ever deleted — handwritten files in the output tree are never touched.

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
