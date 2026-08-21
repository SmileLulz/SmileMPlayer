from __future__ import annotations

import math
import re
from dataclasses import dataclass
from typing import Any


_GAIN_RE = re.compile(r"^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*(?:dB|LU)?\s*$", re.IGNORECASE)
_PEAK_RE = re.compile(r"^\s*([+]?(?:\d+(?:\.\d*)?|\.\d+))\s*$")
_R128_INT_MIN = -32768
_R128_INT_MAX = 32767


@dataclass(slots=True, frozen=True)
class ReplayGainInfo:
    """Normalized ReplayGain metadata for one track.

    ``codec_gain_db`` is codec-level gain which is already applied by the
    decoder (currently relevant to Opus). It is kept separately so it is
    never applied a second time by QAudioOutput, but it can still be included
    when calculating clipping-safe ReplayGain volume.
    """

    track_gain_db: float | None = None
    track_peak: float | None = None
    album_gain_db: float | None = None
    album_peak: float | None = None
    source: str = ""
    codec_gain_db: float = 0.0

    def gain_db(self, mode: str) -> float | None:
        """Return the requested gain, falling back to track gain when needed."""
        if mode == "album" and self.album_gain_db is not None:
            return self.album_gain_db
        return self.track_gain_db

    def raw_peak(self, mode: str) -> float | None:
        """Return the stored ReplayGain peak, without codec-level gain."""
        if mode == "album" and self.album_peak is not None:
            return self.album_peak
        return self.track_peak

    def peak(self, mode: str) -> float | None:
        """Return an effective peak including decoder-applied codec gain."""
        peak = self.raw_peak(mode)
        if peak is None:
            return None
        codec_gain = float(self.codec_gain_db)
        if not math.isfinite(codec_gain) or codec_gain == 0.0:
            return peak
        effective = peak * math.pow(10.0, codec_gain / 20.0)
        return effective if math.isfinite(effective) and effective >= 0.0 else None

    @property
    def available(self) -> bool:
        return self.track_gain_db is not None or self.album_gain_db is not None


def _text_value(value: Any) -> str:
    if isinstance(value, (list, tuple)):
        value = value[0] if value else ""
    if isinstance(value, bytes):
        try:
            return value.decode("utf-8").strip()
        except UnicodeDecodeError:
            return ""
    text_values = getattr(value, "text", None)
    if text_values is not None:
        if isinstance(text_values, (list, tuple)):
            text_values = text_values[0] if text_values else ""
        return str(text_values).strip() if text_values is not None else ""
    return str(value).strip() if value is not None else ""


def _parse_gain(value: Any) -> float | None:
    text = _text_value(value)
    if not text:
        return None
    match = _GAIN_RE.match(text)
    if not match:
        return None
    try:
        gain = float(match.group(1))
    except ValueError:
        return None
    return gain if math.isfinite(gain) else None


def _parse_peak(value: Any) -> float | None:
    text = _text_value(value)
    if not text:
        return None
    match = _PEAK_RE.match(text)
    if not match:
        return None
    try:
        peak = float(match.group(1))
    except ValueError:
        return None
    if not math.isfinite(peak) or peak < 0.0:
        return None
    return peak


def _tag_values(tags: Any) -> dict[str, list[str]]:
    """Collect textual tags case-insensitively, including ID3 TXXX frames."""
    values: dict[str, list[str]] = {}
    if not tags:
        return values

    try:
        items = tags.items()
    except AttributeError:
        items = ()
    for key, value in items:
        key_text = str(key)
        parts = [part.strip() for part in key_text.split(":") if part.strip()]
        if not parts:
            continue
        if parts[0].upper() == "TXXX" and len(parts) > 1:
            key_text = parts[-1]
            desc = getattr(value, "desc", "")
            if desc:
                key_text = str(desc)
        elif parts[-1].upper() in {
            "REPLAYGAIN_TRACK_GAIN",
            "REPLAYGAIN_TRACK_PEAK",
            "REPLAYGAIN_ALBUM_GAIN",
            "REPLAYGAIN_ALBUM_PEAK",
            "R128_TRACK_GAIN",
            "R128_ALBUM_GAIN",
        }:
            key_text = parts[-1]
        normalized = key_text.strip().upper()
        if not normalized:
            continue
        text = _text_value(value)
        if text:
            values.setdefault(normalized, []).append(text)
    return values


def _first(values: dict[str, list[str]], *keys: str) -> str:
    for key in keys:
        entries = values.get(key.upper())
        if entries:
            for value in entries:
                if value:
                    return value
    return ""


