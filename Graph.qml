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

	readonly property ValueAxis xAxis: xA
	readonly property ValueAxis yAxis: yA

	Component {
		id: plotPointDelegate
		Rectangle {
			width: 5
			height: 5
			radius: width / 2
			color: "#5792ea"
		}
	}

	ColorGroup {
		id: colorPallete
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
		}

		axisX: ValueAxis {
			id: xA
			subTickCount: 1
		}

		axisY: ValueAxis {
			id: yA
			subTickCount: 1
		}

		Component.onCompleted: {
			root.backend.pointSeries.pointDelegate = plotPointDelegate
			view.addSeries(root.backend.pointSeries)
		}
	}

	MouseArea {
		anchors.fill: view
		enabled: true

		property real lastX: 0
		property real lastY: 0

		onClicked: if (root.freedrawMode) U.addPoint(mouseX, mouseY, view, xA, yA, root.backend.pointSeries)
		onPositionChanged: {
			if (!pressed) return;
			if (root.freedrawMode) {
				U.addPoint(mouseX, mouseY, view, xA, yA, root.backend.pointSeries);
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
			}

			lastX = mouseX;
			lastY = mouseY;
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