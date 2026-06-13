---
title: Thinking in MinLang
nav_order: 3
---

# Thinking in MinLang

MinLang asks for a different way of working than a general-purpose language. If you try to "implement features" in it, you will fight the validator. If you **declare the program** — its data, its rules, its mutations, its screens — the toolchain does the implementing, the testing, and a good part of the reviewing for you.

## You declare the program; you don't implement it

A MinLang file has no functions, no control flow, no rendering code. It has:

- **Entities** — the data that exists.
- **Constraints** — every state the system must never enter.
- **Actions** — the only mutations that exist (`create`, `set`, `delete`, `deal`).
- **Queries** — the view-models screens read.
- **Screens** — which view is active, the copy on it, and which actions it dispatches.
- **Tests** — executable proof of every rule.

The compiler derives everything else: forms from action inputs, tables from queries, navigation from `set`-actions on a flow entity, a Vitest suite from your tests. There is deliberately no place to put an `if` statement in a button handler — that logic belongs in a constraint, where it guards *every* path, not just the one you remembered.

## Constraints own all business logic

In most stacks a rule like "a deal needs an owner once it's qualified" ends up implemented three times: in the form validation, in the API handler, and (maybe) in the database. In MinLang it is written exactly once:

```text
constraint DealOwnerRequiredWhenQualified {
	on: Deal
	validate: NOT(self.stage == 'qualified' AND self.owner == '')
	message: 'owner is required when a deal is qualified'
}
```

Actions stay pure mutation. The validator rejects any action that smuggles in validation or cross-entity logic (detector D5). Because the constraint is declared on the entity, it guards creation, every `set`, and any future action you add — there is no path around it.

## Determinism is total

`now()`, `today()`, `random()`, and `current_user` are forbidden everywhere — in constraints, actions, tests, even themes and screens (detector D1). MinLang programs are pure functions of their inputs.

Runtime context still gets in, but only through the front door: as **explicit action inputs**. Names like `created_at`, `current_time`, `actor_id`, and `request_id` are classified as *runtime-injected* — the generated server boundary fills them in automatically, and they never appear as form fields. Your tests pass them as literals, which is why every test is reproducible byte for byte.

```text
action CreateTask(id: string, project: ref(Project), title: string,
                  status: enum(todo, doing, done), assignee: string,
                  created_at: string, actor_id: string) {
	on: Task
	create(Task, { id: id, project: project, title: title, status: status,
	               assignee: assignee, created_at: created_at, actor_id: actor_id })
}
```

The user types `title` and picks `status`; the runtime supplies `created_at` and `actor_id`; nothing is implicit.

## Every rule ships with its test triad

A constraint without tests doesn't pass validation. Each critical constraint needs three things (detector D11):

1. A **success test** — the rule permits valid writes.
2. A **failure test** asserting `error_raised('<message>')` — matched **byte for byte** against the constraint's message.
3. A **mutation-rejection assertion** — after the rejected action, state is unchanged (`entity_count(...)` / `entity_has(...)`).

This sounds like ceremony until you've watched it catch a rule that only fired on create and silently let updates through. The triad makes "the rule works" a compiled fact rather than a code-review opinion.

## Generated code is an artifact you review via projections

You never read or edit `app/generated/` to understand a change. Instead the compiler emits **projections**:

- An **ASCII wireframe** per screen (`generated/ui/wire/<screen>.txt`, mobile and desktop widths). A PR that changes a screen shows the UI change as a plain text diff.
- **Rendered screenshots** of every screen, captured by the e2e suite and uploaded as a CI artifact for pixel-level review.

Output is byte-deterministic: the same `.ml` always produces the same bytes, and CI's `--check` mode fails if committed output drifts from the source. "What does this PR do?" is answered by the `.ml` diff plus the wireframe diff — at the level of *rules and screens*, not framework code.

## Agents are first-class authors

The language was shaped so LLM coding agents can write it safely: a closed vocabulary, mechanical validation, exact error messages, and a published rule book. Every release attaches a single-file **language bundle** (canonical rules + detectors + the authoring guide) at a stable URL, and scaffolded repos ship an `AGENTS.md` that points agents at it. The authoring loop agents follow — generate, validate, list violations, fix, revalidate, only output at zero violations — is the same loop `ml1 validate` enforces for humans.

## What this buys you

- **Review at the UI and rule level.** Diffs are one declarative file plus wireframes, not a component tree.
- **Byte-reproducibility.** Same source, same output, same test results — on every machine, forever.
- **Zero drift.** Rules can't diverge between client, server, and tests because they exist in one place; `--check` keeps generated output honest in CI.
- **Proven rules.** Every constraint has executable success/failure/rejection evidence before the program compiles.

## What it costs you

Be honest with yourself about the trade before adopting it:

- **A closed vocabulary.** Screens have a fixed set of keys; widgets are derived, not designed per-pixel in the `.ml` (skins and themes recover a lot of this — see [UI & UX](ui-ux.md)). If the construct doesn't exist, you wait for a bundle that adds it.
- **No per-row delete.** `delete Entity` clears the whole set; the language has no "delete this row" primitive. Flows are designed around status changes instead (see the [cookbook](cookbook/index.md)).
- **No ad-hoc escape hatches.** You cannot drop into imperative code for "just this one rule". The escape hatches that do exist (shell code, skins) are presentation-only and mechanically linted to stay that way.

MinLang is at its best for small, rule-heavy applications where correctness and reviewability matter more than bespoke pixels. For those, declaring the program is simply less work than implementing it.
