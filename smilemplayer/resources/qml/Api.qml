pragma Singleton
import QtQuick

QtObject {
    // Backend references (set from Main.qml)
    property var player: null
    property var library: null

    // Utility functions
    function formatTime(ms) {
        var total = Math.max(0, Math.floor(ms / 1000))
        var m = Math.floor(total / 60)
        var s = total % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function loopLabel(mode) {
        if (mode === "track") return "Track"
        if (mode === "playlist") return "Playlist"
        return "Off"
    }
}
