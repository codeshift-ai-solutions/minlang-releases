# minlang-releases

Public distribution mirror for the `ml1` MinLang compiler: prebuilt
binaries (Releases), one-line install scripts (`install/`), the
`setup-ml1` / `minlang-compile` GitHub Actions (`.github/actions/`),
and the MinLang **language bundle** for LLMs (attached to every
release). Source lives in the private `minlang-core` repository.
License for the distributed runtime packages: MIT.

## Documentation

Guides, the language reference, and the cookbook: https://codeshift-ai-solutions.github.io/minlang-releases/
(served from this repository's `docs/` directory via GitHub Pages).

## Install ml1

| Channel | Command |
|---------|---------|
| Shell (macOS/Linux) | `bash <(curl -fsSL https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.sh)` |
| PowerShell (Windows) | `iwr -useb https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.ps1 \| iex` |
| GitHub Actions (CI) | `uses: codeshift-ai-solutions/minlang-releases/.github/actions/setup-ml1@main` |

## Language rules for LLMs (stable URL)

```
https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
```

## Start development with an AI coding agent

Paste this prompt into any LLM coding agent (Claude Code, Cursor,
Copilot, Windsurf, Kilo Code, ...) to set everything up and begin:

```text
Set up a new MinLang web app and get it running, then ask me what to build.

1. Install the MinLang compiler (ml1):
   macOS/Linux: bash <(curl -fsSL https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.sh)
   Windows PowerShell: iwr -useb https://raw.githubusercontent.com/codeshift-ai-solutions/minlang-releases/main/install/install.ps1 | iex
   Verify with: ml1 --help. Also ensure Node 22+, then run:
   corepack enable && corepack prepare pnpm@10.33.0 --activate

2. Scaffold the app (replace my-app with a short kebab-case name):
   npm create minlang-app my-app && cd my-app
   The ENTIRE application is my-app.ml. Everything under app/generated/ is
   compiler output: committed, never hand-edited.

3. Download and read the MinLang language rules before writing any MinLang:
   https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md
   Follow them exactly: generate -> validate -> fix -> revalidate until zero
   violations. Never use now(), today(), random(), or current_user.

4. Prove the toolchain end to end with the starter program:
   make compile && pnpm --dir app install && make test && make dev
   The app serves at http://localhost:3111.

5. Read AGENTS.md in the scaffolded repo and follow it for every change.
   Then ask me to describe the app I want, rewrite my-app.ml to model it
   (entities, constraints, actions, queries, screens, tests), and repeat
   make compile && make test until green. Show me the running app.
```
