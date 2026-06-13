---
nav_exclude: true
---

# MinLang documentation site (maintainers)

This directory is the **source of truth** for the public MinLang documentation site. It is plain Markdown with Jekyll front matter, rendered by GitHub Pages' built-in Jekyll using the `just-the-docs` remote theme (`_config.yml`) — there is no build tooling in this repo.

## How it publishes

The site is **not** served from this (private) repository. The release workflow's mirror step (`.github/workflows/release.yml`, "Mirror release to the public repo") copies `docs/site/.` into the public mirror's `docs/` directory on every release; GitHub Pages on the mirror (`codeshift-ai-solutions/minlang-releases`, Settings → Pages → Deploy from a branch → `main`, `/docs`) serves it at:

```text
https://codeshift-ai-solutions.github.io/minlang-releases/
```

Enabling Pages on the mirror is a one-time step — see the setup checklist in `packaging/README.md`.

## Authoring rules

- **Accuracy over polish.** Every page is a human-friendly *derivative* of the canonical materials (`docs/minlang_language_bundle_v4/`, `docs/ai/language/`, `spec/target-web/`). On any conflict the bundle wins and the page here must be fixed. Never describe unreleased vocabulary as available — mark it as roadmap.
- **Front matter on every page**: `title`, `nav_order` (and `parent` for nested pages). `nav_exclude: true` keeps a file out of the nav (like this one).
- **Inter-page links are relative Markdown links** (`getting-started.md`, `../style-guide.md`) — GitHub Pages' `jekyll-relative-links` resolves them. External links to install scripts, the language bundle, and the Actions must use `codeshift-ai-solutions/minlang-releases` URLs (the source repo is private; the mirror step's `sed` re-point is a safety net, not the mechanism).
- **Sample programs are real files** under `cookbook/samples/` and must stay validator-clean:

  ```bash
  cd compiler && cargo run -q -p minlang-cli -- validate ../docs/site/cookbook/samples/guestbook.ml
  cd compiler && cargo run -q -p minlang-cli -- validate ../docs/site/cookbook/samples/crm-pipeline.ml
  ```

  When a page inlines a sample, the page and the file must match. Revalidate after any language-affecting change and when a new bundle ships.
