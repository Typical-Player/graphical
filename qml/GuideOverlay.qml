import QtQuick
import QtGraphs
import QtQuick.Controls.Fusion

Item {
    id: root

    required property MouseArea mouseArea
    required property GraphsView graphView
    required property ValueAxis xAxis
    required property ValueAxis yAxis

    readonly property real mouseX: root.mouseArea.mouseX
    readonly property real mouseY: root.mouseArea.mouseY

    readonly property real dataX: {
        const area = root.graphView.plotArea;
        return root.xAxis.min + ((root.mouseX - area.x) / area.width) * (root.xAxis.max - root.xAxis.min);
    }

    readonly property real dataY: {
        const area = root.graphView.plotArea;
        return root.yAxis.max - ((root.mouseY - area.y) / area.height) * (root.yAxis.max - root.yAxis.min);
    }

    readonly property real clampedX: Math.max(root.graphView.plotArea.x, Math.min(root.graphView.plotArea.x + root.graphView.plotArea.width, root.mouseX))

    readonly property real clampedY: Math.max(root.graphView.plotArea.y, Math.min(root.graphView.plotArea.y + root.graphView.plotArea.height, root.mouseY))

    Rectangle {
        x: root.clampedX
        y: root.graphView.plotArea.y
        width: 1
        height: root.graphView.plotArea.height
        color: "red"
    }

    Rectangle {
        x: root.graphView.plotArea.x
        y: root.clampedY
        width: root.graphView.plotArea.width
        height: 1
        color: "red"
    }

    Rectangle {
        id: xLabelBg
        x: Math.max(root.graphView.plotArea.x, Math.min(root.graphView.plotArea.x + root.graphView.plotArea.width - width, root.clampedX - width / 2))
        y: root.graphView.plotArea.y + root.graphView.plotArea.height + 2
        width: xLabel.implicitWidth + 8
        height: xLabel.implicitHeight + 4
        color: "red"

        Label {
            id: xLabel
            anchors.centerIn: parent
            text: root.dataX.toFixed(2)
            color: "white"
            font.pixelSize: 11
            font.family: "monospace"
        }
    }

    Rectangle {
        id: yLabelBg
        x: root.graphView.plotArea.x - width - 2
        y: Math.max(root.graphView.plotArea.y, Math.min(root.graphView.plotArea.y + root.graphView.plotArea.height - height, root.clampedY - height / 2))
        width: yLabel.implicitWidth + 8
        height: yLabel.implicitHeight + 4
        color: "red"

        Label {
            id: yLabel
            anchors.centerIn: parent
            text: root.dataY.toFixed(2)
            color: "white"
            font.pixelSize: 11
            font.family: "monospace"
        }
    }

    Rectangle {
        property int pointRadius: 6
        x: root.clampedX - pointRadius / 2
        y: root.clampedY - pointRadius / 2
        width: pointRadius
        height: pointRadius
        radius: pointRadius / 2
        color: "red"
    }
}
