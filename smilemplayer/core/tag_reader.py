from __future__ import annotations

import base64
import hashlib
import mimetypes
import struct
import sys
from pathlib import Path
from typing import Any

from mutagen import File as MutagenFile
from mutagen.flac import Picture
from mutagen._util import MutagenError

from .models import Track
from .replaygain import read_replaygain


def _first_tag(tags: Any, *keys: str, default: str = "") -> str:
    """Return the first non-empty tag value from the given keys.
    Handles mutagen's VorbisComment which raises ValueError for missing keys.
    """
    if not tags:
        return default
    for key in keys:
        try:
            value = tags.get(key)
        except ValueError:
            continue
        if value is None:
            continue
        if isinstance(value, (list, tuple)):
            value = value[0] if value else default
        if value is not None:
            text = str(value).strip()
            if text:
                return text
    return default


def _extract_cover_data(audio: Any) -> tuple[bytes, str] | None:
    """Extract cover art data and MIME type from a Mutagen audio object."""
    tags = getattr(audio, "tags", None)
    if not tags:
        return None

    try:
        for value in tags.values():
            if value.__class__.__name__ == "APIC" and getattr(value, "data", None):
                return value.data, getattr(value, "mime", "image/jpeg") or "image/jpeg"
    except Exception:
        pass

    try:
        cover_values = tags.get("covr") if tags else None
        if cover_values:
            raw = cover_values[0] if isinstance(cover_values, (list, tuple)) else cover_values
            data = bytes(raw)
            mime = "image/png" if data.startswith(b"\x89PNG") else "image/jpeg"
            return data, mime
    except Exception:
        pass

    try:
        pictures = getattr(audio, "pictures", None) or []
        if pictures:
            picture = pictures[0]
            return picture.data, picture.mime or "image/jpeg"
    except Exception:
        pass

    try:
        encoded = tags.get("coverart") if tags else None
        if encoded:
            raw = encoded[0] if isinstance(encoded, (list, tuple)) else encoded
            return base64.b64decode(raw), "image/jpeg"
    except Exception:
        pass

    try:
        encoded = tags.get("metadata_block_picture")
        if encoded:
            raw = encoded[0] if isinstance(encoded, (list, tuple)) else encoded
            picture = Picture(base64.b64decode(raw))
            return picture.data, picture.mime or "image/jpeg"
    except Exception:
        pass

    return None


def _cover_cache_url(cache_dir: Path, data: bytes, mime: str) -> str:
    """Cache cover art and return a file:// URL."""
    digest = hashlib.sha256(data).hexdigest()[:24]
    ext = mimetypes.guess_extension(mime) or ".jpg"
    if ext == ".jpe":
        ext = ".jpg"
    out = cache_dir / f"{digest}{ext}"
    if not out.exists():
        out.write_bytes(data)
    return out.as_uri()


def _read_opus_output_gain_db(path: str) -> float:
    """Read the OpusHead output-gain field, if this file contains one.

    Ogg Opus and Matroska/WebM Opus both carry the Opus identification packet
    as codec private data. The field is a signed little-endian Q7.8 dB value.
    FFmpeg/Qt applies this gain during decoding; we only retain it as metadata
    so ReplayGain clipping protection can account for the already-applied gain.
    """
    try:
        with open(path, "rb") as handle:
            data = handle.read(128 * 1024)
    except OSError:
        return 0.0

    offset = data.find(b"OpusHead")
    while offset >= 0:
        header = data[offset:offset + 19]
        if len(header) == 19 and header[:8] == b"OpusHead":
            version = header[8]
            channels = header[9]
            if version < 16 and 1 <= channels <= 255:
                try:
                    return struct.unpack_from("<h", header, 16)[0] / 256.0
                except struct.error:
                    return 0.0
        offset = data.find(b"OpusHead", offset + 1)
    return 0.0


def read_track(path: str, cache_dir: Path) -> Track | None:
    """Read one audio file and return a Track object.
    If reading fails, return a fallback Track with minimal metadata.
    """
    resolved = str(Path(path).resolve())
    fallback_title = Path(path).stem

    mtime = 0
    try:
        mtime = int(Path(path).stat().st_mtime)
    except OSError:
        pass
    try:
        audio = MutagenFile(path, easy=False)
    except (OSError, MutagenError, Exception) as e:
        print(f"MutagenFile failed for {path}: {e}", file=sys.stderr)
        audio = None

    if audio is None:
        return Track(
            path=resolved,
            title=fallback_title,
            artist="",
            album="",
            genre="",
            duration_ms=0,
            mtime=mtime,
            art_url="",
        )

    tags = getattr(audio, "tags", None)
    title = _first_tag(tags, "title", "TIT2", "©nam", default=fallback_title)
    artist = _first_tag(tags, "artist", "TPE1", "©ART", "albumartist", "TPE2", "aART")
    album = _first_tag(tags, "album", "TALB", "©alb")
    genre = _first_tag(tags, "genre", "TCON", "©gen")
    codec_gain_db = 0.0
    try:
        if Path(path).suffix.lower() in {".opus", ".oga", ".ogg", ".mka", ".webm"}:
            codec_gain_db = _read_opus_output_gain_db(path)
    except Exception:
        codec_gain_db = 0.0
    replaygain = read_replaygain(tags, codec_gain_db=codec_gain_db)

    duration_ms = 0
    try:
        info = getattr(audio, "info", None)
        if info and hasattr(info, "length"):
            duration_ms = int(max(0.0, float(info.length)) * 1000)
    except Exception as e:
        print(f"Duration read failed for {path}: {e}", file=sys.stderr)

    art_url = ""
    cover = _extract_cover_data(audio)
    if cover:
        try:
            art_url = _cover_cache_url(cache_dir, *cover)
        except Exception as e:
            print(f"Cover cache failed for {path}: {e}", file=sys.stderr)

    return Track(
        path=resolved,
        title=title,
        artist=artist,
        album=album,
        genre=genre,
        duration_ms=duration_ms,
        mtime=mtime,
        art_url=art_url,
        replaygain=replaygain,
    )
