---
title: Home
nav_order: 1
---

# MinLang

**One `.ml` file compiles into a complete, tested, deterministic web app.**

You write a single declarative file — entities, rules, mutations, queries, screens, copy, and tests. The `ml1` compiler turns it into a full Next.js application: typed domain code, pure reducers, server actions, screens, and a Vitest suite proving every rule. You never write React for domain features, and you never edit generated code.

```text
my-app.ml ──── ml1 validate ────────► zero violations (the language gate)
   │
   │  ml1 compile --target web
   ▼
app/generated/ ─────────────────────► domain types · pure reducers · queries ·
   │                                  screen schemas · server actions ·
   │                                  Vitest tests · ASCII wireframes
   │  rendered by
   ▼
@minlang/runtime-web + a thin shell ► the running app (Next.js)
```

## Who it's for

- **Developers** who want the business rules of a small web app in one reviewable file, with the UI and tests derived mechanically from it.
- **Teams using AI coding agents.** MinLang was built so agents can author whole applications safely: the language is small, every rule is machine-checkable, and the published [language bundle](https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md) tells an agent everything it needs.
- **Reviewers** who would rather diff an ASCII wireframe and a one-page rule file than a React tree.

## What a program looks like

This is real MinLang from the [task tracker example](cookbook/task-tracker.md) — a screen, the query it shows, and the action its primary button dispatches:

```text
screen Projects {
	when workspace.view == 'projects'
	title "Projects"
	body "Every task belongs to a project."
	board ProjectList
	primary { label "Add project" action CreateProject }
	button { label "Back to board" action OpenBoard }
}

query ProjectList(workspace: ref(Workspace)) -> list<Project> {
	from Project
}

action CreateProject(id: string, name: string, actor_id: string) {
	on: Project
	create(Project, { id: id, name: name })
}
```

The compiler also emits an ASCII **wireframe projection** of every screen, so a pull request shows UI changes as a plain text diff. Here is the generated wireframe for that screen (mobile width):

```text
┌──────────────────────────────────────┐
│ Projects                             │
├──────────────────────────────────────┤
│ Every task belongs to a project.     │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Name                             │ │
│ ├──────────────────────────────────┤ │
│ │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌ Create project ──────────────────┐ │
│ │ Name: ________                   │ │
│ │ [ Add project ]                  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌ Open board ──────────────────────┐ │
│ │ Workspace: ________              │ │
│ │ [ Back to board ]                │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

## Where to go

| Page | What you'll find |
|------|------------------|
| [Getting started](getting-started.md) | Install `ml1`, scaffold an app, compile, test, run, deploy to Vercel. |
| [Thinking in MinLang](thinking-in-minlang.md) | The mental shift: declare the program instead of implementing it. What that buys and what it costs. |
| [Language reference](language-reference.md) | The full human-readable reference for bundle v4: entities, constraints, actions, queries, screens, themes, tests, and all 27 validator detectors. |
| [Style guide](style-guide.md) | Authoring patterns that keep the validator happy on the first pass. |
| [UI & UX](ui-ux.md) | How screens become widgets, theming, Figma import, skins, wireframe review, accessibility. |
| [CLI reference](cli.md) | Every `ml1` command and flag. |
| [Cookbook](cookbook/index.md) | Recipes plus three complete programs: a [guestbook](cookbook/guestbook.md), the [task tracker](cookbook/task-tracker.md), and a [sales CRM](cookbook/crm-pipeline.md). |

## The canonical rules

This site is a human-friendly derivative. The single source of truth for the language is the versioned **language bundle** attached to every release — give it to any LLM that writes MinLang for you:

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

If anything on this site disagrees with the bundle, the bundle wins.
