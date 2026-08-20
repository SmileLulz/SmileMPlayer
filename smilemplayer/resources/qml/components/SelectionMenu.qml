pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: root

    property var model: []
    property int currentIndex: -1
    property string title: ""

    property real itemHeight: 48
    property real menuHorizontalPadding: 8
    property real menuVerticalPadding: 8
    property real cornerRadius: 20

    property color backgroundColor: Theme.color.backgroundLight
    property color borderColor: Theme.color.border

    signal selected(int index, var value)

    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    modal: false
    focus: true

    background: Rectangle {
        radius: root.cornerRadius
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: 2
    }

    contentItem: Column {
        spacing: 2
        topPadding: root.menuVerticalPadding
        bottomPadding: root.menuVerticalPadding

        Label {
            visible: root.title !== ""
            text: root.title
            color: Theme.color.textSecondary
            font.pixelSize: Theme.font.sizeS
            font.bold: true
            leftPadding: root.menuHorizontalPadding + 12
            rightPadding: root.menuHorizontalPadding + 12
            topPadding: 6
            bottomPadding: 6
        }

        Repeater {
            model: root.model

            delegate: Item {
                required property int index
                required property var modelData

                width: root.width
                height: root.itemHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: root.menuHorizontalPadding
                    anchors.rightMargin: root.menuHorizontalPadding
                    radius: 14

                    color: mouseArea.pressed
                        ? Qt.darker(root.backgroundColor, 1.25)
                        : mouseArea.containsMouse
                            ? Qt.lighter(root.backgroundColor, 1.25)
                            : root.backgroundColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.menuHorizontalPadding + 14
                    anchors.rightMargin: root.menuHorizontalPadding + 14
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: modelData
                        color: index === root.currentIndex
                            ? Theme.color.text
                            : Theme.color.textSecondary

                        font.pixelSize: Theme.font.sizeM
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 20
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        visible: index === root.currentIndex
                        text: ""
                        color: Theme.color.accent
                        font.pixelSize: Theme.font.sizeL
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton

                    onClicked: {
                        root.currentIndex = index
                        root.selected(index, modelData)
                        root.close()
                    }
                }
            }
        }
    }

    function openForItem(item) {
        var point = item.mapToItem(
            null,
            0,
            item.height + 6
        )

        x = Math.max(
            8,
            Math.min(
                point.x,
                root.parent.width - width - 8
            )
        )

        y = Math.max(
            8,
            Math.min(
                point.y,
                root.parent.height - height - 8
            )
        )

        open()
    }
}
