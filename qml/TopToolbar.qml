import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Dialogs
import QtGraphs
import graphical

Rectangle {
    id: root

    required property PointProcessing backend
    required property ValueAxis xAxis
    required property ValueAxis yAxis

    readonly property color selectedColor: selectedColorDialog.selectedColor

    readonly property bool panToggle: pantoggle.checked
    readonly property bool freedrawToggle: freedrawtoggle.checked
    readonly property bool eraserToggle: erasertoggle.checked

    readonly property bool showBestFit: showBestFitToggle.checked
    readonly property bool showGuide: showGuideToggle.checked
    readonly property bool showGrid: showGridToggle.checked
    readonly property bool useFractions: useFractionsToggle.checked

    readonly property int brushSize: brushSizeList.brushSize
    readonly property int brushDensity: brushSizeList.brushDensity

    readonly property bool leftSidebarActive: leftSidebarToggle.checked

    property int spacing: 4

    ColorDialog {
        id: selectedColorDialog
        selectedColor: "blue"
    }

    color: "transparent"

    signal logoClicked

    signal recenterClicked

    RowLayout {
        anchors.fill: parent
        spacing: root.spacing

        ToolButton {
            id: leftSidebarToggle
            checkable: true

            icon.source: "qrc:/icons/opensidebar.svg"
        }

        ToolSeparator {}

        ComboBox {
            model: ["Lineal", "Cuadratic", "Exponential"]
            onCurrentIndexChanged: root.backend.plotType = currentIndex
        }

        ToolSeparator {}

        ToolButton {
            onClicked: {
                root.backend.clear();
                root.xAxis.min = 0;
                root.xAxis.max = 100;
                root.yAxis.min = 0;
                root.yAxis.max = 100;
            }

            icon.source: "qrc:/icons/clear.svg"

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Clear"
        }

        ToolButton {
            enabled: root.backend.pointSeries.count > 0
            onClicked: root.recenterClicked()

            icon.source: "qrc:/icons/recenter.svg"
            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Re-center"
        }

        ToolSeparator {}

        ButtonGroup {
            buttons: toggleModes.children
            exclusive: true
        }

        Row {
            id: toggleModes
            spacing: 4

            ToolButton {
                id: pantoggle
                checkable: true
                checked: true
                icon.source: "qrc:/icons/drag.svg"

                ToolTip.delay: 1000
                ToolTip.visible: hovered
                ToolTip.text: "Drag mode"
            }

            ToolButton {
                id: freedrawtoggle
                checkable: true
                icon.source: "qrc:/icons/freedraw.svg"

                ToolTip.delay: 1000
                ToolTip.visible: hovered
                ToolTip.text: "Freedraw mode"
            }

            ToolButton {
                id: erasertoggle
                checkable: true
                icon.source: "qrc:/icons/eraser.svg"

                ToolTip.delay: 1000
                ToolTip.visible: hovered
                ToolTip.text: "Eraser mode"
            }
        }

        ToolSeparator {}

        ToolButton {
            id: showBestFitToggle
            checkable: true
            checked: true

            icon.source: "qrc:/icons/bestfit.svg"

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Show best fit"
        }

        ToolButton {
            id: showGuideToggle
            checkable: true

            icon.source: "qrc:/icons/showguides.svg"

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Show guides"
        }

        ToolButton {
            id: showGridToggle
            icon.source: "qrc:/icons/showgrid.svg"
            checkable: true
            checked: true

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Show grid"
        }

        ToolSeparator {}

        ToolButton {
            id: useFractionsToggle
            checkable: true
            icon.source: "qrc:/icons/division.svg"

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Show fractions"
        }

        ToolSeparator {
            visible: root.freedrawToggle || root.eraserToggle
        }

        ComboBox {
            id: brushSizeList

            property int brushSize: 1
            property int brushDensity: 1

            visible: root.freedrawToggle || root.eraserToggle
            model: ["Single", "Small", "Medium", "Large"]
            onCurrentIndexChanged: {
                const idx = brushSizeList.currentIndex;
                //? QMLLS for some reason crashes if I put a switch statement here

                if (idx === 0) {
                    brushSizeList.brushSize = 1;
                    brushSizeList.brushDensity = 1;
                }

                if (idx === 1) {
                    brushSizeList.brushSize = 10;
                    brushSizeList.brushDensity = 5;
                }

                if (idx === 2) {
                    brushSizeList.brushSize = 30;
                    brushSizeList.brushDensity = 15;
                }

                if (idx === 3) {
                    brushSizeList.brushSize = 50;
                    brushSizeList.brushDensity = 25;
                }
            }
        }

        ToolButton {
            visible: root.freedrawToggle
            onClicked: {
                selectedColorDialog.open();
            }

            Rectangle {
                anchors.fill: parent
                color: selectedColorDialog.selectedColor
                anchors.margins: 5
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Image {
            id: logo
            source: "qrc:/icons/logo.svg"

            MouseArea {
                id: logoMouseArea
                enabled: true
                hoverEnabled: true
                anchors.fill: parent

                onClicked: root.logoClicked()
            }

            ToolTip.delay: 1000
            ToolTip.visible: logoMouseArea.containsMouse
            ToolTip.text: "About Graphical"
        }
    }
}
