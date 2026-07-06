import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: root

    required property PointsModel pointsModel
    required property FitController fit
    property real probeX: NaN
    property real probeY: NaN

    signal keepOnlySelectionRequested
    signal clearSelectionRequested

    ConfirmDialog {
        id: confirmDialog

        onConfirmed: {
            root.keepOnlySelectionRequested();
            root.clearSelectionRequested();
            root.pointsModel.selectionActive = false;
        }
    }

    ColorGroup {
        id: colorPallete
    }

    Connections {
        target: root.pointsModel
        function onImportFailed(reason) {
            console.warn("Import failed:", reason);
        }
    }

    color: colorPallete.window

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: probeCol.implicitHeight + 16
            color: colorPallete.button
            visible: root.fit.progress === FitController.READY

            ColumnLayout {
                id: probeCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
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

                    Label {
                        text: "X ="
                        font.pointSize: 8
                        color: colorPallete.text
                    }

                    TextField {
                        id: probeXField
                        placeholderText: "x value"
                        Layout.fillWidth: true
                        implicitHeight: 26
                        font.pointSize: 9
                        horizontalAlignment: Text.AlignRight
                        validator: DoubleValidator {
                            notation: DoubleValidator.ScientificNotation
                        }
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
            Layout.fillWidth: true
            implicitHeight: 32
            color: colorPallete.window

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Label {
                    text: "Points"
                    font.bold: true
                    font.pointSize: 8
                    color: colorPallete.text
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "Import"
                    font.pointSize: 7
                    implicitHeight: 22
                    onClicked: root.pointsModel.importFromFile()
                }

                ToolButton {
                    text: "Export"
                    font.pointSize: 7
                    implicitHeight: 22
                    enabled: root.pointsModel.totalCount > 0
                    onClicked: root.pointsModel.exportToFile()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            visible: root.pointsModel.selectionActive
            color: Qt.rgba(0.22, 0.55, 1.0, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 4

                Label {
                    text: root.pointsModel.count + " of " + root.pointsModel.totalCount + " points in selection"
                    font.pointSize: 8
                    color: Qt.rgba(0.15, 0.40, 0.85, 1.0)
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "Keep only selection"
                    font.pointSize: 7
                    implicitHeight: 20
                    ToolTip.delay: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: "Delete all points outside the selection"

                    onClicked: {
                        confirmDialog.message = "Keep only the " + root.pointsModel.count + " selected points and delete the rest?";
                        confirmDialog.open();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            color: colorPallete.base

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                Label {
                    text: "#"
                    color: colorPallete.text
                    font.pointSize: 8
                    Layout.preferredWidth: 34
                }
                Label {
                    text: "X"
                    color: colorPallete.text
                    font.pointSize: 8
                    Layout.fillWidth: true
                }
                Label {
                    text: "Y"
                    color: colorPallete.text
                    font.pointSize: 8
                    Layout.fillWidth: true
                }
                Label {
                    text: "Δy (residual)"
                    color: colorPallete.text
                    font.pointSize: 8
                    Layout.preferredWidth: 90
                }
                Item {
                    Layout.preferredWidth: 32
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: colorPallete.mid
            opacity: 0.4
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.pointsModel
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: PointInputDelegate {}
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: colorPallete.mid
            opacity: 0.4
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            color: colorPallete.button

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Label {
                    text: "Add:"
                    color: colorPallete.text
                    font.pointSize: 9
                }

                TextField {
                    id: addX
                    placeholderText: "X"
                    Layout.fillWidth: true
                    implicitHeight: 28
                    font.pointSize: 9
                    horizontalAlignment: Text.AlignRight
                    validator: DoubleValidator {
                        notation: DoubleValidator.ScientificNotation
                    }
                    Keys.onReturnPressed: addY.forceActiveFocus()
                }
                TextField {
                    id: addY
                    placeholderText: "Y"
                    Layout.fillWidth: true
                    implicitHeight: 28
                    font.pointSize: 9
                    horizontalAlignment: Text.AlignRight
                    validator: DoubleValidator {
                        notation: DoubleValidator.ScientificNotation
                    }
                    Keys.onReturnPressed: addBtn.clicked()
                }

                Button {
                    id: addBtn
                    text: "+"
                    implicitWidth: 32
                    implicitHeight: 28
                    enabled: addX.text.length > 0 && addY.text.length > 0
                    onClicked: {
                        const x = parseFloat(addX.text), y = parseFloat(addY.text);
                        if (!isNaN(x) && !isNaN(y)) {
                            root.pointsModel.appendPoint(x, y);
                            addX.clear();
                            addY.clear();
                            addX.forceActiveFocus();
                            listView.positionViewAtEnd();
                        }
                    }
                }
            }
        }
    }
}
