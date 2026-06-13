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
