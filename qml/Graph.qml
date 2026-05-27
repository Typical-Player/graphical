pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtGraphs
import graphical

Rectangle {
    id: root

    required property PointProcessing backend
    required property bool selectionMode

    required property bool showGrid
    required property bool showGuides
    required property bool showBestFit
    required property color selectedColor
    required property int touchMode

    required property int brushSize
    required property int brushDensity

    readonly property ValueAxis xAxis: xA
    readonly property ValueAxis yAxis: yA

    signal selectionCommitted(rect dataRect)
    signal selectionCleared

    property rect _selDataRect
    property bool _hasSelection: false

    readonly property rect _confirmedScreenRect: {
        const a = view.plotArea;
        if (!_hasSelection || a.width <= 0 || a.height <= 0)
            return Qt.rect(0, 0, 0, 0);
        const xs = a.width / (xA.max - xA.min);
        const ys = a.height / (yA.max - yA.min);
        const sx = a.x + (_selDataRect.x - xA.min) * xs;
        const sy = a.y + (yA.max - (_selDataRect.y + _selDataRect.height)) * ys;
        return Qt.rect(sx, sy, _selDataRect.width * xs, _selDataRect.height * ys);
    }

    readonly property int _hovIdx: gi.ma.containsMouse && !gi.ma.pressed && root.backend.pointCount > 0 ? graphUtils.nearestPointIndex(gi.ma.mouseX, gi.ma.mouseY, 15) : -1

    readonly property point _hovPt: _hovIdx >= 0 ? root.backend.pointAt(_hovIdx) : Qt.point(0, 0)
    readonly property double _hovResidual: _hovIdx >= 0 ? root.backend.residualAt(_hovIdx) : 0.0

    onSelectionModeChanged: {
        if (!root.selectionMode) {
            root._hasSelection = false;
            root.selectionCleared();
        }
    }

    onShowBestFitChanged: {
        if (root.showBestFit) {
            if (!view.hasSeries(root.backend.fitSeries))
                view.addSeries(root.backend.fitSeries);

            if (!view.hasSeries(root.backend.residualSeries))
                view.addSeries(root.backend.residualSeries);
        } else {
            if (view.hasSeries(root.backend.fitSeries))
                view.removeSeries(root.backend.fitSeries);

            if (view.hasSeries(root.backend.residualSeries))
                view.removeSeries(root.backend.residualSeries);
        }
    }

    Component {
        id: plotPointDelegate
        PlotPoint {
            color: root.selectedColor
        }
    }

    ColorGroup {
        id: colorPallete
    }

    GraphUtils {
        id: graphUtils
        backend: root.backend
        xAxis: xA
        yAxis: yA
        plotArea: view.plotArea
    }

    function recenter() {
        graphUtils.recenter();
    }

    // Screen → data coord conversion on selection commit
    Connections {
        target: gi
        function onSelectionConfirmed(x1, y1, x2, y2) {
            const a = view.plotArea;
            const xs = (xA.max - xA.min) / a.width;
            const ys = (yA.max - yA.min) / a.height;
            const L = xA.min + (Math.min(x1, x2) - a.x) * xs;
            const R = xA.min + (Math.max(x1, x2) - a.x) * xs;
            const B = yA.max - (Math.max(y1, y2) - a.y) * ys;
            const T = yA.max - (Math.min(y1, y2) - a.y) * ys;
            root._selDataRect = Qt.rect(L, B, R - L, T - B);
            root._hasSelection = true;
            root.selectionCommitted(root._selDataRect);
        }
        function onSelectionCleared() {
            root._hasSelection = false;
            root.selectionCleared();
        }
    }

    GraphsView {
        id: view
        anchors.fill: parent
        marginLeft: 0
        marginBottom: 0

        theme: GraphsTheme {
            colorScheme: GraphsTheme.ColorScheme.Light
            grid.mainColor: "#b7b7b7"
            grid.mainWidth: 1.5
            grid.subColor: "#CECECE"
            grid.subWidth: 1
            backgroundColor: colorPallete.window
            labelTextColor: colorPallete.text
            gridVisible: root.showGrid
        }

        axisX: ValueAxis {
            id: xA
            subTickCount: 1
            onMinChanged: root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
            onMaxChanged: root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
        }
        axisY: ValueAxis {
            id: yA
            subTickCount: 1
            onMinChanged: root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
            onMaxChanged: root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
        }

        onPlotAreaChanged: root.backend.plotArea = view.plotArea

        Component.onCompleted: {
            root.backend.pointSeries.pointDelegate = plotPointDelegate;
            view.addSeries(root.backend.pointSeries);
            if (root.showBestFit && !view.hasSeries(root.backend.fitSeries))
                view.addSeries(root.backend.fitSeries);
            root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max);
        }
    }

    BrushGuide {
        visible: gi.ma.containsMouse && !(gi.ma.pressedButtons & Qt.RightButton) && !root.selectionMode
        mouseArea: gi.ma
        graphView: view
        guideSize: root.brushSize
    }

    GuideOverlay {
        anchors.fill: view
        visible: root.showGuides && gi.ma.containsMouse && !root.selectionMode
        mouseArea: gi.ma
        graphView: view
        xAxis: xA
        yAxis: yA
    }

    GraphInteractions {
        id: gi
        anchors.fill: view
        selectionMode: root.selectionMode
        bDensity: root.brushDensity
        bSize: root.brushSize
        gu: graphUtils
        gv: view
        xAxis: xA
        yAxis: yA
        touchMode: root.touchMode
    }

    Rectangle {
        visible: gi.isDraggingSelection
        x: gi.selectionDragRect.x
        y: gi.selectionDragRect.y
        width: gi.selectionDragRect.width
        height: gi.selectionDragRect.height
        color: Qt.rgba(0.22, 0.55, 1.0, 0.10)
        border.color: Qt.rgba(0.22, 0.55, 1.0, 0.85)
        border.width: 1
    }

    Rectangle {
        visible: root._hasSelection && root.selectionMode && !gi.isDraggingSelection
        x: root._confirmedScreenRect.x
        y: root._confirmedScreenRect.y
        width: Math.max(0, root._confirmedScreenRect.width)
        height: Math.max(0, root._confirmedScreenRect.height)
        color: Qt.rgba(0.22, 0.55, 1.0, 0.07)
        border.color: Qt.rgba(0.22, 0.55, 1.0, 0.65)
        border.width: 1.5
    }

    Rectangle {
        id: hoverBox
        visible: root._hovIdx >= 0 && !gi.isDraggingSelection
        anchors.top: view.top
        anchors.right: view.right
        anchors.margins: 10
        width: ttCol.implicitWidth + 20
        height: ttCol.implicitHeight + 14
        radius: 4
        color: colorPallete.base
        border.color: colorPallete.mid
        border.width: 1

        ColumnLayout {
            id: ttCol
            anchors.centerIn: parent
            spacing: 3

            Label {
                text: "Point #" + (root._hovIdx + 1)
                font.bold: true
                font.pointSize: 8
                color: colorPallete.text
            }
            Label {
                text: "X :  " + root._hovPt.x.toFixed(4)
                font.pointSize: 8
                font.family: "Courier New"
                color: colorPallete.text
            }
            Label {
                text: "Y :  " + root._hovPt.y.toFixed(4)
                font.pointSize: 8
                font.family: "Courier New"
                color: colorPallete.text
            }
            Label {
                visible: root.backend.progress === PointProcessing.READY
                text: {
                    const r = root._hovResidual;
                    return "Δy:  " + (r >= 0 ? "+" : "") + r.toFixed(4);
                }
                font.pointSize: 8
                font.family: "Courier New"
                color: {
                    const r = root._hovResidual;
                    if (isNaN(r))
                        return colorPallete.text;
                    if (r > 0.001)
                        return "#c0522a";
                    if (r < -0.001)
                        return "#2a7ac0";
                    return "#2a9d2a";
                }
            }
        }
    }
}
