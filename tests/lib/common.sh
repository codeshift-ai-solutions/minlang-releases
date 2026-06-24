#!/usr/bin/env bash
# Shared paths for MinLang Claude plugin tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MARKETPLACE="${ROOT}/.claude-plugin/marketplace.json"
PLUGIN_ROOT="${ROOT}/plugins/minlang"
PLUGIN_MANIFEST="${PLUGIN_ROOT}/.claude-plugin/plugin.json"
INVENTORY="${PLUGIN_ROOT}/commands/commands.json"
DESIGN_DOC="${ROOT}/../../docs/MINLANG_CLAUDE_PLUGIN_PLAN.md"
CLI_VERSION_FILE="${ROOT}/../../compiler/crates/minlang-cli/Cargo.toml"

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

pass() {
	echo "PASS: $*"
}

require_file() {
	[[ -f "$1" ]] || fail "missing file: $1"
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

json_get() {
	python3 - "$@" <<'PY'
import json, sys
path, *keys = sys.argv[1:]
with open(path, encoding="utf-8") as fh:
	data = json.load(fh)
for key in keys:
	if isinstance(data, list):
		data = data[int(key)]
	else:
		data = data[key]
if isinstance(data, (dict, list)):
	print(json.dumps(data))
else:
	print(data)
PY
}
