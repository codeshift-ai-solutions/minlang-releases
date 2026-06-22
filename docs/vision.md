---
title: Vision
nav_order: 2
---

# MinLang Vision

> **About this page.** This page describes the direction and long-term purpose of MinLang. The **shipping language today** is bundle v7 — a deterministic, constraint-first language that compiles to C#/Godot and TypeScript/React web apps. The broader constructs shown here (`app`, `crud`, `workflow`, `dashboard`, `target`, domain packs, etc.) are **aspirational and not yet available**. All such examples are labeled **(future)** or **(illustrative)**. The bundle is the single source of truth for what you can use today: [minlang-language-bundle.md](https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md).

---

MinLang is an AI-first programming language and software generation system designed to make software dramatically cheaper, faster, smaller, and more reliable to build with large language models.

Traditional programming languages were designed primarily for humans and compilers. MinLang is designed for a new development reality: software is increasingly described, generated, reviewed, tested, and modified by AI systems working alongside humans.

The core purpose of MinLang is simple:

> MinLang turns compact human intent into complete, testable, production-grade software.

MinLang is not merely a shorter syntax for existing languages. It is a higher-level software description layer that captures the recurring patterns of real applications — entities, behaviors, screens, workflows, data models, integrations, tests, game systems, simulations, and deployment structures — in a form that both humans and AI agents can read, reason about, transform, and compile.

---

## The Problem MinLang Solves

Modern AI coding is powerful, but inefficient.

Large language models can generate enormous amounts of code, but code-heavy workflows create serious problems:

1. **Token waste.** Mainstream programming languages require large amounts of boilerplate, ceremony, repeated type declarations, framework wiring, folder structure, and glue code. AI systems must read and write all of that.
2. **Context overload.** As projects grow, models run out of context. Important architecture decisions, domain rules, and implementation details get scattered across many files.
3. **Hallucinated architecture.** When a model is asked to generate a large application directly in a general-purpose language, it often invents inconsistent abstractions, misuses frameworks, or forgets earlier decisions.
4. **Fragile iteration.** Small requirement changes can force large edits across many files.
5. **Poor reuse of domain knowledge.** Most applications repeat known patterns: CRUD, forms, permissions, save systems, inventory systems, APIs, validation, workflows, dashboards, queues, tests, deployment, observability, and integrations.

MinLang addresses these problems by giving AI and humans a higher-level language for describing software intent. Instead of asking an AI model to repeatedly generate thousands of lines of framework code, MinLang lets the project describe what the system *is*, what it *must do*, and which platform it should target.

---

## The Core Idea

MinLang is based on a simple observation:

> Most software contains far more implementation detail than decision detail.

A business app, game system, simulation, or workflow may contain thousands of lines of code, but the actual human intent behind that code is often much smaller.

**What MinLang looks like today** (shipping, v7):

```minlang
entity Patient {
	id: id
	mrn: string req
	status: enum(active, inactive) req
}

constraint PatientActive {
	on: Patient
	validate: NOT(self.status == 'inactive')
	message: 'patient must be active'
}

action CreatePatient(id: string, mrn: string, status: enum(active, inactive),
                     created_at: string, actor_id: string) {
	on: Patient
	create(Patient, { id: id, mrn: mrn, status: status,
	                  created_at: created_at, actor_id: actor_id })
}
```

**What future MinLang might look like** (illustrative, not available today):

```text
# ILLUSTRATIVE — NOT CURRENT SYNTAX
entity Patient
  name required text
  dateOfBirth required date
  phone optional phone

crud Patient
  permissions clinicStaff
  audit all changes
```

MinLang is therefore a compression layer between human intent and executable systems — and that compression gets stronger as domain packs and higher-level constructs are added over time.

---

## What MinLang Is (Today)

MinLang today is:

- A deterministic, constraint-first modeling language for entities, rules, actions, queries, screens, and tests.
- A code generation system that compiles `.ml` source to C#/Godot 4 and TypeScript/React/Tailwind web apps.
- A strict validator (49 detectors, reject-first) that enforces correct-by-construction invariants before any code is generated.
- A module system (v6) with package manifests, lockfiles, and closed compile-graph enforcement.
- Unified trigger/schedule surfaces (v7) for server-only API orchestration from UI controls and scheduled jobs.
- A toolchain (`ml1`) with project graph, incremental compilation, LLM sidecars, agent index, and design bridge commands.
- A CLI-to-screen bridge (`ml1 design ui`) that turns structured ASCII UI sketches into MinLang `screen` declarations.
- A published language bundle (canonical rules + detectors + authoring guide) at a stable URL, designed for LLM consumption.

