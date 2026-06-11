pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import graphical

Item {
    id: root

    ColorGroup {
        id: colorGroup
    }

    property int visibleRows: 4
    property int visibleColumns: 4
    property real sizeFactor: 1.0

    property bool isCompressed: true
    property var matrixData: [[]]
    property color matrixColor: colorGroup.text
    property color matrixLinesColor: root.matrixColor

    readonly property int cellH: Math.round(28 * sizeFactor)
    readonly property int dotColW: Math.round(28 * sizeFactor)
    readonly property int dotRowH: Math.round(22 * sizeFactor)
    readonly property int bracketW: Math.round(10 * sizeFactor)
    readonly property int padX: Math.round(8 * sizeFactor)
    readonly property int padY: Math.round(8 * sizeFactor)
    readonly property int totalRows: matrixData.length
    readonly property int totalCols: totalRows > 0 ? matrixData[0].length : 0
    readonly property bool compressRows: isCompressed && totalRows > visibleRows
    readonly property bool compressCols: isCompressed && totalCols > visibleColumns
    readonly property string cellSentinel: "dots"

    function calculateShown(compress: bool, total: int, visible: int): list<var> {
        let r = [];

        if (!compress) {
            for (let i = 0; i < total; i++)
                r.push(i);
            return r;
        }

        const half = Math.floor(visible / 2);

        for (let i = 0; i < half; i++)
            r.push(i);
        r.push(root.cellSentinel);
        for (let j = total - half; j < total; j++)
            r.push(j);

        return r;
    }

    function calculateGridDim(indices: list<var>, dotDim: int, cellDim: int): real {
        let dim = 0;
        for (let i = 0; i < indices.length; i++)
            dim += indices[i] === root.cellSentinel ? dotDim : cellDim;
        return dim;
    }

    function calculateCellPos(idx: int, pad: int, indices: list<var>, dotDim: int, cellDim: int): int {
        let pos = pad;
        for (let i = 0; i < idx; i++) {
            pos += indices[i] === root.cellSentinel ? dotDim : cellDim;
        }
        return pos;
    }

    readonly property var shownRowIndices: root.calculateShown(compressRows, totalRows, visibleRows)
    readonly property var shownColIndices: root.calculateShown(compressCols, totalCols, visibleColumns)


    function rowY(slotIndex: int): int {
        return root.calculateCellPos(slotIndex, padY, shownRowIndices, dotRowH, cellH);
    }

	readonly property var columnWidths: {
		let widths = []
		for (let i = 0; i < shownColIndices.length; i++) {
			const idx = root.shownColIndices[i]
			widths.push(idx === root.cellSentinel ? root.dotColW : root.columnWidth(idx))
		}
		return widths
	}

	readonly property real gridW: {
		let w = 0
		for (let i = 0; i < columnWidths.length; i++) w += columnWidths[i]
		return w
	}
    readonly property real gridH: root.calculateGridDim(root.shownRowIndices, dotRowH, cellH)

    implicitWidth: gridW + bracketW * 2 + padX * 2
    implicitHeight: gridH + padY * 2

	function colX(slotIndex: int): int {
		let pos = padX + bracketW
		for (let i = 0; i < slotIndex; i++)
			pos += root.columnWidths[i]
		return pos
	}

	function measureText(text: string): int {
		return fontMetrics.advanceWidth(text)
	}

	function columnWidth(colIdx: int): int {
		let maxW = 0
		for (let ri = 0; ri < root.shownRowIndices.length; ri++) {
			const rowIdx = root.shownRowIndices[ri]
			if (rowIdx === root.cellSentinel) continue
			const w = root.measureText(root.matrixData[rowIdx][colIdx])
			if (w > maxW) maxW = w
		}
		return Math.max(maxW + Math.round(16 * sizeFactor), Math.round(32 * sizeFactor))
	}

	FontMetrics {
		id: fontMetrics
		font.family: "monospace"
		font.pixelSize: Math.round(13 * root.sizeFactor)
	}

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: Math.max(1, Math.round(2 * root.sizeFactor))
            strokeColor: root.matrixLinesColor

            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin
            pathHints: ShapePath.PathLinear
            fillColor: "transparent"

            startX: root.padX + root.bracketW
            startY: root.padY
            PathLine {
                x: root.padX
                y: root.padY
            }
            PathLine {
                x: root.padX
                y: root.padY + root.gridH
            }
            PathLine {
                x: root.padX + root.bracketW
                y: root.padY + root.gridH
            }
        }

        ShapePath {
            strokeWidth: Math.max(1, Math.round(2 * root.sizeFactor))
            strokeColor: root.matrixLinesColor
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin
            pathHints: ShapePath.PathLinear
            fillColor: "transparent"

            startX: root.padX + root.bracketW + root.gridW
            startY: root.padY
            PathLine {
                x: root.padX + root.bracketW * 2 + root.gridW
                y: root.padY
            }
            PathLine {
                x: root.padX + root.bracketW * 2 + root.gridW
                y: root.padY + root.gridH
            }
            PathLine {
                x: root.padX + root.bracketW + root.gridW
                y: root.padY + root.gridH
            }
        }
    }

    Repeater {
        model: root.shownRowIndices.length

        delegate: Repeater {
            id: cellRepeater
            required property int index
            readonly property int rowSlot: index
            readonly property var rowIdx: root.shownRowIndices[rowSlot]

            model: root.shownColIndices.length

            delegate: Item {
                id: cellItemDelegate
                required property int index
                readonly property int colSlot: index
                readonly property var colIdx: root.shownColIndices[colSlot]

                readonly property bool isEllipsisRow: cellRepeater.rowIdx === root.cellSentinel
                readonly property bool isEllipsisCol: colIdx === root.cellSentinel

                x: root.colX(colSlot)
                y: root.rowY(cellRepeater.rowSlot)
	            width: isEllipsisCol ? root.dotColW : root.columnWidths[colSlot]
	            height: isEllipsisRow ? root.dotRowH : root.cellH

                Text {
                    anchors.centerIn: parent
                    font.family: "monospace"
                    font.pixelSize: Math.round(13 * root.sizeFactor)
                    color: root.matrixColor

                    text: {
                        if (cellItemDelegate.isEllipsisRow && cellItemDelegate.isEllipsisCol)
                            return "⋱";
                        if (cellItemDelegate.isEllipsisRow)
                            return "⋮";
                        if (cellItemDelegate.isEllipsisCol)
                            return "…";

	                    const row = root.matrixData[cellRepeater.rowIdx]
	                    if (row === undefined) return ""
	                    const val = row[cellItemDelegate.colIdx]
	                    if (val === undefined) return ""
	                    return val
                    }
                }
            }
        }
    }
}
