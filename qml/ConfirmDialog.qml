import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Effects

GraphicalDialog {
    id: root

    property string message: "Are you sure?"

        signal confirmed

    width: 340
    height: contentCol.implicitHeight + 48

    ColorGroup { id: colorPallete }

    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 16

        Label {
            text: root.message
            font.pointSize: 10
            color: colorPallete.text
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: root.close()
            }

            Button {
                text: "Confirm"
                palette.button: Qt.rgba(0.75, 0.18, 0.18, 1.0)
                palette.buttonText: "white"
                onClicked: {
                    root.confirmed()
                    root.close()
                }
            }
        }
    }
}