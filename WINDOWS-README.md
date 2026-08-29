<div align="center">
  <h1>Build For Windows</h1>
  <h3>This guide is for Terminal/Powershell, not CMD</h3>
</div>

<br></br>

# 📝 Useful Commands

_Useful terminal commands you may want to know._

```sh
# Give current user the script execution privileges
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Now check
Get-ExecutionPolicy -List
```


# 🔗 ( IMPORTANT ) Build Requirements

> [!NOTE]
> If you don't have `winget`, make sure to install that first. You can search for tutorials online.
>
> If your current user account don't have the script execution privileges - see [📝 Useful Commands](#-useful-commands) section for.


### Python (>= 3.11)

```sh
winget install Python.Python.3.14
```

### Inno Setup (to build installer)

1. Download and install the latest [Inno Setup 6](https://jrsoftware.org/isdl.php#v6) or [Inno Setup 7](https://jrsoftware.org/isdl.php#v7).
2. Make sure you have `C:\Program Files\Inno Setup <6_or_7>` folder added in `PATH` or `Path` environment variable. If not, add it.


# 📦 Build

Make sure to `cd` to the project's root folder first.

### Create virtual python environment

_It is recommended to work in an virtual environment._

Set up the environment:

```sh
# Create
py -3 -m venv .venv

# Update
python -m pip install -U pip

# Install PyInstaller
python -m pip install pyinstaller
```

Activate source:

```sh
.venv\Scripts\activate
```

### Build Notes

> [!NOTE]
> You have three choices to build for windows.
>
> Option 1: Build as `onedir`
>
> Option 2: Build as `onefile`
>
> Option 3: Build an installable setup file

### Option 1 - onedir

> [!WARNING]
> If you've set the onefile's environment variable, unset it first using `Remove-Item Env:SMILEMPLAYER_ONEFILE` command.

Build:

```sh
python -m PyInstaller --clean --noconfirm smilemplayer.spec
```

Now you have the file(s) inside `dist\SmileMPlayer\` folder.

### Option 2 - onefile

Set environment variable for onefile build:

```sh
$env:SMILEMPLAYER_ONEFILE="1"
```

Build:

```sh
python -m PyInstaller --clean --noconfirm smilemplayer.spec
```

Unset the environment variable later if you want (for non-onefile builds):

```sh
Remove-Item Env:SMILEMPLAYER_ONEFILE
```

### Option 3 - Installer

_Make sure you've read the [🔗 ( IMPORTANT ) Build Requirements](#--important--build-requirements) section._

> [!WARNING]
> If you've set the onefile's environment variable, unset it first using `Remove-Item Env:SMILEMPLAYER_ONEFILE` command.

1. Build onedir

```sh
python -m PyInstaller --clean --noconfirm smilemplayer.spec
```

2. Build the installer

```sh
iscc installer\SmileMPlayer.iss
```

Now you have the setup file inside `dist\installer\` folder.
