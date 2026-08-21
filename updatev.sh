#!/bin/bash

set -e

PYPROJECT="pyproject.toml"
PKGBUILD="PKGBUILD"
CHANGELOG="debian/changelog"
CONTROL="debian/control"

CHANGELOG_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"
PKGBUILD_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"
CONTROL_MAINTAINER="SmileLulz <SmileLulz@users.noreply.github.com>"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage:
  $0 1|--major           Bump major version (1.2 -> 2.0)
  $0 2|--minor           Bump minor version (1.2 -> 1.3)
  $0 -s|--set X.Y        Set explicit version (two parts)
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

    IFS='.' read -r major minor <<< "$current"

    case "$type" in
        major) echo "$((major + 1)).0" ;;
        minor) echo "${major}.$((minor + 1))" ;;
    esac
}

update_files() {
    local new_version="$1"
    local pkgname=$(get_pkgname)
    local full_version="${new_version}-1"
    local date=$(date -R)

    sed -i "s/^version = \".*\"/version = \"${new_version}\"/" "$PYPROJECT"
    sed -i "s/^pkgver=.*/pkgver=${new_version}/" "$PKGBUILD"

    if grep -q '^# Maintainer:' "$PKGBUILD"; then
        sed -i "s/^# Maintainer:.*/# Maintainer: ${PKGBUILD_MAINTAINER}/" "$PKGBUILD"
    fi

    if grep -q '^Maintainer:' "$CONTROL"; then
        sed -i "s/^Maintainer:.*/Maintainer: ${CONTROL_MAINTAINER}/" "$CONTROL"
    fi

    local new_entry="${pkgname} (${full_version}) bookworm; urgency=medium

  * Version bump to ${new_version}

 -- ${CHANGELOG_MAINTAINER}  ${date}

"
    echo -e "${new_entry}$(cat "$CHANGELOG")" > "$CHANGELOG"

    echo -e "${GREEN}✓ Updated pyproject.toml${NC}"
    echo -e "${GREEN}✓ Updated PKGBUILD${NC}"
    echo -e "${GREEN}✓ Updated debian/control${NC}"
    echo -e "${GREEN}✓ Updated debian/changelog${NC}"
}

if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    1|--major|2|--minor)
        current_version=$(get_current_version)
        case "$1" in
            1|--major) new_version=$(bump_version "$current_version" "major") ; bump_type="major" ;;
            2|--minor) new_version=$(bump_version "$current_version" "minor") ; bump_type="minor" ;;
        esac
        echo -e "${YELLOW}Bumping ${bump_type} version: ${current_version} -> ${new_version}${NC}"
        ;;
    -s|--set)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Version required with --set${NC}"
            usage
        fi
        new_version="$2"
        echo -e "${YELLOW}Setting version to: ${new_version}${NC}"
        ;;
    *)
        echo -e "${RED}Error: Unknown option '$1'${NC}"
        usage
        ;;
esac

if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use X.Y (two parts)${NC}"
    exit 1
fi

update_files "$new_version"

echo -e "${GREEN}✓ Version successfully updated to ${new_version}-1${NC}"
