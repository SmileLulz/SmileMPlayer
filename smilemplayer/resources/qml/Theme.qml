pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject color: QtObject {
        readonly property color accent: "#FFB4C8"
        readonly property color accentDark: "#6D2B4A"

        readonly property color background: "#1C1B1F"
        readonly property color backgroundLight: "#2B2930"
        readonly property color backgroundLighter: "#3A3740"
        readonly property color backgroundDarker: "#211F26"

        readonly property color text: "#E6E1E5"
        readonly property color textSecondary: "#CAC4D0"

        readonly property color border: "#4A4458"
        readonly property color error: "#F2B8B5"
    }

    readonly property QtObject font: QtObject {
        readonly property int sizeS: 12
        readonly property int sizeM: 15
        readonly property int sizeL: 18
        readonly property int sizeXL: 21
        readonly property int sizeXXL: 24
    }
}
