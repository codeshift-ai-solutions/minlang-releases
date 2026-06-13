---
title: "Sample: Task tracker"
parent: Cookbook
nav_order: 2
---

# Task tracker — the reference example, annotated

This is the real reference program that ships with the toolchain (`examples/task-tracker/task-tracker.ml` in the source repository, and the starter program every scaffolded app begins with). It is quoted here in full, section by section, with the reasoning behind each part — and the wireframes the compiler generates from it.

## Entities

```text
entity Workspace {
	id: string req
	view: enum(board, projects)
}

entity Project {
	id: string req
	name: string
}

entity Task {
	id: string req
	project: ref(Project)
	title: string
	status: enum(todo, doing, done)
	assignee: string
	created_at: string
	actor_id: string
}
```

`Workspace` is the singleton flow entity — one enum member per screen. `Project` is deliberately **create-only** (no `set`-actions later), which is what makes its uniqueness constraint legal. `Task` is the mutable workhorse: a `ref` to its project, an enum status, and two runtime-injected bookkeeping fields (`created_at`, `actor_id`) stored on the row.

## Constraints

```text
constraint TitleRequired {
	on: Task
	validate: NOT(self.title == '')
	message: 'title is required'
}

constraint AssigneeRequiredWhenDoing {
	on: Task
	validate: NOT(self.status == 'doing' AND self.assignee == '')
	message: 'assignee is required when a task is doing'
}

constraint ProjectExists {
	on: Task
	validate: count(Project as p, p == self.project) == 1
	message: 'project does not exist'
}

constraint ProjectNameRequired {
	on: Project
	validate: NOT(self.name == '')
	message: 'project name is required'
}

constraint UniqueProjectName {
	on: Project
	validate: count(Project as p, p.name == name) == 0
	message: 'a project with this name already exists'
}
```

Every pattern from the [style guide](../style-guide.md) appears once:

- `TitleRequired` / `AssigneeRequiredWhenDoing` — `self.`-bound `NOT(invalid state)` forms, valid on a mutable entity. The second one is a *conditional* requirement: it guards both creating a `doing` task without an assignee and *moving* a task to `doing` without one — same constraint, all paths.
- `ProjectExists` — referential integrity via a whole-reference count join (`p == self.project`, never `p.id == ...`).
- `UniqueProjectName` — input-bound uniqueness with the `== 0` boundary, allowed because `Project` is create-only.

## Actions

```text
action CreateProject(id: string, name: string, actor_id: string) {
	on: Project
	create(Project, { id: id, name: name })
}

action CreateTask(id: string, project: ref(Project), title: string, status: enum(todo, doing, done), assignee: string, created_at: string, actor_id: string) {
	on: Task
	create(Task, { id: id, project: project, title: title, status: status, assignee: assignee, created_at: created_at, actor_id: actor_id })
}

action MoveTask(id: string, status: enum(todo, doing, done), actor_id: string) {
	on: Task
	set(status, status)
}

action RenameTask(id: string, title: string, actor_id: string) {
	on: Task
	set(title, title)
}

action OpenProjects(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'projects')
}

action OpenBoard(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'board')
}
```

Pure mutation only — not an `if` in sight. Note the `id` semantics: on `CreateTask` it's a fresh id (auto-filled, hidden); on `MoveTask`/`RenameTask` it *selects the row*, so those forms render with a task picker. `OpenProjects`/`OpenBoard` are the navigation pattern: a `set` on the flow entity.

## Queries and screens

```text
query TaskBoard(workspace: ref(Workspace)) -> list<Task> {
	from Task
}

query ProjectList(workspace: ref(Workspace)) -> list<Project> {
	from Project
}

query TaskDetail(task: ref(Task)) -> Task {
	from Task
}

screen Board {
	when workspace.view == 'board'
	title "Task board"
	hint "Create tasks, move them between statuses, and rename them."
	board TaskBoard
	primary { label "Add task" action CreateTask }
	button { label "Move task" action MoveTask }
	button { label "Rename task" action RenameTask }
	button { label "Projects" action OpenProjects }
}

screen Projects {
	when workspace.view == 'projects'
	title "Projects"
	body "Every task belongs to a project."
	board ProjectList
	primary { label "Add project" action CreateProject }
	button { label "Back to board" action OpenBoard }
}
```

Each screen is: an activation condition, copy, one collection, and the actions it dispatches. Every action with user inputs becomes a form; the dispatching control's label becomes the submit label ("Add task", "Move task", ...). All copy is static string literals — the compiler never invents text.

## Tests

