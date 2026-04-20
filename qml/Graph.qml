pragma ComponentBehavior: Bound
import QtQuick
import QtGraphs
import graphical

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
		graphUtils.recenter()
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

			onMinChanged: {
				root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
			}

			onMaxChanged: {
				root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
			}
		}

		axisY: ValueAxis {
			id: yA
			subTickCount: 1

			onMinChanged: {
				root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
			}

			onMaxChanged: {
				root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
			}
		}

		onPlotAreaChanged: {
			root.backend.plotArea = view.plotArea;
		}

		Component.onCompleted: {
			root.backend.pointSeries.pointDelegate = plotPointDelegate
			view.addSeries(root.backend.pointSeries)
			if (root.showBestFit && !view.hasSeries(root.backend.fitSeries)) {
				view.addSeries(root.backend.fitSeries)
			}

			root.backend.updateFitRange(xA.min, xA.max, yA.min, yA.max)
		}
	}

	BrushGuide {
		visible: root.freedrawMode || root.eraserMode
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

		freedrawMode: root.freedrawMode
		eraserMode: root.eraserMode
		panMode: root.panMode

		bDensity: root.brushDensity
		bSize: root.brushSize

		gu: graphUtils
		gv: view

		xAxis: xA
		yAxis: yA
	}
}