import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls.Fusion

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
			sourceSize.width: 150
			sourceSize.height: 80

			layer.enabled: true
			layer.effect: MultiEffect {
				brightness: Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? 1 : 0
			}
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
			text: `${Qt.application.name} (${Qt.application.version})`
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

		Row {
			spacing: 4
			Label {
				id: gfnotice
				text: "Icons from Google Fonts"
				font.family: "Helvetica"
				font.bold: true
			}

			Label {
				text: "Apache License Version 2.0"
				font.family: "Helvetica"
				font.pointSize: 7
				anchors.verticalCenter: gfnotice.verticalCenter
			}
		}

		Row {
			spacing: 4
			Label {
				id: gffnotice
				text: "Roboto Serif from Google Fonts"
				font.family: "Helvetica"
				font.bold: true
			}

			Label {
				text: "SIL Open Font License Version 1.1"
				font.family: "Helvetica"
				font.pointSize: 7
				anchors.verticalCenter: gffnotice.verticalCenter
			}
		}

		Row {
			spacing: 4
			Label {
				id: lttbcppnotice
				text: "lttb-cpp C++ LTTB downsampling algorithm library"
				font.family: "Helvetica"
				font.bold: true
			}

			Label {
				text: "MIT License"
				font.family: "Helvetica"
				font.pointSize: 7
				anchors.verticalCenter: lttbcppnotice.verticalCenter
			}
		}

		Row {
			spacing: 4
			Label {
				id: qtnotice
				text: "Made using Qt Framework by Qt Group"
				font.family: "Helvetica"
				font.bold: true
			}

			Label {
				text: "GNU General Public License Version 3"
				font.family: "Helvetica"
				font.pointSize: 7
				anchors.verticalCenter: qtnotice.verticalCenter
			}
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