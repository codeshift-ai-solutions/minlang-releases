#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

bridge="${PLUGIN_ROOT}/mcp/ml1-bridge.py"
mcp_json="${PLUGIN_ROOT}/.mcp.json"
require_file "${bridge}"
require_file "${mcp_json}"
[[ -x "${bridge}" ]] || fail "MCP bridge must be executable"

python3 - <<'PY' "${bridge}"
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
for token in ("ALLOWLIST", "ml1_validate", "ml1_features", "path traversal rejected"):
	assert token in text, f"bridge missing {token}"
print("bridge checks ok")
PY

pass "ml1 MCP bridge"
