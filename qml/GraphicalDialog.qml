import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects

Dialog {
	modal: true
	focus: true
	parent: Overlay.overlay
	popupType: Popup.Item

	x: Math.round((parent.width - width) / 2)
	y: Math.round((parent.height - height) / 2)

	ColorGroup {
		id: colorPallete
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