import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: row
    required property int index
    required property double px
    required property double py

    width: listView.width
    implicitHeight: 34
    color: row.index % 2 === 0 ? colorPallete.base : colorPallete.alternateBase

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 4

        Label {
            text: row.index + 1
            color: colorPallete.mid
            font.pointSize: 8
            Layout.preferredWidth: 36
        }

        TextField {
            id: xField
            Layout.fillWidth: true
            implicitHeight: 26
            font.pointSize: 9
            horizontalAlignment: Text.AlignRight
            validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }

            Binding on text {
                when: !xField.activeFocus
                value: Number(row.px).toFixed(4)
            }

            onEditingFinished: {
                const val = parseFloat(text)
                if (!isNaN(val))
                    pointsModel.setPoint(row.index, val, row.py)
            }

            Keys.onEscapePressed: {
                text = Number(row.px).toFixed(4)
                focus = false
            }
        }

        TextField {
            id: yField
            Layout.fillWidth: true
            implicitHeight: 26
            font.pointSize: 9
            horizontalAlignment: Text.AlignRight
            validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }

            Binding on text {
                when: !yField.activeFocus
                value: Number(row.py).toFixed(4)
            }

            onEditingFinished: {
                const val = parseFloat(text)
                if (!isNaN(val))
                    pointsModel.setPoint(row.index, row.px, val)
            }

            Keys.onEscapePressed: {
                text = Number(row.py).toFixed(4)
                focus = false
            }
        }

        ToolButton {
            implicitWidth: 28
            implicitHeight: 28
            icon.source: "qrc:/icons/clear.svg"
            icon.color: colorPallete.text
            icon.width: 14
            icon.height: 14
            onClicked: pointsModel.removePoint(row.index)

            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: "Remove point"
        }
    }
}