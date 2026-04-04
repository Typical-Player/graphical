import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtGraphs
import graphical

import "utils.mjs" as U

Rectangle {
	id: root

	required property PointProcessing backend
	required property ValueAxis xAxis
	required property ValueAxis yAxis

	readonly property bool panToggle: pantoggle.checked
	readonly property bool freedrawToggle: freedrawtoggle.checked

	property int spacing: 4

	color: "transparent"

	signal logoClicked()

	RowLayout {
		anchors.fill: parent
		spacing: root.spacing

		ComboBox {
			model: ["Lineal", "Cuadratic", "Exponential"]
			onCurrentIndexChanged: root.backend.plotType = currentIndex
		}

		ToolSeparator {
		}

		ToolButton {
			text: "Clear"
			onClicked: {
				root.backend.clear()
				root.xAxis.min = 0; root.xAxis.max = 100
				root.yAxis.min = 0; root.yAxis.max = 100
			}

			font.family: "Helvetica"
			icon.source: "qrc:/icons/clear.svg"
		}

		ToolButton {
			text: "Recenter"
			enabled: root.backend.pointSeries.count > 0
			onClicked: U.recenter(root.backend.pointSeries, root.xAxis, root.yAxis)

			font.family: "Helvetica"
			icon.source: "qrc:/icons/recenter.svg"
		}

		ToolSeparator {
		}

		ButtonGroup {
			buttons: toggleModes.children
			exclusive: true
		}

		Row {
			id: toggleModes
			spacing: 4

			ToolButton {
				id: pantoggle
				checkable: true
				checked: true
				icon.source: "qrc:/icons/drag.svg"

				ToolTip.delay: 1000
				ToolTip.visible: hovered
				ToolTip.text: "Pan mode"
			}

			ToolButton {
				id: freedrawtoggle
				checkable: true
				icon.source: "qrc:/icons/freedraw.svg"

				ToolTip.delay: 1000
				ToolTip.visible: hovered
				ToolTip.text: "Freedraw mode"
			}
		}

		Item {
			Layout.fillWidth: true
		}

		Image {
			id: logo
			source: "qrc:/icons/logo.svg"

			MouseArea {
				id: logoMouseArea
				enabled: true
				hoverEnabled: true
				anchors.fill: parent

				onClicked: root.logoClicked()
			}

			ToolTip.delay: 1000
			ToolTip.visible: logoMouseArea.containsMouse
			ToolTip.text: "About Graphical"
		}
	}
}