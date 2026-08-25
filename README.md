<div align="center">
  <img src="https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/refs/heads/main/data/icons/smilemplayer-512.png" width="150px" alt="SmileMPlayer" />
  <h1>🎵 SmileMPlayer 🎵</h1>
  <h3>
    A simple and modern-looking playlist-based local music player for Linux desktops.
    <br/>For non-audiophiles.<br>
  </h3>
  <br></br>
  <img alt="SmileMPlayer Logo" src="https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/refs/heads/main/Screenshots/0.png" width="80%" />
</div>

<br></br>

> [!WARNING]
> This project was meant to be a personal project, but thought it would be nice to share it with others.
> 
> By the way, I am not accepting contributions. Thank you. Hope you like my app :)

# ✨ Features

- Fully customizable/themable via QML
- Material You theme by default
- Folder-based playlist management
- Tracks sorting
- ReplayGain 2.0 support
- MPRIS integration
- All basic things, like cover art, controls, volume, etc...
- See [TODO.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/TODO.md) for more planned features

**See [CHANGELOG.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/CHANGELOG.md) for latest update information. See [WIKI.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/WIKI.md) for more help.**


# 🔗 Dependencies

All dependencies used as APIs, no packages are bundled.

⚠︎ Dependencies will auto-install during app installation, no need to install them manually.

> [!WARNING]
> You'll have to install a nerd font for icon support if you don't have any. The recommended option is JetBrainsMono Nerd Font.
>
> Only the Arch Linux package provides the `ttf-jetbrains-mono-nerd` font as a dependency, so you won't need to install manually.

### Python PIP

> ⚠︎ Manual nerd font installation required.

- `PySide6`
- `mutagen`
- `dbus-next`

### Arch Linux

- `python`
- `pyside6`
- `python-mutagen`
- `python-dbus-next`
- `qt6-multimedia-ffmpeg`
- `ttf-jetbrains-mono-nerd`

### Debian

> ⚠︎ Manual nerd font installation required.

```sh
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts && wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && unzip -o JetBrainsMono.zip && fc-cache -fv
```

- `python3`
- `python3-pyside6.qtcore`
- `python3-pyside6.qtgui`
- `python3-pyside6.qtqml`
- `python3-pyside6.qtmultimedia`
- `python3-pyside6.qtdbus`
- `python3-pyside6.qtwidgets`
- `python3-mutagen`
- `python3-dbus-next`

### Fedora

> ⚠︎ Manual nerd font installation required.

```sh
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts && wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && unzip -o JetBrainsMono.zip && fc-cache -fv
```

- `python3`
- `python3-pyside6`
- `python3-mutagen`
- `python3-dbus-next`


# 📥 Install

You can either choose to install the prebuilt binary from the [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) or [Build & install](#-build) by yourself.

Below guide is for installing prebuilt binary. If you chose to build, then go to [📦 Build](#-build) section.

> ⚠︎ You have to install a nerd font for icon support. The recommended option is JetBrainsMono Nerd Font.

> Replace any `x.x` with the actual version tag.

### Python PIP

1. Download the `.whl` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
# Install
pip install /path/to/smilemplayer-x.x-py3-none-any.whl

# Or install for current user only
pip install --user /path/to/smilemplayer-x.x-py3-none-any.whl
```

### Arch Linux

1. Download the `.tar.zst` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
sudo pacman -U /path/to/smilemplayer-x.x-1-any.pkg.tar.zst
```

### Debian

1. Download the `.deb` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
sudo apt install /path/to/smilemplayer_x.x-1_all.deb
```

### Fedora

1. Download the `.rpm` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
sudo dnf install /path/to/smilemplayer-x.x-1.fcxx.noarch.rpm
```


# 📦 Build

> Replace any `x.x` with the actual version tag.

### Clone the repository

```sh
git clone https://github.com/SmileLulz/SmileMPlayer.git && cd SmileMPlayer
```

### Running directly

```sh
python -m smilemplayer
```

### Build for python pip

```sh
# Build the package
python -m build

# Install locally
python -m pip install .

# Install locally for development
python -m pip install -e .
```

### Build for Arch Linux

Dependencies:

- `python-hatchling`
- `python-build`
- `python-installer`
- `python-wheel`

```sh
sudo pacman -S --needed python-hatchling python-build python-installer python-wheel
```

Build and install in one go (recommended):

```sh
makepkg -si
```

Or:

```sh
# Build first
makepkg -s

#And then install
sudo pacman -U smilemplayer-x.x-1-any.pkg.tar.zst
```

### Build for Debian

Dependencies:

- `build-essential`
- `debhelper`
- `desktop-file-utils`
- `python3-all`
- `python3-hatchling`
- `pybuild-plugin-pyproject`
- `dh-sequence-python3`

```sh
sudo apt install \
    build-essential \
    debhelper \
    desktop-file-utils \
    python3 \
    python3-all \
    python3-hatchling \
    pybuild-plugin-pyproject \
    dh-sequence-python3
```

Build:

```sh
dpkg-buildpackage -b -us -uc
```

Install:

```sh
sudo apt install ../smilemplayer_x.x-1_all.deb
```

### Build for Fedora

Dependencies:

- `appstream`
- `rpm-build`
- `rpmdevtools`
- `python3-devel`
- `python3-hatchling`
- `python3-pip`
- `desktop-file-utils`

Create required directories:

```sh
mkdir -p rpm/{BUILD,BUILDROOT,RPMS,SOURCES,SRPMS}
```

**⚠︎ Now, you have two options for your build:**

**Option 1:** Use the release source archive:

This is for most users who want to just build the release version.

> If you want to build an old or any previous version/commit, do `git checkout` to that commit tag first (e.g. `git checkout v1.6`).

Download the release source archive:

```sh
spectool --define "_topdir $PWD/rpm" rpm/SPECS/smilemplayer.spec
```

Build:

```sh
rpmbuild --define "_topdir $PWD/rpm" -ba rpm/SPECS/smilemplayer.spec
```

Install:

```sh
sudo dnf install rpm/RPMS/noarch/smilemplayer-x.x-1.fcxx.noarch.rpm
```

**Option 2:** Use the local or specific commit source archive:

This is for local testing or building a specific version.

> If you want to build an old or any previous version/commit, do `git checkout` to that commit first (e.g. `git checkout <commit_hash_or_tag>`).

Create the source archive from current commit (replace `x.x` with the actual version):

```sh
git archive --format=tar.gz --prefix=SmileMPlayer-x.x/ HEAD > rpm/SOURCES/vx.x.tar.gz
```

Build:

```sh
rpmbuild --define "_topdir $PWD/rpm" -ba rpm/SPECS/smilemplayer.spec
```

Install:

```sh
sudo dnf install rpm/RPMS/noarch/smilemplayer-x.x-1.fcxx.noarch.rpm
```
