pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    topLeftRadius: 8
    topRightRadius: 8
    bottomLeftRadius: 28
    bottomRightRadius: 8

    color: Theme.color.backgroundLight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Lyrics"
                color: Theme.color.textSecondary
                font.pixelSize: Theme.font.sizeL
                font.bold: true
            }

            BasicButton {
                id: modeButton
                Layout.preferredWidth: 78
                Layout.preferredHeight: 36
                label: Api.player && Api.player.lyricsSyncMode === "word"
                    ? "Word"
                    : "Line"
                radiusTopLeft: 12
                radiusTopRight: 12
                radiusBottomRight: 12
                radiusBottomLeft: 12
                fontSize: Theme.font.sizeS
                fontBold: true
                padding: 8
                canClick: Api.player !== null

                onClicked: syncModeMenu.openForItem(modeButton)
            }

            SelectionMenu {
                id: syncModeMenu

                width: 130
                model: ["Line", "Word"]

                currentIndex:
                    Api.player && Api.player.lyricsSyncMode === "word"
                        ? 1
                        : 0

                title: "Sync mode"

                onSelected: function(index, value) {
                    Api.player.lyricsSyncMode =
                        index === 1 ? "word" : "line"
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: lyricsView

                anchors.fill: parent

                clip: true
                spacing: 2

                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds

                model: Api.player ? Api.player.lyrics : []

                visible:
                    Api.player !== null &&
                    Api.player.lyricsAvailable

                highlightFollowsCurrentItem: true
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: height / 2 - 1
                preferredHighlightEnd: height / 2 + 1

                highlightMoveDuration: 450
                highlightMoveVelocity: -1

                flickDeceleration: 1800
                maximumFlickVelocity: 1800

                WheelHandler {
                    id: wheelHandler

                    target: null
                    blocking: true

                    onWheel: function(event) {
                        const delta = event.angleDelta.y

                        if (delta === 0)
                            return

                        const pixelsPerNotch = 55
                        const maxY = Math.max(
                            0,
                            lyricsView.contentHeight - lyricsView.height
                        )

                        const targetY = Math.max(
                            0,
                            Math.min(
                                maxY,
                                lyricsView.contentY -
                                (delta / 120) * pixelsPerNotch
                            )
                        )

                        wheelAnimation.from = lyricsView.contentY
                        wheelAnimation.to = targetY
                        wheelAnimation.start()

                        event.accepted = true
                    }
                }

                NumberAnimation {
                    id: wheelAnimation

                    target: lyricsView
                    property: "contentY"

                    duration: 280
                    easing.type: Easing.OutCubic
                }

                delegate: Item {
                    id: lyricDelegate

                    required property int index
                    required property var modelData

                    width: lyricsView.width
                    implicitHeight: lineContent.implicitHeight + 10

                    readonly property bool current:
                        Api.player !== null &&
                        index === Api.player.currentLyricIndex

                    ColumnLayout {
                        id: lineContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top

                        anchors.margins: 4

                        spacing: 3

                        Text {
                            Layout.fillWidth: true

                            visible:
                                Api.player === null ||
                                Api.player.lyricsSyncMode === "line" ||
                                !lyricDelegate.modelData.enhanced

                            text: lyricDelegate.modelData.text

                            color:
                                lyricDelegate.current
                                    ? Theme.color.text
                                    : Theme.color.textSecondary

                            font.pixelSize: Theme.font.sizeM
                            font.bold: lyricDelegate.current

                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        Flow {
                            id: wordFlow

                            Layout.fillWidth: true

                            visible:
                                Api.player !== null &&
                                Api.player.lyricsSyncMode === "word" &&
                                lyricDelegate.modelData.enhanced

                            spacing: 0

                            Repeater {
                                model: lyricDelegate.modelData.words

                                delegate: Item {
                                    required property int index
                                    required property var modelData

                                    implicitWidth: wordText.implicitWidth
                                    implicitHeight: wordText.implicitHeight

                                    width: implicitWidth
                                    height: implicitHeight

                                    Text {
                                        id: wordText

                                        anchors.fill: parent

                                        text: modelData.text

                                        color:
                                            lyricDelegate.current &&
                                            index ===
                                                Api.player.currentLyricWordIndex
                                                ? Theme.color.accent
                                            : lyricDelegate.current &&
                                              Api.player.currentLyricWordIndex >= 0 &&
                                              index <
                                                  Api.player.currentLyricWordIndex
                                                ? Theme.color.text
                                                : Theme.color.textSecondary

                                        font.pixelSize: Theme.font.sizeM

                                        font.bold:
                                            lyricDelegate.current &&
                                            index ===
                                                Api.player.currentLyricWordIndex

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 80
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        enabled: lyricDelegate.current
                                        acceptedButtons: Qt.LeftButton

                                        onClicked:
                                            Api.player.seekToLyricWord(
                                                lyricDelegate.index,
                                                index
                                            )
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        enabled: true
                        acceptedButtons: Qt.LeftButton

                        onClicked:
                            Api.player.seekToLyric(lyricDelegate.index)
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    opacity:
                        lyricDelegate.current
                            ? 1.0
                            : 0.72
                }

                Connections {
                    target: Api.player

                    function onCurrentLyricChanged() {
                        if (
                            Api.player &&
                            Api.player.currentLyricIndex >= 0
                        ) {
                            lyricsView.currentIndex =
                                Api.player.currentLyricIndex
                        }
                    }

                    function onLyricsChanged() {
                        if (
                            Api.player &&
                            Api.player.lyricsAvailable
                        ) {
                            lyricsView.currentIndex =
                                Math.max(
                                    0,
                                    Api.player.currentLyricIndex
                                )
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent

                width: parent.width - 24
                spacing: 6

                visible:
                    !Api.player ||
                    !Api.player.lyricsAvailable

                Text {
                    width: parent.width

                    text:
                        Api.player &&
                        Api.player.title !== "Nothing playing"
                            ? "No lyrics found"
                            : "Nothing playing"

                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeM

                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width

                    text:
                        Api.player &&
                        Api.player.title !== "Nothing playing"
                            ? "Add a matching .lrc file next to the audio track."
                            : "Lyrics will appear here when a track is playing."

                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeS
                    opacity: 0.8

                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
