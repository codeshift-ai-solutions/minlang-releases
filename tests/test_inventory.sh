#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_file "${INVENTORY}"
require_file "${DESIGN_DOC}"

python3 - <<'PY' "${INVENTORY}" "${DESIGN_DOC}" "${PLUGIN_ROOT}/commands"
import json, pathlib, re, sys

inventory_path, design_doc_path, commands_dir = sys.argv[1:4]
with open(inventory_path, encoding="utf-8") as fh:
	inv = json.load(fh)
commands = inv.get("commands") or []
assert len(commands) == 23, f"expected 23 commands, got {len(commands)}"

design = pathlib.Path(design_doc_path).read_text(encoding="utf-8")
# Extract command names from design doc table rows like | `/minlang:author-app` |
catalog = set(re.findall(r"`/minlang:([a-z0-9-]+)`", design))
inventory_names = {c["name"] for c in commands}
missing = sorted(catalog - inventory_names)
extra = sorted(inventory_names - catalog)
assert not missing, f"inventory missing design-doc commands: {missing}"
assert not extra, f"inventory has unknown commands: {extra}"

for cmd in commands:
	path = pathlib.Path(commands_dir) / cmd["file"]
	assert path.is_file(), f"missing command file for {cmd['name']}: {path}"
	text = path.read_text(encoding="utf-8")
	assert "authority-preflight" in text, f"{cmd['name']} must reference authority-preflight"
	assert "app/generated" in text, f"{cmd['name']} must mention app/generated protection"
	assert ".env" in text, f"{cmd['name']} must mention .env protection"
	if cmd.get("produces_minlang"):
		assert "VALIDATE" in text or "validate" in text, f"{cmd['name']} must require validation"

print("inventory checks ok")
PY

pass "command inventory coverage"
