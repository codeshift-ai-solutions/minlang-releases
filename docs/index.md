---
title: Home
nav_order: 1
---

# MinLang

MinLang exists to make business systems easy to **read, write, review, and evolve** for both humans and LLMs.

- Humans read one declarative source of truth for rules, flow, copy, and tests.
- LLMs work against a constrained language, explicit validator feedback, and compiler-generated context maps.
- Teams keep determinism, test-first rigor, and constraint-first domain safety without scattered duplicate logic.

In MinLang, imports are **compile dependencies**. Local modules and pinned remote capsules are resolved into one closed graph, then compiled from pinned bytes. There is no runtime source linking.

## LLM quick-read

```text
MinLang in 8 lines:
1) Constraints own business logic; actions are pure mutation.
2) Determinism is strict (no now/today/random/current_user).
3) Tests are first-class and rule-driven (success/failure/rejection).
4) Modules/packages are explicit (v6: package/module/import/export).
5) minlang.toml + minlang.lock define a closed compile graph.
6) Remote dependencies are pinned and verified before compile.
7) Compiler emits sidecars (.ml.min) + maps + .mlai agent index.
8) Refactor/incremental/watch workflows are graph-aware, not ad-hoc.
```

Canonical bundle (authority): [minlang-language-bundle.md](https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md)

## Feature highlights

- Constraint-first and test-first modeling with deterministic validator gates.
- Multi-file modules and package manifests (`minlang.toml`) plus lockfiles (`minlang.lock`).
- Compile dependency closure for local/workspace/vendored/pinned remote capsules.
- LLM-safe workflows: `ml1 explain`, minimized sidecars (`.ml.min` + maps), `.mlai` index shards.
- Refactor workflows (`ml1 refactor plan/preview/shard/apply/verify/rollback/status`) for large graph changes.
- Incremental and background workflows (`ml1 compile --incremental`, `ml1 watch`, `ml1 daemon`, `ml1 deps precompile`).
- Generated TS/C# runtime planning with index/dirty-set/performance-manifest coverage.

## Time and context savings (conservative)

- **Authoring and review:** 20-40% less time when rules/screens/tests stay in one source instead of split framework layers.
- **Agent context loading:** 30-60% less token/context usage via sidecars and compiler-generated module maps.
- **Large-change planning:** 25-50% less coordination time with graph-aware refactor and explain workflows.
- **Drift/debug loops:** 15-35% faster due to deterministic compile/check and lockfile-based dependency closure.

## Where to go

| Page | What you'll find |
|------|------------------|
| [Vision](vision.md) | The purpose and long-term direction of MinLang — AI-first, intent compression, the 50× ambition. |
| [Getting started](getting-started.md) | Install `ml1`, scaffold an app, compile, test, run, deploy. |
| [Thinking in MinLang](thinking-in-minlang.md) | The mental shift: declare systems instead of hand-implementing behavior in many layers. |
| [Language reference](language-reference.md) | Human-readable reference for bundle v6, including module/package and compile dependency model. |
| [Style guide](style-guide.md) | Authoring patterns that keep the validator happy on the first pass. |
| [UI & UX](ui-ux.md) | How screens become widgets, theming, Figma import, skins, ASCII UI design bridge, wireframe review, accessibility. |
| [CLI reference](cli.md) | Every `ml1` command and flag. |
| [Cookbook](cookbook/index.md) | Recipes plus three complete programs: a [guestbook](cookbook/guestbook.md), the [task tracker](cookbook/task-tracker.md), and a [sales CRM](cookbook/crm-pipeline.md). |

## The canonical rules

This site is a human-friendly derivative. The single source of truth for the language is the versioned **language bundle** attached to every release — give it to any LLM that writes MinLang for you:

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

If anything on this site disagrees with the bundle, the bundle wins.
