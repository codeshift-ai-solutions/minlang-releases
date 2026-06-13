---
title: Language reference
nav_order: 4
---

# Language reference (bundle v4)

The complete human-readable reference for MinLang as defined by language bundle **v4**. This page is a derivative: the canonical authority is the versioned bundle attached to every release —

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

— and **on any conflict, the bundle wins**. Bundles are additive: every program valid under v1–v3 remains valid under v4.

## Program structure

A program is one `.ml` file containing top-level declarations, in any order:

| Declaration | Purpose | Required? |
|---|---|---|
| `entity` | The data that exists | yes (at least one) |
| `constraint` | A state the system must never enter | per rule |
| `action` | A named mutation (`create`/`set`/`delete`/`deal` steps only) | per mutation |
| `query` | A view-model screens read | per view |
| `screen` | Declarative flow, copy, and controls | optional |
| `theme` | Static look-and-feel data | optional |
| `asset` | Declarative asset intent (sprite/audio) | optional |
| `test` | Executable proof of behavior | per constraint (triad) |

Indentation is by tabs; identifiers for declarations are PascalCase, fields and inputs snake_case (see the [style guide](style-guide.md)).

## Entities

```text
entity Deal {
	id: string req
	company: ref(Company)
	title: string
	stage: enum(lead, qualified, won, lost)
	owner: string
	amount: int
	created_at: string
}
```

Field types:

| Type | Meaning | Web form control |
|---|---|---|
| `string` | text | text input |
| `int` | integer | number input |
| `bool` | boolean | checkbox |
| `enum(a, b, c)` | one of the listed members | select |
| `ref(Entity)` | reference to a row of `Entity` | select over that entity's rows |

`req` marks a field required. Every entity has an `id: string req` field that identifies its rows; rows are ordered by ascending `id`.

## Constraints

Constraints own **all** business logic. Actions are not allowed to validate anything (detector D5).

```text
constraint DealCompanyExists {
	on: Deal
	validate: count(Company as c, c == self.company) == 1
	message: 'company does not exist'
}
```

- `on:` — the entity whose writes this constraint guards. It guards **every** write path: create, every `set`, all of them.
- `validate:` — a boolean predicate over `self` (the row being written), action inputs, and `count(...)` joins. Operators: `==`, `>=`, `<=`, `AND`, `NOT(...)`.
- `message:` — a single-quoted literal. Failure tests must match it **byte for byte**.

The predicate shapes that pass validation:

1. **Self-bound predicates** for invariants on the row itself — required on mutable entities:

   ```text
   validate: NOT(self.stage == 'qualified' AND self.owner == '')
   ```

   Prefer the explicit invalid-state form `NOT(<invalid state>)`; `OR`-escape logic and off-by-one boundaries are rejected (D6).

2. **Count joins** for anything cross-entity — there is **no dot-walking** (`self.company.name` is rejected, D2):

   ```text
   validate: count(Company as c, c == self.company AND c.status == 'active') == 1
   ```

   Compare **whole references** (`c == self.company`), never `c.id == self.company` (D8).

3. **Create-time uniqueness** — compares the action's *input variable*, not `self`, and uses the proactive `== 0` boundary:

   ```text
   validate: count(Company as c, c.name == name) == 0
   ```

   `<= 1`, `>= 1`, and `self.field` in uniqueness checks are all rejected (D3/D4). Because input-bound constraints don't cover `set` paths, **put uniqueness only on create-only entities** — the [style guide](style-guide.md) explains the D3/D4/D7 interplay.

## Actions

```text
action CreateDeal(id: string, company: ref(Company), title: string,
                  stage: enum(lead, qualified, won, lost), owner: string,
                  amount: int, created_at: string, actor_id: string) {
	on: Deal
	create(Deal, { id: id, company: company, title: title, stage: stage,
	               owner: owner, amount: amount, created_at: created_at, actor_id: actor_id })
}
```

- The signature declares typed inputs. `on:` names the subject entity.
- The body is **pure mutation** — a sequence of steps from exactly four forms:

| Step | Effect |
|---|---|
| `create(Entity, { field: value, ... })` | insert a row |
| `set(field, value)` | write one field of the subject row |
| `delete Entity` | clear **the whole set** of `Entity` — there is no per-row delete |
| `deal(profile: <name>, seed: <int>)` | v4: compile-time expansion into deterministic `create` steps (this bundle defines the `golf_opening` card profile). No runtime randomness — the seed is a literal and expansion uses a normative shuffle |

No conditionals, no validation, no reads. Constraints decide whether the mutation is allowed.

### Input classification

Every input is either **user-supplied** (rendered as a form field) or **runtime-injected** (filled automatically at the server boundary, never shown in a form). Classification is by name; the runtime-injected names are exactly:

```text
delta_ms, frame_no, rng_draw, current_time, current_date,
actor_id, provider, recorded_at, recorded_by, request_id, created_at
```

These are *ordinary explicit inputs* — they don't bypass determinism, they just document where the value comes from. Tests supply them as literals.

