from __future__ import annotations

from bisect import bisect_right
from dataclasses import dataclass, field
from pathlib import Path
import re
from typing import Mapping


@dataclass(frozen=True, slots=True)
class LyricWord:
    """A word-level lyric segment with an absolute timestamp in milliseconds."""

    timestamp_ms: int
    text: str


@dataclass(frozen=True, slots=True)
class LyricLine:
    """A lyric line with an absolute timestamp and optional word timing."""

    timestamp_ms: int
    text: str
    words: tuple[LyricWord, ...] = field(default_factory=tuple)

    @property
    def enhanced(self) -> bool:
        return bool(self.words)


@dataclass(frozen=True, slots=True)
class LyricsDocument:
    """Parsed LRC document."""

    lines: tuple[LyricLine, ...]
    metadata: Mapping[str, str] = field(default_factory=dict)
    offset_ms: int = 0

    @property
    def enhanced(self) -> bool:
        return any(line.words for line in self.lines)


class LrcParser:
    """Parse standard and enhanced LRC lyric files defensively."""

    _timestamp_re = re.compile(
        r"\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]"
    )
    _metadata_re = re.compile(r"^\[([^:\]]+):(.*?)\]$")
    _word_timestamp_re = re.compile(
        r"<(?:(\d+):(\d{2})(?:[.:](\d{1,3}))?)>"
    )

    def parse_file(self, path: str | Path) -> LyricsDocument:
        """Parse an LRC file, returning an empty document on unreadable input."""
        file_path = Path(path)
        try:
            raw = file_path.read_bytes()
        except (OSError, ValueError):
            return LyricsDocument(lines=tuple())

        text = self._decode(raw)
        if text is None:
            return LyricsDocument(lines=tuple())
        return self.parse(text)

    def parse(self, text: str) -> LyricsDocument:
        metadata: dict[str, str] = {}
        raw_lines: list[LyricLine] = []

        for raw_line in text.splitlines():
            stripped = raw_line.lstrip("\ufeff").strip()
            if not stripped:
                continue
            metadata_match = self._metadata_re.match(stripped)
            if metadata_match and not self._timestamp_re.match(stripped):
                key = metadata_match.group(1).strip().casefold()
                metadata[key] = metadata_match.group(2)

        offset_ms = 0
        try:
            offset_ms = int(metadata.get("offset", "0").strip())
        except ValueError:
            pass

        for raw_line in text.splitlines():
            line = raw_line.lstrip("\ufeff")
            stripped = line.strip()
            if not stripped:
                continue

            metadata_match = self._metadata_re.match(stripped)
            if metadata_match and not self._timestamp_re.match(stripped):
                continue

            timestamps = list(self._timestamp_re.finditer(line))
            if not timestamps:
                continue

            body = line[timestamps[-1].end():]
            parsed_timestamps: list[int] = []
            for match in timestamps:
                timestamp = self._parse_timestamp(
                    match.group(1), match.group(2), match.group(3)
                )
                if timestamp is not None:
                    parsed_timestamps.append(timestamp + offset_ms)

            if not parsed_timestamps:
                continue

            words = self._parse_words(body, parsed_timestamps[0], offset_ms)
            line_text = self._strip_word_timestamps(body)
            for timestamp_ms in parsed_timestamps:
                raw_lines.append(
                    LyricLine(
                        timestamp_ms=timestamp_ms,
                        text=line_text,
                        words=words,
                    )
                )

        raw_lines.sort(key=lambda lyric: lyric.timestamp_ms)
        return LyricsDocument(
            lines=tuple(raw_lines),
            metadata=dict(metadata),
            offset_ms=offset_ms,
        )

    @staticmethod
    def _decode(data: bytes) -> str | None:
        for encoding in ("utf-8-sig", "utf-16", "utf-16-le", "utf-16-be"):
            try:
                return data.decode(encoding)
            except UnicodeDecodeError:
                continue
        try:
            return data.decode("utf-8", errors="replace")
        except UnicodeError:
            return None

    @classmethod
    def _parse_timestamp(
        cls, minutes: str, seconds: str, fraction: str | None
    ) -> int | None:
        try:
            minute_value = int(minutes)
            second_value = int(seconds)
            if second_value >= 60:
                return None

            milliseconds = 0
            if fraction:
                if len(fraction) == 1:
                    milliseconds = int(fraction) * 100
                elif len(fraction) == 2:
                    milliseconds = int(fraction) * 10
                else:
                    milliseconds = int(fraction[:3])

            return (minute_value * 60 + second_value) * 1000 + milliseconds
        except ValueError:
            return None

    @classmethod
    def _strip_word_timestamps(cls, body: str) -> str:
        return cls._word_timestamp_re.sub("", body)

    @classmethod
    def _parse_words(
        cls, body: str, line_timestamp_ms: int, offset_ms: int
    ) -> tuple[LyricWord, ...]:
        matches = list(cls._word_timestamp_re.finditer(body))
        if not matches:
            return tuple()

        words: list[LyricWord] = []
        prefix = body[:matches[0].start()]
        if prefix.strip():
            words.append(LyricWord(line_timestamp_ms, prefix))

        for index, match in enumerate(matches):
            timestamp = cls._parse_timestamp(
                match.group(1), match.group(2), match.group(3)
            )
            if timestamp is None:
                continue
            end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
            words.append(
                LyricWord(
                    timestamp_ms=timestamp + offset_ms,
                    text=body[match.end():end],
                )
            )

        return tuple(words)


class LyricsSynchronizer:
    """Synchronize parsed lyrics directly against media playback position."""

    def __init__(self) -> None:
        self._document = LyricsDocument(lines=tuple())
        self._line_index = -1
        self._word_index = -1
        self._line_timestamps: tuple[int, ...] = tuple()
        self._word_timestamps: tuple[int, ...] = tuple()

    @property
    def document(self) -> LyricsDocument:
        return self._document

    @property
    def line_index(self) -> int:
        return self._line_index

    @property
    def word_index(self) -> int:
        return self._word_index

    def set_document(self, document: LyricsDocument) -> None:
        self._document = document
        self._line_timestamps = tuple(line.timestamp_ms for line in document.lines)
        self._line_index = -1
        self._word_index = -1
        self._word_timestamps = tuple()

    def update(self, position_ms: int) -> tuple[int, int]:
        lines = self._document.lines
        if not lines:
            self._line_index = -1
            self._word_index = -1
            self._word_timestamps = tuple()
            return self._line_index, self._word_index

        position = max(0, int(position_ms))
        new_line_index = bisect_right(self._line_timestamps, position) - 1
        if new_line_index < 0:
            new_line_index = -1

        if new_line_index != self._line_index:
            self._line_index = new_line_index
            if new_line_index >= 0:
                words = lines[new_line_index].words
                self._word_timestamps = tuple(word.timestamp_ms for word in words)
            else:
                self._word_timestamps = tuple()

        if new_line_index < 0 or not self._word_timestamps:
            self._word_index = -1
        else:
            self._word_index = bisect_right(self._word_timestamps, position) - 1

        return self._line_index, self._word_index


def find_sidecar(track_path: str | Path) -> Path | None:
    """Return the matching LRC sidecar, accepting common case variants."""
    audio_path = Path(track_path)
    for candidate in (
        audio_path.with_suffix(".lrc"),
        audio_path.with_suffix(".LRC"),
    ):
        if candidate.is_file():
            return candidate
    return None
