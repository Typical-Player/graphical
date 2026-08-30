import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

ApplicationWindow {
    id: root

    ColorGroup {
        id: colorPallete
    }

    width: 1300
    height: 700

    minimumWidth: 500
    minimumHeight: 500

    visible: true
    title: "Graphical"

    topPadding: SafeArea.margins.top
    bottomPadding: SafeArea.margins.bottom
    leftPadding: SafeArea.margins.left
    rightPadding: SafeArea.margins.right

    color: colorPallete.window

    readonly property bool mobile: width <= 700


    PointData {
        id: mainData
    }

    PointData {
        id: selectionData
    }

    FitController {
        id: mainFit
        source: mainData
        plotType: topBar.plotType
        useFractions: topBar.useFractions
    }

    FitController {
        id: selectionFit
        source: selectionData
        plotType: topBar.plotType
        useFractions: topBar.useFractions
    }

    DisplayProcessor {
        id: display
        source: mainData
        fit: mainFit
        selectionSource: selectionData
        selectionFit: selectionFit
        fitSamples: 200
    }

    PointsModel {
        id: pointsModel
        source: mainData
        fit: mainFit
    }

    Binding {
        target: mainFit; property: "plotType";
        value: topBar.plotType
    }
    Binding {
        target: display; property: "performanceMode";
        value: topBar.performanceMode
    }

    property real probeX: NaN
    readonly property real probeY: isNaN(probeX) ? NaN : mainFit.evaluateAt(probeX)

    GraphicalDialog {
        id: aboutDialog
        width: 550
        height: 400

        Loader {
            active: aboutDialog.enabled
            asynchronous: true
            anchors.fill: parent

            AboutDialog {
                anchors.fill: parent
                anchors.margins: 10

                onClosedClicked: aboutDialog.close()
            }
        }
    }

    Connections {
        target: graph

        function onSelectionCommitted(dataRect) {
            pointsModel.selectionRect = dataRect;
            pointsModel.selectionActive = true;

            const r = dataRect;
            const all = mainData.allPoints;
            const filtered = all.filter(p =>
                p.x >= r.x && p.x <= r.x + r.width &&
                p.y >= r.y && p.y <= r.y + r.height
            );

            selectionData.setAllPoints(filtered);
            selectionFit.source = selectionData;
        }

        function onSelectionCleared() {
            pointsModel.selectionActive = false;
            selectionData.clear();
            selectionFit.source = selectionData;
        }
    }

    Item {
        anchors.fill: parent

        TopToolbar {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.topMargin: SafeArea.margins.top
            leftPadding: 20
            rightPadding: 20

            height: root.mobile ? 52 : 40

            xAxis: graph.xAxis
            yAxis: graph.yAxis

            onLogoClicked: aboutDialog.open()
            onRecenterClicked: graph.recenter()

            pointCount: mainData.pointCount
            onClearRequested: {
                mainData.clear()
                graph.xAxis.min = 0; graph.xAxis.max = 100
                graph.yAxis.min = 0; graph.yAxis.max = 100
            }
        }

        SplitView {
            id: contentArea

            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            orientation: Qt.Horizontal

            Sidebar {
                id: leftSidebar
                SplitView.preferredWidth: leftSidebar.width
                width: root.mobile ? 0 : (topBar.leftSidebarActive ? 450 : 0)

                title: "Best Fit using the Least-Squares method"
                isMobile: root.mobile
                isActive: topBar.leftSidebarActive
                mobileOverlayTarget: mobileOverlay

                LeftSidebar {
                    anchors.fill: parent
                    fit: mainFit
                }
            }

            ColumnLayout {
                SplitView.fillWidth: true
                spacing: 0

                Graph {
                    id: graph

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    mainFit: mainFit
                    mainData: mainData
                    mainDisplay: display

                    selectionMode: topBar.selectionToggle
                    showGrid: topBar.showGrid
                    showGuides: !root.mobile && topBar.showGuide
                    showBestFit: topBar.showBestFit

                    selectedColor: topBar.selectedColor

                    brushSize: topBar.brushSize
                    brushDensity: topBar.brushDensity
                    touchMode: topBar.touchMode

                    probeX: root.probeX
                    probeY: root.probeY

                    forceTouchInput: topBar.touchModeToggle

                    Button {
                        id: toggleResultBtn
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 0
                        z: 100

                        padding: root.mobile ? 10 : 6
                        text: resultBar.collapsed ? "Show results" : "Hide"

                        onClicked: resultBar.collapsed = !resultBar.collapsed
                    }
                }

                ResultBar {
                    id: resultBar
                    Layout.fillWidth: true
                    implicitHeight: 100

                    property bool collapsed: root.mobile

                    clip: true
                    Layout.preferredHeight: collapsed ? 0 : (root.mobile ? 120 : 100)
                    visible: Layout.preferredHeight > 0
                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    fit: mainFit
                    selectionFit: selectionFit
                }
            }

            Sidebar {
                id: rightSidebar
                SplitView.preferredWidth: rightSidebar.width
                width: root.mobile ? 0 : (topBar.rightSidebarActive ? 320 : 0)

                title: "Graph Properties"
                isMobile: root.mobile
                isActive: topBar.rightSidebarActive
                mobileOverlayTarget: mobileOverlay

                RightSidebar {
                    anchors.fill: parent
                    pointsModel: pointsModel
                    fit: mainFit

                    probeX: root.probeX
                    probeY: root.probeY
                    onProbeXChanged: root.probeX = probeX

                    onKeepOnlySelectionRequested: mainData.setAllPoints(selectionData.allPoints)
                    onClearSelectionRequested: {
                        selectionData.clear()
                        mainFit.source = mainData
                    }
                }
            }
        }

        Rectangle {
            id: mobileBackdrop
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            z: 99

            visible: root.mobile && (topBar.leftSidebarActive || topBar.rightSidebarActive)

            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    topBar.closeLeftSidebar()
                    topBar.closeRightSidebar()
                }
            }
        }

        Rectangle {
            id: mobileOverlay

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            z: 100
            color: colorPallete.window
            visible: root.mobile && (topBar.leftSidebarActive || topBar.rightSidebarActive)
            clip: true

            readonly property real activeHeight: parent.height * 0.55
            height: (root.mobile && (topBar.leftSidebarActive || topBar.rightSidebarActive)) ? activeHeight : 0

            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutExpo
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
}
