import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Item {
	id: root
	required property PointProcessing backend

	readonly property sidebarResult rm: backend.resultMatrices

	readonly property string sidebarFont: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"

	readonly property real matrixSizeFact: .7

	implicitHeight: main.implicitHeight
	implicitWidth: main.implicitWidth

	FontLoader {
		id: robotoSerif
		source: "qrc:/icons/RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.ttf"
	}

	ColorGroup {
		id: colorPallete
	}

	ColumnLayout {
		id: main
		anchors.fill: parent
		anchors.margins: 10
		spacing: 10

		Label {
			text: "Line of Best Fit using the Least-Squares method"

			font.family: robotoSerif.name
			font.pointSize: 14
			wrapMode: Text.WordWrap
			Layout.fillWidth: true
			color: "black"
		}

		RowLayout {
			Label {
				text: "A = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.aMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		RowLayout {
			Label {
				text: "B = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.bMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		RowLayout {
			Label {
				text: "Aᵀ = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.atMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		RowLayout {
			Label {
				text: "AᵀA = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.ataMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		RowLayout {
			Label {
				text: "(AᵀA)⁻¹ = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.atainvMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		RowLayout {
			Label {
				text: "AᵀB = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.atbMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: root.matrixSizeFact
			}
		}

		Rectangle {
			implicitHeight: 1
			color: "black"
			Layout.fillWidth: true
		}

		//? Result

		RowLayout {
			Label {
				text: "(AᵀA)⁻¹AᵀB = "
				font.family: robotoSerif.name
				Layout.alignment: Qt.AlignVCenter
				color: "black"
			}

			Matrix {
				matrixData: root.rm.resMat
				visibleRows: root.rm.rowResolution
				visibleColumns: root.rm.colResolution
				isCompressed: true
				sizeFactor: 1
			}
		}

		Item {
			Layout.fillHeight: true
		}
	}
}
