# Community marketplace submission (optional)

The **primary** distribution path is the public mirror marketplace at
`codeshift-ai-solutions/minlang-releases`. Anthropic community marketplace
submission is optional and reviewed externally.

## Plugin purpose

MinLang authoring, migration, refactoring, diagnostics, and release-readiness
commands for Claude Code users. Bundle authority is preserved via the stable
language bundle URL and the shared authority-preflight skill.

## Pre-submission validation

```text
make check-claude-plugin
make test-claude-plugin
make verify-claude-plugin-release
claude plugin validate packaging/claude-plugin
claude plugin validate packaging/claude-plugin/plugins/minlang
```

## Install and test

```text
/plugin marketplace add codeshift-ai-solutions/minlang-releases
/plugin install minlang@minlang-releases
/minlang:validate-authority
```

Local checkout:

```text
/plugin marketplace add ./packaging/claude-plugin
/plugin install minlang@minlang-releases
```

## Security notes

- No secrets, tokens, or private URLs in plugin files.
- Hooks are non-destructive: they validate or remind; they never edit
  `app/generated/` or `.env`.
- MCP bridge is local-only with an allowlisted `ml1` command set.
- No network services or credential storage.

## Data and network behavior

- Commands instruct fetching the public language bundle from GitHub Releases.
- No telemetry or external API calls from plugin scripts except user-initiated
  bundle downloads documented in commands/skills.

## Dependencies

- **Claude Code**: required to use the plugin (optional for MinLang itself).
- **ml1**: external local compiler; not bundled. Install from minlang-releases.
- **Python 3**: optional, for MCP bridge stdio server only.

## Release and update model

- Marketplace files mirror from `packaging/claude-plugin/` on every ml1 release.
- Plugin version in `plugin.json` syncs to the ml1 release tag.
- Users update via marketplace refresh after new releases publish.

## Submission checklist (maintainer)

- [ ] All validation commands pass
- [ ] Command inventory covers all 23 design-doc commands
- [ ] README and COMMUNITY_SUBMISSION.md current
- [ ] No secrets in repository or submission package
- [ ] Mirror marketplace remains primary distribution path
- [ ] Submit through Anthropic community marketplace form when ready
