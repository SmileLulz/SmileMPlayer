# Changelogs

### v2.5

- Conditional `dbus-next` library importing
- Added bundled font only for Windows build (gonna test Windows build)
- Updated DEPENDENCIES.md
- Updated README.md

### v2.4

- Theme color update

### v2.3

- Updated UI for lyrics
- Added smooth scrolling to lyrics panel
- Made `install.sh` executable

### v2.2

- Fixed fedora build issue

### v2.2.b1

- Fixing fedora build workflow

### v2.1

- Added LRC sidecar lyrics support
- Added lyrics support in UI
- Added `lyrics_enabled` in config
- Updated README.md

### v2.0

- Fixed `debian/copyright`'s year mistake
- Some `pyproject.toml` changes

### v1.9

- Fixed appstream developer id

### v1.8

- Added git workflows for build-and-release automation
- Changed metainfo / appstream id from `com.smilelulz.SmileMPlayer` to `io.github.SmileLulz.SmileMPlayer`
- Some project and README.md updates

### v1.7

- Testing git workflow

### v1.6

- Some proper packaging
- Updated README.md

### v1.5

- Some project updates
- Updated README.md

### v1.4

- Backend changes:
  - Removed explicit GStreamer backend
  - Less dependencies because of no explicit GStreamer backend
- Frontend changes:
  - Added default nerd font (JetBainsMonoNerdFont) for glyphs support for systems that doesn't have any nerd fonts installed
- Some changes in README.md

### v1.3

- Backend changes:
    - Added MPRIS integration setting
- Frontend changes:
    - Did some changes on now-playing card
- Designed a final icon/logo
- Added WIKI.md

### v1.2

- Frontend changes:
    - Fixed now-playing card's cover art sizing
- Few changes in README.md

### v1.1

- Backend changes:
    - Fixed some ReplayGain issues
- Frontend changes:
    - Made track list responsive grid-based view, with scrollbar support
    - Added keyboard support to track list and now-playing card
    - Solved focusing issues
- Few changes in README.md

### v1.0

- Added complete MPRIS integration (hopefully)
- Fixed next/previous not working because of loop state
- Fixed a playlist refreshing issue where it's automatically selecting random tracks when refreshing
- Changed version format of the project from Semantic Versioning to Dotted-Decimal Notation (two integer)

### v0.9.0

- Implemented ReplayGain 2.0 support
- Added master gain setting for extra output volume
- Fixed a small PKGBUILD issue

### v0.8.1

- Few project changes

### v0.8.0 (beta-stable)

- Added mtime sorting
- Few changes in UI
- Fixed: sorting not syncing correctly with the config on launch
