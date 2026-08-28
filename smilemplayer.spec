import os
from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files


project_root = Path(SPECPATH)

datas = collect_data_files(
    "smilemplayer",
    includes=[
        "resources/**/*",
    ],
)

onefile = os.environ.get("SMILEMPLAYER_ONEFILE") == "1"

a = Analysis(
    ["windows_entry.py"],
    pathex=[str(project_root)],
    binaries=[],
    datas=datas,
    hiddenimports=[],
    hookspath=["hooks"],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "dbus_next",
    ],
    noarchive=False,
)

pyz = PYZ(a.pure)

if onefile:
    exe = EXE(
        pyz,
        a.scripts,
        a.binaries,
        a.datas,
        [],
        name="SmileMPlayer",
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        console=False,
        icon=str(project_root / "data/icons/smilemplayer.ico"),
    )

else:
    exe = EXE(
        pyz,
        a.scripts,
        [],
        [],
        [],
        exclude_binaries=True,
        name="SmileMPlayer",
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        console=False,
        icon=str(project_root / "data/icons/smilemplayer.ico"),
    )

    coll = COLLECT(
        exe,
        a.binaries,
        a.datas,
        strip=False,
        upx=False,
        name="SmileMPlayer",
    )