**What MinLang is not today:** a general-purpose language, a no-code builder, or a system that covers every application domain without custom shell code. The gap between today and the vision is tracked in every scaffolded app's `MINLANG_LANGUAGE_SUPPORT.md`.

---

## The Vision

### Radical compression of software creation

MinLang's long-term ambition is to achieve radical compression in several dimensions:

**Token compression.** MinLang should reduce the number of tokens required to describe, generate, modify, and review software. AI development cost is heavily affected by input and output tokens. A language that expresses software intent in 5×, 10×, 20×, or even 50× fewer tokens changes the economics of AI-assisted software.

**Context compression.** A model should not need to read dozens of generated files to understand a project. It should be able to inspect the MinLang source and know the intended structure of the system.

**Architectural compression.** MinLang should encode common architectural decisions directly into reusable constructs. Common patterns — CRUD, workflows, dashboards, game systems, simulations — should not need to be reinvented on each project.

**Maintenance compression.** When requirements change, the source of truth changes in one compact place. Generated code is regenerated, migrated, or patched consistently.

**Cognitive compression.** Humans should be able to understand the purpose of a system faster. The important parts should be obvious; repetitive implementation detail should move into the toolchain.

### The 50× ambition

MinLang's long-term ambition is to make some categories of software up to 50× smaller to describe than their conventional implementation.

The realistic expectation is nuanced:

- Simple boilerplate-heavy features may compress dramatically.
- Domain-pack features (healthcare records, inventory, game save systems) may compress by large factors.
- Custom algorithms and novel logic compress less.
- Complex edge cases still require explicit detail.

MinLang should make the common case radically cheaper without pretending complexity disappears.

---

## Design Principles

### Intent First

MinLang should prioritize what the system *means* over how the target platform implements it. The language should capture decisions, not boilerplate.

### Human-Readable

MinLang must remain readable by humans. A developer, founder, designer, or domain expert should be able to inspect a MinLang file and understand the purpose of the system.

### AI-Native

MinLang should be easy for AI agents to generate, modify, diff, validate, and reason about. The syntax should avoid unnecessary noise. The semantics should be explicit. Common patterns should have stable representations.

### Deterministic Expansion

MinLang generation should be predictable. The same MinLang source, compiler version, and target settings should produce the same output. AI may help write the MinLang; the MinLang toolchain makes the output reliable.

### Strong Defaults, Easy Overrides

Simple things should be extremely small to express. Complex things should be expressible by progressively adding detail.

### Domain Packs Over One-Off Code

Reusable expertise should live in domain packs. A healthcare app, Godot game, banking workflow, physics simulation, or inventory system should not require the AI to reinvent architecture every time.

### Generated Code Must Be Inspectable

MinLang should not hide the output. Generated code should be readable, testable, and compatible with normal development workflows.

### Tests Are First-Class

MinLang should generate tests, not just implementation code. This is already the case today (test triads are enforced by the validator).

### Multiple Targets

MinLang should support multiple targets over time: games, web apps, business systems, APIs, simulations, workflows, and platform-specific runtimes. Today: Godot 4 and web.

### Source of Truth

The MinLang source should be the canonical project representation. Generated code is output, not the primary design artifact.

---

## Core Components (Vision)

MinLang is not just syntax. It is a full system. Today's components are implemented; future components are described as direction.

