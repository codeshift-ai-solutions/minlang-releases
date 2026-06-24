# MinLang Claude plugin

Claude Code plugin for authoring, migrating, refactoring, validating, and
release-checking MinLang applications.

## Commands

All commands are namespaced `/minlang:*`. See [COMMANDS.md](COMMANDS.md) and
`commands/commands.json` for the full inventory (23 commands across migration,
authoring, refactoring, diagnostics, and creative workflows).

## Published documentation

The public site documents this plugin command by command:

- Overview & install: <https://codeshift-ai-solutions.github.io/minlang-releases/claude-plugin/>
- Every command: <https://codeshift-ai-solutions.github.io/minlang-releases/claude-plugin/commands.html>
- Agents & tooling: <https://codeshift-ai-solutions.github.io/minlang-releases/claude-plugin/agents-and-tooling.html>
- `ml1` CLI reference: <https://codeshift-ai-solutions.github.io/minlang-releases/cli.html>

## Authority

Every producing command loads the **authority-preflight** skill and reads the
stable language bundle:

`https://github.com/codeshift-ai-solutions/minlang-releases/releases/latest/download/minlang-language-bundle.md`

## Components

| Directory | Purpose |
|-----------|---------|
| `commands/` | Slash command definitions |
| `skills/authority-preflight/` | Shared bundle and verification workflow |
| `agents/` | Optional creator, gatekeeper, migration architect agents |
| `hooks/` | Non-destructive post-edit `.ml` validation guard |
| `mcp/` | Optional local `ml1` MCP bridge (allowlisted commands) |

## Optional MCP bridge

When enabled, exposes allowlisted local `ml1` tools (`features`, `validate`,
`graph`, `update --check`). Shell verification in commands remains authoritative.

## ml1 recommendation

```text
ml1 language claude-plugin
```

Prints marketplace install commands without requiring Claude Code for other agents.
