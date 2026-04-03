export function addPoint(x, y, view, xA, yA, mainScatterSeries) {
    const area = view.plotArea

    const pointX = xA.min + ((x - area.x) / area.width) * (xA.max - xA.min)
    const pointY = yA.max - ((y - area.y) / area.height) * (yA.max - yA.min)
    mainScatterSeries.append(pointX, pointY)
}

export function recenter(mainScatterSeries, xA, yA) {
    if (mainScatterSeries.count === 0) return
    let minX = Infinity, maxX = -Infinity
    let minY = Infinity, maxY = -Infinity
    for (let i = 0; i < mainScatterSeries.count; i++) {
        const p = mainScatterSeries.at(i)
        if (p.x < minX) minX = p.x
        if (p.x > maxX) maxX = p.x
        if (p.y < minY) minY = p.y
        if (p.y > maxY) maxY = p.y
    }
    const padX = (maxX - minX) * 0.1 || 10
    const padY = (maxY - minY) * 0.1 || 10
    xA.min = minX - padX;
    xA.max = maxX + padX
    yA.min = minY - padY;
    yA.max = maxY + padY
}