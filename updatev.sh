#!/bin/bash

set -e

PYPROJECT="pyproject.toml"
PKGBUILD="PKGBUILD"
CHANGELOG="debian/changelog"
CONTROL="debian/control"
SPEC="rpm/SPECS/smilemplayer.spec"

CHANGELOG_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"
PKGBUILD_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"
CONTROL_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"
SPEC_PACKAGER="SmileLulz"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage:
  $0 1|--major           Bump major version (1.2 -> 2.0)
  $0 2|--minor           Bump minor version (1.2 -> 1.3)
  $0 -s|--set X.Y[...]   Set explicit version (e.g. 1.6, 1.6.b1, 2.0.rc1)
EOF
    exit 1
}

get_current_version() {
    grep -m1 '^version = ' "$PYPROJECT" | cut -d'"' -f2
}

get_pkgname() {
    grep -m1 '^pkgname=' "$PKGBUILD" | cut -d'=' -f2
}

bump_version() {
    local current="$1"
    local type="$2"

    if [[ ! "$current" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: ${type} bump requires a clean X.Y version. Current version is '${current}'.${NC}" >&2
        echo -e "${YELLOW}Use --set to explicitly set a version with a suffix.${NC}" >&2
        exit 1
    fi

    local major
    local minor

    IFS='.' read -r major minor <<< "$current"

    case "$type" in
        major) echo "$((major + 1)).0" ;;
        minor) echo "${major}.$((minor + 1))" ;;
        *)     echo "Error: Unknown bump type '$type'" >&2; exit 1 ;;
    esac
}

update_files() {
    local new_version="$1"
    local pkgname
    local full_version
    local date
    local fedora_date

    pkgname=$(get_pkgname)
    full_version="${new_version}-1"
    date=$(date -R)
    fedora_date=$(date '+%a %b %d %Y')

    # pyproject.toml
    sed -i \
        "s/^version = \".*\"/version = \"${new_version}\"/" \
        "$PYPROJECT"

    # Arch PKGBUILD
    sed -i \
        "s/^pkgver=.*/pkgver=${new_version}/" \
        "$PKGBUILD"

    if grep -q '^# Maintainer:' "$PKGBUILD"; then
        sed -i \
            "s/^# Maintainer:.*/# Maintainer: ${PKGBUILD_MAINTAINER}/" \
            "$PKGBUILD"
    fi

    # Debian control
    if grep -q '^Maintainer:' "$CONTROL"; then
        sed -i \
            "s/^Maintainer:.*/Maintainer: ${CONTROL_MAINTAINER}/" \
            "$CONTROL"
    fi

    # Debian changelog
    local new_entry="${pkgname} (${full_version}) bookworm; urgency=medium

  * Version bump to ${new_version}

 -- ${CHANGELOG_MAINTAINER}  ${date}

"
    echo -e "${new_entry}$(cat "$CHANGELOG")" > "$CHANGELOG"

    # Fedora spec
    sed -i \
        "s/^Version:.*/Version:        ${new_version}/" \
        "$SPEC"

    # Fedora changelog
    python3 - "$SPEC" "$new_version" "$fedora_date" "$SPEC_PACKAGER" <<'PY'
import sys
from pathlib import Path

spec_path = Path(sys.argv[1])
version = sys.argv[2]
date = sys.argv[3]
packager = sys.argv[4]

text = spec_path.read_text()

marker = "%changelog"
if marker not in text:
    raise SystemExit("Error: %changelog section not found in Fedora spec")

before, changelog = text.split(marker, 1)

lines = changelog.lstrip("\n").splitlines()

if lines:
    next_entry = None

    for i in range(1, len(lines)):
        if lines[i].startswith("* "):
            next_entry = i
            break

    if next_entry is not None:
        changelog = "\n".join(lines[next_entry:]) + "\n"
    else:
        changelog = ""
else:
    changelog = ""

new_entry = (
    f"* {date} {packager} - {version}-1\n"
    f"- Version bump to {version}\n\n"
)

spec_path.write_text(
    before.rstrip() + "\n\n%changelog\n" + new_entry + changelog
)
PY

    echo -e "${GREEN}✓ Updated pyproject.toml${NC}"
    echo -e "${GREEN}✓ Updated PKGBUILD${NC}"
    echo -e "${GREEN}✓ Updated debian/control${NC}"
    echo -e "${GREEN}✓ Updated debian/changelog${NC}"
    echo -e "${GREEN}✓ Updated Fedora spec${NC}"
}

if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    1|--major|2|--minor)
        current_version=$(get_current_version)

        case "$1" in
            1|--major)
                new_version=$(bump_version "$current_version" "major")
                bump_type="major"
                ;;
            2|--minor)
                new_version=$(bump_version "$current_version" "minor")
                bump_type="minor"
                ;;
        esac

        echo -e "${YELLOW}Bumping ${bump_type} version: ${current_version} -> ${new_version}${NC}"
        ;;

    -s|--set)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Version required with --set${NC}"
            usage
        fi

        new_version="$2"

        # X.Y with optional arbitrary non-whitespace suffix beginning
        # immediately after the second numeric component.
        if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+(\.[^[:space:]]+)?$ ]]; then
            echo -e "${RED}Error: Invalid version format. Use X.Y or X.Y.<suffix>${NC}"
            echo -e "${YELLOW}Examples: 1.6, 1.6.b1, 1.6.alpha, 2.0.rc1${NC}"
            exit 1
        fi

        echo -e "${YELLOW}Setting version to: ${new_version}${NC}"
        ;;

    *)
        echo -e "${RED}Error: Unknown option '$1'${NC}"
        usage
        ;;
esac

# Validate versions produced by major/minor as well.
if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+$|^[0-9]+\.[0-9]+\.[^[:space:]]+$ ]]; then
    echo -e "${RED}Error: Invalid version format: ${new_version}${NC}"
    exit 1
fi

# Verify required files exist before modifying anything.
for file in "$PYPROJECT" "$PKGBUILD" "$CHANGELOG" "$CONTROL" "$SPEC"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: Required file not found: $file${NC}"
        exit 1
    fi
done

update_files "$new_version"

echo -e "${GREEN}✓ Version successfully updated to ${new_version}-1${NC}"
