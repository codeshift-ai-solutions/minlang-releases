#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
	test_manifest.sh
	test_inventory.sh
	test_authority.sh
	test_agents.sh
	test_hooks.sh
	test_bridge.sh
)

for test in "${tests[@]}"; do
	bash "${SCRIPT_DIR}/${test}"
done

echo "All plugin fixture tests passed."
