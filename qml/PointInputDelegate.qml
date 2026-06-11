import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import graphical

Rectangle {
    id: row
    required property int    index
    required property double px
    required property double py
    required property double residual
    required property int    sourceIndex

    readonly property PointsModel pointsModel: ListView.view.model

    function formatResidual(r) {
        if (isNaN(r)) return "—"
        return (r >= 0 ? "+" : "") + r.toFixed(4)
    }

    ColorGroup {
        id: colorPallete
    }

    width: ListView.view.width; implicitHeight: 34
    color: row.index % 2 === 0 ? colorPallete.window : colorPallete.base

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 4; spacing: 4

        Label {
            text: row.sourceIndex + 1
            color: colorPallete.text;
            font.pointSize: 8
            Layout.preferredWidth: 34
        }

        TextField {
            id: xField; Layout.fillWidth: true; implicitHeight: 26
            font.pointSize: 9; horizontalAlignment: Text.AlignRight
            validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
            Binding on text { when: !xField.activeFocus; value: Number(row.px).toFixed(4) }
            onEditingFinished: {
                const v = parseFloat(text)
                if (!isNaN(v)) row.pointsModel.setPoint(row.index, v, row.py)
            }
            Keys.onEscapePressed: { text = Number(row.px).toFixed(4); focus = false }
        }

        TextField {
            id: yField; Layout.fillWidth: true; implicitHeight: 26
            font.pointSize: 9; horizontalAlignment: Text.AlignRight
            validator: DoubleValidator { notation: DoubleValidator.ScientificNotation }
            Binding on text { when: !yField.activeFocus; value: Number(row.py).toFixed(4) }
            onEditingFinished: {
                const v = parseFloat(text)
                if (!isNaN(v)) row.pointsModel.setPoint(row.index, row.px, v)
            }
            Keys.onEscapePressed: { text = Number(row.py).toFixed(4); focus = false }
        }

        Label {
            text: row.formatResidual(row.residual)
            Layout.preferredWidth: 90
            font.pointSize: 8; font.family: "Courier New"
            horizontalAlignment: Text.AlignRight
            color: {
                if (isNaN(row.residual)) return colorPallete.mid
                if (row.residual >  0.001) return colorPallete.text
                if (row.residual < -0.001) return colorPallete.text
                return "#2a9d2a"
            }
        }

        ToolButton {
            implicitWidth: 28; implicitHeight: 28
            icon.source: "qrc:/icons/clear.svg"; icon.color: colorPallete.text
            icon.width: 14; icon.height: 14
            onClicked: row.pointsModel.removePoint(row.index)
            ToolTip.delay: 1000; ToolTip.visible: hovered; ToolTip.text: "Remove point"
        }
    }
}