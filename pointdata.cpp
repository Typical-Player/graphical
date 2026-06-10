#include "pointdata.h"

PointData::PointData(QObject *parent) : QObject(parent) {
}

QList<QPointF> PointData::allPoints() const {
    return _points;
}

int PointData::pointCount() const {
    return _points.count();
}

QPointF PointData::pointAt(const qint64 idx) const {
    return _points[idx];
}

void PointData::addPoint(const QPointF &point) {
    _points.push_back(point);
    emit pointsChanged();
}

void PointData::addPoints(const QList<QPointF> &points) {
    _points.append(points);
    emit pointsChanged();
}

void PointData::removePoint(const qint64 idx) {
    _points.removeAt(idx);
    emit pointsChanged();
}

void PointData::setPoint(const qint64 idx, const QPointF &point) {
    _points[idx] = point;
    emit pointsChanged();
}

void PointData::setAllPoints(const QList<QPointF> &points) {
    _points.clear();
    _points = points;
    emit pointsChanged();
}

void PointData::clear() {
    _points.clear();
    emit pointsChanged();
}
