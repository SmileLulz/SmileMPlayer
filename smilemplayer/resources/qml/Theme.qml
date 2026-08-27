pragma Singleton

import QtQuick

QtObject {
    readonly property QtObject color: QtObject {
        readonly property color accent: "#c9beff"
        readonly property color accentDark: "#605790"

        readonly property color background: "#1c1b20"
        readonly property color backgroundLight: Qt.lighter("#201f25", 1.1)
        readonly property color backgroundLighter: Qt.darker("#605c71", 1.8)
        readonly property color backgroundDarker: background

        readonly property color text: "#c9c5d0"
        readonly property color textSecondary: "#938f99"

        readonly property color border: Qt.darker("#c9beff", 1.8)
        readonly property color error: "#ffb4ab"
    }

    readonly property QtObject font: QtObject {
        readonly property int sizeS: 12
        readonly property int sizeMS: 13
        readonly property int sizeM: 15
        readonly property int sizeL: 18
        readonly property int sizeXL: 21
        readonly property int sizeXXL: 24
    }
}
