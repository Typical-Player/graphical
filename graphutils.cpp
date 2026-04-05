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

QScatterSeries* graphutils::targetSeries() const {
	return _targetSeries;
}

void graphutils::setTargetSeries(QScatterSeries* targetSeries) {
	if (_targetSeries == targetSeries) return;

	_targetSeries = targetSeries;
	emit targetSeriesChanged();
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

	for (qint64 i = 0; i < count; ++i) {
		auto wx = baseX;
		auto wy = baseY;

		if (radius > 0) {
			const auto angle = _rand.generateDouble() * 2 * M_PI;
			const auto r = _rand.generateDouble() * radius;

			wx += std::cos(angle) * r * scaleX;
			wy += std::sin(angle) * r * scaleY;
		}

		_targetSeries->append(wx, wy);
	}
}

void graphutils::erasePoints(const qint64 mouseX, const qint64 mouseY, const qint64 brushSize) const {
	if (!checkValid()) return;

	const auto radX = brushSize * (_xAxis->max() - _xAxis->min()) / _plotArea.width();
	const auto radY = brushSize * (_yAxis->max() - _yAxis->min()) / _plotArea.height();

	const auto cX = _xAxis->min() + (mouseX - _plotArea.x()) / _plotArea.width() * (_xAxis->max() - _xAxis->min());
	const auto cY = _yAxis->max() - (mouseY - _plotArea.y()) / _plotArea.height() * (_yAxis->max() - _yAxis->min());
	auto keep = QList<QPointF>();

	for (qint64 i = 0; i < _targetSeries->count(); ++i) {
		auto p = _targetSeries->at(i);
		const auto dx = (p.x() - cX) / radX;

		if (const auto dy = (p.y() - cY) / radY; dx * dx + dy * dy > 1.0) keep.push_back(p);
	}

	_targetSeries->replace(keep);
}

void graphutils::recenter() const {
	if (!checkValid()) return;
	if (_targetSeries->count() == 0) return;

	auto minX = INFINITY;
	auto minY = INFINITY;
	auto maxX = -INFINITY;
	auto maxY = -INFINITY;
	for (qint64 i = 0; i < _targetSeries->count(); ++i) {
		auto p = _targetSeries->at(i);
		if (p.x() < minX) minX = p.x();
		if (p.x() > maxX) maxX = p.x();
		if (p.y() < minY) minY = p.y();
		if (p.y() > maxY) maxY = p.y();
	}

	const float padX = std::max((maxX - minX) * 0.1f, 10.0f);
	const float padY = std::max((maxY - minY) * 0.1f, 10.0f);

	xAxis()->setMin(minX - padX);
	xAxis()->setMax(maxX + padX);
	yAxis()->setMin(minY - padY);
	yAxis()->setMax(maxY + padY);
}

bool graphutils::checkValid() const {
	return _targetSeries || _xAxis || _yAxis;
}
