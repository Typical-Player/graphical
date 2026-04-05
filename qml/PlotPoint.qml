import QtQuick

Rectangle {
	id: root
	property int pointSize: 5

	width: root.pointSize
	height: root.pointSize
	radius: width / 2
}