#include "graphutils.h"

graphutils::graphutils(QObject* parent) : QObject(parent) {}

QRectF graphutils::plotArea() const {
	return _plotArea;
}

void graphutils::setPlotArea(const QRectF& plotArea) {
	if (_plotArea == plotArea) return;

	_plotArea = plotArea;
	emit plotAreaChanged();
}

PointData * graphutils::data() const {
	return _pointData;
}

void graphutils::setData(PointData *data) {
	if (_pointData == data) return;
	_pointData = data;
	emit dataChanged();
}

QValueAxis* graphutils::xAxis() const {
	return _xAxis;
}

void graphutils::setXAxis(QValueAxis* xAxis) {
	if (_xAxis == xAxis) return;
	_xAxis = xAxis;
	emit xAxisChanged();
}

QValueAxis* graphutils::yAxis() const {
	return _yAxis;
}

void graphutils::setYAxis(QValueAxis* yAxis) {
	if (_yAxis == yAxis) return;

	_yAxis = yAxis;
	emit yAxisChanged();
}

void graphutils::addPoint(const qint64 mouseX, const qint64 mouseY, const qint64 count, const qint64 radius) {
	if (!checkValid()) return;

	const auto scaleX = (_xAxis->max() - _xAxis->min()) / _plotArea.width();
	const auto scaleY = (_yAxis->max() - _yAxis->min()) / _plotArea.height();

	const auto baseX = _xAxis->min() + (mouseX - _plotArea.x()) * scaleX;
	const auto baseY = _yAxis->max() - (mouseY - _plotArea.y()) * scaleY;
	QList<QPointF> pts;
	for (qint64 i = 0; i < count; ++i) {
		auto wx = baseX;
		auto wy = baseY;

		if (radius > 0) {
			const auto angle = _rand.generateDouble() * 2 * M_PI;
			const auto r = _rand.generateDouble() * radius;

			wx += std::cos(angle) * r * scaleX;
			wy += std::sin(angle) * r * scaleY;
		}

		pts.append({wx, wy});
	}

	_pointData->addPoints(pts);
}

void graphutils::erasePoints(const qint64 mouseX, const qint64 mouseY, const qint64 brushSize) const {
	if (!checkValid()) return;

	const auto radX = brushSize * (_xAxis->max() - _xAxis->min()) / _plotArea.width();
	const auto radY = brushSize * (_yAxis->max() - _yAxis->min()) / _plotArea.height();

	const auto cX = _xAxis->min() + (mouseX - _plotArea.x()) / _plotArea.width() * (_xAxis->max() - _xAxis->min());
	const auto cY = _yAxis->max() - (mouseY - _plotArea.y()) / _plotArea.height() * (_yAxis->max() - _yAxis->min());
	QList<QPointF> keep;
	for (const auto& p : _pointData->allPoints()) {
		const auto dx = (p.x() - cX) / radX;

		if (const auto dy = (p.y() - cY) / radY; dx * dx + dy * dy > 1.0)
			keep.push_back(p);
	}

	_pointData->setAllPoints(keep);
}

void graphutils::recenter() const {
	if (!checkValid()) return;
	const auto& pts = _pointData->allPoints();
	if (pts.count() == 0) return;

	auto minX = INFINITY;
	auto minY = INFINITY;
	auto maxX = -INFINITY;
	auto maxY = -INFINITY;
	for (qint64 i = 0; i < pts.count(); ++i) {
		auto p = pts.at(i);
		if (p.x() < minX) minX = p.x();
		if (p.x() > maxX) maxX = p.x();
		if (p.y() < minY) minY = p.y();
		if (p.y() > maxY) maxY = p.y();
	}

	const float padX = std::max((maxX - minX) * 0.1f, 1.0f);
	const float padY = std::max((maxY - minY) * 0.1f, 1.0f);

	xAxis()->setMin(minX - padX);
	xAxis()->setMax(maxX + padX);
	yAxis()->setMin(minY - padY);
	yAxis()->setMax(maxY + padY);
}

int graphutils::nearestPointIndex(const qreal mouseX, const qreal mouseY, const qreal thresholdPx) const {
	if (!checkValid()) return -1;
	const auto& pts = _pointData->allPoints();
	if (pts.isEmpty()) return -1;

	const qreal xScale = _plotArea.width()  / (_xAxis->max() - _xAxis->min());
	const qreal yScale = _plotArea.height() / (_yAxis->max() - _yAxis->min());
	const qreal threshold2 = thresholdPx * thresholdPx;

	int   bestIdx   = -1;
	qreal bestDist2 = threshold2;

	for (int i = 0; i < pts.size(); ++i) {
		const qreal sx = _plotArea.x() + (pts[i].x() - _xAxis->min()) * xScale;
		const qreal sy = _plotArea.y() + (_yAxis->max() - pts[i].y()) * yScale;
		if (const qreal d2 = (sx - mouseX) * (sx - mouseX) + (sy - mouseY) * (sy - mouseY); d2 < bestDist2) { bestDist2 = d2; bestIdx = i; }
	}
	return bestIdx;
}

bool graphutils::checkValid() const {
	return _pointData && _xAxis && _yAxis;
}

#include "moc_graphutils.cpp"
