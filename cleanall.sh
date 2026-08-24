#!/bin/bash

rm -rf smilemplayer/__pycache__/
rm -rf smilemplayer/core/__pycache__/
rm -rf .pybuild/
rm -rf build/
rm -rf dist/
rm -rf pkg/
rm -rf src/
rm -rf debian/.debhelper/
rm -rf debian/smilemplayer/

rm -rf rpm/BUILD/*
rm -rf rpm/BUILDROOT/*
rm -rf rpm/RPMS/*
rm -rf rpm/SOURCES/*
rm -rf rpm/SRPMS/*

rm -f smilemplayer-*.pkg.tar.zst
rm -f ../smilemplayer_*.deb
rm -f ../smilemplayer_*.buildinfo
rm -f ../smilemplayer_*.changes
rm -f debian/debhelper-build-stamp
rm -f debian/files
rm -f debian/*.substvars
rm -f debian/*.debhelper
rm -f debian/*.log
