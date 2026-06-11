#!/usr/bin/env bash
# Install ml1 from GitHub Releases (macOS/Linux).
#   GH_TOKEN=... bash install.sh [version]
# Uses `gh` when available (required for private repos without curl auth);
# falls back to the GitHub API with GH_TOKEN, then to building from source.
set -euo pipefail

REPO="${MINLANG_REPO:-codeshift-ai-solutions/minlang-releases}"
VERSION="${1:-latest}"
DEST="${MINLANG_INSTALL_DIR:-${HOME}/.local/bin}"

os="$(uname -s)"; arch="$(uname -m)"
case "${os}-${arch}" in
	Darwin-arm64) TARGET="aarch64-apple-darwin" ;;
	Darwin-x86_64) TARGET="x86_64-apple-darwin" ;;
	Linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
	Linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
	*) echo "error: unsupported platform ${os}/${arch}" >&2; exit 1 ;;
esac

resolve_version() {
	if [ "${VERSION}" != "latest" ]; then
		echo "${VERSION#v}"
	elif command -v gh >/dev/null 2>&1; then
		gh release view --repo "${REPO}" --json tagName -q .tagName | sed 's/^v//'
	else
		curl -fsSL -H "Authorization: Bearer ${GH_TOKEN:?set GH_TOKEN or install gh}" \
			"https://api.github.com/repos/${REPO}/releases/latest" |
			python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))'
	fi
}

VER="$(resolve_version)"
NAME="ml1-v${VER}-${TARGET}"
TMP="$(mktemp -d)"
echo "==> installing ml1 v${VER} (${TARGET}) to ${DEST}"

if command -v gh >/dev/null 2>&1; then
	gh release download "v${VER}" --repo "${REPO}" --pattern "${NAME}.tar.gz" --dir "${TMP}"
else
	asset_url=$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" \
		"https://api.github.com/repos/${REPO}/releases/tags/v${VER}" |
		python3 -c "import json,sys; assets=json.load(sys.stdin)['assets']; print(next(a['url'] for a in assets if a['name']=='${NAME}.tar.gz'))")
	curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/octet-stream" \
		-o "${TMP}/${NAME}.tar.gz" "${asset_url}"
fi

tar -xzf "${TMP}/${NAME}.tar.gz" -C "${TMP}"
mkdir -p "${DEST}"
install -m 0755 "${TMP}/${NAME}/ml1" "${DEST}/ml1"
rm -rf "${TMP}"
echo "==> done: $("${DEST}/ml1" 2>&1 | head -1)"
case ":${PATH}:" in *":${DEST}:"*) ;; *) echo "note: add ${DEST} to PATH" ;; esac
