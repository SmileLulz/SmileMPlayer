#!/bin/bash

echo -e "\033[1;33mCleaning...\033[0m"

# Directories
directories=(
    ".pybuild"
    "build"
    "dist"
    "pkg"
    "src"
    "debian/.debhelper"
    "debian/smilemplayer"
    "rpm/BUILD"
    "rpm/BUILDROOT"
    "rpm/RPMS"
    "rpm/SOURCES"
    "rpm/SRPMS"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo -e "Removed: $dir"
    fi
done

# Files
file_patterns=(
    "smilemplayer-*.pkg.tar.zst"
    "smilemplayer-*.rpm"
    "smilemplayer_*.deb"
    "../smilemplayer_*.deb"
    "../smilemplayer_*.buildinfo"
    "../smilemplayer_*.changes"
    "debian/debhelper-build-stamp"
    "debian/files"
    "debian/*.substvars"
    "debian/*.debhelper"
    "debian/*.log"
)

for pattern in "${file_patterns[@]}"; do
    if [[ "$pattern" == *[*?[]* ]]; then
        shopt -s nullglob
        files=($pattern)
        shopt -u nullglob
        if [ ${#files[@]} -gt 0 ]; then
            rm -f "${files[@]}"
            echo -e "Removed: $pattern (${#files[@]} files)"
        fi
    else
        if [ -f "$pattern" ]; then
            rm -f "$pattern"
            echo -e "Removed: $pattern"
        fi
    fi
done

find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

echo -e "\033[0;32mCleanup complete\033[0m"
