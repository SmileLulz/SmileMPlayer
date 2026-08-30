<div align="center">
  <img alt="SmileMPlayer Logo" src="https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/refs/heads/main/data/icons/smilemplayer-512.png" width="150px"/>
  <h1>🎵 SmileMPlayer 🎵</h1>
  <h3>A simple and modern playlist-focused local music player.</h3>
  <p>SmileMPlayer is a simple and modern playlist-focused local music player with LRC sidecar lyrics support, ReplayGain 2.0 support, MPRIS integration, fully customizable UI, Material You style by default, and so on.</p>
  <h3>Available For <a href="#-install">Linux</a> & <a href="#windows">Windows</a></h2>
  <br></br>
  <img alt="Screenshot" src="https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/refs/heads/main/Screenshots/0.png" width="80%" />
  <br></br>
  <h3><a href="https://github.com/SmileLulz/SmileMPlayer/blob/main/WIKI.md">Wiki</a>  &ensp;  <a href="https://github.com/SmileLulz/SmileMPlayer/blob/main/CHANGELOG.md">Changelogs</a>  &ensp;  <a href="https://github.com/SmileLulz/SmileMPlayer/blob/main/WINDOWS-README.md">Windows Readme</a></h2>
</div>

<br></br>

> [!NOTE]
> This project was meant to be a personal project, but I'm feeling happy to share it with others. Therefore, I am not accepting contributions. Thank you. Hope you like this simple music player :)

<details>
<summary><h1>📚 Table of contents</h1></summary>

