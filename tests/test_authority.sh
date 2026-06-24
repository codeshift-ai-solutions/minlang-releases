#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

skill="${PLUGIN_ROOT}/skills/authority-preflight/SKILL.md"
require_file "${skill}"

python3 - <<'PY' "${skill}" "${INVENTORY}"
import json, pathlib, sys
skill_path, inventory_path = sys.argv[1:3]
text = pathlib.Path(skill_path).read_text(encoding="utf-8")
with open(inventory_path, encoding="utf-8") as fh:
	inv = json.load(fh)
stable = inv["stable_bundle_url"]
assert stable in text, "authority skill must include stable bundle URL"
for token in ("app/generated", ".env", "now()", "ml1 features", "ml1 validate"):
	assert token in text, f"authority skill missing {token}"
print("authority link checks ok")
PY

pass "authority references"
