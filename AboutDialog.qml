import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
	id: root

	signal closedClicked()

	Button {
		text: "Close"
		onClicked: root.closedClicked()
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.margins: 10
	}

	ColorGroup {
		id: colorPallete
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 2

		Image {
			source: "qrc:/icons/logo.svg"
			fillMode: Image.PreserveAspectFit

			mipmap: true
			sourceSize.width: 300
			sourceSize.height: 100
		}

		Item {
			implicitHeight: 4
		}

		Rectangle {
			Layout.fillWidth: true
			implicitHeight: 1

			color: colorPallete.text
		}

		Item {
			implicitHeight: 4
		}

		Label {
			text: "Graphical (0.0.1a)"
			font.family: "Helvetica"
			font.bold: true
		}

		Label {
			text: ["Cristofer Moises Apaza Chapa",
				"Bismarck Aquino Juan Diego",
				"Coaguila Fuentes Cristian Jean Pool",
				"Gomez Romero Adrian Rogers"].join("\n")

			font.family: "Helvetica"
		}

		Item {
			implicitHeight: 8
		}

		Label {
			text: "Made using Qt Framework by Qt Group"
			font.family: "Helvetica"
			font.bold: true
		}

		Label {
			text: "Modules used: \n" +
				["Quick",
					"Graphs",
					"Svg"].join("\n")

			font.family: "Helvetica"
			font.italic: true
			font.pointSize: 8
		}

		Item {
			Layout.fillHeight: true
		}
	}
}