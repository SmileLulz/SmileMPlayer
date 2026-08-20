from __future__ import annotations

import os
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot

from .models import Track
from .tag_reader import read_track

AUDIO_EXTENSIONS = {
    ".mp3", ".flac", ".ogg", ".oga", ".opus", ".m4a", ".mp4", ".aac",
    ".wav", ".wv", ".ape", ".aiff", ".aif", ".mka",
}


class _PlaylistScanner(QObject):
    """
    Worker that scans a folder tree for audio files and returns a list of Tracks.
    Runs in its own thread.
    """
    finished = Signal(int, list)  # playlist_index, tracks

    def __init__(self, playlist_index: int, folder: str, cache_dir: str) -> None:
        super().__init__()
        self.playlist_index = playlist_index
        self.folder = folder
        self.cache_dir = Path(cache_dir)

    @Slot()
    def run(self) -> None:
        tracks: list[Track] = []
        root = Path(self.folder).expanduser()

        try:
            if not root.is_dir():
                self.finished.emit(self.playlist_index, tracks)
                return

            stack = [root]
            while stack:
                directory = stack.pop()
                try:
                    with os.scandir(directory) as entries:
                        for entry in entries:
                            try:
                                if entry.is_dir(follow_symlinks=False):
                                    stack.append(Path(entry.path))
                                elif (
                                    entry.is_file(follow_symlinks=False)
                                    and Path(entry.name).suffix.lower() in AUDIO_EXTENSIONS
                                ):
                                    track = read_track(entry.path, self.cache_dir)
                                    if track is not None:
                                        tracks.append(track)
                            except (OSError, PermissionError):
                                continue
                except (OSError, PermissionError):
                    continue
        finally:
            tracks.sort(key=lambda t: (t.title.casefold(), t.artist.casefold(), t.path.casefold()))
            self.finished.emit(self.playlist_index, tracks)
