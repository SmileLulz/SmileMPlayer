from __future__ import annotations

import random
from pathlib import Path

from PySide6.QtCore import QObject, Property, QTimer, QUrl, Signal, Slot
from PySide6.QtMultimedia import QMediaPlayer

from .library import LibraryManager
from .lyrics import LrcParser, LyricsDocument, LyricsSynchronizer, find_sidecar
from .media_player import MediaPlayer
from .models import Track
from .playlist_model import PlaylistModel
from .replaygain import effective_volume
from .settings import AppSettings


class PlayerBackend(QObject):
    """
    Main player controller - handles playlist logic, playback, sorting,
    shuffle, loop mode, ReplayGain normalization, and exposes properties to QML.
    """
    currentTrackChanged = Signal()
    positionChanged = Signal()
    durationChanged = Signal()
    playingChanged = Signal()
    volumeChanged = Signal()
    shuffleChanged = Signal()
    loopModeChanged = Signal()
    errorChanged = Signal()
    trackChanged = Signal(int)
    statusMessage = Signal(str)
    capabilitiesChanged = Signal()
    sortKeyChanged = Signal()
    replayGainChanged = Signal()
    lyricsChanged = Signal()
    currentLyricChanged = Signal()
    lyricsSyncModeChanged = Signal()

    LOOP_MODES = ("none", "track", "playlist")
    REPLAYGAIN_MODES = ("track", "album")

    def __init__(self, library: LibraryManager, settings: AppSettings, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.library = library
        self.settings = settings
        self.playlistModel: PlaylistModel = library.playlistModel

        self._media = MediaPlayer(self)
        self._media.positionChanged.connect(self._on_position)
        self._media.durationChanged.connect(self._on_duration)
        self._media.playbackStateChanged.connect(self._on_playback_state)
        self._media.mediaStatusChanged.connect(self._on_media_status)
        self._media.errorOccurred.connect(self._on_error)
        self._media.sourceChanged.connect(lambda _: self.currentTrackChanged.emit())

        self._master_volume = max(0.0, min(1.0, float(settings.data.get("volume", 0.8))))
        self._media.setVolume(self._master_volume)

        self._replaygain_enabled = bool(settings.data.get("replaygain_enabled", True))
        replaygain_mode = str(settings.data.get("replaygain_mode", "track"))
        self._replaygain_mode = replaygain_mode if replaygain_mode in self.REPLAYGAIN_MODES else "track"
        self._replaygain_preamp_db = float(settings.data.get("replaygain_preamp_db", 0.0))
        self._master_gain_db = float(settings.data.get("master_gain_db", 0.0))
        self._replaygain_prevent_clipping = bool(settings.data.get("replaygain_prevent_clipping", True))

        self._current_index = -1
        self._position_ms = 0
        self._duration_ms = 0
        self._shuffle = bool(settings.data.get("shuffle", False))
        loop = str(settings.data.get("loop", "none"))
        self._loop_mode = loop if loop in self.LOOP_MODES else "none"
        self._started = False
        self._rng = random.Random()
        self._last_error = ""
        self._sort_key = str(settings.data.get("sort", "title"))
        self._sort_desc = bool(settings.data.get("sort_desc", False))

        self._lyrics_parser = LrcParser()
        self._lyrics_sync = LyricsSynchronizer()
        self._lyrics_document = LyricsDocument(lines=tuple())
        lyrics_sync_mode = str(settings.data.get("lyrics_sync_mode", "line"))
        self._lyrics_sync_mode = lyrics_sync_mode if lyrics_sync_mode in ("line", "word") else "line"

        self._volume_save_timer = QTimer(self)
        self._volume_save_timer.setSingleShot(True)
        self._volume_save_timer.setInterval(500)
        self._volume_save_timer.timeout.connect(self._save_volume)

        self.library.scanFinished.connect(self._on_playlist_scan_finished)
        self.library.rescanStarted.connect(self._on_playlist_rescan_started)
        self.library.currentPlaylistChanged.connect(self._on_playlist_changed)

    def startup(self) -> None:
        """Start scanning any unloaded playlists on application launch."""
        if self._started:
            return
        self._started = True
        for index, tracks in enumerate(self.library._tracks):
            if not tracks:
                self.library.scanPlaylist(index)

    # QML Properties
    @Property(QObject, constant=True)
    def playlistModelObject(self) -> QObject:
        return self.playlistModel

    @Property(str, notify=currentTrackChanged)
    def title(self) -> str:
        track = self.current_track
        return track.title if track else "Nothing playing"

    @Property(str, notify=currentTrackChanged)
    def artist(self) -> str:
        track = self.current_track
        return track.artist if track and track.artist else "Unknown artist"

    @Property(str, notify=currentTrackChanged)
    def album(self) -> str:
        track = self.current_track
        return track.album if track and track.album else "Unknown album"

    @Property(str, notify=currentTrackChanged)
    def coverArt(self) -> str:
        track = self.current_track
        return track.art_url if track else ""

    @Property(str, notify=currentTrackChanged)
    def path(self) -> str:
        track = self.current_track
        return track.path if track else ""

    @Property(int, notify=positionChanged)
    def position(self) -> int:
        return self._position_ms

    @Property(int, notify=durationChanged)
    def duration(self) -> int:
        return self._duration_ms

    @Property(bool, notify=playingChanged)
    def playing(self) -> bool:
        return self._media.playbackState() == QMediaPlayer.PlaybackState.PlayingState

    @Property(float, notify=volumeChanged)
    def volume(self) -> float:
        return self._master_volume

    @volume.setter
    def volume(self, value: float) -> None:
        self.setVolume(value)

    @Property(bool, notify=shuffleChanged)
    def shuffle(self) -> bool:
        return self._shuffle

    @shuffle.setter
    def shuffle(self, value: bool) -> None:
        self.setShuffle(value)

    @Property(str, notify=loopModeChanged)
    def loopMode(self) -> str:
        return self._loop_mode

    @loopMode.setter
    def loopMode(self, value: str) -> None:
        self.setLoopMode(value)

    @Property(bool, notify=replayGainChanged)
    def replayGainEnabled(self) -> bool:
        return self._replaygain_enabled

    @replayGainEnabled.setter
    def replayGainEnabled(self, value: bool) -> None:
        self.setReplayGainEnabled(value)

    @Property(str, notify=replayGainChanged)
    def replayGainMode(self) -> str:
        return self._replaygain_mode

    @replayGainMode.setter
    def replayGainMode(self, value: str) -> None:
        self.setReplayGainMode(value)

    @Property(float, notify=replayGainChanged)
    def replayGainPreampDb(self) -> float:
        return self._replaygain_preamp_db

    @Property(bool, notify=replayGainChanged)
    def replayGainPreventClipping(self) -> bool:
        return self._replaygain_prevent_clipping

    @Property(float, notify=replayGainChanged)
    def masterGainDb(self) -> float:
        return self._master_gain_db

    @masterGainDb.setter
    def masterGainDb(self, value: float) -> None:
        self.setMasterGainDb(value)

    @Property(str, notify=currentTrackChanged)
    def replayGainSource(self) -> str:
        track = self.current_track
        return track.replaygain.source if track else ""

    @Property(float, notify=currentTrackChanged)
    def currentReplayGainDb(self) -> float:
        track = self.current_track
        if not track:
            return 0.0
        gain = track.replaygain.gain_db(self._replaygain_mode)
        return float(gain) if gain is not None else 0.0

    @Property(str, notify=errorChanged)
    def lastError(self) -> str:
        return self._last_error

    @Property(int, notify=trackChanged)
    def currentIndex(self) -> int:
        return self._current_index

    @Property(bool, notify=capabilitiesChanged)
    def canGoPrevious(self) -> bool:
        return bool(self.library.current_tracks())

    @Property(bool, notify=capabilitiesChanged)
    def canGoNext(self) -> bool:
        return bool(self.library.current_tracks())

    @Property(str, notify=sortKeyChanged)
    def sortKey(self) -> str:
        return self._sort_key

    @Property(bool, notify=lyricsChanged)
    def lyricsAvailable(self) -> bool:
        return bool(self._lyrics_document.lines)

    @Property(list, notify=lyricsChanged)
    def lyrics(self) -> list[dict]:
        return [
            {
                "timestampMs": line.timestamp_ms,
                "text": line.text,
                "enhanced": line.enhanced,
                "words": [
                    {
                        "timestampMs": word.timestamp_ms,
                        "text": word.text,
                    }
                    for word in line.words
                ],
            }
            for line in self._lyrics_document.lines
        ]

    @Property(dict, notify=lyricsChanged)
    def lyricsMetadata(self) -> dict:
        return dict(self._lyrics_document.metadata)

    @Property(int, notify=lyricsChanged)
    def lyricsOffsetMs(self) -> int:
        return self._lyrics_document.offset_ms

    @Property(str, notify=lyricsSyncModeChanged)
    def lyricsSyncMode(self) -> str:
        return self._lyrics_sync_mode

    @lyricsSyncMode.setter
    def lyricsSyncMode(self, value: str) -> None:
        self.setLyricsSyncMode(value)

    @Property(int, notify=currentLyricChanged)
    def currentLyricIndex(self) -> int:
        return self._lyrics_sync.line_index

    @Property(int, notify=currentLyricChanged)
    def currentLyricWordIndex(self) -> int:
        return self._lyrics_sync.word_index

    @Property(str, notify=currentLyricChanged)
    def currentLyricText(self) -> str:
        index = self._lyrics_sync.line_index
        if 0 <= index < len(self._lyrics_document.lines):
            return self._lyrics_document.lines[index].text
        return ""

    @property
    def current_track(self) -> Track | None:
        return self.playlistModel.track(self._current_index)

    # Playback Control
    @Slot(int, bool)
    def playIndex(self, index: int, autoplay: bool = True) -> None:
        track = self.playlistModel.track(index)
        if not track:
            return
        self._current_index = index
        self._position_ms = 0
        self._duration_ms = track.duration_ms
        self._load_lyrics_for_track(track.path)
        self._apply_replaygain()
        self._media.setSource(QUrl.fromLocalFile(track.path))
        if autoplay:
            self._media.play()
        self._emit_track_signals()

    @Slot()
    def play(self) -> None:
        if not self.current_track:
            tracks = self.library.current_tracks()
            if tracks:
                self.playIndex(0, True)
            return
        self._media.play()

    @Slot()
    def pause(self) -> None:
        self._media.pause()

    @Slot()
    def playPause(self) -> None:
        if self.playing:
            self.pause()
        else:
            self.play()

    @Slot()
    def stop(self) -> None:
        self._media.stop()

    @Slot()
    def next(self) -> None:
        tracks = self.library.current_tracks()
        if not tracks:
            return
        if self._shuffle and len(tracks) > 1:
            candidates = [i for i in range(len(tracks)) if i != self._current_index]
            self.playIndex(self._rng.choice(candidates), True)
            return
        if self._current_index < len(tracks) - 1:
            self.playIndex(self._current_index + 1, True)
            return
        if self._loop_mode == "playlist":
            self.playIndex(0, True)
        else:
            self.stop()
            self.statusMessage.emit("Reached the end of the playlist")

    @Slot()
    def previous(self) -> None:
        tracks = self.library.current_tracks()
        if not tracks:
            return
        if self._position_ms > 3000:
            self._seek_internal(0)
            return
        if self._shuffle and len(tracks) > 1:
            candidates = [i for i in range(len(tracks)) if i != self._current_index]
            self.playIndex(self._rng.choice(candidates), True)
            return
        if self._current_index > 0:
            self.playIndex(self._current_index - 1, True)
        elif self._loop_mode == "playlist":
            self.playIndex(len(tracks) - 1, True)
        else:
            self._seek_internal(0)

    @Slot(int)
    def seek(self, position_ms: int) -> None:
        self._seek_internal(position_ms)

    @Slot(int)
    def seekToLyric(self, index: int) -> None:
        if not 0 <= index < len(self._lyrics_document.lines):
            return
        self._seek_internal(self._lyrics_document.lines[index].timestamp_ms)

    @Slot(int, int)
    def seekToLyricWord(self, line_index: int, word_index: int) -> None:
        if not 0 <= line_index < len(self._lyrics_document.lines):
            return
        words = self._lyrics_document.lines[line_index].words
        if not 0 <= word_index < len(words):
            return
        self._seek_internal(words[word_index].timestamp_ms)

    @Slot(str)
    def setLyricsSyncMode(self, mode: str) -> None:
        mode = str(mode)
        if mode not in ("line", "word") or mode == self._lyrics_sync_mode:
            return
        self._lyrics_sync_mode = mode
        self.settings.data["lyrics_sync_mode"] = mode
        self.settings.save()
        self.lyricsSyncModeChanged.emit()

    @Slot()
    def reloadLyrics(self) -> None:
        track = self.current_track
        if track is None:
            self._clear_lyrics()
            return
        self._load_lyrics_for_track(track.path)

    def _seek_internal(self, position_ms: int) -> None:
        self._media.seek(position_ms)

    # Volume
    @Slot(float)
    def setVolume(self, value: float) -> None:
        value = max(0.0, min(1.0, float(value)))
        self._master_volume = value
        self._apply_replaygain()
        self.settings.data["volume"] = value
        self._volume_save_timer.start()
        self.volumeChanged.emit()

    @Slot()
    def _save_volume(self) -> None:
        self.settings.save()

    # ReplayGain
    def _apply_replaygain(self) -> None:
        track = self.current_track
        if not self._replaygain_enabled or not track:
            self._media.setVolume(self._master_volume)
            return

        gain = track.replaygain.gain_db(self._replaygain_mode)
        peak = track.replaygain.peak(self._replaygain_mode)
        volume = effective_volume(
            master_volume=self._master_volume,
            gain_db=gain,
            peak=peak,
            prevent_clipping=self._replaygain_prevent_clipping,
            preamp_db=self._replaygain_preamp_db,
            master_gain_db=self._master_gain_db,
        )
        self._media.setVolume(volume)

    @Slot(bool)
    def setReplayGainEnabled(self, value: bool) -> None:
        value = bool(value)
        if value == self._replaygain_enabled:
            return
        self._replaygain_enabled = value
        self.settings.data["replaygain_enabled"] = value
        self.settings.save()
        self._apply_replaygain()
        self.replayGainChanged.emit()

    @Slot(str)
    def setReplayGainMode(self, value: str) -> None:
        if value not in self.REPLAYGAIN_MODES or value == self._replaygain_mode:
            return
        self._replaygain_mode = value
        self.settings.data["replaygain_mode"] = value
        self.settings.save()
        self._apply_replaygain()
        self.replayGainChanged.emit()
        self.currentTrackChanged.emit()

    @Slot(float)
    def setReplayGainPreampDb(self, value: float) -> None:
        value = float(value)
        if value == self._replaygain_preamp_db:
            return
        self._replaygain_preamp_db = value
        self.settings.data["replaygain_preamp_db"] = value
        self.settings.save()
        self._apply_replaygain()
        self.replayGainChanged.emit()

    @Slot(float)
    def setMasterGainDb(self, value: float) -> None:
        value = max(-12.0, min(12.0, float(value)))
        if value == self._master_gain_db:
            return
        self._master_gain_db = value
        self.settings.data["master_gain_db"] = value
        self.settings.save()
        self._apply_replaygain()
        self.replayGainChanged.emit()

    @Slot(bool)
    def setReplayGainPreventClipping(self, value: bool) -> None:
        value = bool(value)
        if value == self._replaygain_prevent_clipping:
            return
        self._replaygain_prevent_clipping = value
        self.settings.data["replaygain_prevent_clipping"] = value
        self.settings.save()
        self._apply_replaygain()
        self.replayGainChanged.emit()

    # Shuffle
    @Slot()
    def toggleShuffle(self) -> None:
        self.setShuffle(not self._shuffle)

    @Slot(bool)
    def setShuffle(self, value: bool) -> None:
        value = bool(value)
        if value == self._shuffle:
            return
        self._shuffle = value
        self.settings.data["shuffle"] = value
        self.settings.save()
        self.shuffleChanged.emit()

    # Loop
    @Slot()
    def cycleLoopMode(self) -> None:
        index = self.LOOP_MODES.index(self._loop_mode)
        self.setLoopMode(self.LOOP_MODES[(index + 1) % len(self.LOOP_MODES)])

    @Slot(str)
    def setLoopMode(self, value: str) -> None:
        if value not in self.LOOP_MODES:
            return
        if value == self._loop_mode:
            return
        self._loop_mode = value
        self.settings.data["loop"] = value
        self.settings.save()
        self.loopModeChanged.emit()

    # Sorting
    @Slot(str)
    def sortCurrentPlaylist(self, key: str) -> None:
        allowed = {"title", "artist", "filename", "mtime", "duration"}
        if key not in allowed or not self.library._tracks:
            return

        tracks = self.library.current_tracks()
        current_path = self.current_track.path if self.current_track else ""

        if key == "duration":
            tracks.sort(key=lambda t: (t.duration_ms, t.title.casefold(), t.path.casefold()), reverse=self._sort_desc)
        elif key == "filename":
            tracks.sort(key=lambda t: t.filename.casefold(), reverse=self._sort_desc)
        elif key == "artist":
            tracks.sort(key=lambda t: (t.artist.casefold(), t.title.casefold(), t.path.casefold()), reverse=self._sort_desc)
        elif key == "mtime":
            tracks.sort(key=lambda t: (t.mtime, t.title.casefold(), t.path.casefold()), reverse=self._sort_desc)
        else:
            tracks.sort(key=lambda t: (t.title.casefold(), t.artist.casefold(), t.path.casefold()), reverse=self._sort_desc)

        self.library._tracks[self.library.currentPlaylist] = tracks
        self.library._sync_model()
        self._sort_key = key
        self.settings.data["sort"] = key
        self.settings.data["sort_desc"] = self._sort_desc
        self.settings.save()

        self.sortKeyChanged.emit()

        if current_path:
            self._current_index = next(
                (i for i, track in enumerate(tracks) if track.path == current_path),
                -1,
            )
        elif self._current_index >= len(tracks):
            self._current_index = -1

        self.trackChanged.emit(self._current_index)
        self.currentTrackChanged.emit()
        self._apply_replaygain()

    @Slot()
    def toggleSortDirection(self) -> None:
        self._sort_desc = not self._sort_desc
        self.sortCurrentPlaylist(self._sort_key)

    # File Opening
    @Slot(str)
    def openFile(self, file_url: str) -> None:
        url = QUrl(file_url)
        if url.isLocalFile():
            path = Path(url.toLocalFile()).resolve()
        else:
            path = Path(file_url).expanduser().resolve()

        tracks = self.library.current_tracks()
        for i, track in enumerate(tracks):
            if Path(track.path).resolve() == path:
                self.playIndex(i, True)
                return
        self.statusMessage.emit(f"File is not in the current playlist: {path.name}")

    # Error Display
    @Slot()
    def showError(self) -> None:
        if self._last_error:
            self.statusMessage.emit(self._last_error)

    # Lyrics
    def _clear_lyrics(self) -> None:
        self._lyrics_document = LyricsDocument(lines=tuple())
        self._lyrics_sync.set_document(self._lyrics_document)
        self.lyricsChanged.emit()
        self.currentLyricChanged.emit()

    def _load_lyrics_for_track(self, track_path: str) -> None:
        sidecar = find_sidecar(track_path)
        document = (
            self._lyrics_parser.parse_file(sidecar)
            if sidecar is not None
            else LyricsDocument(lines=tuple())
        )
        self._lyrics_document = document
        self._lyrics_sync.set_document(document)
        self._lyrics_sync.update(self._position_ms)
        self.lyricsChanged.emit()
        self.currentLyricChanged.emit()

    # Internal Signal Handlers
    def _on_position(self, position: int) -> None:
        self._position_ms = position
        old_line = self._lyrics_sync.line_index
        old_word = self._lyrics_sync.word_index
        new_line, new_word = self._lyrics_sync.update(position)
        self.positionChanged.emit()
        if old_line != new_line or old_word != new_word:
            self.currentLyricChanged.emit()

    def _on_duration(self, duration: int) -> None:
        self._duration_ms = duration if duration else (self.current_track.duration_ms if self.current_track else 0)
        self.durationChanged.emit()

    def _on_playback_state(self, state: QMediaPlayer.PlaybackState) -> None:
        self.playingChanged.emit()

    def _on_media_status(self, status: QMediaPlayer.MediaStatus) -> None:
        if status == QMediaPlayer.MediaStatus.EndOfMedia:
            if self._loop_mode == "track":
                self._seek_internal(0)
                self._media.play()
            else:
                self.next()
        elif status == QMediaPlayer.MediaStatus.InvalidMedia:
            if self._last_error:
                self.statusMessage.emit(self._last_error)

    def _on_error(self, error_string: str) -> None:
        self._last_error = error_string
        self.errorChanged.emit()
        if self._last_error:
            self.statusMessage.emit(self._last_error)

    @Slot()
    def _on_playlist_changed(self) -> None:
        self._media.stop()
        self._current_index = -1
        self._position_ms = 0
        self._duration_ms = 0
        self._clear_lyrics()
        self._media.setVolume(self._master_volume)
        self.trackChanged.emit(-1)
        self.currentTrackChanged.emit()
        self.positionChanged.emit()
        self.durationChanged.emit()
        self.capabilitiesChanged.emit()

        if self.library.current_tracks() and self._sort_key:
            self.sortCurrentPlaylist(self._sort_key)

    def _on_playlist_scan_finished(self, playlist_name: str, count: int) -> None:
        if playlist_name == self.library.playlist_name(self.library.currentPlaylist):
            self.statusMessage.emit(f"{playlist_name}: {count} tracks")
            if self._sort_key:
                self.sortCurrentPlaylist(self._sort_key)
        self.capabilitiesChanged.emit()
    
    def _on_playlist_rescan_started(self) -> None:
        self._media.stop()
        self._current_index = -1
        self._position_ms = 0
        self._duration_ms = 0
        self._clear_lyrics()

        self._media.setVolume(self._master_volume)

        self.trackChanged.emit(-1)
        self.currentTrackChanged.emit()
        self.positionChanged.emit()
        self.durationChanged.emit()
        self.capabilitiesChanged.emit()

    def _emit_track_signals(self) -> None:
        self.trackChanged.emit(self._current_index)
        self.currentTrackChanged.emit()
        self.positionChanged.emit()
        self.durationChanged.emit()
        self.capabilitiesChanged.emit()
        self.replayGainChanged.emit()
