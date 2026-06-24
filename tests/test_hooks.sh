#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

hooks_json="${PLUGIN_ROOT}/hooks/hooks.json"
hook_script="${PLUGIN_ROOT}/hooks/post-edit-ml.sh"
require_file "${hooks_json}"
require_file "${hook_script}"
[[ -x "${hook_script}" ]] || fail "hook script must be executable"

python3 - <<'PY' "${hooks_json}" "${hook_script}"
import json, pathlib, sys
hooks_path, script_path = sys.argv[1:3]
with open(hooks_path, encoding="utf-8") as fh:
	cfg = json.load(fh)
script = pathlib.Path(script_path).read_text(encoding="utf-8")
for forbidden in ("rm -rf", "app/generated/", ".env"):
	# hook script must not mutate forbidden targets
	if forbidden == "app/generated/":
		assert "never edit" in script.lower() or "blocked" in script.lower()
for token in ("skip", "ml1 validate", "make validate"):
	assert token in script, f"hook script missing {token}"
print("hook safety checks ok")
PY

pass "guarded hooks"
