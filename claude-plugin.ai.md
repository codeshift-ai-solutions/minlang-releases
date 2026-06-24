# MinLang Claude plugin — AI module map

## Marketplace root (`packaging/claude-plugin/`)

| Path | Role |
|------|------|
| `.claude-plugin/marketplace.json` | Lists `minlang` plugin at `./plugins/minlang` |
| `README.md` | Install, validate, smoke-test docs |
| `COMMUNITY_SUBMISSION.md` | Optional Anthropic marketplace checklist |
| `tests/` | Shell fixture tests wired to Makefile |

## Plugin root (`plugins/minlang/`)

| Component | Path | Notes |
|-----------|------|-------|
| Manifest | `.claude-plugin/plugin.json` | Version synced to ml1 release |
| Commands | `commands/*.md` + `commands/commands.json` | 23 commands, shared contract |
| Authority skill | `skills/authority-preflight/SKILL.md` | Required by all producing commands |
| Agents | `agents/minlang-*.md` | Creator, gatekeeper, migration architect |
| Hooks | `hooks/hooks.json`, `hooks/post-edit-ml.sh` | Non-destructive `.ml` guard |
| MCP bridge | `.mcp.json`, `mcp/ml1-bridge.py` | Allowlisted local ml1 tools |
| Monitors | `monitors/monitors.json` | Empty placeholder (optional future) |

## Validation

Run `make check-claude-plugin` before release. Inventory tests fail if any
design-doc command is missing from `commands/commands.json` or `commands/`.

## Distribution

Mirrored to `minlang-releases` repository root on release. Primary install:

```text
/plugin marketplace add codeshift-ai-solutions/minlang-releases
/plugin install minlang@minlang-releases
```

## Related

- Design: `docs/MINLANG_CLAUDE_PLUGIN_PLAN.md`
- Plan: `docs/ai/plans/minlang-claude-plugin/PLAN.md`
- CLI recommendation: `ml1 language claude-plugin`
