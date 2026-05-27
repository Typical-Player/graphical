import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

ApplicationWindow {
    id: root

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

    readonly property bool mobile: width <= 700

    ColorGroup {
        id: colorPallete
    }

    color: colorPallete.window

    GraphicalDialog {
        id: aboutDialog
        width: 500
        height: 380

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

    PointProcessing {
        id: processing
        useFractions: topBar.useFractions
    }

    PointsModel {
        id: pointsModel
        backend: processing
    }

    Connections {
        target: graph

        function onSelectionCommitted(dataRect) {
            pointsModel.selectionRect = dataRect;
            pointsModel.selectionActive = true;
        }

        function onSelectionCleared() {
            pointsModel.selectionActive = false;
        }
    }

    Item {
        anchors.fill: parent
        ToolBar {
            id: appToolbar

            z: 200

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.topMargin: SafeArea.margins.top

            height: root.mobile ? 52 : 40

            TopToolbar {
                id: topBar
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 2
                anchors.bottomMargin: 2

                backend: processing
                xAxis: graph.xAxis
                yAxis: graph.yAxis

                onLogoClicked: aboutDialog.open()
                onRecenterClicked: graph.recenter()
            }
        }

        Item {
            id: contentArea

            anchors.top: appToolbar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            SplitView {
                id: splitView

                anchors.fill: parent
                orientation: Qt.Horizontal

                visible: !root.mobile

                Rectangle {
                    id: leftDesktopSidebar

                    color: "transparent"

                    visible: width > 0

                    SplitView.preferredWidth: width

                    width: topBar.leftSidebarActive ? 450 : 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutExpo
                        }
                    }

                    clip: true

                    ProcessingSidebarWrapper {
                        anchors.fill: parent
                        backend: processing
                        isActive: width > 0
                    }
                }

                ColumnLayout {
                    SplitView.fillWidth: true
                    spacing: 0

                    Graph {
                        id: graph

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        backend: processing

                        selectionMode: topBar.selectionToggle
                        showGrid: topBar.showGrid
                        showGuides: !root.mobile && topBar.showGuide
                        showBestFit: topBar.showBestFit

                        selectedColor: topBar.selectedColor

                        brushSize: topBar.brushSize
                        brushDensity: topBar.brushDensity
                        touchMode: topBar.touchMode
                    }

                    ResultBar {
                        Layout.fillWidth: true
                        implicitHeight: 50

                        backend: processing
                    }
                }

                Rectangle {
                    id: rightDesktopSidebar

                    color: "transparent"

                    visible: width > 0

                    SplitView.preferredWidth: width

                    width: topBar.rightSidebarActive ? 320 : 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutExpo
                        }
                    }

                    clip: true

                    RightSidebar {
                        anchors.fill: parent
                        pointsModel: pointsModel
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                visible: root.mobile

                Graph {
                    id: mobileGraph

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    backend: processing

                    selectionMode: topBar.selectionToggle
                    showGrid: topBar.showGrid
                    showGuides: false
                    showBestFit: topBar.showBestFit

                    selectedColor: topBar.selectedColor

                    brushSize: topBar.brushSize
                    brushDensity: topBar.brushDensity
                    touchMode: topBar.touchMode
                }

                ResultBar {
                    Layout.fillWidth: true
                    implicitHeight: 50

                    backend: processing
                }
            }

            Rectangle {
                id: mobileOverlay

                anchors.fill: parent

                visible: root.mobile && (topBar.leftSidebarActive || topBar.rightSidebarActive)

                color: "#80000000"

                z: 90

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        topBar.closeLeftSidebar();
                        topBar.closeRightSidebar();
                    }
                }
            }

            Rectangle {
                id: mobileLeftSheet

                visible: root.mobile && topBar.leftSidebarActive

                z: 100

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.height * 0.55

                radius: 16

                color: colorPallete.base

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44

                        color: colorPallete.window

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Label {
                                text: "Processing"
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            ToolButton {
                                icon.source: "qrc:/icons/close.svg"

                                onClicked: topBar.closeLeftSidebar()
                            }
                        }
                    }

                    ProcessingSidebarWrapper {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        backend: processing
                        isActive: topBar.leftSidebarActive
                    }
                }
            }

            Rectangle {
                id: mobileRightSheet

                visible: root.mobile && topBar.rightSidebarActive

                z: 100

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.height * 0.55

                radius: 16

                color: colorPallete.base

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44

                        color: colorPallete.window

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Label {
                                text: "Point editor"
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            ToolButton {
                                icon.source: "qrc:/icons/close.svg"

                                onClicked: topBar.closeRightSidebar()
                            }
                        }
                    }

                    RightSidebar {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        pointsModel: pointsModel
                    }
                }
            }
        }
    }
}