- [✨ Features](#-features)
- [🔗 ( IMPORTANT ) Dependency Notes](#--important--dependency-notes)
- 📥 [Install](#-install)
    - [Linux](#linux-1)
    - [Windows](#windows)
- [📦 Build by yourself](#-build-by-yourself)
    - [Clone the repository](#clone-the-repository)
    - [Running directly](#running-directly)
    - [Build for Arch Linux](#build-for-arch-linux)
    - [Build for Debian](#build-for-debian)
    - [Build for Fedora](#build-for-fedora)
    - [Build for python pip](#build-for-python-pip)
- [🧾 License](#-license)

</details>

# ✨ Features

- Fully customizable/themable via QML
- Material You style by default
- Folders as playlists
- Tracks sorting
- LRC sidecar lyrics support
- ReplayGain 2.0 support
- MPRIS integration
- All the basic things, like cover art, controls, volume, etc...
- See [WIKI.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/WIKI.md) for more help

**See [CHANGELOG.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/CHANGELOG.md) for latest update information.**


# 🔗 ( IMPORTANT ) Dependency Notes

> [!WARNING]
> It is not recommended to install with `pip`. Installing with python `pip` won't install the system dependencies, you'll have to install them manually.

### Linux

You'll have to install a nerd font for icon support if you don't have any. The recommended option is **[JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)**.

For any **Arch Linux** distribution, you don't need to install the nerd font manually; since the `ttf-jetbrains-mono-nerd` package is available in **Extra & AUR**. So it will be automatically installed.

Below command will install the **JetBrainsMono Nerd Font**; for any other distros that uses `fc-cache`.

```sh
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts && wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && unzip -o JetBrainsMono.zip && fc-cache -fv
```

**See [DEPENDENCIES.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/DEPENDENCIES.md) for more information.**


# 📥 Install

_Make sure you've read the [🔗 ( IMPORTANT ) Dependency Notes](#--important--dependency-notes) section._

<details>
<summary><h3>Linux</h3></summary>

This will install the latest release on any distribution (Arch, Debain, Fedora based distros; but sadly not for Void Linux yet).

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/main/install.sh | bash
```

OR, if you want to inspect the installation script first:

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/main/install.sh -o install.sh

# Inspect
less install.sh

# Then you can install with the downloaded script
bash install.sh
```

</details>

<details>
<summary><h3>Windows</h3></summary>

> [!NOTE]
> There are three ways to download/install, CHOOSE ONE.

Go to [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

**Option 1: Installer (recommended):**

Install:

```powershell
irm https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/main/install-win.ps1 | iex
```

OR, if you want to inspect the installation script first:

```powershell
# Download the script
irm https://raw.githubusercontent.com/SmileLulz/SmileMPlayer/main/install-win.ps1 -OutFile install-win.ps1

# Inspect
notepad .\install-win.ps1

# Then you can install with the downloaded script
.\install-win.ps1
```

You can also keep this script for checking or installing future updates directly. You can run these commands:

```powershell
# Show help message
.\install-win.ps1 -Help  # Or -h

# Check for latest update
.\install-win.ps1 -CheckUpdate  # Or -cu

# Install latest version
.\install-win.ps1

# Download and varify the installer without installing it
.\install-win.ps1 -DryRun  # Or -dr
```

**Option 2: Portable/standalone `exe`:**

- Download the `SmileMPlayer-x.x-windows-x64.exe` file and run it directly.

**Option 3: Portable `zip` archive:**

- Download the `SmileMPlayer-x.x-windows-x64.zip` file, extract it anywhere, then run the `SmileMPlayer.exe`.

</details>

<details>
<summary><h1>📦 Build by yourself</h1></summary>

_Make sure you've read the [🔗 ( IMPORTANT ) Dependency Notes](#--important--dependency-notes) section._

_For **Windows** build guide, see [WINDOWS-README.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/WINDOWS-README.md)._

> Replace any `x.x` with the actual version tag.

### Clone the repository

```sh
git clone https://github.com/SmileLulz/SmileMPlayer.git && cd SmileMPlayer
```

### Running directly

```sh
python -m smilemplayer
```

<details>
<summary><h3>Build for Arch Linux</h3></summary>

Build dependencies:

```sh
sudo pacman -S --needed \
    python-hatchling \
    python-build \
    python-installer \
    python-wheel
```

Build and install in one go (recommended):

```sh
makepkg -si
```

Or build first, then install:

```sh
# Build first
makepkg -s

# And then install
sudo pacman -U smilemplayer-x.x-1-any.pkg.tar.zst
```

</details>

<details>
<summary><h3>Build for Debian</h3></summary>

Build dependencies:

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

1. Build:

```sh
dpkg-buildpackage -b -us -uc
```

2. Install:

```sh
sudo apt install ../smilemplayer_x.x-1_all.deb
```

</details>

<details>
<summary><h3>Build for Fedora</h3></summary>

Build dependencies:

```sh
sudo dnf install \
    git \
    appstream \
    rpm-build \
    rpmdevtools \
    python3-devel \
    python3-hatchling \
    python3-pip \
    desktop-file-utils \
    python3-rpm-generators
```

Create required directories:

```sh
mkdir -p rpm/{BUILD,BUILDROOT,RPMS,SOURCES,SRPMS}
```

> [!NOTE]
> Now, you have two options to build:
> 
> Option 1: Use the release source archive.
>
> Option 2: Use a specific commit source archive.

**Option 1:**

_This is for most users who just want to build the release version._

> Make sure to `git checkout` to that commit tag first (e.g. `git checkout v1.6`).

1. Download the release source archive:

```sh
spectool --define "_topdir $PWD/rpm" rpm/SPECS/smilemplayer.spec
```

2. Build:

```sh
rpmbuild --define "_topdir $PWD/rpm" -ba rpm/SPECS/smilemplayer.spec
```

3. Install:

```sh
sudo dnf install rpm/RPMS/noarch/smilemplayer-x.x-1.fcxx.noarch.rpm
```

**Option 2:**

_This is mostly for local testing or building from a specific commit._

> Make sure to `git checkout` to that commit first (e.g. `git checkout <commit_hash_or_tag>`).

1. Create the source archive from current commit (replace `x.x` with the actual version):

```sh
git archive --format=tar.gz --prefix=SmileMPlayer-x.x/ HEAD > rpm/SOURCES/vx.x.tar.gz
```

2. Build:

```sh
rpmbuild --define "_topdir $PWD/rpm" -ba rpm/SPECS/smilemplayer.spec
```

3. Install:

```sh
sudo dnf install rpm/RPMS/noarch/smilemplayer-x.x-1.fcxx.noarch.rpm
```

</details>

<details>
<summary><h3>Build for python pip</h3></summary>

_Not recommended._

1. Build:

```sh
python -m build
```

2. Install locally:

```sh
python -m pip install .
```
Or install locally for development puposes:

```sh
python -m pip install -e .
```

</details>
</details>


<details>
<summary><h1>🧾 License</h1></summary>

This project is licensed under the GNU General Public License v3.0 only.

Also see [DEPENDENCIES.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/DEPENDENCIES.md).

</details>
