export function addPoint(x, y, view, xA, yA, series, count = 1, radius = 0) {
    const area = view.plotArea;
    const scaleX = (xA.max - xA.min) / area.width;
    const scaleY = (yA.max - yA.min) / area.height;

    const baseX = xA.min + (x - area.x) * scaleX;
    const baseY = yA.max - (y - area.y) * scaleY;

    for (let i = 0; i < count; i++) {
        let wx = baseX;
        let wy = baseY;
        if (radius > 0) {
            const angle = Math.random() * 2 * Math.PI;
            const r = Math.random() * radius;
            wx += Math.cos(angle) * r * scaleX;
            wy += Math.sin(angle) * r * scaleY;
        }
        series.append(wx, wy);
    }
}

export function recenter(series, xA, yA) {
    if (series.count === 0) return
    let minX = Infinity, maxX = -Infinity
    let minY = Infinity, maxY = -Infinity
    for (let i = 0; i < series.count; i++) {
        const p = series.at(i)
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