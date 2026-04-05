import QtQuick
import graphical

Item {
	id: root

	required property PointProcessing backend
	property bool isActive: false

	readonly property int expandedWidth: 400

	implicitWidth: isActive ? expandedWidth : 0

	Behavior on implicitWidth {
		NumberAnimation {
			duration: 500
			easing: Easing.OutExpo
		}
	}

	ColorGroup {
		id: colorPallete
	}

	clip: true

	Rectangle {
		x: root.x
		y: root.y
		height: root.height
		width: root.expandedWidth

		color: colorPallete.base

		ProcessingSidebar {
			anchors.fill: parent
			backend: root.backend
		}
	}

	Rectangle {
		x: root.width - 1
		y: root.y
		height: root.height
		width: 1

		color: colorPallete.dark
	}
}