| Component | Status |
|---|---|
| Surface language (entities, constraints, actions, tests) | **Shipping** |
| Module system (v6: package/module/import/export, manifests, lockfiles) | **Shipping** |
| Web target (Next.js/React/TypeScript/Zod, full-app declarations) | **Shipping** |
| Godot 4 target (C#, game primitives) | **Shipping** |
| ASCII UI design bridge (`ml1 design ui`) | **Shipping** |
| Figma/Tokens Studio design bridge (`ml1 design tokens`) | **Shipping** |
| LLM tooling (sidecars, `.mlai` index, explain, refactor) | **Shipping** |
| Domain packs (healthcare, finance, game systems, etc.) | **Future** |
| Higher-level abstractions (`crud`, `workflow`, `dashboard`) | **Future** |
| Additional targets (mobile, backend APIs, cloud deployment) | **Future** |
| Agent workflow integrations | **Partially shipping, evolving** |

### Domain Packs (illustrative, future)

Domain packs encode reusable knowledge for specific kinds of software. The following examples show *what this might look like* — **not current syntax**:

```text
# ILLUSTRATIVE — NOT CURRENT SYNTAX
business.crud Patient
healthcare.fhir PatientSync
godot.ecs ParadeUnit
game.inventory LootSystem
simulation.economy EconomyModel
workflow.messaging AppointmentReminder
```

Each pack turns compact declarations into known-good, consistent, tested software structures.

---

## Example: From Intent to System (Illustrative)

> **Note:** The following example uses *aspirational vocabulary* that is not available in the shipping language. It is shown to communicate direction.

A future MinLang file might say:

```text
# ILLUSTRATIVE — NOT CURRENT SYNTAX
app ClinicAssistant
target web.fastapi
target ui.react

entity Patient
  name required text
  dateOfBirth required date
  preferredLanguage optional text

entity Conversation
  patient Patient
  startedAt datetime
  summary text
  status enum active, completed, escalated

workflow InboundCall
  receive call
  identify patient
  capture reason
  summarize conversation
  escalate if urgent
  store Conversation

dashboard ClinicOverview
  show active conversations
  show escalated conversations
```

**What MinLang *does* today** for the domain-modeling portion of this:

```minlang
entity Patient {
	id: id
	name: string req
	date_of_birth: string req
	preferred_language: string
}

entity Conversation {
	id: id
	patient: ref(Patient) req
	started_at: string req
	status: enum(active, completed, escalated) req
}

constraint EscalationRequiresPatient {
	on: Conversation
	validate: NOT(self.status == 'escalated' AND count(Patient as p, p == self.patient) == 0)
	message: 'escalated conversation must have a patient'
}
```

---

## The Human and AI Roles

**MinLang does not remove humans from software development.** It changes what humans focus on:

- What should the system do?
- What are the domain rules?
- What are the edge cases?
- What should be safe, private, audited, or reversible?
- What should be generated by default vs. customized?

**AI agents are central to MinLang.** A good AI agent should be able to:

1. Turn a user request into MinLang.
2. Validate the MinLang against project rules.
3. Ask clarifying questions only when necessary.
4. Generate or update the target code.
5. Run tests.
6. Interpret errors.
7. Patch the MinLang source or generated output.
8. Explain the change in human terms.
9. Preserve the architecture over time.

MinLang gives AI agents a safer, smaller, more structured object to operate on — instead of asking an agent to modify a sprawling codebase directly, the agent modifies the MinLang source and lets the compiler regenerate the correct implementation.

---

## The Compiler Contract

A MinLang compiler provides a stable contract:

Given MinLang source + compiler version + target generator, the compiler produces predictable output. AI may help write the MinLang; the compiler makes the output reliable.

This is already enforced today: same `.ml` + same `ml1` version = byte-identical output. The validator gate (reject-first, 49 detectors) means a program either compiles clean or produces an actionable diagnostic — there is no "close enough" output.

---

## Safety and Trust

MinLang is designed with trust in mind. Because it may generate large amounts of code, it supports:

- Transparent output (generated code is committed, readable, diffable)
- Deterministic builds (same source = same output, always)
- Test generation (test triads enforced by the validator)
- Validation errors with exact diagnostics (no silent failures)
- Explicit determinism constraints (no `now()`, `today()`, `random()`, `current_user`)
- Audit artifacts (`.mlai` index, explain reports, support briefs)

AI-generated software is only useful if people can trust it. MinLang makes that trust easier to earn.

---

## The Long-Term Vision

The long-term vision for MinLang is a complete AI-native software creation platform.

A user should be able to describe a product, game, workflow, simulation, or business system in ordinary language. An AI agent should translate that into MinLang. MinLang should become the durable source of truth. The compiler and generators should produce the working system. Tests and documentation should be generated alongside the implementation. Future changes should happen by modifying the MinLang source.

The workflow becomes:

1. Describe intent.
2. Convert intent to MinLang.
3. Validate the semantic model.
4. Generate the target implementation.
5. Run tests.
6. Inspect results.
7. Refine the MinLang.
8. Repeat.

**MinLang is a language for the next phase of software development:** compact enough for humans, structured enough for compilers, and semantic enough for AI.

---

## Where MinLang Is Today

| Capability | Status |
|---|---|
| Entities, constraints, actions, queries, tests | Shipping (v1+) |
| Screens, derive queries | Shipping (v3+) |
| Deal step, extended screens, scoring derives | Shipping (v4+) |
| Full-app web declarations (secret, config, service, pipeline, prompt, schema, effect) | Shipping (v5+) |
| Multi-file modules, package manifests, lockfiles, compile graph | Shipping (v6) |
| Unified trigger + schedule surfaces | Shipping (v7) |
| ASCII UI design bridge (`ml1 design ui`) | Shipping (v0.6.4) |
| LLM toolchain (sidecars, index, explain, refactor, AI-safe agents) | Shipping (v6) |
| Domain packs | Not yet shipped |
| Higher-level constructs (`crud`, `workflow`, `dashboard`) | Not yet shipped |
| Additional targets beyond Godot + web | Not yet shipped |

The canonical rules for what works today:

```text
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```
