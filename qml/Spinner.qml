pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Fusion
import QtQuick.Shapes
import graphical

BusyIndicator {
	id: busyIndicator

	opacity: running ? 1.0 : 0.0
	Behavior on opacity {
		NumberAnimation {
			duration: 200
		}
	}

	background: Rectangle {
		implicitWidth: 32
		implicitHeight: 32
		color: "white"
		radius: width / 2
	}

	layer.enabled: true
	layer.effect: MultiEffect {
		shadowEnabled: true
		shadowColor: "black"
		shadowBlur: 1.0
		shadowVerticalOffset: 5
		shadowHorizontalOffset: 0
	}

	contentItem: Item {
		implicitWidth: 64
		implicitHeight: 64

		Item {
			id: item
			anchors.fill: parent
			opacity: busyIndicator.running ? 1 : 0

			transformOrigin: Item.Center

			Behavior on opacity {
				OpacityAnimator {
					duration: 250
				}
			}

			RotationAnimator {
				target: item
				running: busyIndicator.visible && busyIndicator.running
				from: 0
				to: 360
				loops: Animation.Infinite
				duration: 1250
			}

			Shape {
				anchors.fill: parent
				preferredRendererType: Shape.CurveRenderer

				ShapePath {
					id: path
					strokeColor: "black"
					strokeWidth: 2
					fillColor: "transparent"

					startX: item.width / 2
					startY: 2
					PathArc {
						x: item.width / 2
						y: item.height - 2
						radiusX: item.width / 2 - 2
						radiusY: item.height / 2 - 2
						useLargeArc: false
						direction: PathArc.Clockwise
					}
				}
			}
		}
	}
}