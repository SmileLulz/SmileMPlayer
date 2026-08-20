from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(slots=True, frozen=True)
class Track:
    """Immutable track metadata."""
    path: str
    title: str
    artist: str
    album: str
    genre: str
    duration_ms: int
    art_url: str = ""

    @property
    def filename(self) -> str:
        return Path(self.path).name

    @property
    def track_id(self) -> str:
        return f"track:{self.path}"
