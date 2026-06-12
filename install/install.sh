#!/usr/bin/env bash
# Install ml1 from GitHub Releases (macOS/Linux).
#   bash install.sh [version]
# Works unauthenticated against public repos (e.g. the minlang-releases
# mirror). For private repos, authenticate with `gh auth login` or GH_TOKEN.
set -euo pipefail

REPO="${MINLANG_REPO:-codeshift-ai-solutions/minlang-releases}"
VERSION="${1:-latest}"
DEST="${MINLANG_INSTALL_DIR:-${HOME}/.local/bin}"

fail() { echo "error: $*" >&2; exit 1; }

os="$(uname -s)"; arch="$(uname -m)"
case "${os}-${arch}" in
	Darwin-arm64) TARGET="aarch64-apple-darwin" ;;
	Darwin-x86_64) TARGET="x86_64-apple-darwin" ;;
	Linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
	Linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
	*) fail "unsupported platform ${os}/${arch}" ;;
esac

have_gh() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }

resolve_version() {
	if [ "${VERSION}" != "latest" ]; then
		echo "${VERSION#v}"
		return
	fi
	if have_gh; then
		gh release view --repo "${REPO}" --json tagName -q .tagName | sed 's/^v//'
		return
	fi
	if [ -n "${GH_TOKEN:-}" ]; then
		curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" \
			"https://api.github.com/repos/${REPO}/releases/latest" |
			python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))' \
			2>/dev/null && return
		fail "could not resolve the latest release of ${REPO} with GH_TOKEN (bad token or no access?)"
	fi
	# Unauthenticated: the releases/latest redirect carries the tag — works
	# for public repos with no API call and no token.
	local final
	final="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
		"https://github.com/${REPO}/releases/latest" 2>/dev/null)" || true
	case "${final}" in
		*/releases/tag/v*) echo "${final##*/releases/tag/v}"; return ;;
	esac
	fail "could not resolve the latest release of ${REPO}.
If the repo is private, authenticate first (gh auth login, or set GH_TOKEN).
If it is public, check the repo name (MINLANG_REPO=${REPO}) and that a release exists."
}

VER="$(resolve_version)"
NAME="ml1-v${VER}-${TARGET}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
echo "==> installing ml1 v${VER} (${TARGET}) to ${DEST}"

download() {
	if have_gh; then
		gh release download "v${VER}" --repo "${REPO}" \
			--pattern "${NAME}.tar.gz" --dir "${TMP}" && return
	fi
	if [ -n "${GH_TOKEN:-}" ]; then
		# Private-repo path: asset downloads need the API URL + octet-stream.
		local asset_url
		asset_url="$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" \
			"https://api.github.com/repos/${REPO}/releases/tags/v${VER}" |
			python3 -c "import json,sys
assets = json.load(sys.stdin).get('assets', [])
m = [a['url'] for a in assets if a['name'] == '${NAME}.tar.gz']
print(m[0] if m else '')")" || asset_url=""
		[ -n "${asset_url}" ] || fail "release v${VER} of ${REPO} has no asset ${NAME}.tar.gz"
		curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" \
			-H "Accept: application/octet-stream" \
			-o "${TMP}/${NAME}.tar.gz" "${asset_url}" && return
	fi
	# Unauthenticated public download.
	curl -fsSL -o "${TMP}/${NAME}.tar.gz" \
		"https://github.com/${REPO}/releases/download/v${VER}/${NAME}.tar.gz" && return
	fail "could not download ${NAME}.tar.gz from ${REPO} release v${VER}.
If the repo is private, authenticate first (gh auth login, or set GH_TOKEN)."
}

download
tar -xzf "${TMP}/${NAME}.tar.gz" -C "${TMP}"
mkdir -p "${DEST}"
install -m 0755 "${TMP}/${NAME}/ml1" "${DEST}/ml1"
echo "==> done: $("${DEST}/ml1" 2>&1 | head -1)"
case ":${PATH}:" in *":${DEST}:"*) ;; *) echo "note: add ${DEST} to PATH" ;; esac
