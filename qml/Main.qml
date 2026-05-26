import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

ApplicationWindow {
    id: root
    width: 1300; height: 512; visible: true; title: "Graphical"
    minimumWidth: 1300; minimumHeight: 512

    GraphicalDialog {
        id: aboutDialog; width: 500; height: 380
        Loader {
            active: aboutDialog.enabled; asynchronous: true; anchors.fill: parent
            AboutDialog {
                anchors.fill: parent; anchors.margins: 10
                onClosedClicked: aboutDialog.close()
            }
        }
    }

    PointProcessing {
        id: processing; useFractions: topBar.useFractions
    }

    PointsModel {
        id: pointsModel; backend: processing
    }

    ColorGroup {
        id: colorPallete
    }
    color: colorPallete.window

    Connections {
        target: graph

        function onSelectionCommitted(dataRect) {
            pointsModel.selectionRect = dataRect
            pointsModel.selectionActive = true
        }

        function onSelectionCleared() {
            pointsModel.selectionActive = false
        }
    }

    header: ToolBar {
        height: 40
        TopToolbar {
            id: topBar
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            anchors.topMargin: 2; anchors.bottomMargin: 2
            spacing: 8
            backend: processing; xAxis: graph.xAxis; yAxis: graph.yAxis
            onLogoClicked: aboutDialog.open()
            onRecenterClicked: graph.recenter()
        }
    }

    SplitView {
        anchors.fill: parent; orientation: Qt.Horizontal

        Rectangle {
            id: leftWrap; color: "transparent"
            visible: topBar.leftSidebarActive || width > 0
            SplitView.preferredWidth: width
            width: topBar.leftSidebarActive ? 450 : 0
            states: [
                State {
                    name: "open"; when: topBar.leftSidebarActive; PropertyChanges {
                        target: leftWrap; width: 450
                    }
                },
                State {
                    name: "closed"; when: !topBar.leftSidebarActive; PropertyChanges {
                        target: leftWrap; width: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "open";
                    to: "closed"
                    SequentialAnimation {
                        NumberAnimation {
                            properties: "width"; duration: 500; easing.type: Easing.OutExpo
                        }
                        ScriptAction {
                            script: leftWrap.visible = false
                        }
                    }
                },
                Transition {
                    from: "closed";
                    to: "open"
                    SequentialAnimation {
                        ScriptAction {
                            script: leftWrap.visible = true
                        }
                        NumberAnimation {
                            properties: "width"; duration: 500; easing.type: Easing.OutExpo
                        }
                    }
                }
            ]
            ProcessingSidebarWrapper {
                anchors.fill: parent; isActive: topBar.leftSidebarActive; backend: processing
            }
        }

        ColumnLayout {
            SplitView.fillWidth: true; spacing: 0

            Graph {
                id: graph
                Layout.fillHeight: true; Layout.fillWidth: true
                backend: processing
                selectionMode: topBar.selectionToggle
                showGrid: topBar.showGrid
                showGuides: topBar.showGuide
                showBestFit: topBar.showBestFit
                selectedColor: topBar.selectedColor
                brushSize: topBar.brushSize
                brushDensity: topBar.brushDensity
            }

            ResultBar {
                Layout.fillWidth: true; implicitHeight: 50; backend: processing
            }
        }

        Rectangle {
            id: rightWrap; color: "transparent"
            visible: topBar.rightSidebarActive || width > 0
            SplitView.preferredWidth: width
            width: topBar.rightSidebarActive ? 320 : 0
            states: [
                State {
                    name: "open"; when: topBar.rightSidebarActive; PropertyChanges {
                        target: rightWrap; width: 320
                    }
                },
                State {
                    name: "closed"; when: !topBar.rightSidebarActive; PropertyChanges {
                        target: rightWrap; width: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "open";
                    to: "closed"
                    SequentialAnimation {
                        NumberAnimation {
                            properties: "width"; duration: 500; easing.type: Easing.OutExpo
                        }
                        ScriptAction {
                            script: rightWrap.visible = false
                        }
                    }
                },
                Transition {
                    from: "closed";
                    to: "open"
                    SequentialAnimation {
                        ScriptAction {
                            script: rightWrap.visible = true
                        }
                        NumberAnimation {
                            properties: "width"; duration: 500; easing.type: Easing.OutExpo
                        }
                    }
                }
            ]
            RightSidebar {
                anchors.fill: parent; pointsModel: pointsModel
            }
        }
    }
}