import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import graphical

ApplicationWindow {
	id: root
	width: 800
	height: 512
	visible: true
	title: "Graphical"

	minimumWidth: 800
	minimumHeight: 512

	property bool freedrawmode: topBar.freedrawToggle
	property bool panmode: topBar.panToggle

	Dialog {
		id: aboutDialog
		modal: true
		focus: true
		parent: Overlay.overlay
		popupType: Popup.Item

		x: Math.round((parent.width - width) / 2)
		y: Math.round((parent.height - height) / 2)

		width: 500
		height: 350

		AboutDialog {
			anchors.fill: parent
			anchors.margins: 10

			onClosedClicked: aboutDialog.close()
		}

		background: Rectangle {
			color: colorPallete.window
			radius: 4

			layer.enabled: true
			layer.effect: MultiEffect {
				shadowEnabled: true
				shadowColor: "black"
				shadowBlur: 1.0
				shadowVerticalOffset: 5
				shadowHorizontalOffset: 0
			}
		}

		enter: Transition {
			NumberAnimation {
				property: "opacity";
				from: 0.0;
				to: 1.0; duration: 180
			}
			NumberAnimation {
				property: "scale";
				from: 0.5;
				to: 1.0; duration: 180; easing.type: Easing.OutExpo
			}
		}

		exit: Transition {
			NumberAnimation {
				property: "opacity";
				from: 1.0;
				to: 0.0; duration: 180
			}
		}
	}

	PointProcessing {
		id: processing
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
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 0

		Graph {
			id: graph
			Layout.fillHeight: true
			Layout.fillWidth: true
			backend: processing
			panMode: root.panmode
			freedrawMode: root.freedrawmode
		}

		ResultBar {
			Layout.fillWidth: true
			implicitHeight: 50

			backend: processing
		}
	}
}
