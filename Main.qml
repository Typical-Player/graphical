import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtGraphs
import graphical

Window {
	id: root
	width: 800
	height: 512
	visible: true
	title: "Graphical"

	minimumWidth: 800
	minimumHeight: 512

	property bool freedrawmode: freedrawtoggle.checked
	property bool panmode: pantoggle.checked

	PointProcessing {
		id: processing
		series: mainScatterSeries
	}

	function randomInRange(min: int, max: int): int {
		return Math.random() * (max - min) + min
	}

	function addPoint(x: int, y: int): int {
		const area = view.plotArea

		const pointX = xA.min + ((x - area.x) / area.width) * (xA.max - xA.min)
		const pointY = yA.max - ((y - area.y) / area.height) * (yA.max - yA.min)
		mainScatterSeries.append(pointX, pointY)
	}

	function recenter() {
		if (mainScatterSeries.count === 0) return
		let minX = Infinity, maxX = -Infinity
		let minY = Infinity, maxY = -Infinity
		for (let i = 0; i < mainScatterSeries.count; i++) {
			const p = mainScatterSeries.at(i)
			if (p.x < minX) minX = p.x
			if (p.x > maxX) maxX = p.x
			if (p.y < minY) minY = p.y
			if (p.y > maxY) maxY = p.y
		}
		const padX = (maxX - minX) * 0.1 || 10
		const padY = (maxY - minY) * 0.1 || 10
		xA.min = minX - padX;
		xA.max = maxX + padX
		yA.min = minY - padY;
		yA.max = maxY + padY
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 4

		RowLayout {
			Layout.fillWidth: true
			implicitHeight: 80
			Layout.alignment: Qt.AlignVCenter
			spacing: 8

			Button {
				text: "Clear"
				onClicked: {
					mainScatterSeries.clear()
					xA.min = 0; xA.max = 100
					yA.min = 0; yA.max = 100
				}
			}

			Button {
				text: "Process points"
				onClicked: processing.processPlot()
			}

			Button {
				text: "Recenter"
				enabled: mainScatterSeries.count > 0
				onClicked: root.recenter()
			}

			ButtonGroup {
				buttons: toggleModes.children
				exclusive: true
			}

			Row {
				id: toggleModes

				RadioButton {
					id: pantoggle
					text: "Pan"
					checked: true
				}

				RadioButton {
					id: freedrawtoggle
					text: "Freedraw"
				}
			}

			ComboBox {
				model: ["Lineal", "Cuadratic", "Exponential"]
				onCurrentIndexChanged: processing.plotType = currentIndex
			}

			Label {
				text: "Points: " + mainScatterSeries.count
			}
		}

		Rectangle {
			Layout.fillHeight: true
			Layout.fillWidth: true

			GraphsView {
				id: view
				anchors.fill: parent

				theme: GraphsTheme {
					colorScheme: GraphsTheme.ColorScheme.Dark
					seriesColors: ["#E0D080", "#B0A060"]
					borderColors: ["#807040", "#706030"]
					grid.mainColor: "#ccccff"
					grid.subColor: "#eeeeff"
					axisY.mainColor: "#ccccff"
					axisY.subColor: "#eeeeff"
				}

				axisX: ValueAxis {
					id: xA
					min: 0; max: 100
				}

				axisY: ValueAxis {
					id: yA
					min: 0; max: 100
				}

				ScatterSeries {
					id: mainScatterSeries
				}
			}

			MouseArea {
				anchors.fill: view
				enabled: root.freedrawmode || root.panmode

				property real lastX: 0
				property real lastY: 0

				onClicked: if (root.freedrawmode) root.addPoint(mouseX, mouseY)
				onPositionChanged: {
					if (!pressed) return;
					if (root.freedrawmode) {
						root.addPoint(mouseX, mouseY);
					}

					if (root.panmode) {
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

		Rectangle {
			Layout.fillWidth: true
			height: 80
			color: statusColor()
			radius: 4

			function statusColor(): string {
				switch (processing.progress) {
					case PointProcessing.PROCESSING:
						return "#1a3a5c"
					case PointProcessing.READY:
						return "#1a3d1a"
					case PointProcessing.ERROR:
						return "#4a1a1a"
					case PointProcessing.CANCELED:
						return "#3a3a1a"
					default:
						return "#2a2a2a"
				}
			}

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 8
				spacing: 2

				RowLayout {
					Layout.fillWidth: true

					BusyIndicator {
						running: processing.progress === PointProcessing.PROCESSING
						visible: running
						Layout.preferredWidth: 24
						Layout.preferredHeight: 24
					}

					Label {
						text: statusText()
						color: "white"
						font.bold: true

						function statusText(): string {
							switch (processing.progress) {
								case PointProcessing.NOTFIRED:
									return "Ready"
								case PointProcessing.PROCESSING:
									return "Processing..."
								case PointProcessing.CANCELED:
									return "Canceled"
								case PointProcessing.ERROR:
									return "Error | code: " + processing.error
								case PointProcessing.READY:
									return "Done"
								default:
									return ""
							}
						}
					}

					Button {
						text: "Cancel"
						visible: processing.progress === PointProcessing.PROCESSING
						onClicked: processing.requestCancel()
						Layout.alignment: Qt.AlignRight
					}
				}

				Label {
					visible: processing.progress === PointProcessing.READY
					text: "f(x) = " + processing.resultEquation
					color: "#80ff80"
					font.family: "monospace"
					elide: Text.ElideRight
					Layout.fillWidth: true
				}
			}
		}
	}
}
