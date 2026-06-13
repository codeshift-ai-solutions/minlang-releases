---
title: Style guide
nav_order: 5
---

# Style guide

Patterns that make MinLang programs pass `ml1 validate` on the first try and stay easy to review. The [language reference](language-reference.md) says what is legal; this page says what works.

## The singleton screen-flow entity

Multi-screen apps are driven by one small UI-state entity whose enum field has **one member per screen**:

```text
entity Workspace {
	id: string req
	view: enum(pipeline, companies)
}
```

Screen `when` conditions are evaluated against the **first row in `id` order** of that entity — the singleton convention. Navigation is just `set`-actions:

```text
action OpenCompanies(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'companies')
}

screen Companies {
	when workspace.view == 'companies'
	...
	button { label "Back to pipeline" action OpenPipeline }
}
```

Conventions: name the entity after the app's container (`Workspace`, `Guestbook`, `Game`), call the field `view` (or `phase` for games), and seed exactly one row of it in the app shell (`seed.ts`) — with zero rows, no screen activates.

## The uniqueness rule: D3/D4/D7 interplay

Three detectors interact around uniqueness, and together they force one design decision:

- **D3** requires create-time uniqueness to use the proactive boundary `count(Entity as e, e.field == input_field) == 0`.
- **D4** forbids `self.<field>` inside that check — you must compare the **action input**.
- **D7** rejects any input-bound constraint on an entity that *also* has `set` actions, because the update path would bypass it.

**Consequence: uniqueness constraints go only on create-only entities.** If an entity needs both uniqueness and mutability, split it: keep the unique identity create-only and hang the mutable state off it via a `ref`.

```text
# Company is create-only → uniqueness is allowed
constraint UniqueCompanyName {
	on: Company
	validate: count(Company as c, c.name == name) == 0
	message: 'a company with this name already exists'
}

# Deal is mutable (MoveDeal, ReassignDeal) → only self.-bound predicates
constraint DealOwnerRequiredWhenQualified {
	on: Deal
	validate: NOT(self.stage == 'qualified' AND self.owner == '')
	message: 'owner is required when a deal is qualified'
}
```

On mutable entities, the predicates that satisfy all three detectors are:

- `self.`-bound invalid-state forms: `NOT(self.title == '')`, `NOT(self.status == 'doing' AND self.assignee == '')`
- whole-reference count joins (next section)

## Whole-reference joins

Cross-entity checks are always `count(...)` joins, and the join compares the **whole reference**, never an id field:

```text
# good
validate: count(Project as p, p == self.project) == 1

# rejected (D8)
validate: count(Project as p, p.id == self.project) == 1

# rejected (D2 — dot-walking)
validate: self.project.name == 'General'
```

Use `== 1` for "the referenced row exists (with these properties)" and `== 0` for "no conflicting row exists".

## Test triad discipline

Write the triad **as you write the constraint**, not after. For each critical constraint:

1. **Success** — a test where the guarded write goes through. One success test can serve several constraints on the same write path (e.g. one `CreateDealSucceeds` covers every create-time rule on `Deal`).
2. **Failure** — `error_raised('<message>')`, copied **byte for byte** from the constraint. Don't retype it; copy-paste it.
3. **Rejection leaves state unchanged** — in the same failure test, assert the post-state: `entity_count(Deal) == 0` after a rejected create, `entity_has(Deal.1, stage == "lead")` after a rejected `set`.

If a constraint guards both a create and a `set` path, give the `set` path its own failure test — that is exactly the lifecycle leak D7 exists to catch.

One more consequence worth knowing: if you can't express a failure test for a rule (no literal can violate it), the triad can't be completed — drop the rule rather than ship it untested.

## Naming conventions

| Thing | Convention | Examples |
|---|---|---|
| Entities | PascalCase noun | `Company`, `Deal`, `Visitor` |
| Fields, inputs | snake_case | `created_at`, `owner`, `view` |
| Constraints | PascalCase, *SubjectRule* | `UniqueCompanyName`, `DealTitleRequired` |
| Actions | PascalCase, *VerbNoun* | `CreateDeal`, `MoveDeal`, `OpenCompanies` |
| Queries | PascalCase, view-shaped | `PipelineBoard`, `CompanyList` |
| Screens | PascalCase, place-shaped | `Pipeline`, `Companies` |
| Tests | PascalCase, *SubjectOutcome* | `MoveDealRejectsQualifiedWithoutOwner` |
| Constraint messages | single-quoted, lowercase, specific | `'owner is required when a deal is qualified'` |
| Screen copy | double-quoted sentences | `"Every deal belongs to a company."` |

Runtime-injected inputs must use the canonical names (`created_at`, `actor_id`, `current_time`, ...) — classification is by name, so `createdAt` would become a form field. The full list is in the [language reference](language-reference.md#input-classification).

## Small-program shape

A well-shaped MinLang file reads top to bottom in this order:

1. The flow entity, then domain entities
2. Constraints, grouped by entity
3. Actions: creates, then sets, then navigation
4. Queries
5. Screens (in flow order)
6. Theme (if any)
7. Tests, grouped by constraint/action

Keep programs small. If the file stops fitting in one review sitting, that's a sign the app wants splitting — one `.ml` is one application. Avoid speculative fields and rules: every constraint costs a triad, which is the language nudging you toward only the rules you mean.

## Remember the deletion rule

`delete Entity` clears the **whole set**. There is no per-row delete, so don't design flows that need one — model removal as a status change (`stage: enum(..., lost)`, `archived: bool`) and filter or read accordingly. See [the cookbook recipe](cookbook/index.md#per-row-ish-flows-without-per-row-delete).
