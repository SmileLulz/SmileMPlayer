import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."
import "."

Rectangle {
    id: root
    objectName: "Now Playing"

    topLeftRadius: 8
    topRightRadius: 28
    bottomLeftRadius: 8
    bottomRightRadius: 8

    color: Theme.color.backgroundLight

    activeFocusOnTab: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Space) {
            Api.player.playPause()
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            Api.player.seek(Api.player.position + 5000)
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            Api.player.seek(Math.max(0, Api.player.position - 5000))
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            Api.player.setVolume(Math.min(1, Api.player.volume + 0.05))
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            Api.player.setVolume(Math.max(0, Api.player.volume - 0.05))
            event.accepted = true
        } else if (event.key === Qt.Key_N) {
            Api.player.next()
            event.accepted = true
        } else if (event.key === Qt.Key_P) {
            Api.player.previous()
            event.accepted = true
        } else if (event.key === Qt.Key_S) {
            Api.player.toggleShuffle()
            event.accepted = true
        } else if (event.key === Qt.Key_L) {
            Api.player.cycleLoopMode()
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.forceActiveFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 32

        Item {
            Layout.preferredWidth: Math.min(400, parent.height)
            Layout.preferredHeight: Math.min(400, parent.height)

            Layout.minimumWidth: Math.min(100, parent.height)
            Layout.minimumHeight: Math.min(100, parent.height)

            Layout.maximumWidth: parent.height
            Layout.maximumHeight: parent.height

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Theme.color.backgroundDarker

                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    color: "white"
                    radius: 22
                }

                Image {
                    id: coverArt
                    anchors.fill: parent
                    visible: false
                    source: Api.player.coverArt
                    sourceSize: Qt.size(
                        Math.ceil(width * Screen.devicePixelRatio),
                        Math.ceil(height * Screen.devicePixelRatio)
                    )
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: coverArt
                    maskEnabled: true
                    maskSource: coverMask
                    maskInverted: false
                    maskThresholdMin: 0.5
                    maskThresholdMax: 1.0
                    maskSpreadAtMin: 0
                    maskSpreadAtMax: 0
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    color: Theme.color.accent
                    font.pixelSize: Math.max(48, Math.min(300, parent.height * 0.4))
                    visible: coverArt.status !== Image.Ready
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Api.player.title
                color: Theme.color.text
                font.pixelSize: 32
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Api.player.artist
                color: Theme.color.accent
                font.pixelSize: Theme.font.sizeXL
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Api.player.album
                color: Theme.color.textSecondary
                font.pixelSize: Theme.font.sizeL
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 10

                Text {
                    Layout.preferredWidth: 32
                    Layout.alignment: Qt.AlignVCenter
                    text: Api.formatTime(Api.player.position)
                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeS
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                CustomSlider {
                    id: progress
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    from: 0
                    to: Math.max(Api.player.duration, 1)
                    value: Api.player.position
                    enabled: Api.player.duration > 0
                    onMoved: Api.player.seek(value)
                }

                Text {
                    Layout.preferredWidth: 32
                    Layout.alignment: Qt.AlignVCenter
                    text: Api.formatTime(Api.player.duration)
                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeS
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 8

                Item { Layout.fillWidth: true }

                CustomButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    label: Api.player.shuffle ? "" : "󰒞"
                    fontSize: Theme.font.sizeM
                    padding: 0
                    radiusTopLeft: 26
                    radiusTopRight: 6
                    radiusBottomLeft: 26
                    radiusBottomRight: 6
                    textColor: Api.player.shuffle
                               ? Theme.color.accent
                               : Theme.color.textSecondary

                    backgroundColor: Theme.color.backgroundLighter
                    onClicked: Api.player.toggleShuffle()
                }

                CustomButton {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    label: "󰒮"
                    fontSize: Theme.font.sizeL
                    padding: 0
                    radiusTopLeft: 6
                    radiusTopRight: 6
                    radiusBottomLeft: 6
                    radiusBottomRight: 6
                    textColor: Theme.color.text
                    backgroundColor: Theme.color.backgroundLighter
                    onClicked: Api.player.previous()
                }

                CustomButton {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 50
                    label: Api.player.playing ? "" : ""
                    fontSize: Theme.font.sizeXL
                    padding: 0
                    radiusTopLeft: 26
                    radiusTopRight: 26
                    radiusBottomLeft: 26
                    radiusBottomRight: 26
                    textColor: Theme.color.backgroundDarker
                    backgroundColor: Theme.color.accent
                    rippleColor: Theme.color.accentDark
                    onClicked: Api.player.playPause()
                }

                CustomButton {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    label: "󰒭"
                    fontSize: Theme.font.sizeL
                    padding: 0
                    radiusTopLeft: 6
                    radiusTopRight: 6
                    radiusBottomLeft: 6
                    radiusBottomRight: 6
                    textColor: Theme.color.text
                    backgroundColor: Theme.color.backgroundLighter
                    onClicked: Api.player.next()
                }

                CustomButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    label: {
                        switch (Api.player.loopMode) {
                        case "track":
                            return ""
                        case "playlist":
                            return ""
                        default:
                            return ""
                        }
                    }

                    fontSize: Theme.font.sizeM
                    padding: 0
                    radiusTopLeft: 6
                    radiusTopRight: 26
                    radiusBottomLeft: 6
                    radiusBottomRight: 26
                    textColor: Api.player.loopMode !== "none"
                               ? Theme.color.accent
                               : Theme.color.textSecondary

                    backgroundColor: Theme.color.backgroundLighter
                    onClicked: Api.player.cycleLoopMode()
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
