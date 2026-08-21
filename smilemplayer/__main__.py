from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QStandardPaths, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .core.library import LibraryManager
from .core.mpris import MprisServer
from .core.player_backend import PlayerBackend
from .core.settings import AppSettings


def _xdg_data_dirs() -> list[str]:
    """Return XDG data directories in search order, without duplicates."""
    home = Path.home()
    raw_home = os.environ.get("XDG_DATA_HOME")
    data_home = Path(raw_home).expanduser() if raw_home else home / ".local" / "share"

    result = [str(data_home)]
    for entry in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"):
        if entry:
            result.append(entry)
    seen: set[str] = set()
    unique: list[str] = []
    for entry in result:
        if entry not in seen:
            seen.add(entry)
            unique.append(entry)
    return unique


def generate_theme(source_dir: Path, target_dir: Path) -> None:
    """Copy all files from source_dir to target_dir recursively."""
    if not source_dir.exists():
        print(f"Error: Source directory {source_dir} does not exist.", file=sys.stderr)
        sys.exit(1)
    target_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source_dir, target_dir, dirs_exist_ok=True, symlinks=False)
    print(f"Theme files generated successfully in: {target_dir}")


def main() -> int:
    QCoreApplication.setOrganizationName("SmileLulz")
    QCoreApplication.setOrganizationDomain("smilemplayer.local")
    QCoreApplication.setApplicationName("SmileMPlayer")
    parser = argparse.ArgumentParser(description="SmileMPlayer - A simple playlist-based local music player")
    parser.add_argument(
         "-gt", "--gen-theme",
        action="store_true",
        help="Generate default theme files into '~/.config/SmileMPlayer/theme' directory"
    )
    args = parser.parse_args()

    config_dir = Path(QStandardPaths.writableLocation(QStandardPaths.StandardLocation.ConfigLocation)) / "SmileMPlayer"
    if args.gen_theme:
        source_root = Path(__file__).resolve().parent / "resources" / "qml"
        target_root = config_dir / "theme"
        generate_theme(source_root, target_root)
        return 0

    if sys.platform.startswith("linux"):
        os.environ.setdefault("QT_MEDIA_BACKEND", "gstreamer")

    app = QGuiApplication(sys.argv)
    desktop_file_installed = any(
        (Path(base) / "applications" / "smilemplayer.desktop").is_file()
        for base in _xdg_data_dirs()
    )
    if desktop_file_installed:
        app.setDesktopFileName("smilemplayer")

    settings = AppSettings(str(config_dir))
    library = LibraryManager(settings)
    backend = PlayerBackend(library, settings)
    mpris = MprisServer(backend)
    if not mpris.start():
        print("Warning: MPRIS support could not be started.", file=sys.stderr)
    app.aboutToQuit.connect(mpris.stop)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("player", backend)
    engine.rootContext().setContextProperty("library", library)
    custom_theme = settings.data.get("theme", "")
    if custom_theme and Path(custom_theme).expanduser().is_file():
        theme_path = Path(custom_theme).expanduser().resolve()
        qml_path = QUrl.fromLocalFile(str(theme_path))
    else:
        qml_path = QUrl.fromLocalFile(str(Path(__file__).resolve().parent / "resources" / "qml" / "Main.qml"))

    engine.load(qml_path)
    if not engine.rootObjects():
        return 1

    backend.startup()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
