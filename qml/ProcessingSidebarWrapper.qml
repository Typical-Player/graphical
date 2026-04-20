pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Fusion
import graphical

Item {
	id: root

	required property PointProcessing backend
	property bool isActive: false

	Component {
		id: processingSidebarComponent
		ProcessingSidebar {
			backend: root.backend
		}
	}

	clip: true

	Rectangle {
		x: root.x
		y: root.y
		height: root.height
		width: root.width
		color: "white"

		Flickable {
			anchors.fill: parent
			contentWidth: root.width
			contentHeight: processingLoader.height
			clip: true

			ScrollBar.vertical: ScrollBar {
				policy: ScrollBar.AsNeeded
			}
			ScrollBar.horizontal: ScrollBar {
				policy: ScrollBar.AsNeeded
			}

			flickDeceleration: 0
			boundsBehavior: Flickable.StopAtBounds
			flickableDirection: Flickable.VerticalFlick
			maximumFlickVelocity: 0

			Loader {
				id: processingLoader
				width: root.width
				height: item ? item.implicitHeight : 0
				asynchronous: true
				active: root.isActive
				sourceComponent: processingSidebarComponent
			}
		}
	}

	Rectangle {
		anchors.fill: parent
		opacity: root.backend.progress === PointProcessing.PROCESSING || processingLoader.status !== Loader.Ready  ? 1 : 0

		clip: true

		color: Qt.rgba(0, 0, 0, .5)

		Behavior on opacity {
			NumberAnimation {
				duration: 500
				easing: Easing.OutExpo
			}
		}

		Spinner {
			anchors.centerIn: parent
			running: root.backend.progress === PointProcessing.PROCESSING
		}
	}
}
