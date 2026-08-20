import QtQuick
import QtQuick.Controls
import ".."

Slider {
    id: root

    readonly property real trackThickness: 8
    readonly property real thumbWidth: 3
    readonly property real thumbHeight: 28
    readonly property real thumbGap: 4
    readonly property real capsuleRadius: trackThickness / 2
    readonly property real handleWidth: thumbWidth + 8

    readonly property real thumbCenterX:
        leftPadding
        + visualPosition * (availableWidth - handleWidth)
        + handleWidth / 2

    readonly property real thumbLeftX: thumbCenterX - thumbWidth / 2
    readonly property real thumbRightX: thumbCenterX + thumbWidth / 2

    readonly property real leftWidth:Math.max(0, thumbLeftX - leftPadding - thumbGap)
    readonly property real rightWidth:Math.max(0, availableWidth - thumbRightX - thumbGap)

    property int animDuration: pressed ? 0 : 150

    implicitHeight: Math.max(thumbHeight, trackThickness + 12)

    background: Item {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: root.trackThickness

        Rectangle {
            width: root.leftWidth
            height: parent.height
            radius: root.capsuleRadius
            color: Theme.color.accent
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Behavior on width {
                NumberAnimation {
                    duration: root.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            width: root.rightWidth
            height: parent.height
            radius: root.capsuleRadius
            color: Theme.color.backgroundLighter
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Behavior on width {
                NumberAnimation {
                    duration: root.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    handle: Item {
        width: root.handleWidth
        height: root.thumbHeight
        x: root.leftPadding
           + root.visualPosition
           * (root.availableWidth - width)

        Behavior on x {
            NumberAnimation {
                duration: root.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.thumbWidth
            height: root.thumbHeight * 0.9
            radius: width / 2
            color: Theme.color.accent
        }
    }
}
