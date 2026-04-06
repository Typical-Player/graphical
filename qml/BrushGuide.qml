import QtQuick
import QtGraphs

Rectangle {
    id: root

    required property MouseArea mouseArea
    required property GraphsView graphView
    required property int guideSize

    color: "transparent"
    x: root.graphView.plotArea.x
    y: root.graphView.plotArea.y
    width: root.graphView.plotArea.width
    height: root.graphView.plotArea.height

    clip: true

    Rectangle {
        id: brushCursor
        width: root.guideSize * 2
        height: root.guideSize * 2
        radius: root.guideSize

        color: "transparent"

        border.color: "black"
        border.width: .5

        x: root.mouseArea.mouseX - root.guideSize - root.graphView.plotArea.x
        y: root.mouseArea.mouseY - root.guideSize - root.graphView.plotArea.y
    }
}