```text
test CreateTaskSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" })
	]
	when: CreateTask on Task { id: "t1", project: "p1", title: "Ship the compiler", status: "todo", assignee: "" }
	then: [
		entity_count(Task) == 1,
		entity_has(Task.1, title == "Ship the compiler")
	]
}

test TitleRequiredRejectsEmpty {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" })
	]
	when: CreateTask on Task { id: "t1", project: "p1", title: "", status: "todo", assignee: "" }
	then: [
		error_raised('title is required'),
		entity_count(Task) == 0
	]
}

test AssigneeRequiredWhenDoingRejects {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" })
	]
	when: CreateTask on Task { id: "t1", project: "p1", title: "Ship the compiler", status: "doing", assignee: "" }
	then: [
		error_raised('assignee is required when a task is doing'),
		entity_count(Task) == 0
	]
}

test ProjectExistsRejectsUnknown {
	setup: [
		create(Workspace, { id: "w1", view: "board" })
	]
	when: CreateTask on Task { id: "t1", project: "ghost", title: "Ship the compiler", status: "todo", assignee: "" }
	then: [
		error_raised('project does not exist'),
		entity_count(Task) == 0
	]
}

test MoveTaskSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" }),
		create(Task, { id: "t1", project: "p1", title: "Ship the compiler", status: "todo", assignee: "casey", created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveTask on Task { id: "t1", status: "doing" }
	then: [
		entity_has(Task.1, status == "doing"),
		entity_count(Task) == 1
	]
}

test MoveTaskRejectsDoingWithoutAssignee {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" }),
		create(Task, { id: "t1", project: "p1", title: "Ship the compiler", status: "todo", assignee: "", created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveTask on Task { id: "t1", status: "doing" }
	then: [
		error_raised('assignee is required when a task is doing'),
		entity_has(Task.1, status == "todo")
	]
}

test RenameTaskSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p1", name: "General" }),
		create(Task, { id: "t1", project: "p1", title: "Old name", status: "todo", assignee: "", created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: RenameTask on Task { id: "t1", title: "New name" }
	then: [
		entity_has(Task.1, title == "New name")
	]
}

test CreateProjectSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "board" })
	]
	when: CreateProject on Project { id: "p1", name: "Platform" }
	then: [
		entity_count(Project) == 1,
		entity_has(Project.1, name == "Platform")
	]
}

test ProjectNameRequiredRejectsEmpty {
	setup: [
		create(Workspace, { id: "w1", view: "board" })
	]
	when: CreateProject on Project { id: "p1", name: "" }
	then: [
		error_raised('project name is required'),
		entity_count(Project) == 0
	]
}

test UniqueProjectNameRejectsDuplicate {
	setup: [
		create(Workspace, { id: "w1", view: "board" }),
		create(Project, { id: "p0", name: "General" })
	]
	when: CreateProject on Project { id: "p1", name: "General" }
	then: [
		error_raised('a project with this name already exists'),
		entity_count(Project) == 1
	]
}

test OpenProjectsSwitchesView {
	setup: [
		create(Workspace, { id: "w1", view: "board" })
	]
	when: OpenProjects on Workspace { workspace: "w1" }
	then: [
		entity_has(Workspace.1, view == "projects")
	]
}
```

The triads to notice:

- `AssigneeRequiredWhenDoing` is tested on **both** write paths: rejected at create (`AssigneeRequiredWhenDoingRejects`) and rejected at `set` (`MoveTaskRejectsDoingWithoutAssignee`, whose state-unchanged assertion is `entity_has(Task.1, status == "todo")` — the move didn't happen). That second test is the lifecycle coverage detector D7 made concrete.
- Rejected creates assert `entity_count(...) == 0`; the rejected duplicate asserts `== 1` (the original row survives).
- Tests pass runtime-injected values (`created_at`, `actor_id`) as plain literals in `setup:` — that's all determinism asks.

## The wireframes

The compiler emits these from the screens above (`generated/ui/wire/board.txt` and `projects.txt`, mobile sections shown; each file also contains an 80-column desktop rendering):

```text
┌──────────────────────────────────────┐
│ Task board                           │
├──────────────────────────────────────┤
│ Create tasks, move them between      │
│ statuses, and rename them.           │
│                                      │
│ ┌─────┬─────┬─────┬─────┬─────┬────┐ │
│ │ Pro │ Tit │ Sta │ Ass │ Cre │ Ac │ │
│ ├─────┼─────┼─────┼─────┼─────┼────┤ │
│ │ ░░░ │ ░░░ │ ░░░ │ ░░░ │ ░░░ │ ░░ │ │
│ │ ░░░ │ ░░░ │ ░░░ │ ░░░ │ ░░░ │ ░░ │ │
│ └─────┴─────┴─────┴─────┴─────┴────┘ │
│                                      │
│ ┌ Create task ─────────────────────┐ │
│ │ Project: ________                │ │
│ │ Title: ________                  │ │
│ │ Status: ________                 │ │
│ │ Assignee: ________               │ │
│ │ [ Add task ]                     │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌ Move task ───────────────────────┐ │
│ │ Id: ________                     │ │
│ │ Status: ________                 │ │
│ │ [ Move task ]                    │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌ Rename task ─────────────────────┐ │
│ │ Id: ________                     │ │
│ │ Title: ________                  │ │
│ │ [ Rename task ]                  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌ Open projects ───────────────────┐ │
│ │ Workspace: ________              │ │
│ │ [ Projects ]                     │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

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

Read across: the `Create task` form has four visible fields — `id`, `created_at`, and `actor_id` from the action signature are absent, exactly as the input classification promises. The `Move task` form's `Id` field is the row selector. These text files are what a reviewer diffs when a PR changes a screen ([recipe](index.md#read-a-pr-wire-diff--previews)).

This program is the scaffold's starter — `npm create minlang-app my-app` gives you exactly this app running, ready to be rewritten into yours.
