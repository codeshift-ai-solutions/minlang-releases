entity Workspace {
	id: string req
	view: enum(pipeline, companies)
}

entity Company {
	id: string req
	name: string
}

entity Deal {
	id: string req
	company: ref(Company)
	title: string
	stage: enum(lead, qualified, won, lost)
	owner: string
	amount: int
	created_at: string
	actor_id: string
}

constraint CompanyNameRequired {
	on: Company
	validate: NOT(self.name == '')
	message: 'company name is required'
}

constraint UniqueCompanyName {
	on: Company
	validate: count(Company as c, c.name == name) == 0
	message: 'a company with this name already exists'
}

constraint DealTitleRequired {
	on: Deal
	validate: NOT(self.title == '')
	message: 'deal title is required'
}

constraint DealCompanyExists {
	on: Deal
	validate: count(Company as c, c == self.company) == 1
	message: 'company does not exist'
}

constraint DealOwnerRequiredWhenQualified {
	on: Deal
	validate: NOT(self.stage == 'qualified' AND self.owner == '')
	message: 'owner is required when a deal is qualified'
}

constraint DealOwnerRequiredWhenWon {
	on: Deal
	validate: NOT(self.stage == 'won' AND self.owner == '')
	message: 'owner is required when a deal is won'
}

action CreateCompany(id: string, name: string, actor_id: string) {
	on: Company
	create(Company, { id: id, name: name })
}

action CreateDeal(id: string, company: ref(Company), title: string, stage: enum(lead, qualified, won, lost), owner: string, amount: int, created_at: string, actor_id: string) {
	on: Deal
	create(Deal, { id: id, company: company, title: title, stage: stage, owner: owner, amount: amount, created_at: created_at, actor_id: actor_id })
}

action MoveDeal(id: string, stage: enum(lead, qualified, won, lost), actor_id: string) {
	on: Deal
	set(stage, stage)
}

action ReassignDeal(id: string, owner: string, actor_id: string) {
	on: Deal
	set(owner, owner)
}

action OpenCompanies(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'companies')
}

action OpenPipeline(workspace: ref(Workspace), actor_id: string) {
	on: Workspace
	set(view, 'pipeline')
}

query PipelineBoard(workspace: ref(Workspace)) -> list<Deal> {
	from Deal
}

query CompanyList(workspace: ref(Workspace)) -> list<Company> {
	from Company
}

screen Pipeline {
	when workspace.view == 'pipeline'
	title "Sales pipeline"
	hint "Create deals, move them through stages, and reassign owners."
	board PipelineBoard
	primary { label "Add deal" action CreateDeal }
	button { label "Move deal" action MoveDeal }
	button { label "Reassign deal" action ReassignDeal }
	button { label "Companies" action OpenCompanies }
}

screen Companies {
	when workspace.view == 'companies'
	title "Companies"
	body "Every deal belongs to a company."
	board CompanyList
	primary { label "Add company" action CreateCompany }
	button { label "Back to pipeline" action OpenPipeline }
}

test CreateCompanySucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" })
	]
	when: CreateCompany on Company { id: "c1", name: "Acme Corp" }
	then: [
		entity_count(Company) == 1,
		entity_has(Company.1, name == "Acme Corp")
	]
}

test CompanyNameRequiredRejectsEmpty {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" })
	]
	when: CreateCompany on Company { id: "c1", name: "" }
	then: [
		error_raised('company name is required'),
		entity_count(Company) == 0
	]
}

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

test CreateDealSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" })
	]
	when: CreateDeal on Deal { id: "d1", company: "c1", title: "Annual license", stage: "lead", owner: "", amount: 12000 }
	then: [
		entity_count(Deal) == 1,
		entity_has(Deal.1, title == "Annual license")
	]
}

test DealTitleRequiredRejectsEmpty {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" })
	]
	when: CreateDeal on Deal { id: "d1", company: "c1", title: "", stage: "lead", owner: "", amount: 12000 }
	then: [
		error_raised('deal title is required'),
		entity_count(Deal) == 0
	]
}

test DealCompanyExistsRejectsUnknown {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" })
	]
	when: CreateDeal on Deal { id: "d1", company: "ghost", title: "Annual license", stage: "lead", owner: "", amount: 12000 }
	then: [
		error_raised('company does not exist'),
		entity_count(Deal) == 0
	]
}

test DealOwnerRequiredWhenQualifiedRejectsCreate {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" })
	]
	when: CreateDeal on Deal { id: "d1", company: "c1", title: "Annual license", stage: "qualified", owner: "", amount: 12000 }
	then: [
		error_raised('owner is required when a deal is qualified'),
		entity_count(Deal) == 0
	]
}

test MoveDealSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" }),
		create(Deal, { id: "d1", company: "c1", title: "Annual license", stage: "lead", owner: "morgan", amount: 12000, created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveDeal on Deal { id: "d1", stage: "qualified" }
	then: [
		entity_has(Deal.1, stage == "qualified"),
		entity_count(Deal) == 1
	]
}

test MoveDealRejectsQualifiedWithoutOwner {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" }),
		create(Deal, { id: "d1", company: "c1", title: "Annual license", stage: "lead", owner: "", amount: 12000, created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveDeal on Deal { id: "d1", stage: "qualified" }
	then: [
		error_raised('owner is required when a deal is qualified'),
		entity_has(Deal.1, stage == "lead")
	]
}

test MoveDealRejectsWonWithoutOwner {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" }),
		create(Deal, { id: "d1", company: "c1", title: "Annual license", stage: "lead", owner: "", amount: 12000, created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveDeal on Deal { id: "d1", stage: "won" }
	then: [
		error_raised('owner is required when a deal is won'),
		entity_has(Deal.1, stage == "lead")
	]
}

test DealOwnerRequiredWhenWonSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" }),
		create(Deal, { id: "d1", company: "c1", title: "Annual license", stage: "qualified", owner: "morgan", amount: 12000, created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: MoveDeal on Deal { id: "d1", stage: "won" }
	then: [
		entity_has(Deal.1, stage == "won"),
		entity_count(Deal) == 1
	]
}

test ReassignDealSucceeds {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" }),
		create(Company, { id: "c1", name: "Acme Corp" }),
		create(Deal, { id: "d1", company: "c1", title: "Annual license", stage: "lead", owner: "morgan", amount: 12000, created_at: "2026-01-01T00:00:00Z", actor_id: "a1" })
	]
	when: ReassignDeal on Deal { id: "d1", owner: "casey" }
	then: [
		entity_has(Deal.1, owner == "casey")
	]
}

test OpenCompaniesSwitchesView {
	setup: [
		create(Workspace, { id: "w1", view: "pipeline" })
	]
	when: OpenCompanies on Workspace { workspace: "w1" }
	then: [
		entity_has(Workspace.1, view == "companies")
	]
}

test OpenPipelineSwitchesView {
	setup: [
		create(Workspace, { id: "w1", view: "companies" })
	]
	when: OpenPipeline on Workspace { workspace: "w1" }
	then: [
		entity_has(Workspace.1, view == "pipeline")
	]
}
