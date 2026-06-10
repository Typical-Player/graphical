import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: sidebar
    property string title: ""
    property bool isMobile: false
    property bool isActive: false
    property Item mobileOverlayTarget: null
    default property alias content: innerContent.children

    ColorGroup {
        id: colorPallete
    }

    color: "transparent"
    visible: width > 0
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutExpo
        }
    }

    Rectangle {
        id: movingContainer

        parent: (sidebar.isMobile && sidebar.mobileOverlayTarget)
            ? sidebar.mobileOverlayTarget
            : sidebar

        anchors.fill: parent
        color: colorPallete.window
        visible: sidebar.isMobile ? sidebar.isActive : true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: sidebar.title !== "" ? 36 : 0
                visible: sidebar.title !== ""
                color: Qt.darker(colorPallete.window, 1.05)

                Label {
                    anchors.centerIn: parent
                    text: sidebar.title
                    font.bold: true
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.darker(colorPallete.window, 1.2)
                }
            }

            Item {
                id: innerContent
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}