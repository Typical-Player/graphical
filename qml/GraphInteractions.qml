import QtQuick
import QtGraphs
import graphical

Item {
    id: root
    readonly property MouseArea ma: graphMouseArea

    required property bool selectionMode
    required property int  bDensity
    required property int  bSize

    required property GraphUtils  gu
    required property ValueAxis   xAxis
    required property ValueAxis   yAxis
    required property GraphsView  gv

    signal selectionConfirmed(real x1, real y1, real x2, real y2)
    signal selectionCleared()

    readonly property rect selectionDragRect: Qt.rect(
        Math.min(_selX, graphMouseArea.mouseX),
        Math.min(_selY, graphMouseArea.mouseY),
        Math.abs(graphMouseArea.mouseX - _selX),
        Math.abs(graphMouseArea.mouseY - _selY)
    )
    readonly property bool isDraggingSelection:
        root.selectionMode
        && graphMouseArea.pressed
        && (graphMouseArea.pressedButtons & Qt.LeftButton)
        && _wasDrag

    property real _selX:    0
    property real _selY:    0
    property bool _wasDrag: false

    MouseArea {
        id: graphMouseArea
        anchors.fill: parent
        enabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        property real lastX: 0
        property real lastY: 0

        onPressed: function(mouse) {
            lastX = mouseX
            lastY = mouseY
            root._wasDrag = false
            if (root.selectionMode && mouse.button === Qt.LeftButton) {
                root._selX = mouseX
                root._selY = mouseY
            }
        }

        onPositionChanged: function(mouse) {
            if (!pressed) return

            if (pressedButtons & Qt.RightButton) {
                const area   = root.gv.plotArea
                const scaleX = (root.xAxis.max - root.xAxis.min) / area.width
                const scaleY = (root.yAxis.max - root.yAxis.min) / area.height
                root.xAxis.min -= (mouseX - lastX) * scaleX
                root.xAxis.max -= (mouseX - lastX) * scaleX
                root.yAxis.min += (mouseY - lastY) * scaleY
                root.yAxis.max += (mouseY - lastY) * scaleY
                lastX = mouseX
                lastY = mouseY
                return
            }

            if (pressedButtons & Qt.LeftButton) {
                if (root.selectionMode) {
                    if (Math.abs(mouseX - root._selX) > 6 || Math.abs(mouseY - root._selY) > 6)
                        root._wasDrag = true
                    return
                }

                if (mouse.modifiers & Qt.ControlModifier) {
                    root.gu.erasePoints(mouseX, mouseY, root.bSize)
                    return
                }

                const dist = Math.hypot(mouseX - lastX, mouseY - lastY)
                if (dist >= Math.max(1, root.bSize / 4)) {
                    root.gu.addPoint(mouseX, mouseY, root.bDensity, root.bSize)
                    lastX = mouseX
                    lastY = mouseY
                }
            }
        }

        onReleased: function(mouse) {
            if (mouse.button !== Qt.LeftButton || !root.selectionMode) return
            if (root._wasDrag)
                root.selectionConfirmed(root._selX, root._selY, mouseX, mouseY)
        }

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) return

            if (root.selectionMode) {
                if (!root._wasDrag) root.selectionCleared()
                return
            }

            if (mouse.modifiers & Qt.ControlModifier)
                root.gu.erasePoints(mouseX, mouseY, root.bSize)
            else
                root.gu.addPoint(mouseX, mouseY, root.bDensity, root.bSize)
        }

        onWheel: function(wheel) {
            const area   = root.gv.plotArea
            const factor = wheel.angleDelta.y > 0 ? 0.85 : 1.15
            const mx = root.xAxis.min + ((wheel.x - area.x) / area.width)  * (root.xAxis.max - root.xAxis.min)
            const my = root.yAxis.max - ((wheel.y - area.y) / area.height) * (root.yAxis.max - root.yAxis.min)
            root.xAxis.min = mx + (root.xAxis.min - mx) * factor
            root.xAxis.max = mx + (root.xAxis.max - mx) * factor
            root.yAxis.min = my + (root.yAxis.min - my) * factor
            root.yAxis.max = my + (root.yAxis.max - my) * factor
        }
    }
}