### `id` semantics

- An `id` input on a **create** action is a *fresh id*: filled at the server boundary (`deps.newId()`), never shown to the user.
- An `id` input on a **`set`** action *selects the subject row*: rendered as a select over the `on:` entity's rows.
- An action with **no** user-supplied inputs renders as a plain button.

## Queries

```text
query PipelineBoard(workspace: ref(Workspace)) -> list<Deal> {
	from Deal
}
```

- `from Entity` returns the entity's rows. Return types: `list<Entity>` or a single `Entity`.
- A query input whose name matches a field of the source entity **filters** rows by it; otherwise all rows are returned, sorted by ascending `id` (`placed_at` first when that field exists).
- Screens bind queries via `board` (below).

### Derive queries

A query may compute its result with `derive <builtin>(<args>)` instead of `from` — a pure, bundle-defined function of state. No logic, `count(...)`, conditionals, or runtime dependence is allowed in a derive (D21/D26). The v4 builtins:

| Builtin | Args | Returns | Purpose |
|---|---|---|---|
| `grid_status(game)` | `ref(Game)` | `enum(playing, x_won, o_won, draw)` | 3×3 mark-board outcome (win line / draw / playing) |
| `card_total(game, owner)` | `ref(Game)`, enum owner | `int` | Golf hand score for a player |
| `round_winner(game)` | `ref(Game)` | `enum(none, player1, player2, tie)` | Lowest total wins |
| `top_stock_card(game)` | `ref(Game)` | `string` (Card id) | Deterministic top of the stock pile |
| `top_discard_card(game)` | `ref(Game)` | `string` (Card id) | Deterministic top of the discard pile |

```text
query BoardOutcome(game: ref(Game)) -> enum(playing, x_won, o_won, draw) {
	derive grid_status(game)
}
```

Outcome math lives in MinLang via these builtins — target emitters are forbidden from re-implementing it.

## Screens

Screens are **declarative data**: which view is active, the copy on it, and which actions its controls dispatch. They never gate, validate, or mutate state.

```text
screen Pipeline {
	when workspace.view == 'pipeline'
	title "Sales pipeline"
	hint "Create deals, move them through stages, and reassign owners."
	board PipelineBoard
	primary { label "Add deal" action CreateDeal }
	button { label "Companies" action OpenCompanies }
}
```

The full v3/v4 vocabulary (anything else is rejected, D18/D23):

| Key | Form | Notes |
|---|---|---|
| `when` | conjunction of `<entity>.<field> == '<literal>'` terms joined by `AND` | **required**. Evaluated against the first row in `id` order of the entity (the singleton convention). No `OR`, no other comparators, no `count(...)` |
| `title` | static string literal | page heading |
| `body` | static string literal | paragraph copy |
| `hint` | static string literal | helper copy |
| `status` | `status <entity>.<field> { member "copy" ... }` | live status line; the field must be an `enum`, and the copy map must cover **every** member exactly once |
| `headline` | same shape as `status` | outcome headline |
| `board` | `board QueryName` or `board QueryName { layout dual_hands columns N }` | names a declared query. Default layout `grid_3x3` renders as a responsive table on the web; `dual_hands` (with required `columns`) renders a card grid |
| `primary` | `primary { label "..." action Name }` or `primary { label "..." sequence [A, B] }` | the primary control; `action` XOR `sequence` |
| `button` | `button { label "..." action Name when <entity>.<field> == '<member>' }` | repeatable secondary controls; `when` is an optional visibility condition (same equality-conjunction form) |
| `tap` | `tap stock\|discard\|slot { action Name }` or with `sequence [...]` | repeatable pile/slot input targets (card games) |

**All copy is static string literals** (D19). Titles, bodies, hints, labels, and every enum-copy entry live in the `.ml`; compilers and emitters must never invent, default, or hardcode user-facing text.

The first screen in declaration order whose `when` holds is the active one. Multi-screen flow is driven by a small UI-state entity plus navigation actions — see the [style guide](style-guide.md).

## Theme

A `theme` block restyles the compiled app with static data. Sections: `palette`, `font`, `cell`, `window`.

```text
theme Default {
	palette {
		primary "#1e40af"
		surface "#f8fafc"
		text "#0f172a"
	}
	font {
		family "Inter"
	}
}
```

For the **web target** only these keys map (anything else fails the compile, naming the key and the supported set):

- `palette.{accent, border, danger, danger_text, focus_ring, primary, primary_text, success, surface, surface_raised, text, text_muted, warning}` → `--ml-color-*` design tokens
- `font.family` → `--ml-font-family`

Palette values must be `#rgb`/`#rrggbb` hex literals. `font.size`, `font.mark_size`, and the `cell`/`window` sections are **game-host-only** (Godot target) and fail a web compile.

**Contrast is a compile gate**: the effective light palette must keep `text`/`surface`, `text`/`surface_raised`, `text_muted`/`surface`, `primary_text`/`primary`, and `danger_text`/`danger` at **≥ 4.5:1** (WCAG 2.1 AA); violations fail the compile with the measured ratio. More in [UI & UX](ui-ux.md).

