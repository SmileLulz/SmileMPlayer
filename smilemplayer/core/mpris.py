from __future__ import annotations

import asyncio
import hashlib
import queue
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, QCoreApplication, Qt, Signal

try:
    from dbus_next import DBusError, Variant
    from dbus_next.aio import MessageBus
    from dbus_next.constants import PropertyAccess, RequestNameReply
    from dbus_next.service import ServiceInterface, dbus_property, method, signal
except ImportError as exc:  # pragma: no cover - missing runtime dependency
    raise RuntimeError(
        "SmileMPlayer MPRIS support requires the 'dbus-next' package."
    ) from exc

from .player_backend import PlayerBackend


MPRIS_PATH = "/org/mpris/MediaPlayer2"
MPRIS_BUS_NAME = "org.mpris.MediaPlayer2.smilemplayer"
ROOT_IFACE = "org.mpris.MediaPlayer2"
PLAYER_IFACE = "org.mpris.MediaPlayer2.Player"


@dataclass(frozen=True, slots=True)
class MprisState:
    playback_status: str
    loop_status: str
    rate: float
    shuffle: bool
    volume: float
    position_us: int
    length_us: int
    metadata: dict[str, Variant]
    track_id: str
    can_go_next: bool
    can_go_previous: bool
    can_play: bool
    can_pause: bool
    can_seek: bool


def _track_object_path(path: str) -> str:
    digest = hashlib.sha1(path.encode("utf-8", "surrogatepass")).hexdigest()
    return f"/org/mpris/MediaPlayer2/track/{digest}"


def _file_uri(path: str) -> str:
    from urllib.parse import quote
    return "file://" + quote(str(Path(path).resolve()), safe="/:")


class MprisCommandBridge(QObject):
    """Qt-thread bridge used by the D-Bus worker thread to reach PlayerBackend."""

    playRequested = Signal()
    pauseRequested = Signal()
    playPauseRequested = Signal()
    stopRequested = Signal()
    nextRequested = Signal()
    previousRequested = Signal()
    seekRequested = Signal(int)
    volumeRequested = Signal(float)
    shuffleRequested = Signal(bool)
    loopRequested = Signal(str)
    openUriRequested = Signal(str)
    quitRequested = Signal()


class MprisRootInterface(ServiceInterface):
    def __init__(self, server: "MprisServer") -> None:
        super().__init__(ROOT_IFACE)
        self._server = server

    @method()
    def Raise(self):
        # Do I need to add something here?
        return None

    @method()
    def Quit(self):
        self._server.bridge.quitRequested.emit()

    @dbus_property(PropertyAccess.READ)
    def CanQuit(self) -> "b":
        return True

    @dbus_property(PropertyAccess.READ)
    def CanRaise(self) -> "b":
        return False

    @dbus_property(PropertyAccess.READ)
    def HasTrackList(self) -> "b":
        return False

    @dbus_property(PropertyAccess.READ)
    def Identity(self) -> "s":
        return "SmileMPlayer"

    @dbus_property(PropertyAccess.READ)
    def DesktopEntry(self) -> "s":
        return "smilemplayer"

    @dbus_property(PropertyAccess.READ)
    def SupportedUriSchemes(self) -> "as":
        return ["file"]

    @dbus_property(PropertyAccess.READ)
    def SupportedMimeTypes(self) -> "as":
        return [
            "audio/mpeg",
            "audio/ogg",
            "audio/flac",
            "audio/x-flac",
            "audio/wav",
            "audio/x-wav",
            "audio/aac",
            "audio/mp4",
            "audio/x-m4a",
            "audio/opus",
            "audio/webm",
        ]


