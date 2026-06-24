#!/usr/bin/env bash
# Post-edit guard for MinLang source files. Non-destructive: validates or reminds only.
set -euo pipefail

readonly FORBIDDEN_EDIT='app/generated'
readonly ENV_FILE='.env'

# Claude passes hook context on stdin as JSON when available.
input="$(cat || true)"

# Extract edited file path from hook payload when present.
file_path=""
if command -v python3 >/dev/null 2>&1 && [[ -n "${input}" ]]; then
	file_path="$(python3 - <<'PY' "${input}" 2>/dev/null || true
import json, sys
raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
	data = json.loads(raw)
except json.JSONDecodeError:
	print("")
	raise SystemExit(0)
for key in ("file_path", "path", "filePath"):
	if isinstance(data.get(key), str):
		print(data[key])
		raise SystemExit(0)
tool_input = data.get("tool_input") or data.get("input") or {}
if isinstance(tool_input, dict):
	for key in ("file_path", "path", "filePath"):
		if isinstance(tool_input.get(key), str):
			print(tool_input[key])
			raise SystemExit(0)
print("")
PY
)"
fi

if [[ -z "${file_path}" ]]; then
	echo "minlang hook: skip — could not determine edited file"
	exit 0
fi

case "${file_path}" in
	*.ml|*.mlui) ;;
	*)
		echo "minlang hook: skip — not a MinLang source file (${file_path})"
		exit 0
		;;
esac

if [[ "${file_path}" == *"${FORBIDDEN_EDIT}"* ]]; then
	echo "minlang hook: blocked path pattern — never edit ${FORBIDDEN_EDIT}"
	exit 0
fi

if [[ "$(basename "${file_path}")" == "${ENV_FILE}" ]] || [[ "${file_path}" == *"/${ENV_FILE}" ]]; then
	echo "minlang hook: blocked — do not edit ${ENV_FILE}"
	exit 0
fi

# Walk up to find project root.
dir="$(dirname "${file_path}")"
project_root=""
while [[ "${dir}" != "/" ]]; do
	if [[ -f "${dir}/minlang.json" ]]; then
		project_root="${dir}"
		break
	fi
	dir="$(dirname "${dir}")"
done

if [[ -z "${project_root}" ]]; then
	echo "minlang hook: skip — no minlang.json found near ${file_path}"
	exit 0
fi

if ! command -v ml1 >/dev/null 2>&1; then
	echo "minlang hook: reminder — run ml1 validate after editing ${file_path} (ml1 not on PATH)"
	exit 0
fi

if [[ -f "${project_root}/Makefile" ]] && grep -q '^validate:' "${project_root}/Makefile" 2>/dev/null; then
	( cd "${project_root}" && make validate ) || {
		echo "minlang hook: make validate reported issues — fix before continuing"
		exit 0
	}
	echo "minlang hook: make validate passed for ${project_root}"
	exit 0
fi

ml1 validate "${file_path}" || {
	echo "minlang hook: ml1 validate reported issues for ${file_path}"
	exit 0
}

echo "minlang hook: ml1 validate passed for ${file_path}"
exit 0
