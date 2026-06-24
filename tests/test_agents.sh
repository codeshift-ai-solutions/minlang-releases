#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

agents_dir="${PLUGIN_ROOT}/agents"
for agent in minlang-creator minlang-gatekeeper minlang-migration-architect; do
	require_file "${agents_dir}/${agent}.md"
done

python3 - <<'PY' "${agents_dir}"
import pathlib, sys
agents = pathlib.Path(sys.argv[1])
creator = (agents / "minlang-creator.md").read_text(encoding="utf-8")
gatekeeper = (agents / "minlang-gatekeeper.md").read_text(encoding="utf-8")
migration = (agents / "minlang-migration-architect.md").read_text(encoding="utf-8")
assert "GENERATE" in creator and "VALIDATE" in creator and "REVALIDATE" in creator
assert "strict sanitized JSON" in gatekeeper.lower() or "strict sanitized JSON only" in gatekeeper
assert "migration ledger" in migration.lower()
for text in (creator, gatekeeper, migration):
	assert "authority-preflight" in text
print("agent checks ok")
PY

pass "specialized agents"