def _parse_r128_gain(value: Any) -> float | None:
    """Parse an Opus R128 Q7.8 fixed-point gain, referenced to -23 LUFS."""
    text = _text_value(value)
    if not text:
        return None
    try:
        raw = int(text, 10)
    except ValueError:
        return None
    if not _R128_INT_MIN <= raw <= _R128_INT_MAX:
        return None
    return raw / 256.0


def read_replaygain(tags: Any, codec_gain_db: float = 0.0) -> ReplayGainInfo:
    """Read ReplayGain 2.0 metadata plus Opus/R128 metadata.

    ``codec_gain_db`` is decoder-level gain, e.g. the OpusHead output gain.
    It is not added to the user-facing ReplayGain gain because FFmpeg already
    applies it to decoded samples. It is retained for clipping protection.
    """
    try:
        codec_gain_db = float(codec_gain_db)
    except (TypeError, ValueError):
        codec_gain_db = 0.0
    if not math.isfinite(codec_gain_db):
        codec_gain_db = 0.0

    values = _tag_values(tags)
    track_gain = _parse_gain(_first(values, "REPLAYGAIN_TRACK_GAIN"))
    track_peak = _parse_peak(_first(values, "REPLAYGAIN_TRACK_PEAK"))
    album_gain = _parse_gain(_first(values, "REPLAYGAIN_ALBUM_GAIN"))
    album_peak = _parse_peak(_first(values, "REPLAYGAIN_ALBUM_PEAK"))
    if track_gain is not None or album_gain is not None:
        return ReplayGainInfo(
            track_gain_db=track_gain,
            track_peak=track_peak,
            album_gain_db=album_gain,
            album_peak=album_peak,
            source="replaygain",
            codec_gain_db=codec_gain_db,
        )

    # Opus R128 metadata uses -23 LUFS as its reference unlike ReplayGain 2.0's -18 LUFS reference
    # Convert to the ReplayGain 2.0 reference
    r128_track = _parse_r128_gain(_first(values, "R128_TRACK_GAIN"))
    r128_album = _parse_r128_gain(_first(values, "R128_ALBUM_GAIN"))
    if r128_track is None and r128_album is None:
        return ReplayGainInfo(codec_gain_db=codec_gain_db)

    return ReplayGainInfo(
        track_gain_db=(r128_track + 5.0) if r128_track is not None else None,
        album_gain_db=(r128_album + 5.0) if r128_album is not None else None,
        source="r128",
        codec_gain_db=codec_gain_db,
    )


def gain_to_linear(gain_db: float) -> float:
    """Convert a gain in dB to a linear amplitude multiplier."""
    return math.pow(10.0, gain_db / 20.0)


def clipping_safe_gain_db(
    gain_db: float,
    peak: float | None,
    master_volume: float,
    codec_gain_db: float = 0.0,
) -> float:
    """Limit positive gain so the effective peak cannot exceed digital full scale.

    ``codec_gain_db`` has already been applied by the decoder. Therefore it is
    included in the clipping calculation but never in the returned QAudioOutput
    gain, preventing double application.
    """
    gain = float(gain_db)
    master = max(0.0, min(1.0, float(master_volume)))

    if peak is None or peak <= 0.0 or master <= 0.0:
        return gain

    try:
        codec_linear = gain_to_linear(float(codec_gain_db))
    except (ValueError, OverflowError):
        codec_linear = 1.0
    if not math.isfinite(codec_linear) or codec_linear <= 0.0:
        codec_linear = 1.0

    allowed_linear = 1.0 / (peak * master * codec_linear)
    if allowed_linear <= 0.0:
        return gain
    allowed_gain = 20.0 * math.log10(allowed_linear)
    return min(gain, allowed_gain)


def effective_volume(
    master_volume: float,
    gain_db: float | None,
    peak: float | None,
    prevent_clipping: bool,
    preamp_db: float,
    master_gain_db: float = 0.0,
    codec_gain_db: float = 0.0,
) -> float:
    """Return the final QAudioOutput volume for the current track."""
    master = max(0.0, min(1.0, float(master_volume)))
    if master <= 0.0:
        return 0.0

    gain = float(gain_db) if gain_db is not None else 0.0
    gain += float(preamp_db) + float(master_gain_db)

    if prevent_clipping:
        gain = clipping_safe_gain_db(gain, peak, master, codec_gain_db=codec_gain_db)

    return max(0.0, min(1.0, master * gain_to_linear(gain)))
