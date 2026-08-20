from __future__ import annotations

from pathlib import Path
from typing import Any

from PySide6.QtCore import (
    QObject, Property, QThread, QUrl, Signal, Slot, QStandardPaths
)

from .models import Track
from .playlist_model import PlaylistModel
from .scanner import _PlaylistScanner
from .settings import AppSettings


class LibraryManager(QObject):
    """
    Manages a collection of playlist folders.
    Each folder becomes a separate playlist.
    """
    playlistsChanged = Signal()
    currentPlaylistChanged = Signal()
    scanStarted = Signal(str)
    scanFinished = Signal(str, int)
    errorMessage = Signal(str)

    def __init__(self, settings: AppSettings, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.settings = settings
        cache = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.CacheLocation)
        self.cache_dir = Path(cache) / "art"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        self.playlistModel = PlaylistModel(self)
        self._folders: list[str] = []
        self._names: list[str] = []
        self._tracks: list[list[Track]] = []
        self._current_index = 0
        self._threads: set[QThread] = set()
        self._scan_queue: list[int] = []
        self._active_scan: int | None = None

        self._load_from_settings()

    # ---------- Private ----------
    def _load_from_settings(self) -> None:
        folders = self.settings.data.get("folders", [])
        if isinstance(folders, list):
            for folder in folders:
                p = Path(str(folder)).expanduser()
                if p.is_dir():
                    self._folders.append(str(p.resolve()))
                    self._names.append(p.name or str(p))
                    self._tracks.append([])

        if self._folders:
            self._current_index = min(
                int(self.settings.data.get("current_playlist", 0) or 0),
                len(self._folders) - 1
            )
        self._sync_model()

    def _sync_model(self) -> None:
        tracks = self._tracks[self._current_index] if self._tracks else []
        self.playlistModel.set_tracks(tracks)

    def _persist(self) -> None:
        self.settings.data["folders"] = self._folders
        self.settings.data["current_playlist"] = self._current_index
        self.settings.save()

    def _start_scan(self, index: int) -> None:
        self._active_scan = index
        thread = QThread(self)
        worker = _PlaylistScanner(index, self._folders[index], str(self.cache_dir))
        worker.moveToThread(thread)
        thread._worker = worker  # keep reference

        thread.started.connect(worker.run)
        worker.finished.connect(self._on_scan_finished)
        worker.finished.connect(thread.quit)
        worker.finished.connect(worker.deleteLater)
        thread.finished.connect(thread.deleteLater)
        thread.finished.connect(lambda t=thread: self._threads.discard(t))

        self.scanStarted.emit(self._names[index])
        self._threads.add(thread)
        thread.start()

    @Slot(int, object)
    def _on_scan_finished(self, index: int, tracks: list[Track]) -> None:
        if not 0 <= index < len(self._folders):
            return
        self._tracks[index] = tracks
        if index == self._current_index:
            self._sync_model()
        self.scanFinished.emit(self._names[index], len(tracks))
        self._active_scan = None

        if self._scan_queue:
            next_index = self._scan_queue.pop(0)
            if 0 <= next_index < len(self._folders):
                self._start_scan(next_index)

    # ---------- QML Properties ----------
    @Property("QStringList", notify=playlistsChanged)
    def playlistNames(self) -> list[str]:
        return list(self._names)

    @Property(int, notify=currentPlaylistChanged)
    def currentPlaylist(self) -> int:
        return self._current_index

    # ---------- Public Slots ----------
    @Slot(str)
    def addFolder(self, folder: str) -> None:
        if str(folder).startswith("file:"):
            folder = QUrl(str(folder)).toLocalFile()
        folder = str(Path(folder).expanduser().resolve())

        if not Path(folder).is_dir():
            self.errorMessage.emit(f"Not a folder: {folder}")
            return

        if folder in self._folders:
            self.setCurrentPlaylist(self._folders.index(folder))
            return

        self._folders.append(folder)
        self._names.append(Path(folder).name or folder)
        self._tracks.append([])
        self._persist()
        self.playlistsChanged.emit()
        self.setCurrentPlaylist(len(self._folders) - 1)
        self.scanPlaylist(len(self._folders) - 1)

    @Slot(int)
    def removePlaylist(self, index: int) -> None:
        if not 0 <= index < len(self._folders):
            return
        self._folders.pop(index)
        self._names.pop(index)
        self._tracks.pop(index)
        self._current_index = min(self._current_index, len(self._folders) - 1) if self._folders else 0
        self._persist()
        self.playlistsChanged.emit()
        self.currentPlaylistChanged.emit()
        self._sync_model()

    @Slot(int)
    def setCurrentPlaylist(self, index: int) -> None:
        if not 0 <= index < len(self._folders):
            return
        if self._current_index == index:
            self._sync_model()
            if not self._tracks[index]:
                self.scanPlaylist(index)
            return
        self._current_index = index
        self.settings.data["current_playlist"] = index
        self._persist()
        self.currentPlaylistChanged.emit()
        self._sync_model()
        if not self._tracks[index]:
            self.scanPlaylist(index)

    @Slot(int)
    def rescanPlaylist(self, index: int) -> None:
        if 0 <= index < len(self._folders):
            self.scanPlaylist(index)

    @Slot()
    def rescanCurrent(self) -> None:
        if self._folders:
            self.scanPlaylist(self._current_index)

    # ---------- Scan Scheduling ----------
    def scanPlaylist(self, index: int) -> None:
        if not 0 <= index < len(self._folders):
            return
        if self._active_scan == index or index in self._scan_queue:
            return
        if self._active_scan is not None:
            self._scan_queue.append(index)
            return
        self._start_scan(index)

    # ---------- Query Methods ----------
    def current_tracks(self) -> list[Track]:
        return list(self._tracks[self._current_index]) if self._tracks else []

    def playlist_name(self, index: int) -> str:
        return self._names[index] if 0 <= index < len(self._names) else "Playlist"

    def folders(self) -> list[str]:
        return list(self._folders)
