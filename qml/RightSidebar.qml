import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: root

    required property PointProcessing backend

    color: "transparent"

    PointsModel {
        id: pointsModel
        backend: root.backend
    }

    ColorGroup {
        id: colorPallete
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            color: colorPallete.button

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Label {
                    text: "Points  (" + pointsModel.count + ")"
                    color: colorPallete.text
                    font.family: "Helvetica"
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            color: colorPallete.base

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                Label {
                    text: "#"
                    color: colorPallete.mid
                    font.pointSize: 8
                    Layout.preferredWidth: 36
                }
                Label {
                    text: "X"
                    color: colorPallete.mid
                    font.pointSize: 8
                    Layout.fillWidth: true
                }
                Label {
                    text: "Y"
                    color: colorPallete.mid
                    font.pointSize: 8
                    Layout.fillWidth: true
                }
                Item { Layout.preferredWidth: 32 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: colorPallete.mid
            opacity: 0.4
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: pointsModel

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: PointInputDelegate {}
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
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
                    validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
                    Keys.onReturnPressed: addY.forceActiveFocus()
                }

                TextField {
                    id: addY
                    placeholderText: "Y"
                    Layout.fillWidth: true
                    implicitHeight: 28
                    font.pointSize: 9
                    horizontalAlignment: Text.AlignRight
                    validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
                    Keys.onReturnPressed: addBtn.clicked()
                }

                Button {
                    id: addBtn
                    text: "+"
                    implicitWidth: 32
                    implicitHeight: 28
                    enabled: addX.text.length > 0 && addY.text.length > 0

                    onClicked: {
                        const x = parseFloat(addX.text)
                        const y = parseFloat(addY.text)
                        if (!isNaN(x) && !isNaN(y)) {
                            pointsModel.appendPoint(x, y)
                            addX.clear()
                            addY.clear()
                            addX.forceActiveFocus()
                            listView.positionViewAtEnd()
                        }
                    }
                }
            }
        }
    }
}