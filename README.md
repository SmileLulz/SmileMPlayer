> This project was meant to be a personal project, but I'm sharing anyways. Therefore, I am not accepting contributions. Thank you. Hope you like my app :)


# ❤️ SmileMPlayer

A simple and playlist-based local music player for non-audiophiles.


### ✨ Features

- Fully customizable/themable via QML
- Folder-based playlist management
- Playlist-based single track list
- Tracks sorting
- All basic things, like cover art, controls, volume, etc...
- See [TODO.md](https://github.com/SmileLulz/SmileMPlayer/blob/main/TODO.md) for more planned features


# 🏞️ Screenshots

| ![Screenshot 1](https://github.com/SmileLulz/SmileMPlayer/blob/main/Screenshots/0.png) | ![Screenshot 2](https://github.com/SmileLulz/SmileMPlayer/blob/main/Screenshots/1.png) |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |


# 🔗 Dependencies

All dependencies used as APIs, nothing is bundled.

Install (Arch Linux):

```sh
sudo pacman -S --needed pyside6 python-mutagen qt6-multimedia-gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad
```


# 📥 Install

You can either choose to install the prebuilt binary from the [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) or [Build & install](#-build) by yourself. Below guide is for installing prebuilt binary.

### Python PIP

1. Download the `.whl` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
# Install
pip install /path/to/smilemplayer-x.x.x-py3-none-any.whl

# Or install for current user only
pip install --user /path/to/smilemplayer-x.x.x-py3-none-any.whl
```

### Arch Linux

1. Download the `.tar.zst` file from [Releases](https://github.com/SmileLulz/SmileMPlayer/releases) page.

2. Install:

```sh
sudo pacman -U /path/to/smilemplayer-x.x.x-x-any.pkg.tar.zst
```


# 📦 Build

**NOTE:** All below guides are wrote for/in Arch Linux; since I am using Arch, I can't test in other distros and can't guarentee that other guides than Arch will work correctly.

### Clone the repository

```sh
git clone https://github.com/SmileLulz/SmileMPlayer.git && cd SmileMPlayer
```

### Running from source

```sh
python -m smilemplayer
```

### Build for python pip

```sh
# Build the package
python -m build

# Install locally
python -m pip install .

# For development
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

Build and install:

```sh
makepkg -si
```
