---
title: UI & UX
nav_order: 6
---

# UI & UX

How MinLang turns declarations into an interface, and how to get a polished, accessible app out of the system — what you can shape today, and what arrives with bundle v5.

## How screens become widgets

The web emitter derives a typed screen schema (data only — no React, no styles) from each `screen` declaration, and the handwritten runtime renders it. The derivation is mechanical:

| You declare | You get |
|---|---|
| `title` / `body` / `hint` | heading / paragraph / helper text, copy verbatim |
| `status` / `headline` enum-copy map | a status badge / outcome headline that shows the copy for the current member |
| `board Query` (default layout) | a **responsive table** over the query's entity — every field except `id` becomes a column, with humanized labels and an empty state |
| `board Query { layout dual_hands columns N }` | a card grid (game layout) |
| a dispatched action with user-supplied inputs | a **form**: `string`→text, `int`→number, `bool`→checkbox, `enum`→select, `ref(E)`→select over `E`'s rows. Runtime-injected inputs never appear; a create-action's `id` is auto-filled; a `set`-action's `id` renders as a row selector |
| a dispatched action with no user inputs | a plain button (`primary` or secondary) |
| `button ... when <entity>.<field> == '<member>'` | declarative visibility, evaluated against the singleton row |

Forms never use native `required` attributes — your constraints are the validation, and rejection messages come from the `.ml`. Full derivation rules live in the repo's `spec/target-web/UI_SCHEMA.md`.

## Theming from the `.ml`

A `theme` block overrides the app's `--ml-*` design tokens — the emitter appends a sorted `:root { ... }` block to the generated CSS. No theme block means byte-identical default output.

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

Web-mappable keys: `palette.{accent, border, danger, danger_text, focus_ring, primary, primary_text, success, surface, surface_raised, text, text_muted, warning}` and `font.family`. Anything else — including the game-host-only `cell`/`window` sections — fails the compile with a message naming the key and the supported set.

**Accessibility is a compile gate, not a lint:** the effective light palette must keep every text-on-surface pair (`text`/`surface`, `text`/`surface_raised`, `text_muted`/`surface`, `primary_text`/`primary`, `danger_text`/`danger`) at **≥ 4.5:1** (WCAG 2.1 AA). A failing palette fails the compile and reports the measured ratio. You cannot ship an unreadable theme.

## Figma tokens import

Designers keep working in Figma; the toolchain imports the tokens:

```bash
ml1 design tokens export.json --apply my-app.ml   # idempotent splice
make compile
```

Accepted exports: Figma Variables (native), Tokens Studio, and plain W3C design-tokens JSON. The importer maps token names onto the theme vocabulary (lowercase, non-alphanumerics → `_`, longest name suffix wins) through an alias table:

| Figma name contains | Maps to |
|---|---|
| `brand` | `primary` |
| `background`, `bg` | `surface` |
| `foreground`, `fg` | `text` |
| `muted` | `text_muted` |
| `error` | `danger` |
| `on_primary`, `primary_foreground` | `primary_text` |
| `card`, `elevated` | `surface_raised` |
| `ring`, `focus` | `focus_ring` |
| `divider`, `outline`, `stroke` | `border` |
| `positive` | `success` |

Colors land as lowercase `#rrggbb`; `{alias}` references resolve inside the export (cycles are rejected); the first family of a `fontFamily` stack becomes `font.family`. Unmapped tokens are reported as `note:` lines, never errors. The compile gate (vocabulary + AA contrast) still decides what ships — the importer only shapes data. Without `--apply`, the block prints to stdout.

## Skins: pixel-perfect components

When tokens aren't enough, a **skin** replaces how one widget key renders — without touching generated code. A skin is a registry override, typically adapted from a Figma Make component export:

- One skin per widget key at `app/skins/<widget-key>.tsx` (≤ 50 lines; client halves and helpers in sibling files). Keys: `heading`, `text`, `hint`, `status_badge`, `headline`, `table`, `card_grid`, `form`, `primary_action`, `secondary_action`, `tap_target`, `empty_state`.
- Registered in `seed.ts`: `bindRegistryOverrides({ table: TableSkin })`. Unregistered keys keep the curated default.
- Adapting an export means **deleting three things**: its data fetching and local data state (rows arrive in `deps.viewModels[node.query]`), its hardcoded copy (the schema node carries all text from the `.ml`), and its literal colors (style with token classes like `bg-surface-raised` / `text-ink`; recolor via the `theme` block).

A mechanical lint enforces the contract (`node scripts/lint-skins.mjs app/skins`, part of `make test` and the deploy workflow). It rejects, per `file:line`: hardcoded JSX copy, color literals (`#hex`, `rgb(`, `text-[#...]`), forbidden APIs (`fetch(`, `Date.now`, `Math.random`, `new Date(`, `toLocale*`), and adapter imports. Deliberate exceptions use `// skin-lint-allow: <rule>` on the line. The full recipe, including a worked Figma-Make-table example, is in the repo's `spec/target-web/SKIN_GUIDE.md`; see also the [cookbook recipe](cookbook/index.md#swap-a-widget-with-a-skin).

## Reviewing UI: wireframes and previews

UI review happens on **projections**, not on generated code:

- **Wireframes.** Every compile emits one ASCII wireframe per screen at `generated/ui/wire/<screen>.txt`, at mobile (40 cols) and desktop (80 cols) widths, rendered from the same schema the app renders — wireframe and UI cannot disagree. A PR that changes a screen shows the change as a plain text diff; reviewers see the before/after layout without running anything.
- **Screen previews.** The e2e suite captures rendered screenshots of every screen at mobile (390×844) and desktop (1280×800) viewports; CI uploads them as the `screen-previews` artifact. Locally: `make preview` in a scaffolded app.

Wireframes are projections, never sources — `--check` mode covers them like all generated output, so they can't drift. See [Read a PR](cookbook/index.md#read-a-pr-wire-diff--previews) for the review workflow.

## Accessibility guarantees

- **Contrast** — themed palettes are AA-gated at compile time (above).
- **Automated scans** — the e2e suite runs axe (`@axe-core/playwright`) against WCAG 2.A/AA and 2.1 A/AA rule sets with **zero serious or critical findings** allowed; the scans cover skinned apps too.
- **Keyboard** — the e2e suite includes a keyboard-only journey; generated controls are focusable and operable without a pointer.
- **Structure** — schemas carry derived a11y labels for screens, tables, and forms; the runtime renders semantic landmarks and labels from them.

## Responsive behavior

Generated screens are mobile-first: tables render responsively, forms stack, and the two wireframe widths (40/80 cols) plus the two preview viewports give you the small- and large-screen story of every change in review. There is a compressed-JS budget (≤ 120 KB) enforced by the e2e suite, which keeps the app light on slow connections.

## Today vs. roadmap (bundle v5)

Everything above is available **now**. The following are planned for **bundle v5** and are **not yet available** — don't try to use them; the validator will reject the vocabulary:

- **Presentation layouts**: `feed`, `cards`, and `list` query renderings with declarative field→slot mapping (title, subtitle, meta...), alongside today's `table`.
- **Per-row action bindings** — inline row actions on collections.
- **Display metadata** — label fields and formatting hints.
- **Web asset pipeline** — content-addressed images for web apps.

Until v5 lands, the levers for a distinctive UI are: the `theme` block (colors/typography), skins (per-widget rendering), and screen composition in the `.ml`. New vocabulary always ships as a new, full, versioned bundle — existing programs keep compiling unchanged.
