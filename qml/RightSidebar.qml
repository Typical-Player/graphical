import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: root

    required property PointsModel pointsModel

    required property PointProcessing backend

    property real probeX: NaN
    property real probeY: NaN

    color: "transparent"

    ColorGroup { id: colorPallete }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: probeCol.implicitHeight + 16
            color: colorPallete.button
            visible: root.backend.progress === PointProcessing.READY

            ColumnLayout {
                id: probeCol
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top; margins: 8
                }
                spacing: 4

                Label {
                    text: "Evaluate fit"
                    font.bold: true
                    font.pointSize: 8
                    color: colorPallete.text
                }

                RowLayout {
                    spacing: 4

                    Label { text: "X ="; font.pointSize: 8; color: colorPallete.text }

                    TextField {
                        id: probeXField
                        placeholderText: "x value"
                        Layout.fillWidth: true
                        implicitHeight: 26
                        font.pointSize: 9
                        horizontalAlignment: Text.AlignRight
                        validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
                        onTextChanged: root.probeX = acceptableInput ? parseFloat(text) : NaN

                        Binding on text {
                            when: isNaN(root.probeX) && probeXField.text.length > 0
                            value: ""
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 36
            color: colorPallete.button

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                Label {
                    text: "Points  (" + root.pointsModel.count + ")"
                    font.bold: true; color: colorPallete.text; Layout.fillWidth: true
                }
                ToolButton {
                    icon.source: "qrc:/icons/clear.svg"; icon.color: colorPallete.text
                    enabled: root.pointsModel.totalCount > 0
                    onClicked: root.pointsModel.backend.clear()
                    ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Clear all points"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 26
            visible: root.pointsModel.selectionActive
            color: Qt.rgba(0.22, 0.55, 1.0, 0.12)

            Label {
                anchors.centerIn: parent
                text: root.pointsModel.count + " of "
                    + root.pointsModel.totalCount + " points in selection"
                font.pointSize: 8
                color: Qt.rgba(0.15, 0.40, 0.85, 1.0)
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 26
            color: colorPallete.base

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 0

                Label { text: "#";   color: colorPallete.mid; font.pointSize: 8; Layout.preferredWidth: 34 }
                Label { text: "X";   color: colorPallete.mid; font.pointSize: 8; Layout.fillWidth: true }
                Label { text: "Y";   color: colorPallete.mid; font.pointSize: 8; Layout.fillWidth: true }
                Label { text: "Δy (residual)"; color: colorPallete.mid; font.pointSize: 8; Layout.preferredWidth: 90 }
                Item  { Layout.preferredWidth: 32 }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: colorPallete.mid; opacity: 0.4 }

        ListView {
            id: listView
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            model: root.pointsModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: PointInputDelegate {}
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: colorPallete.mid; opacity: 0.4 }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 44
            color: colorPallete.button

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 4

                Label { text: "Add:"; color: colorPallete.text; font.pointSize: 9 }

                TextField {
                    id: addX; placeholderText: "X"
                    Layout.fillWidth: true; implicitHeight: 28
                    font.pointSize: 9; horizontalAlignment: Text.AlignRight
                    validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
                    Keys.onReturnPressed: addY.forceActiveFocus()
                }
                TextField {
                    id: addY; placeholderText: "Y"
                    Layout.fillWidth: true; implicitHeight: 28
                    font.pointSize: 9; horizontalAlignment: Text.AlignRight
                    validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
                    Keys.onReturnPressed: addBtn.clicked()
                }

                Button {
                    id: addBtn; text: "+"; implicitWidth: 32; implicitHeight: 28
                    enabled: addX.text.length > 0 && addY.text.length > 0
                    onClicked: {
                        const x = parseFloat(addX.text), y = parseFloat(addY.text)
                        if (!isNaN(x) && !isNaN(y)) {
                            root.pointsModel.appendPoint(x, y)
                            addX.clear(); addY.clear()
                            addX.forceActiveFocus()
                            listView.positionViewAtEnd()
                        }
                    }
                }
            }
        }
    }
}