class MprisPlayerInterface(ServiceInterface):
    def __init__(self, server: "MprisServer") -> None:
        super().__init__(PLAYER_IFACE)
        self._server = server
        self._state = server.initial_state

    def apply_state(self, state: MprisState) -> None:
        previous = self._state
        self._state = state

        changed: dict[str, Any] = {}
        if state.playback_status != previous.playback_status:
            changed["PlaybackStatus"] = state.playback_status
        if state.loop_status != previous.loop_status:
            changed["LoopStatus"] = state.loop_status
        if state.rate != previous.rate:
            changed["Rate"] = state.rate
        if state.shuffle != previous.shuffle:
            changed["Shuffle"] = state.shuffle
        if state.volume != previous.volume:
            changed["Volume"] = state.volume
        if state.track_id != previous.track_id:
            changed["Metadata"] = state.metadata
        if state.can_go_next != previous.can_go_next:
            changed["CanGoNext"] = state.can_go_next
        if state.can_go_previous != previous.can_go_previous:
            changed["CanGoPrevious"] = state.can_go_previous
        if state.can_play != previous.can_play:
            changed["CanPlay"] = state.can_play
        if state.can_pause != previous.can_pause:
            changed["CanPause"] = state.can_pause
        if state.can_seek != previous.can_seek:
            changed["CanSeek"] = state.can_seek

        if changed:
            self.emit_properties_changed(changed)

    @method()
    def Next(self):
        self._server.bridge.nextRequested.emit()

    @method()
    def Previous(self):
        self._server.bridge.previousRequested.emit()

    @method()
    def Pause(self):
        self._server.bridge.pauseRequested.emit()

    @method()
    def Play(self):
        self._server.bridge.playRequested.emit()

    @method()
    def PlayPause(self):
        self._server.bridge.playPauseRequested.emit()

    @method()
    def Stop(self):
        self._server.bridge.stopRequested.emit()

    @method()
    def Seek(self, Offset: "x"):
        target = max(0, self._state.position_us + int(Offset))
        if self._state.length_us:
            target = min(target, self._state.length_us)
        self._server.bridge.seekRequested.emit(target // 1000)
        self.Seeked(target)

    @method()
    def SetPosition(self, TrackId: "o", Position: "x"):
        # The TrackId guard is important
        # It prevents a stale controller command from seeking a newer track after the current track changed
        if not self._state.track_id or TrackId != self._state.track_id:
            return
        target = max(0, int(Position))
        if self._state.length_us:
            target = min(target, self._state.length_us)
        self._server.bridge.seekRequested.emit(target // 1000)
        self.Seeked(target)

    @method()
    def OpenUri(self, Uri: "s"):
        if not Uri.startswith("file:"):
            raise DBusError(
                "org.mpris.MediaPlayer2.Player.NoUriScheme",
                "SmileMPlayer only supports file:// URIs.",
            )
        self._server.bridge.openUriRequested.emit(Uri)

    @dbus_property(PropertyAccess.READ)
    def PlaybackStatus(self) -> "s":
        return self._state.playback_status

    @dbus_property(PropertyAccess.READWRITE)
    def LoopStatus(self) -> "s":
        return self._state.loop_status

    @LoopStatus.setter
    def LoopStatus(self, value: "s") -> None:
        if value not in {"None", "Track", "Playlist"}:
            raise DBusError(
                "org.mpris.MediaPlayer2.Player.InvalidLoopStatus",
                "LoopStatus must be None, Track, or Playlist.",
            )
        self._server.bridge.loopRequested.emit({
            "None": "none",
            "Track": "track",
            "Playlist": "playlist",
        }[value])

    @dbus_property(PropertyAccess.READWRITE)
    def Rate(self) -> "d":
        return self._state.rate

    @Rate.setter
    def Rate(self, value: "d") -> None:
        value = float(value)
        if value == 0.0:
            self._server.bridge.pauseRequested.emit()
            return
        # QMediaPlayer does not expose rate control through this app
        # So I'm keeping the mandatory MPRIS property at its only valid supported value
        if value != 1.0:
            raise DBusError(
                "org.mpris.MediaPlayer2.Player.Rate",
                "SmileMPlayer does not support variable playback rates.",
            )

    @dbus_property(PropertyAccess.READWRITE)
    def Shuffle(self) -> "b":
        return self._state.shuffle

    @Shuffle.setter
    def Shuffle(self, value: "b") -> None:
        self._server.bridge.shuffleRequested.emit(bool(value))

    @dbus_property(PropertyAccess.READ)
    def Metadata(self) -> "a{sv}":
        return self._state.metadata

    @dbus_property(PropertyAccess.READWRITE)
    def Volume(self) -> "d":
        return self._state.volume

    @Volume.setter
    def Volume(self, value: "d") -> None:
        self._server.bridge.volumeRequested.emit(max(0.0, float(value)))

    @dbus_property(PropertyAccess.READ)
    def Position(self) -> "x":
        return self._state.position_us

    @dbus_property(PropertyAccess.READ)
    def MinimumRate(self) -> "d":
        return 1.0

    @dbus_property(PropertyAccess.READ)
    def MaximumRate(self) -> "d":
        return 1.0

    @dbus_property(PropertyAccess.READ)
    def CanGoNext(self) -> "b":
        return self._state.can_go_next

    @dbus_property(PropertyAccess.READ)
    def CanGoPrevious(self) -> "b":
        return self._state.can_go_previous

    @dbus_property(PropertyAccess.READ)
    def CanPlay(self) -> "b":
        return self._state.can_play

    @dbus_property(PropertyAccess.READ)
    def CanPause(self) -> "b":
        return self._state.can_pause

    @dbus_property(PropertyAccess.READ)
    def CanSeek(self) -> "b":
        return self._state.can_seek

    @dbus_property(PropertyAccess.READ)
    def CanControl(self) -> "b":
        return True

    @signal()
    def Seeked(self, Position: "x") -> "x":
        return Position


class MprisServer:
    """MPRIS 2 service backed by the existing PlayerBackend state machine."""

    def __init__(self, backend: PlayerBackend) -> None:
        self.backend = backend
        self.bridge = MprisCommandBridge()
        self.queue: queue.Queue[MprisState] = queue.Queue()
        self.thread = threading.Thread(target=self._thread_main, name="smilemplayer-mpris", daemon=True)
        self._ready = threading.Event()
        self._error: BaseException | None = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._async_stop: asyncio.Event | None = None
        self._bus: MessageBus | None = None

        self._connect_bridge()
        for signal in (
            backend.currentTrackChanged,
            backend.positionChanged,
            backend.durationChanged,
            backend.playingChanged,
            backend.volumeChanged,
            backend.shuffleChanged,
            backend.loopModeChanged,
            backend.capabilitiesChanged,
        ):
            signal.connect(self._queue_state)

        self.initial_state = self._snapshot()
        self._queue_state()

    def _connect_bridge(self) -> None:
        self.bridge.playRequested.connect(self.backend.play, Qt.ConnectionType.QueuedConnection)
        self.bridge.pauseRequested.connect(self.backend.pause, Qt.ConnectionType.QueuedConnection)
        self.bridge.playPauseRequested.connect(self.backend.playPause, Qt.ConnectionType.QueuedConnection)
        self.bridge.stopRequested.connect(self.backend.stop, Qt.ConnectionType.QueuedConnection)
        self.bridge.nextRequested.connect(self.backend.next, Qt.ConnectionType.QueuedConnection)
        self.bridge.previousRequested.connect(self.backend.previous, Qt.ConnectionType.QueuedConnection)
        self.bridge.seekRequested.connect(self.backend.seek, Qt.ConnectionType.QueuedConnection)
        self.bridge.volumeRequested.connect(self.backend.setVolume, Qt.ConnectionType.QueuedConnection)
        self.bridge.shuffleRequested.connect(self.backend.setShuffle, Qt.ConnectionType.QueuedConnection)
        self.bridge.loopRequested.connect(self.backend.setLoopMode, Qt.ConnectionType.QueuedConnection)
        self.bridge.openUriRequested.connect(self.backend.openFile, Qt.ConnectionType.QueuedConnection)
        self.bridge.quitRequested.connect(QCoreApplication.quit, Qt.ConnectionType.QueuedConnection)

    def _snapshot(self) -> MprisState:
        backend = self.backend
        track = backend.current_track
        tracks = backend.library.current_tracks()
        index = backend.currentIndex

        if backend.playing:
            playback_status = "Playing"
        elif track is not None:
            playback_status = (
                "Paused"
                if backend._media.playbackState().name == "PausedState"
                else "Stopped"
            )
        else:
            playback_status = "Stopped"

        loop_status = {
            "none": "None",
            "track": "Track",
            "playlist": "Playlist",
        }.get(backend.loopMode, "None")

        metadata: dict[str, Variant] = {}
        track_id = ""
        length_us = max(0, int(backend.duration)) * 1000

        if track is not None:
            track_id = _track_object_path(track.path)
            metadata = {
                "mpris:trackid": Variant("o", track_id),
                "mpris:length": Variant("x", length_us),
                "xesam:title": Variant("s", track.title or track.filename),
                "xesam:artist": Variant("as", [track.artist] if track.artist else []),
                "xesam:album": Variant("s", track.album) if track.album else Variant("s", ""),
                "xesam:genre": Variant("as", [track.genre] if track.genre else []),
                "xesam:url": Variant("s", _file_uri(track.path)),
            }
            if track.art_url:
                metadata["mpris:artUrl"] = Variant("s", track.art_url)

        if not track:
            can_play = bool(tracks)
            can_pause = False
            can_seek = False
        else:
            can_play = True
            can_pause = True
            can_seek = bool(backend._media.isSeekable())

        if not tracks:
            can_go_next = False
            can_go_previous = False
        else:
            can_go_previous = index >= 0
            can_go_next = (
                backend.shuffle
                or backend.loopMode == "playlist"
                or index < len(tracks) - 1
                or index < 0
            )

        return MprisState(
            playback_status=playback_status,
            loop_status=loop_status,
            rate=1.0,
            shuffle=bool(backend.shuffle),
            volume=float(backend.volume),
            position_us=max(0, int(backend.position)) * 1000,
            length_us=length_us,
            metadata=metadata,
            track_id=track_id,
            can_go_next=bool(can_go_next),
            can_go_previous=bool(can_go_previous),
            can_play=bool(can_play),
            can_pause=bool(can_pause),
            can_seek=bool(can_seek),
        )

    def _queue_state(self) -> None:
        try:
            self.queue.put_nowait(self._snapshot())
            if self._loop is not None:
                self._loop.call_soon_threadsafe(lambda: None)
        except RuntimeError:
            # When stopping the app, it can race signal delivery
            # State publication is no longer useful once the server is stopping
            pass

    def start(self) -> bool:
        self.thread.start()
        self._ready.wait(timeout=5.0)
        if self._error is not None:
            return False
        return self._ready.is_set()

    def stop(self) -> None:
        if not self.thread.is_alive():
            return
        if self._async_stop is not None and self._loop is not None:
            self._loop.call_soon_threadsafe(self._async_stop.set)
        self.thread.join(timeout=2.0)

    async def _run(self) -> None:
        self._loop = asyncio.get_running_loop()
        self._async_stop = asyncio.Event()
        self._bus = await MessageBus().connect()

        root = MprisRootInterface(self)
        player = MprisPlayerInterface(self)
        self._bus.export(MPRIS_PATH, root)
        self._bus.export(MPRIS_PATH, player)

        reply = await self._bus.request_name(MPRIS_BUS_NAME)
        if reply != RequestNameReply.PRIMARY_OWNER:
            instance_name = f"{MPRIS_BUS_NAME}.instance{__import__('os').getpid()}"
            await self._bus.request_name(instance_name)

        self._ready.set()

        while not self._async_stop.is_set():
            await asyncio.sleep(0.025)
            while True:
                try:
                    state = self.queue.get_nowait()
                except queue.Empty:
                    break
                player.apply_state(state)

        self._bus.disconnect()
        self._bus = None

    def _thread_main(self) -> None:
        try:
            asyncio.run(self._run())
        except BaseException as exc:
            self._error = exc
            self._ready.set()
