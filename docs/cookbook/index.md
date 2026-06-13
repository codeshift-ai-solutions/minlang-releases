---
title: Cookbook
nav_order: 8
has_children: true
---

# Cookbook

Recipes for the situations every MinLang app runs into, plus three complete, annotated programs:

| Program | What it shows |
|---|---|
| [Guestbook](guestbook.md) | The smallest useful app: one screen, create-only entity, uniqueness |
| [Task tracker](task-tracker.md) | The reference example, annotated section by section, with its wireframes |
| [Sales CRM](crm-pipeline.md) | A pipeline board: flow entity, create-only + mutable entities, lifecycle rules |

Both the guestbook and the CRM listings are validator-clean against bundle v4 — the raw `.ml` files live next to these pages ([guestbook.ml](samples/guestbook.ml), [crm-pipeline.ml](samples/crm-pipeline.ml)).

---

## Add a screen + navigation action

**Problem:** your app needs a second view and a way to get there.

Screens activate off a singleton flow entity. Adding a screen is three edits — extend the enum, add a navigation action, declare the screen:

```text
entity Workspace {
	id: string req
	view: enum(board, projects, settings)    # 1. new member
}

action OpenSettings(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'settings')                     # 2. navigation = a set-action
}

screen Settings {
	when workspace.view == 'settings'         # 3. the new screen
	title "Settings"
	button { label "Back to board" action OpenBoard }
}
```

Then put a `button { label "Settings" action OpenSettings }` on the screens that should link to it, and add a test asserting the view switch (`entity_has(Workspace.1, view == "settings")`). Navigation has no special machinery — it is ordinary state your screens select on.

## Enforce uniqueness correctly

**Problem:** "no two companies with the same name" — and the validator rejects your first three attempts.

The rule (the D3/D4/D7 interplay, explained in the [style guide](../style-guide.md)): uniqueness counts compare the **input variable** with the proactive `== 0` boundary, and they may only live on **create-only entities**.

```text
constraint UniqueCompanyName {
	on: Company                                # Company has no set-actions
	validate: count(Company as c, c.name == name) == 0
	message: 'a company with this name already exists'
}
```

If the entity must also be mutable, split the unique identity into its own create-only entity and reference it. And complete the triad — success test, duplicate-rejection test with the byte-exact message, and `entity_count(Company) == 1` after the rejection.

## Per-row-ish flows without per-row delete

**Problem:** users want to "remove" a task, but `delete Entity` clears the whole set and there is no per-row delete.

Model removal as a **status change**. Give the entity a terminal member and a normal `set`-action:

```text
entity Task {
	id: string req
	title: string
	status: enum(todo, doing, done, archived)
}

action ArchiveTask(id: string, actor_id: string) {
	on: Task
	set(status, 'archived')
}
```

The `id` input on a `set`-action renders as a row selector, so "archive task" becomes a form where the user picks the row — that is the idiomatic per-row interaction. Rows stay in the data (queries return all rows of the source entity today; v5's display metadata will widen what collections can do — see [roadmap](../ui-ux.md#today-vs-roadmap-bundle-v5)). A real bulk reset is what `delete` is for: a `ClearBoard` action that wipes and reseeds.

## Theme an app from Figma

**Problem:** the design team has a Figma file; the app ships with default tokens.

1. Export design tokens from Figma — native Variables export, the Tokens Studio plugin, or any W3C design-tokens JSON.
2. Run the importer against your app:

   ```bash
   ml1 design tokens export.json --apply my-app.ml
   ```

   It maps token names (`brand` → `primary`, `bg` → `surface`, `fg` → `text`, ...) onto the theme vocabulary and splices a `theme Default { ... }` block into the file. Unmapped tokens print as notes, never errors. The run is idempotent.
3. Compile:

   ```bash
   make compile
   ```

   The compile gate checks the vocabulary and **WCAG AA contrast** (≥ 4.5:1 for every text-on-surface pair) — a palette that fails reports the measured ratio, and nothing ships until it passes.

Full mapping and alias table: [UI & UX](../ui-ux.md#figma-tokens-import).

## Swap a widget with a skin

**Problem:** the default table doesn't match the design system; you want your own component without touching generated code.

1. Create `app/skins/table.tsx` — a server component taking exactly `WidgetProps<"table">`. Rows come from `deps.viewModels[node.query]`; all copy comes from the schema node; styling uses token classes (`bg-surface-raised`, `text-ink`, `border-edge`).
2. Register it in `seed.ts`:

   ```ts
   import { bindRegistryOverrides } from "@minlang/runtime-web";
   import { TableSkin } from "./skins/table";

   bindRegistryOverrides({ table: TableSkin });
   ```

3. Lint and test:

   ```bash
   make lint-skins   # rejects hardcoded copy, color literals, fetch/Date.now, adapter imports
   make test
   ```

If you start from a Figma Make export, the adaptation is mostly deletion: remove its data fetching, its local data state, its hardcoded strings, and its literal colors. Details and a worked example: [UI & UX](../ui-ux.md#skins-pixel-perfect-components).

## Read a PR (wire diff + previews)

**Problem:** a PR claims "adds an archive button to the board" — how do you review it without checking out and running the app?

Read it top-down, in this order:

1. **The `.ml` diff** — the only source change. New action? New constraint with its message? Tests present (success + byte-exact failure + state-unchanged assertions)?
2. **The wireframe diff** (`generated/ui/wire/<screen>.txt`) — the UI change as plain text. A new `[ Archive task ]` form box appearing in `board.txt` at both mobile and desktop widths *is* the feature, visually:

   ```text
   + │ ┌ Archive task ────────────────────┐ │
   + │ │ Id: ________                     │ │
   + │ │ [ Archive task ]                 │ │
   + │ └──────────────────────────────────┘ │
   ```

3. **The rest of `generated/`** — you don't review it line by line; CI's `--check` mode proves it matches the `.ml`, and the generated Vitest suite proves the rules.
4. **Screen previews** — for pixel-level changes (themes, skins), download the `screen-previews` CI artifact: rendered screenshots of every screen at mobile and desktop viewports.

Wireframes are projections rendered from the same schema the app uses — they cannot disagree with the real UI.
