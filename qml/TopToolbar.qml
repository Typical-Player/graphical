import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Effects
import QtGraphs
import graphical

Rectangle {
    id: root

    required property PointProcessing backend
    required property ValueAxis xAxis
    required property ValueAxis yAxis

    readonly property color selectedColor: selectedColorDialog.selectedColor
    readonly property bool  showBestFit: showBestFitToggle.checked
    readonly property bool  showGuide: showGuideToggle.checked
    readonly property bool  showGrid: showGridToggle.checked
    readonly property bool  useFractions: useFractionsToggle.checked
    readonly property bool  selectionToggle: selectionModeBtn.checked
    readonly property bool  leftSidebarActive: leftSidebarToggle.checked
    readonly property bool  rightSidebarActive: rightSidebarToggle.checked
    readonly property int   brushSize: brushSizeList.brushSize
    readonly property int   brushDensity: brushSizeList.brushDensity

    property int spacing: 4

    ColorGroup {
        id: colorPallete
    }
    ColorDialog {
        id: selectedColorDialog; selectedColor: "blue"
    }

    color: "transparent"

        signal
    logoClicked
        signal
    recenterClicked

    RowLayout {
        anchors.fill: parent
        spacing: root.spacing

        ToolButton {
            id: leftSidebarToggle; checkable: true
            icon.source: "qrc:/icons/opensidebar.svg"; icon.color: colorPallete.text
        }

        ToolSeparator {
        }

        ComboBox {
            model: ["Lineal", "Cuadratic", "Exponential"]
            onCurrentIndexChanged: root.backend.plotType = currentIndex
        }

        ToolSeparator {
        }

        ToolButton {
            onClicked: {
                root.backend.clear()
                root.xAxis.min = 0; root.xAxis.max = 100
                root.yAxis.min = 0; root.yAxis.max = 100
            }
            icon.source: "qrc:/icons/clear.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Clear"
        }

        ToolButton {
            enabled: root.backend.pointSeries.count > 0
            onClicked: root.recenterClicked()
            icon.source: "qrc:/icons/recenter.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Re-center"
        }

        ToolButton {
            id: selectionModeBtn; checkable: true
            icon.source: "qrc:/icons/selection.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered
            ToolTip.text: "Selection mode"
        }

        ToolSeparator {
        }

        ToolButton {
            id: showBestFitToggle; checkable: true; checked: true
            icon.source: "qrc:/icons/bestfit.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Show best fit"
        }
        ToolButton {
            id: showGuideToggle; checkable: true
            icon.source: "qrc:/icons/showguides.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Show guides"
        }
        ToolButton {
            id: showGridToggle; checkable: true; checked: true
            icon.source: "qrc:/icons/showgrid.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Show grid"
        }

        ToolSeparator {
        }

        ToolButton {
            id: useFractionsToggle; checkable: true
            icon.source: "qrc:/icons/division.svg"; icon.color: colorPallete.text
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Show fractions"
        }

        ToolSeparator {
        }

        ComboBox {
            id: brushSizeList
            property int brushSize: 1
            property int brushDensity: 1
            model: ["Single", "Small", "Medium", "Large"]
            onCurrentIndexChanged: {
                const t = [[1, 1], [10, 5], [30, 15], [50, 25]][currentIndex]
                brushSize = t[0]; brushDensity = t[1]
            }
        }

        ToolButton {
            onClicked: selectedColorDialog.open()
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Draw color"
            Rectangle {
                anchors.fill: parent; anchors.margins: 5
                color: selectedColorDialog.selectedColor
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Label {
            visible: performanceOptions.currentIndex === 0
            text: "Automatic: " + (root.backend.resolvedPerformance === 1
                ? "High performance" : "Low performance")
            color: colorPallete.text; font.pointSize: 8; font.family: "Helvetica"
        }
        ComboBox {
            id: performanceOptions
            model: ["Automatic", "High performance", "Low performance", "No optimizations"]
            onCurrentIndexChanged: root.backend.performanceMode = currentIndex
        }

        ToolSeparator {
        }

        ToolButton {
            id: rightSidebarToggle; checkable: true
            icon.source: "qrc:/icons/opensidebar.svg"; icon.color: colorPallete.text
            transform: Scale {
                xScale: -1; origin.x: rightSidebarToggle.width / 2
            }
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Point editor"
        }

        Image {
            id: logo; source: "qrc:/icons/logo.svg"
            MouseArea {
                id: logoMouseArea; enabled: true; hoverEnabled: true
                anchors.fill: parent; onClicked: root.logoClicked()
            }
            ToolTip.delay: 1000; ToolTip.visible: logoMouseArea.containsMouse
            ToolTip.text: "About Graphical"
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? 1 : 0
            }
        }
    }
}