import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: root

    property bool canClick: true
    property string label: "Label"

    property real fontSize: 16
    property bool fontBold: false

    property real padding: 16
    property real minimumWidth: 178

    property real radiusTopLeft: 14
    property real radiusTopRight: 14
    property real radiusBottomRight: 14
    property real radiusBottomLeft: 14

    property color textColor: Theme.color.text
    property color textColorSecondary: Theme.color.textSecondary

    property color backgroundColor: Theme.color.backgroundLighter
    property color backgroundColorHover: Qt.lighter(backgroundColor, 1.25)
    property color backgroundColorPressed: Qt.darker(backgroundColor, 1.25)
    property color backgroundColorDisabled: Theme.color.backgroundLight

    property color rippleColor: Theme.color.accent
    property real rippleOpacity: 0.5
    property int rippleDuration: 700

    signal clicked(var mouse)
    signal clickedAt(real x, real y)

    readonly property bool hovered: canClick && mouseArea.containsMouse
    readonly property bool pressed: canClick && mouseArea.pressed

    readonly property color currentTextColor:
        !canClick
            ? textColorSecondary
            : pressed
                ? textColorSecondary
                : textColor

    readonly property color currentBackgroundColor:
        !canClick
            ? backgroundColorDisabled
            : pressed
                ? backgroundColorPressed
                : hovered
                    ? backgroundColorHover
                    : backgroundColor

    implicitWidth: Math.max(minimumWidth, textBox.implicitWidth + padding * 2)
    implicitHeight: textBox.implicitHeight + padding * 2

    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: root.radiusTopLeft
        topRightRadius: root.radiusTopRight
        bottomRightRadius: root.radiusBottomRight
        bottomLeftRadius: root.radiusBottomLeft
        color: root.currentBackgroundColor

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Rectangle {
        id: rippleMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: "white"
        topLeftRadius: root.radiusTopLeft
        topRightRadius: root.radiusTopRight
        bottomRightRadius: root.radiusBottomRight
        bottomLeftRadius: root.radiusBottomLeft
    }

    Item {
        id: rippleSource
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            id: ripple
            x: originX - width / 2
            y: originY - height / 2
            width: 0
            height: width
            radius: width / 2
            color: root.rippleColor
            opacity: root.rippleOpacity
            property real originX: 0
            property real originY: 0
        }
    }

    MultiEffect {
        id: rippleEffect
        anchors.fill: parent
        source: rippleSource
        maskEnabled: true
        maskSource: rippleMask
        maskInverted: false
        maskThresholdMin: 0.5
        maskThresholdMax: 1.0
        maskSpreadAtMin: 0.0
        maskSpreadAtMax: 0.0
        visible: rippleAnimation.running
    }

    Text {
        id: textBox
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: root.label
        color: root.currentTextColor
        font.pixelSize: root.fontSize
        font.bold: root.fontBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    ParallelAnimation {
        id: rippleAnimation

        PropertyAnimation {
            id: rippleSizeAnimation
            target: ripple
            property: "width"
            from: 0
            duration: root.rippleDuration
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            id: rippleOpacityAnimation
            target: ripple
            property: "opacity"
            from: root.rippleOpacity
            to: 0
            duration: root.rippleDuration
            easing.type: Easing.OutQuad
        }

        onFinished: {
            ripple.width = 0
            ripple.opacity = root.rippleOpacity
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.canClick
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onClicked: function(mouse) {
            root.triggerRipple(mouse.x, mouse.y)
            root.clicked(mouse)
            root.clickedAt(mouse.x, mouse.y)
        }
    }

    function triggerRipple(x, y) {
        if (!root.canClick)
            return
        var dx = Math.max(x, root.width - x)
        var dy = Math.max(y, root.height - y)
        var targetDiameter =
            Math.sqrt(dx * dx + dy * dy) * 2
        rippleAnimation.stop()
        ripple.originX = x
        ripple.originY = y
        ripple.width = 0
        ripple.opacity = root.rippleOpacity
        rippleSizeAnimation.to = targetDiameter
        rippleAnimation.start()
    }
}
