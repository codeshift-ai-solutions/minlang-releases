---
title: "Sample: Guestbook"
parent: Cookbook
nav_order: 1
---

# Guestbook — the smallest useful app

A complete MinLang program: visitors sign a guestbook with a name and a message, each name signs once, entries show on one screen. This is the shape to start from when you build anything new.

The listing below is **validator-clean as of bundle v4** (`ml1 validate` → `validation ok`). Raw file: [samples/guestbook.ml](samples/guestbook.ml).

```text
entity Guestbook {
	id: string req
	view: enum(entries)
}

entity Visitor {
	id: string req
	name: string
	note: string
	created_at: string
}

constraint VisitorNameRequired {
	on: Visitor
	validate: NOT(self.name == '')
	message: 'name is required'
}

constraint VisitorMessageRequired {
	on: Visitor
	validate: NOT(self.note == '')
	message: 'message is required'
}

constraint UniqueVisitorName {
	on: Visitor
	validate: count(Visitor as v, v.name == name) == 0
	message: 'this name has already signed the guestbook'
}

action SignGuestbook(id: string, name: string, note: string, created_at: string, actor_id: string) {
	on: Visitor
	create(Visitor, { id: id, name: name, note: note, created_at: created_at })
}

query EntryList(guestbook: ref(Guestbook)) -> list<Visitor> {
	from Visitor
}

screen Entries {
	when guestbook.view == 'entries'
	title "Guestbook"
	hint "Sign once with your name and a short message."
	board EntryList
	primary { label "Sign the guestbook" action SignGuestbook }
}

test SignGuestbookSucceeds {
	setup: [
		create(Guestbook, { id: "g1", view: "entries" })
	]
	when: SignGuestbook on Visitor { id: "v1", name: "Ada", note: "Hello from the analytical engine." }
	then: [
		entity_count(Visitor) == 1,
		entity_has(Visitor.1, name == "Ada")
	]
}

test VisitorNameRequiredRejectsEmpty {
	setup: [
		create(Guestbook, { id: "g1", view: "entries" })
	]
	when: SignGuestbook on Visitor { id: "v1", name: "", note: "Hello." }
	then: [
		error_raised('name is required'),
		entity_count(Visitor) == 0
	]
}

test VisitorMessageRequiredRejectsEmpty {
	setup: [
		create(Guestbook, { id: "g1", view: "entries" })
	]
	when: SignGuestbook on Visitor { id: "v1", name: "Ada", note: "" }
	then: [
		error_raised('message is required'),
		entity_count(Visitor) == 0
	]
}

test UniqueVisitorNameRejectsDuplicate {
	setup: [
		create(Guestbook, { id: "g1", view: "entries" }),
		create(Visitor, { id: "v0", name: "Ada", note: "First!", created_at: "2026-01-01T00:00:00Z" })
	]
	when: SignGuestbook on Visitor { id: "v1", name: "Ada", note: "Hello again." }
	then: [
		error_raised('this name has already signed the guestbook'),
		entity_count(Visitor) == 1
	]
}
```

## Why it's shaped this way

**The flow entity exists even with one screen.** `Guestbook` with `view: enum(entries)` looks redundant, but `when` needs an entity to select on, and the shell seeds its one row. When you add a second screen later, you extend the enum instead of restructuring.

**`Visitor` is create-only — so uniqueness is allowed.** There is no `set`-action on `Visitor`, which is exactly what permits `UniqueVisitorName` to compare the *input* `name` with the proactive `== 0` boundary. If you ever add an "edit message" action, the constraint set must change (see [the style guide](../style-guide.md) on the D3/D4/D7 interplay).

**Inputs split themselves into form fields and injected values.** On `SignGuestbook`, the user types `name` and `note`; `id` is a fresh id filled at the server boundary; `created_at` and `actor_id` are runtime-injected by name and never appear in the form. Note `actor_id` is accepted but not stored — declaring it documents the call contract even when the entity doesn't keep it.

**One success test covers all three constraints' happy path**, because they guard the same write path. Each failure test carries the byte-exact `error_raised(...)` message **and** the state-unchanged assertion (`entity_count(Visitor) == 0`, or `== 1` for the duplicate case where the original row must survive). That's the full triad for every rule — D11 satisfied.

**What the screen becomes:** a heading, the hint, a table of visitors (columns `Name`, `Note`, `Created at` — `id` is the row key, not a column), and one "Sign the guestbook" form with two text inputs. Compile it yourself to see the wireframe:

```bash
ml1 compile guestbook.ml --target web --out app
cat app/generated/ui/wire/entries.txt
```

## Try it

```bash
npm create minlang-app guestbook
cd guestbook
# replace guestbook.ml with the listing above
make compile && pnpm --dir app install && make test && make dev
```