## Asset

An `asset` declares *intent* for a sprite or audio asset as static data; realizing bytes from intent happens out-of-band and is pinned deterministically by the toolchain.

```text
asset PlaceSound {
	kind audio
	intent "short soft wooden click, single tap, ~120ms, mono"
	seed 1337
}
```

Fields (fixed vocabulary, D14–D17): `kind` (`sprite` | `audio`), `intent` (one static string literal), `seed` (integer literal), optional `style_ref` (names a declared theme).

## Tests

```text
test UniqueCompanyNameRejectsDuplicate {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c0", name: "Acme Corp" })
	]
	when: CreateCompany on Company { id: "c1", name: "Acme Corp" }
	then: [
		error_raised('a company with this name already exists'),
		entity_count(Company) == 1
	]
}
```

- `setup:` — a list of `create(...)` steps establishing the starting state. Literals only; tests are fully deterministic (D12).
- `when:` — one action invocation: `ActionName on Entity { input: literal, ... }`.
- `then:` — assertions:
  - `error_raised('<message>')` — the action was rejected with exactly this message (**byte-exact** match against the constraint's `message:`).
  - `entity_count(Entity) == N` — row count.
  - `entity_has(Entity.N, field == "value")` — field of the Nth row (1-based, `id` order).

Every critical constraint requires the **test triad** (D11): a success test, a failure test with the exact message, and assertions proving the rejected mutation changed nothing. Each compiles to a Vitest file that must pass unmodified.

## The validator: 27 detectors

`ml1 validate` (and the generation contract LLM authors follow) enforces these detectors. D1–D13 cover behavior, D14–D17 presentation (v2), D18–D21 screens/derive (v3), D22–D27 deal/extended screens/scoring derives (v4). Optional-construct detectors only fire when the construct is declared.

| ID | Rejects | Why |
|----|---------|-----|
| D1 | `now()`, `today()`, `random()`, `current_user` anywhere | Total determinism; runtime context must arrive as explicit inputs |
| D2 | Dot-walking (`self.company.name`) | Cross-entity logic must be explicit `count(...)` joins |
| D3 | Weak uniqueness boundaries (`<= 1`, `>= 1`, `self.field`) | Duplicates must be blocked *before* the conflicting write |
| D4 | `self.field` in create-time input-driven invariants | Create-time checks must bind the action input, not the not-yet-written row |
| D5 | Business logic inside actions | Constraints own rules; actions stay pure mutation |
| D6 | Weak constraint shape (`OR` escapes, off-by-one, delayed enforcement) | Rules must model the invalid state explicitly and block the first bad transition |
| D7 | Invariants enforceable only on create | Every mutation path must be guarded — updates can't bypass rules |
| D8 | Mismatched reference comparisons (`c.id == self.company`) | Referential integrity: compare whole refs of matching type |
| D9 | Undeclared entities / hidden side effects in actions | Mutations stay inside the declared domain scope |
| D10 | Contradictory, unsatisfiable constraint sets | A program with no valid state is a bug, not a program |
| D11 | Missing test-triad members for a critical constraint | Every rule needs success + exact-message failure + rejection-leaves-state-unchanged proof |
| D12 | Non-determinism in tests/setup | Tests must reproduce byte for byte |
| D13 | Coverage claims not backed by triads | No false confidence |
| D14 | Unknown `theme`/`asset` keys | Presentation vocabulary is fixed and portable |
| D15 | Non-literal presentation values | Look and feel is static data, not computation |
| D16 | `style_ref` to an undeclared theme | No dangling references |
| D17 | Runtime/RNG/time/identity dependence in presentation | Presentation can't bypass determinism |
| D18 | Unknown screen keys | Screen vocabulary is fixed |
| D19 | Non-literal screen copy | All user-facing text lives in the `.ml`, never in the compiler |
| D20 | Malformed screen bindings (`when` shape, non-exhaustive copy maps, unknown query/action names) | Screens bind only declared things, exhaustively |
| D21 | Invalid derive (unknown builtin, wrong args/return, embedded logic) | Outcome derivation is a pure builtin |
| D22 | Invalid `deal` step (unknown profile, non-literal seed) | Dealing is compile-time and deterministic |
| D23 | Unknown extended screen keys (beyond v3 + `button`/`tap`) | v4 vocabulary is fixed too |
| D24 | Invalid `button`/`tap`/`sequence` (undeclared actions, empty sequence, bad tap target) | Controls dispatch only declared actions |
| D25 | Invalid board layout (unknown kind, missing `columns` for `dual_hands`) | Layout metadata must be complete |
| D26 | Derive builtin outside the v4 set, or arg/return mismatch | Closed builtin set per bundle |
| D27 | `deal` touching `random()`/`now()` or non-literal profile/seed | Deal is not runtime RNG |

When the validator and any document disagree, the stricter rule from the **bundle** applies. Download the canonical bundle: [minlang-language-bundle.md](https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md).
