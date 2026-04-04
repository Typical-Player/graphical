pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtGraphs
import graphical

import "utils.mjs" as U

Rectangle {
	id: root

	required property PointProcessing backend
	required property bool panMode
	required property bool freedrawMode
	required property bool eraserMode

	required property bool showGrid
	required property bool showGuides
	required property bool showBestFit
	required property color selectedColor

	required property int brushSize
	required property int brushDensity

	readonly property ValueAxis xAxis: xA
	readonly property ValueAxis yAxis: yA

	onShowBestFitChanged: {
		if (root.showBestFit && !view.hasSeries(root.backend.fitSeries)) {
			view.addSeries(root.backend.fitSeries)
			return;
		}

		view.removeSeries(root.backend.fitSeries)
	}

	Component {
		id: plotPointDelegate
		Rectangle {
			width: 5
			height: 5
			radius: width / 2
			color: root.selectedColor
		}
	}

	ColorGroup {
		id: colorPallete
	}

	Rectangle {
		id: viewWrapper
		anchors.fill: parent
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

				gridVisible: root.showGrid
			}

			axisX: ValueAxis {
				id: xA
				subTickCount: 1

				onMinChanged: {
					root.backend.updateFitRange(xA.min, xA.max)
				}

				onMaxChanged: {
					root.backend.updateFitRange(xA.min, xA.max)
				}
			}

			axisY: ValueAxis {
				id: yA
				subTickCount: 1
			}

			Component.onCompleted: {
				root.backend.pointSeries.pointDelegate = plotPointDelegate
				view.addSeries(root.backend.pointSeries)
				if (root.showBestFit && !view.hasSeries(root.backend.fitSeries)) {
					view.addSeries(root.backend.fitSeries)
				}

				root.backend.updateFitRange(xA.min, xA.max)
			}
		}
	Rectangle {
		id: brushCursor
		enabled: false
		visible: root.freedrawMode || root.eraserMode
		width: root.brushSize * 2
		height: root.brushSize * 2
		radius: root.brushSize
		color: root.eraserMode
			? Qt.rgba(1, 0.3, 0.3, 0.15)
			: Qt.rgba(root.selectedColor.r,
				root.selectedColor.g,
				root.selectedColor.b, 0.15)

		border.color: root.eraserMode
			? Qt.rgba(1, 0.2, 0.2, 0.6)
			: Qt.rgba(root.selectedColor.r,
				root.selectedColor.g,
				root.selectedColor.b, 0.6)

		border.width: 3

		x: graphMouseArea.mouseX - root.brushSize
		y: graphMouseArea.mouseY - root.brushSize

		Behavior on width  { NumberAnimation { duration: 80 } }
		Behavior on height { NumberAnimation { duration: 80 } }
		Behavior on radius { NumberAnimation { duration: 80 } }
	}
	}


	MouseArea {
		id: graphMouseArea
		anchors.fill: viewWrapper
		enabled: true

		property real lastX: 0
		property real lastY: 0

		hoverEnabled: true

		preventStealing: true

		onClicked: if (root.freedrawMode) U.addPoint(mouseX, mouseY, view, xA, yA,
			root.backend.pointSeries, root.brushDensity, root.brushSize)

		onPositionChanged: {
			if (!pressed) return;
			if (root.freedrawMode) {
				const dist = Math.hypot(mouseX - lastX, mouseY - lastY)

				if (dist >= Math.max(1, root.brushSize / 4)) {
					U.addPoint(mouseX, mouseY, view, xA, yA,
						root.backend.pointSeries, root.brushDensity, root.brushSize);
					lastX = mouseX
					lastY = mouseY
				}
				return
			}

			if (root.panMode) {
				const area = view.plotArea

				const scaleX = (xA.max - xA.min) / area.width
				const scaleY = (yA.max - yA.min) / area.height
				const dx = (mouseX - lastX) * scaleX
				const dy = (mouseY - lastY) * scaleY

				xA.min -= dx;
				xA.max -= dx
				yA.min += dy;
				yA.max += dy
				lastX = mouseX
				lastY = mouseY
			}
		}

		onPressed: {
			lastX = mouseX;
			lastY = mouseY;
		}

		onWheel: function (wheel) {
			const area = view.plotArea
			const factor = wheel.angleDelta.y > 0 ? 0.85 : 1.15

			const mx = xA.min + ((wheel.x - area.x) / area.width) * (xA.max - xA.min)
			const my = yA.max - ((wheel.y - area.y) / area.height) * (yA.max - yA.min)

			xA.min = mx + (xA.min - mx) * factor
			xA.max = mx + (xA.max - mx) * factor
			yA.min = my + (yA.min - my) * factor
			yA.max = my + (yA.max - my) * factor
		}
	}
}