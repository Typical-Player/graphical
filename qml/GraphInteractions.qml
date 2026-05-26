import QtQuick
import QtGraphs
import graphical

Item {
    id: root
    readonly property MouseArea ma: graphMouseArea

    required property int bDensity
    required property int bSize

    required property GraphUtils gu
    required property ValueAxis xAxis
    required property ValueAxis yAxis
    required property GraphsView gv

    MouseArea {
        id: graphMouseArea
        anchors.fill: parent
        enabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real lastX: 0
        property real lastY: 0

        hoverEnabled: true

        onClicked: function(mouse) {
            // Right-click releases are handled via onPositionChanged / pan logic; nothing to do on click
            if (mouse.button === Qt.RightButton)
                return;

            if (mouse.modifiers & Qt.ControlModifier)
                root.gu.erasePoints(mouseX, mouseY, root.bSize);
            else
                root.gu.addPoint(mouseX, mouseY, root.bDensity, root.bSize);
        }

        onPositionChanged: function(mouse) {
            if (!pressed)
                return;

            // Right-click drag → pan
            if (pressedButtons & Qt.RightButton) {
                const area = root.gv.plotArea;
                const scaleX = (root.xAxis.max - root.xAxis.min) / area.width;
                const scaleY = (root.yAxis.max - root.yAxis.min) / area.height;
                const dx = (mouseX - lastX) * scaleX;
                const dy = (mouseY - lastY) * scaleY;

                root.xAxis.min -= dx;
                root.xAxis.max -= dx;
                root.yAxis.min += dy;
                root.yAxis.max += dy;
                lastX = mouseX;
                lastY = mouseY;
                return;
            }

            // Left-click drag → draw or erase
            if (pressedButtons & Qt.LeftButton) {
                if (mouse.modifiers & Qt.ControlModifier) {
                    root.gu.erasePoints(mouseX, mouseY, root.bSize);
                    // No lastX/Y update needed — eraser radius is position-based, not stroke-based
                    return;
                }

                const dist = Math.hypot(mouseX - lastX, mouseY - lastY);
                if (dist >= Math.max(1, root.bSize / 4)) {
                    root.gu.addPoint(mouseX, mouseY, root.bDensity, root.bSize);
                    lastX = mouseX;
                    lastY = mouseY;
                }
            }
        }

        onPressed: {
            lastX = mouseX;
            lastY = mouseY;
        }

        onWheel: function(wheel) {
            const area = root.gv.plotArea;
            const factor = wheel.angleDelta.y > 0 ? 0.85 : 1.15;

            const mx = root.xAxis.min + ((wheel.x - area.x) / area.width) * (root.xAxis.max - root.xAxis.min);
            const my = root.yAxis.max - ((wheel.y - area.y) / area.height) * (root.yAxis.max - root.yAxis.min);

            root.xAxis.min = mx + (root.xAxis.min - mx) * factor;
            root.xAxis.max = mx + (root.xAxis.max - mx) * factor;
            root.yAxis.min = my + (root.yAxis.min - my) * factor;
            root.yAxis.max = my + (root.yAxis.max - my) * factor;
        }
    }
}