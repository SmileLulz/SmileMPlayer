from __future__ import annotations

from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, QObject

from .models import Track


class PlaylistModel(QAbstractListModel):
    """Qt model that exposes a list of Tracks to QML views."""

    # Custom roles
    PathRole = Qt.ItemDataRole.UserRole + 1
    TitleRole = Qt.ItemDataRole.UserRole + 2
    ArtistRole = Qt.ItemDataRole.UserRole + 3
    AlbumRole = Qt.ItemDataRole.UserRole + 4
    DurationRole = Qt.ItemDataRole.UserRole + 5
    ArtRole = Qt.ItemDataRole.UserRole + 6
    FilenameRole = Qt.ItemDataRole.UserRole + 7
    GenreRole = Qt.ItemDataRole.UserRole + 8
    IndexRole = Qt.ItemDataRole.UserRole + 9

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._tracks: list[Track] = []

    def roleNames(self) -> dict[int, bytes]:
        return {
            self.PathRole: b"path",
            self.TitleRole: b"title",
            self.ArtistRole: b"artist",
            self.AlbumRole: b"album",
            self.DurationRole: b"durationMs",
            self.ArtRole: b"artUrl",
            self.FilenameRole: b"filename",
            self.GenreRole: b"genre",
            self.IndexRole: b"trackIndex",
        }

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._tracks)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or not 0 <= index.row() < len(self._tracks):
            return None
        track = self._tracks[index.row()]
        mapping = {
            self.PathRole: track.path,
            self.TitleRole: track.title,
            self.ArtistRole: track.artist,
            self.AlbumRole: track.album,
            self.DurationRole: track.duration_ms,
            self.ArtRole: track.art_url,
            self.FilenameRole: track.filename,
            self.GenreRole: track.genre,
            self.IndexRole: index.row(),
        }
        return mapping.get(role)

    def set_tracks(self, tracks: list[Track]) -> None:
        """Replace all tracks and reset the model."""
        self.beginResetModel()
        self._tracks = tracks
        self.endResetModel()

    def track(self, index: int) -> Track | None:
        if 0 <= index < len(self._tracks):
            return self._tracks[index]
        return None

    @property
    def tracks(self) -> list[Track]:
        return list(self._tracks)
