#!/usr/bin/env bash

set -euo pipefail

REPO="SmileLulz/SmileMPlayer"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
SmileMPlayer installer

Usage:
  $0
  $0 --dry-run
  $0 --help

Installs the latest published SmileMPlayer release for:
  - Arch Linux and Arch-based distributions
  - Debian and Debian-based distributions
  - Fedora and Fedora-based distributions

Options:
  --dry-run    Download and verify the package, but do not install it.
  --help       Show this help message.
EOF
}

DRY_RUN=0

case "${1:-}" in
    "")
        ;;
    --dry-run)
        DRY_RUN=1
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
        usage >&2
        exit 1
        ;;
esac

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}Error: Required command not found: $1${NC}" >&2
        exit 1
    fi
}

require_command curl
require_command python3
require_command sha256sum

if [[ ! -r /etc/os-release ]]; then
    echo -e "${RED}Error: Cannot determine the Linux distribution.${NC}" >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

distro=""
package_kind=""

case "${ID}" in
    arch|cachyos|manjaro|endeavouros)
        distro="Arch Linux or Arch-based"
        package_kind="arch"
        ;;
    debian|ubuntu|linuxmint|pop)
        distro="Debian or Debian-based"
        package_kind="debian"
        ;;
    fedora)
        distro="Fedora"
        package_kind="fedora"
        ;;
    *)
        if [[ "${ID_LIKE:-}" == *arch* ]]; then
            distro="Arch-based"
            package_kind="arch"
        elif [[ "${ID_LIKE:-}" == *debian* || "${ID_LIKE:-}" == *ubuntu* ]]; then
            distro="Debian-based"
            package_kind="debian"
        elif [[ "${ID_LIKE:-}" == *fedora* || "${ID_LIKE:-}" == *rhel* ]]; then
            distro="Fedora/RHEL-based"
            package_kind="fedora"
        fi
        ;;
esac

if [[ -z "$package_kind" ]]; then
    echo -e "${RED}Unsupported distribution: ${PRETTY_NAME:-${ID:-unknown}}${NC}" >&2
    echo
    echo "Download a package manually from:"
    echo "https://github.com/${REPO}/releases/latest"
    exit 1
fi

echo -e "${BLUE}SmileMPlayer installer${NC}"
echo
echo "Detected system: ${PRETTY_NAME:-$distro}"
echo "Package type:    $package_kind"
echo

echo -e "${YELLOW}Fetching latest release information...${NC}"

release_json="$(
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "$API_URL"
)"

release_tag="$(
    printf '%s' "$release_json" |
        python3 -c \
            'import json,sys; print(json.load(sys.stdin)["tag_name"])'
)"

release_name="$(
    printf '%s' "$release_json" |
        python3 -c \
            'import json,sys; print(json.load(sys.stdin)["name"])'
)"

case "$package_kind" in
    arch)
        asset_regex='^smilemplayer-.+-[0-9]+-any\.pkg\.tar\.zst$'
        ;;
    debian)
        asset_regex='^smilemplayer_.+_all\.deb$'
        ;;
    fedora)
        asset_regex='^smilemplayer-.+\.noarch\.rpm$'
        ;;
esac

asset_json="$(
    printf '%s' "$release_json" |
        ASSET_REGEX="$asset_regex" \
        python3 -c '
import json
import os
import re
import sys

release = json.load(sys.stdin)
pattern = re.compile(os.environ["ASSET_REGEX"])

matches = [
    asset
    for asset in release.get("assets", [])
    if pattern.fullmatch(asset.get("name", ""))
]

if len(matches) == 0:
    raise SystemExit("No matching package asset found.")
if len(matches) > 1:
    names = ", ".join(asset["name"] for asset in matches)
    raise SystemExit(f"Multiple matching package assets found: {names}")

print(json.dumps(matches[0]))
'
)"

asset_name="$(
    printf '%s' "$asset_json" |
        python3 -c \
            'import json,sys; print(json.load(sys.stdin)["name"])'
)"

download_url="$(
    printf '%s' "$asset_json" |
        python3 -c \
            'import json,sys; print(json.load(sys.stdin)["browser_download_url"])'
)"

digest="$(
    printf '%s' "$asset_json" |
        python3 -c \
            'import json,sys; print(json.load(sys.stdin).get("digest") or "")'
)"

echo "Release:          $release_name"
echo "Tag:              $release_tag"
echo "Package:          $asset_name"
echo

if [[ -z "$digest" || "$digest" != sha256:* ]]; then
    echo -e "${RED}Error: GitHub did not provide a SHA-256 digest for the selected asset.${NC}" >&2
    exit 1
fi

expected_sha="${digest#sha256:}"

tmpdir="$(mktemp -d)"
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

package_path="$tmpdir/$asset_name"

echo -e "${YELLOW}Downloading package...${NC}"

curl -fsSL \
    --retry 3 \
    --retry-all-errors \
    -o "$package_path" \
    "$download_url"

actual_sha="$(
    sha256sum "$package_path" |
        awk '{print $1}'
)"

if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo -e "${RED}Error: SHA-256 verification failed.${NC}" >&2
    echo "Expected: $expected_sha" >&2
    echo "Actual:   $actual_sha" >&2
    exit 1
fi

echo -e "${GREEN}✓ SHA-256 verified${NC}"
echo

if (( DRY_RUN )); then
    echo -e "${GREEN}Dry run complete. Package was downloaded and verified but not installed.${NC}"
    exit 0
fi

case "$package_kind" in
    arch)
        require_command pacman
        require_command sudo

        echo -e "${YELLOW}Installing with pacman...${NC}"

        sudo pacman -U --noconfirm "$package_path"
        ;;

    debian)
        require_command apt-get
        require_command sudo

        echo -e "${YELLOW}Installing with apt...${NC}"

        sudo apt-get install -y "$package_path"
        ;;

    fedora)
        require_command dnf
        require_command sudo

        echo -e "${YELLOW}Installing with dnf...${NC}"

        sudo dnf install -y "$package_path"
        ;;
esac

echo
echo -e "${GREEN}✓ SmileMPlayer ${release_tag} installed successfully.${NC}"
echo
echo "Run it with:"
echo "  smilemplayer"
