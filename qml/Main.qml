import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

ApplicationWindow {
	id: root
	width: 900
	height: 512
	visible: true
	title: "Graphical"

	minimumWidth: 900
	minimumHeight: 512

	GraphicalDialog {
		id: aboutDialog
		width: 500
		height: 350

		Loader {
			active: aboutDialog.enabled
			asynchronous: true
			anchors.fill: parent
			AboutDialog {
				anchors.fill: parent
				anchors.margins: 10

				onClosedClicked: aboutDialog.close()
			}
		}
	}

	PointProcessing {
		id: processing
		useFractions: topBar.useFractions
	}

	ColorGroup {
		id: colorPallete
	}

	color: colorPallete.window

	header: ToolBar {
		height: 40
		TopToolbar {
			id: topBar
			anchors.fill: parent
			anchors.leftMargin: 10
			anchors.rightMargin: 10
			anchors.topMargin: 2
			anchors.bottomMargin: 2
			spacing: 8

			backend: processing
			xAxis: graph.xAxis
			yAxis: graph.yAxis

			onLogoClicked: {
				aboutDialog.open()
			}

			onRecenterClicked: {
				graph.recenter()
			}
		}
	}

	RowLayout {
		anchors.fill: parent
		spacing: 0

		ProcessingSidebarWrapper {
			Layout.fillHeight: true
			isActive: topBar.leftSidebarActive
			backend: processing
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 0

			Graph {
				id: graph
				Layout.fillHeight: true
				Layout.fillWidth: true
				backend: processing
				panMode: topBar.panToggle
				freedrawMode: topBar.freedrawToggle
				eraserMode: topBar.eraserToggle

				showGrid: topBar.showGrid
				showGuides: topBar.showGuide
				showBestFit: topBar.showBestFit
				selectedColor: topBar.selectedColor

				brushSize: topBar.brushSize
				brushDensity: topBar.brushDensity
			}

			ResultBar {
				Layout.fillWidth: true
				implicitHeight: 50

				backend: processing
			}
		}
	}
}
