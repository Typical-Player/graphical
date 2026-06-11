import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Dialogs
import QtGraphs
import graphical

ToolBar {
    id: root

    property int plotType: 0
    property int performanceMode: 0
    property int pointCount: 0

    required property ValueAxis xAxis
    required property ValueAxis yAxis

    readonly property bool mobile: Window.width <= 700 || Qt.platform.os === "android"

    readonly property int touchMode: {
        return touchModeGroup.checkedButton?.touchModeValue ?? 0
    }

    ButtonGroup {
        id: touchModeGroup
    }

    readonly property color selectedColor: selectedColorDialog.selectedColor

    readonly property bool showBestFit: showBestFitToggle.checked

    readonly property bool showGuide: showGuideToggle.checked

    readonly property bool showGrid: showGridToggle.checked

    readonly property bool useFractions: useFractionsToggle.checked

    readonly property bool selectionToggle: selectionModeBtn.checked

    readonly property bool touchModeToggle: forceTouchToggle.checked

    property bool leftSidebarActive: leftSidebarToggle.checked

    property bool rightSidebarActive: rightSidebarToggle.checked

    readonly property int brushSize: brushSizeList.brushSize

    readonly property int brushDensity: brushSizeList.brushDensity

    function closeLeftSidebar() {
        leftSidebarToggle.checked = false;
    }

    function closeRightSidebar() {
        rightSidebarToggle.checked = false;
    }

    function toggleLeftSidebar() {
        leftSidebarToggle.checked = !leftSidebarToggle.checked;
    }

    function toggleRightSidebar() {
        rightSidebarToggle.checked = !rightSidebarToggle.checked;
    }

    ColorGroup {
        id: colorPallete
    }

    ColorDialog {
        id: selectedColorDialog
        selectedColor: "blue"
    }

        signal
    logoClicked
        signal
    recenterClicked

    signal clearRequested()

    Flickable {
        anchors.fill: parent

        contentWidth: Math.max(width, toolbarRow.implicitWidth)
        contentHeight: height

        flickableDirection: Flickable.HorizontalFlick
        clip: true

        interactive: contentWidth > width

        boundsBehavior: Flickable.StopAtBounds

        RowLayout {
            id: toolbarRow

            height: parent.height
            spacing: 4

            anchors.verticalCenter: parent.verticalCenter

            width: Math.max(parent.width, implicitWidth)

            ToolButton {
                id: leftSidebarToggle

                checkable: true

                icon.source: "qrc:/icons/opensidebar.svg"
                icon.color: colorPallete.text
            }

            ToolSeparator {
            }

            ComboBox {
                implicitWidth: root.mobile ? 110 : 150

                model: ["Lineal", "Cuadratic", "Exponential", "Automatic"]

                onCurrentIndexChanged: root.plotType = currentIndex
            }

            Label {
                visible: root.plotType === 3
                text: ""
                font.bold: true
                color: colorPallete.text
                leftPadding: 4
            }

            ToolSeparator {
            }

            ToolButton {
                icon.source: "qrc:/icons/clear.svg"
                icon.color: colorPallete.text

                onClicked: {
                    root.clearRequested()

                    root.xAxis.min = 0;
                    root.xAxis.max = 100;

                    root.yAxis.min = 0;
                    root.yAxis.max = 100;
                }
            }

            ToolButton {
                enabled: root.pointCount > 0

                icon.source: "qrc:/icons/recenter.svg"
                icon.color: colorPallete.text

                onClicked: root.recenterClicked()
            }

            ToolButton {
                id: selectionModeBtn

                checkable: true

                icon.source: "qrc:/icons/selection.svg"
                icon.color: colorPallete.text
            }

            ToolSeparator {
            }

            ToolButton {
                id: showBestFitToggle

                checkable: true
                checked: true

                icon.source: "qrc:/icons/bestfit.svg"
                icon.color: colorPallete.text
            }

            ToolButton {
                id: showGuideToggle

                checkable: true

                icon.source: "qrc:/icons/showguides.svg"
                icon.color: colorPallete.text
            }

            ToolButton {
                id: showGridToggle

                checkable: true
                checked: true

                icon.source: "qrc:/icons/showgrid.svg"
                icon.color: colorPallete.text
            }

            ToolButton {
                id: forceTouchToggle

                checkable: true
                checked: false

                icon.source: "qrc:/icons/touch.svg"
                icon.color: colorPallete.text
            }

            ToolSeparator {
                visible: root.mobile
            }

            ToolButton {
                visible: root.mobile
                checkable: true
                checked: true
                ButtonGroup.group: touchModeGroup
                icon.source: "qrc:/icons/freedraw.svg"
                icon.color: colorPallete.text
                property int touchModeValue: 0
            }

            ToolButton {
                visible: root.mobile
                checkable: true
                ButtonGroup.group: touchModeGroup
                icon.source: "qrc:/icons/eraser.svg"
                icon.color: colorPallete.text
                property int touchModeValue: 1
            }

            ToolButton {
                visible: root.mobile
                checkable: true
                ButtonGroup.group: touchModeGroup
                icon.source: "qrc:/icons/drag.svg"
                icon.color: colorPallete.text
                property int touchModeValue: 2
            }

            ToolSeparator {
            }

            ToolButton {
                id: useFractionsToggle

                checkable: true

                icon.source: "qrc:/icons/division.svg"
                icon.color: colorPallete.text
            }

            ToolSeparator {
            }

            ComboBox {
                id: brushSizeList

                implicitWidth: root.mobile ? 100 : 150

                property int brushSize: 1
                property int brushDensity: 1

                model: ["Single", "Small", "Medium", "Large"]

                onCurrentIndexChanged: {
                    const t = [[1, 1], [10, 5], [30, 15], [50, 25]][currentIndex];

                    brushSize = t[0];
                    brushDensity = t[1];
                }
            }

            ToolButton {
                onClicked: selectedColorDialog.open()

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5

                    color: selectedColorDialog.selectedColor
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ComboBox {
                id: performanceOptions

                implicitWidth: root.mobile ? 130 : 180

                model: ["Automatic", "High performance", "Low performance", "No optimizations"]

                onCurrentIndexChanged: root.performanceMode = currentIndex
            }

            ToolSeparator {
            }

            ToolButton {
                id: rightSidebarToggle

                checkable: true

                icon.source: "qrc:/icons/opensidebar.svg"
                icon.color: colorPallete.text

                transform: Scale {
                    xScale: -1
                    origin.x: rightSidebarToggle.width / 2
                }
            }

            Image {
                id: logo

                source: (Application.styleHints.colorScheme === Qt.Dark)
                    ? "qrc:/icons/logo_light.svg"
                    : "qrc:/icons/logo.svg"

                Layout.minimumWidth: root.mobile ? 28 : 36
                Layout.minimumHeight: root.mobile ? 28 : 36

                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent

                    onClicked: root.logoClicked()
                }
            }
        }
    }
}
