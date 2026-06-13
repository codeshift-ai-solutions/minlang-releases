---
title: Getting started
nav_order: 2
---

# Getting started

From nothing to a deployed MinLang web app. The whole path is:

```text
write one .ml file  →  ml1 compile  →  pnpm dev / push to deploy
```

You need: a shell, Node 22+, and (for deploys) a GitHub repo.

## 1. Install the compiler (`ml1`)

All channels serve prebuilt binaries from the public `minlang-releases` repository — no token or account required.

| Channel | Command |
|---------|---------|
| Shell (macOS/Linux) | `bash <(curl -fsSL https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.sh)` |
| PowerShell (Windows) | `iwr -useb https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.ps1 \| iex` |
| GitHub Actions (CI) | `uses: codeshift-ai-solutions/minlang-releases/.github/actions/setup-ml1@main` |
| From source | `cargo install --git <minlang-core-url> minlang-cli` — requires access to the private source repository; external users should use the prebuilt channels above |

Verify:

```bash
ml1 --help
```

## 2. One-time Node setup

The generated app uses pnpm via corepack:

```bash
corepack enable && corepack prepare pnpm@10.33.0 --activate
```

## 3. Scaffold an app

```bash
npm create minlang-app my-app
cd my-app
```

This creates:

- `my-app.ml` — **your entire application**. It starts as a working task tracker.
- `app/` — a thin Next.js shell consuming the published `@minlang/*` runtime packages from npm. No submodule, no monorepo.
- `Makefile` — `compile`, `test`, `dev`, `build`, `update` targets.
- A GitHub Actions workflow that verifies and deploys on push.
- `AGENTS.md` / `CLAUDE.md` — instructions for coding agents, including where to fetch the language rules.

## 4. Write, compile, test, run

```bash
$EDITOR my-app.ml        # entities, constraints, actions, queries, screens, tests
make compile             # ml1 validate + compile → app/generated/
pnpm --dir app install   # first time only
make test                # generated test triads + integration tests
make dev                 # http://localhost:3111
```

Everything under `app/generated/` is compiler output: committed to git, never hand-edited. If you want to change the app, change `my-app.ml` and recompile.

Two rules save the most time when editing the `.ml`:

1. **Never use `now()`, `today()`, `random()`, or `current_user`.** Time and identity arrive as explicit action inputs (e.g. `created_at`, `actor_id`) that the server fills in automatically. See [Thinking in MinLang](thinking-in-minlang.md).
2. **Every business rule is a `constraint`, and every constraint ships with three tests** (success, exact-message failure, rejection leaves state unchanged). The [style guide](style-guide.md) has the patterns.

Writing MinLang with an AI agent? Point it at the canonical language bundle first:

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

## 5. Theming from Figma (optional)

If you have Figma design tokens (native Variables export, Tokens Studio, or W3C design-tokens JSON):

```bash
ml1 design tokens export.json --apply my-app.ml
make compile
```

This splices a `theme` block into your `.ml` that restyles the whole app. Details in [UI & UX](ui-ux.md).

## 6. Deploy to Vercel

Push the repo to GitHub. The scaffolded workflow deploys on every push to `main` once three secrets exist:

| Secret | Scope | Where to find it |
|--------|-------|------------------|
| `VERCEL_TOKEN` | org-level (set once) | Vercel → Account Settings → Tokens |
| `VERCEL_ORG_ID` | org-level (set once) | Vercel → Team Settings → General → Team ID |
| `VERCEL_PROJECT_ID` | per repo | Printed by the first deploy run, or Vercel → Project → Settings → General |

How it behaves:

- With only the two org-level secrets set, the **first run** links a Vercel project named after the repo, deploys it, prints the project id, and asks you to pin it as the `VERCEL_PROJECT_ID` repo secret.
- With all three set, every push re-compiles `my-app.ml` in `--check` mode (stale committed output fails the run), typechecks, tests, builds, and deploys prebuilt output.
- With `VERCEL_TOKEN` or `VERCEL_ORG_ID` missing, the deploy step skips with a notice — CI stays green before Vercel is wired.

The deploy logic lives in a public reusable workflow on `minlang-releases`, so fixes reach every scaffolded repo automatically.

**Persistence caveat:** the default in-memory adapter is ephemeral and per-serverless-instance — correct for demos only. Bind a real `DataAdapter` in `app/seed.ts` before treating a deployment as durable.

## 7. Staying current

One command updates the compiler binary, the `@minlang/*` package pins, and the generated output:

```bash
ml1 update           # self-update ml1, bump pins + pnpm install, recompile
ml1 update --check   # report only; exit 1 if updates are available (CI-gateable)
```

Scaffolded apps also get `make update`. Full flag reference: [CLI](cli.md).

## Next

- [Thinking in MinLang](thinking-in-minlang.md) — read this before writing your first real program.
- [Cookbook](cookbook/index.md) — complete, validator-clean programs to copy from.
