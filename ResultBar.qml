import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import graphical

Rectangle {
	id: root
	required property PointProcessing backend

	function statusColor(): string {
		switch (backend.progress) {
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

	color: root.statusColor()
	Behavior on color {
		ColorAnimation {
			duration: 300; easing.type: Easing.InOutQuad
		}
	}

	function statusText(): string {
		switch (root.backend.progress) {
			case PointProcessing.NOTFIRED:
				return "Ready"
			case PointProcessing.PROCESSING:
				return "Processing..."
			case PointProcessing.CANCELED:
				return "Canceled"
			case PointProcessing.ERROR:
				return "Error | code: " + root.backend.error
			case PointProcessing.READY:
				return "Best fit: " + root.backend.resultEquation
			default:
				return ""
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 8
		spacing: 2

		RowLayout {
			Layout.fillWidth: true

			Label {
				id: statusLabel
				text: root.statusText()
				color: root.backend.progress === PointProcessing.READY ? "#80ff80" : "white"
				font.family: "Helvetica"

				Behavior on text {
					SequentialAnimation {
						NumberAnimation {
							target: statusLabel; property: "opacity";
							to: 0; duration: 120
						}
						PropertyAction {
							target: statusLabel; property: "text"
						}
						NumberAnimation {
							target: statusLabel; property: "opacity";
							to: 1; duration: 120
						}
					}
				}

				Behavior on color {
					ColorAnimation {
						duration: 240; easing.type: Easing.InOutQuad
					}
				}
			}

			Item {
				Layout.fillWidth: true
			}

			BusyIndicator {
				id: busyIndicator
				running: root.backend.progress === PointProcessing.PROCESSING
				Layout.preferredWidth: 24
				Layout.preferredHeight: 24

				opacity: running ? 1.0 : 0.0
				Behavior on opacity {
					NumberAnimation {
						duration: 200
					}
				}

				background: Rectangle {
					implicitWidth: 64
					implicitHeight: 64
					color: "white"
					radius: width / 2
				}
			}
		}
	}
}