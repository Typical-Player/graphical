import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Item {
	id: root
	required property PointProcessing backend

	readonly property string sidebarFont: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"

	FontLoader {
		id: robotoSerif
		source: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 10

		Label {
			text: "Line of Best Fit using the Least-Squares method"

			font.family: robotoSerif.name
			font.pointSize: 14
			wrapMode: Text.WordWrap
			Layout.fillWidth: true
		}

		Item {
			Layout.fillHeight: true
		}
	}
}