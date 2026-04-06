import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Fusion
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
}