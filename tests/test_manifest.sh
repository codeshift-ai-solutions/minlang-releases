#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_file "${MARKETPLACE}"
require_file "${PLUGIN_MANIFEST}"

python3 - <<'PY' "${MARKETPLACE}" "${PLUGIN_MANIFEST}"
import json, sys
marketplace_path, plugin_path = sys.argv[1:3]
with open(marketplace_path, encoding="utf-8") as fh:
	marketplace = json.load(fh)
with open(plugin_path, encoding="utf-8") as fh:
	plugin = json.load(fh)
assert marketplace.get("name"), "marketplace name required"
plugins = marketplace.get("plugins") or []
names = [p.get("name") for p in plugins]
assert "minlang" in names, "marketplace must list minlang plugin"
entry = next(p for p in plugins if p.get("name") == "minlang")
assert entry.get("source") == "./plugins/minlang", "plugin source must be ./plugins/minlang"
assert plugin.get("name") == "minlang", "plugin manifest name must be minlang"
for field in ("description", "repository", "homepage", "license"):
	assert plugin.get(field), f"plugin manifest missing {field}"
print("manifest checks ok")
PY

pass "marketplace and plugin manifests"
