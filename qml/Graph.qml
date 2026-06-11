pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtGraphs
import graphical

Rectangle {
    id: root

    required property FitController mainFit
    required property PointData mainData
    required property DisplayProcessor mainDisplay

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

    property bool forceTouchInput: false

    readonly property bool _hasTouchInput:
        Qt.platform.os === "android" ||
        Qt.platform.os === "ios"     ||
        (Qt.platform.os === "wasm" && root.width <= 900) ||
        root.forceTouchInput

    signal selectionCommitted(rect dataRect)
    signal selectionCleared

    property rect _selDataRect
    property bool _hasSelection: false

    required property real probeX
    required property real probeY

    readonly property bool _probeVisible: {
        if (isNaN(root.probeX) || isNaN(root.probeY)) return false;
        const a = view.plotArea;
        if (a.width <= 0) return false;
        const sx = a.x + (root.probeX - xA.min) / (xA.max - xA.min) * a.width;
        return sx >= a.x && sx <= a.x + a.width;
    }

    readonly property real _probeSX: {
        const a = view.plotArea;
        return a.x + (root.probeX - xA.min) / (xA.max - xA.min) * a.width;
    }

    readonly property real _probeSY: {
        const a = view.plotArea;
        return a.y + (yA.max - root.probeY) / (yA.max - yA.min) * a.height;
    }

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

    readonly property int _hovIdx: gi.ma.containsMouse && !gi.ma.pressed && root.mainData.pointCount > 0 ? graphUtils.nearestPointIndex(gi.ma.mouseX, gi.ma.mouseY, 15) : -1

    readonly property point _hovPt: _hovIdx >= 0 ? root.mainData.pointAt(_hovIdx) : Qt.point(0, 0)
    readonly property double _hovResidual: _hovIdx >= 0 ? root.mainFit.residualFor(_hovIdx) : 0.0

    onSelectionModeChanged: {
        if (!root.selectionMode) {
            root._hasSelection = false;
            root.selectionCleared();
            if (root.mainDisplay && root.mainDisplay.selectionFitSeries) {
                root.mainDisplay.selectionFitSeries.clear();
            }
            if (view.hasSeries(root.mainDisplay.selectionFitSeries)){
                view.removeSeries(root.mainDisplay.selectionFitSeries);
            }
        } else {
            if (root.mainDisplay && root.mainDisplay.selectionFitSeries) {
                root.mainDisplay.selectionFitSeries.clear();
            }
            if (!view.hasSeries(root.mainDisplay.selectionFitSeries)){
                view.addSeries(root.mainDisplay.selectionFitSeries);
            }
        }
    }

    onShowBestFitChanged: {
        if (root.showBestFit) {
            if (!view.hasSeries(root.mainDisplay.fitSeries))
                view.addSeries(root.mainDisplay.fitSeries);

            if (!view.hasSeries(root.mainDisplay.residualSeries))
                view.addSeries(root.mainDisplay.residualSeries);
        } else {
            if (view.hasSeries(root.mainDisplay.fitSeries))
                view.removeSeries(root.mainDisplay.fitSeries);

            if (view.hasSeries(root.mainDisplay.residualSeries))
                view.removeSeries(root.mainDisplay.residualSeries);
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
        data: root.mainData
        xAxis: xA
        yAxis: yA
        plotArea: view.plotArea
    }

    function recenter() {
        graphUtils.recenter();
    }

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

    Rectangle {
        visible: root._probeVisible
        x: root._probeSX
        y: view.plotArea.y
        width: 1
        height: view.plotArea.height
        color: "transparent"

        Repeater {
            model: Math.ceil(view.plotArea.height / 10)
            Rectangle {
                required property int index
                y: index * 10
                width: 1.5
                height: 5
                color: Qt.rgba(0.15, 0.45, 0.90, 0.75)
            }
        }
    }

    Rectangle {
        visible: root._probeVisible
        x: root._probeSX - 5
        y: root._probeSY - 5
        width: 10; height: 10
        radius: 5
        color: Qt.rgba(0.15, 0.45, 0.90, 0.9)
        border.color: "white"
        border.width: 1.5
        z: 10
    }

    Rectangle {
        id: probeLabel
        visible: root._probeVisible

        readonly property bool flipLeft: root._probeSX > view.plotArea.x + view.plotArea.width * 0.75

        x: flipLeft ? root._probeSX - width - 10 : root._probeSX + 12
        y: Math.max(view.plotArea.y + 4,
            Math.min(root._probeSY - height / 2,
                view.plotArea.y + view.plotArea.height - height - 4))

        width: probeLabelCol.implicitWidth + 16
        height: probeLabelCol.implicitHeight + 10
        radius: 4
        color: colorPallete.base
        border.color: Qt.rgba(0.15, 0.45, 0.90, 0.6)
        border.width: 1
        z: 10

        ColumnLayout {
            id: probeLabelCol
            anchors.centerIn: parent
            spacing: 2
            Label {
                text: "x = " + root.probeX.toFixed(4)
                font.pointSize: 7.5
                font.family: "Courier New"
                color: colorPallete.text
            }
            Label {
                text: "y = " + root.probeY.toFixed(4)
                font.pointSize: 7.5
                font.family: "Courier New"
                color: Qt.rgba(0.15, 0.45, 0.90, 1.0)
            }
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
            onMinChanged: root.mainDisplay.updateFitRange(xA.min, xA.max, yA.min, yA.max)
            onMaxChanged: root.mainDisplay.updateFitRange(xA.min, xA.max, yA.min, yA.max)
        }
        axisY: ValueAxis {
            id: yA
            subTickCount: 1
            onMinChanged: root.mainDisplay.updateFitRange(xA.min, xA.max, yA.min, yA.max)
            onMaxChanged: root.mainDisplay.updateFitRange(xA.min, xA.max, yA.min, yA.max)
        }

        onPlotAreaChanged: root.mainDisplay.plotArea = view.plotArea

        Component.onCompleted: {
            root.mainDisplay.pointSeries.pointDelegate = plotPointDelegate;
            view.addSeries(root.mainDisplay.pointSeries);
            if (root.showBestFit && !view.hasSeries(root.mainDisplay.fitSeries))
                view.addSeries(root.mainDisplay.fitSeries);

            if (root.selectionMode && !view.hasSeries(root.mainDisplay.selectionFitSeries)) {
                view.addSeries(root.mainDisplay.selectionFitSeries);
            }
            root.mainDisplay.updateFitRange(xA.min, xA.max, yA.min, yA.max);
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
        visible: root.showGuides && gi.ma.containsMouse
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
        hasTouchInput: root._hasTouchInput
    }

    Item {
        x: view.plotArea.x
        y: view.plotArea.y
        width: view.plotArea.width
        height: view.plotArea.height
        clip: true

        Rectangle {
            visible: gi.isDraggingSelection
            x: gi.selectionDragRect.x - view.plotArea.x
            y: gi.selectionDragRect.y - view.plotArea.y
            width: gi.selectionDragRect.width
            height: gi.selectionDragRect.height
            color: Qt.rgba(0.22, 0.55, 1.0, 0.10)
            border.color: Qt.rgba(0.22, 0.55, 1.0, 0.85)
            border.width: 1
        }

        Rectangle {
            visible: root._hasSelection && root.selectionMode && !gi.isDraggingSelection
            x: root._confirmedScreenRect.x - view.plotArea.x
            y: root._confirmedScreenRect.y - view.plotArea.y
            width: Math.max(0, root._confirmedScreenRect.width)
            height: Math.max(0, root._confirmedScreenRect.height)
            color: Qt.rgba(0.22, 0.55, 1.0, 0.07)
            border.color: Qt.rgba(0.22, 0.55, 1.0, 0.65)
            border.width: 1.5
        }
    }
}
