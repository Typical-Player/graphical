import QtQuick
import QtQuick.Controls.Fusion

Item {
    id: marqueeRoot

    property alias text: textItem.text
    property alias font: textItem.font
    property alias color: textItem.color

    property real speed: 45
    property int startDelay: 1500

    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight
    clip: true

    readonly property bool needsScrolling: textItem.implicitWidth > marqueeRoot.width

    onNeedsScrollingChanged: {
        if (!needsScrolling) {
            marqueeAnim.stop()
            textItem.x = 0
        } else {
            marqueeAnim.restart()
        }
    }

    onWidthChanged: {
        if (needsScrolling && !marqueeAnim.running) marqueeAnim.restart()
    }

    Label {
        id: textItem
        height: parent.height
        verticalAlignment: Text.AlignVCenter
    }

    SequentialAnimation {
        id: marqueeAnim
        running: marqueeRoot.needsScrolling
        loops: Animation.Infinite

        PauseAnimation { duration: marqueeRoot.startDelay }

        NumberAnimation {
            target: textItem
            property: "x"
            from: 0
            to: marqueeRoot.width - textItem.implicitWidth
            duration: Math.abs(to) * (1000 / marqueeRoot.speed)
            easing.type: Easing.Linear
        }

        PauseAnimation { duration: marqueeRoot.startDelay }

        NumberAnimation {
            target: textItem
            property: "x"
            to: 0
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }
}