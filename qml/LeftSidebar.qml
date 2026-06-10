import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Item {
    id: root
    required property FitController fit
    readonly property sidebarResult rm: fit.resultMatrices
    readonly property string sidebarFont: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"
    readonly property real matrixSizeFact: .7

    FontLoader {
        id: robotoSerif
        source: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: main
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Label {
                    text: "A = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.aMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }

                Label {
                    text: "B = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.bMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }
            }

            RowLayout {
                Label {
                    text: "Aᵀ = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.atMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }
            }

            RowLayout {
                Label {
                    text: "AᵀA = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.ataMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }
            }

            RowLayout {
                Label {
                    text: "(AᵀA)⁻¹ = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.atainvMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }

                Label {
                    text: "AᵀB = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.atbMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: root.matrixSizeFact
                }
            }

            Rectangle {
                implicitHeight: 1
                color: "black"
                Layout.fillWidth: true
            }

            RowLayout {
                Label {
                    text: "(AᵀA)⁻¹AᵀB = "
                    font.family: robotoSerif.name
                    Layout.alignment: Qt.AlignVCenter
                    color: "black"
                }

                Matrix {
                    matrixData: root.rm.resMat
                    visibleRows: root.rm.rowResolution
                    visibleColumns: root.rm.colResolution
                    isCompressed: true
                    sizeFactor: 1
                }
            }
        }
    }
}
