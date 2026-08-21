from __future__ import annotations

from PySide6.QtCore import QObject, Signal, QUrl
from PySide6.QtMultimedia import QAudioOutput, QMediaPlayer


class MediaPlayer(QObject):
    """
    Thin wrapper around QMediaPlayer + QAudioOutput.
    Exposes clean signals and methods for playback control.
    """

    positionChanged = Signal(int)
    durationChanged = Signal(int)
    playbackStateChanged = Signal(QMediaPlayer.PlaybackState)
    mediaStatusChanged = Signal(QMediaPlayer.MediaStatus)
    errorOccurred = Signal(str)
    sourceChanged = Signal(QUrl)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._player = QMediaPlayer(self)
        self._audio_output = QAudioOutput(self)
        self._player.setAudioOutput(self._audio_output)

        self._player.positionChanged.connect(self.positionChanged.emit)
        self._player.durationChanged.connect(self.durationChanged.emit)
        self._player.playbackStateChanged.connect(self.playbackStateChanged.emit)
        self._player.mediaStatusChanged.connect(self.mediaStatusChanged.emit)
        self._player.errorOccurred.connect(self._on_error)
        self._player.sourceChanged.connect(self.sourceChanged.emit)

        self._last_error = ""

    def _on_error(self, error: QMediaPlayer.Error, error_string: str) -> None:
        self._last_error = error_string
        self.errorOccurred.emit(error_string)

    # Public API
    def setSource(self, url: QUrl) -> None:
        self._player.setSource(url)

    def play(self) -> None:
        self._player.play()

    def pause(self) -> None:
        self._player.pause()

    def stop(self) -> None:
        self._player.stop()

    def seek(self, position_ms: int) -> None:
        if self._player.isSeekable():
            self._player.setPosition(position_ms)

    def position(self) -> int:
        return self._player.position()

    def duration(self) -> int:
        return self._player.duration()

    def playbackState(self) -> QMediaPlayer.PlaybackState:
        return self._player.playbackState()

    def mediaStatus(self) -> QMediaPlayer.MediaStatus:
        return self._player.mediaStatus()

    def volume(self) -> float:
        return self._audio_output.volume()

    def setVolume(self, volume: float) -> None:
        self._audio_output.setVolume(max(0.0, min(1.0, float(volume))))

    @property
    def last_error(self) -> str:
        return self._last_error

    def isSeekable(self) -> bool:
        return self._player.isSeekable()
