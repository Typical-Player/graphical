#include "pointsmodel.h"
#include <limits>

PointsModel::PointsModel(QObject *parent) : QAbstractListModel(parent) {
}

PointData *PointsModel::source() const { return _source; }

void PointsModel::setSource(PointData *s) {
    if (_source == s) return;
    if (_source) {
        disconnect(_source, &PointData::pointsChanged, this, &PointsModel::onPointsChanged);
    }
    _source = s;
    if (_source) {
        connect(_source, &PointData::pointsChanged, this, &PointsModel::onPointsChanged);
        onPointsChanged();
    }
    emit sourceChanged();
}

FitController *PointsModel::fit() const { return _fit; }

void PointsModel::setFit(FitController *f) {
    if (_fit == f) return;
    if (_fit) {
        disconnect(_fit, &FitController::resultChanged, this, &PointsModel::onFitUpdated);
    }
    _fit = f;
    if (_fit) {
        connect(_fit, &FitController::resultChanged, this, &PointsModel::onFitUpdated);
        onFitUpdated();
    }
    emit fitChanged();
}

int PointsModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return _selectionActive
               ? static_cast<int>(_filteredIndices.size())
               : static_cast<int>(_points.size());
}

int PointsModel::totalCount() const { return static_cast<int>(_points.size()); }

QVariant PointsModel::data(const QModelIndex &index, const int role) const {
    if (!index.isValid() || index.row() >= rowCount()) return {};
    const int actual = resolveRow(index.row());
    if (actual < 0 || actual >= static_cast<int>(_points.size())) return {};

    const auto &p = _points.at(actual);
    switch (role) {
        case XRole: return p.x();
        case YRole: return p.y();
        case SourceIndexRole: return actual;
        case ErrorRole:
            return _fit
                       ? _fit->residualFor(p)
                       : std::numeric_limits<double>::quiet_NaN();
        default: return {};
    }
}

bool PointsModel::setData(const QModelIndex &index, const QVariant &value, int role) {
    if (!index.isValid() || index.row() >= rowCount()) return false;
    const int actual = resolveRow(index.row());
    if (actual < 0 || actual >= static_cast<int>(_points.size())) return false;

    auto &p = _points[actual];
    switch (role) {
        case XRole: p.setX(value.toReal());
            break;
        case YRole: p.setY(value.toReal());
            break;
        default: return false;
    }
    emit dataChanged(index, index, {role});
    return true;
}

Qt::ItemFlags PointsModel::flags(const QModelIndex &index) const {
    if (!index.isValid()) return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

QHash<int, QByteArray> PointsModel::roleNames() const {
    return {
        {XRole, "px"},
        {YRole, "py"},
        {ErrorRole, "residual"},
        {SourceIndexRole, "sourceIndex"},
    };
}

bool PointsModel::selectionActive() const { return _selectionActive; }

void PointsModel::setSelectionActive(const bool active) {
    if (_selectionActive == active) return;
    _selectionActive = active;
    rebuildFilter();
    emit selectionActiveChanged();
}

QRectF PointsModel::selectionRect() const { return _selectionRect; }

void PointsModel::setSelectionRect(const QRectF &rect) {
    _selectionRect = rect;
    emit selectionRectChanged();
    if (_selectionActive) rebuildFilter();
}

void PointsModel::appendPoint(const qreal x, const qreal y) {
    if (!_source) return;
    _selfModifying = true;
    const QPointF pt{x, y};
    const int newActualIdx = static_cast<int>(_points.size());

    if (!_selectionActive || _selectionRect.contains(pt)) {
        const int visualRow = _selectionActive
                                  ? static_cast<int>(_filteredIndices.size())
                                  : newActualIdx;
        beginInsertRows({}, visualRow, visualRow);
        _points.append(pt);
        if (_selectionActive) _filteredIndices.append(newActualIdx);
        endInsertRows();
    } else {
        _points.append(pt);
    }

    _source->addPoint(pt);
    _selfModifying = false;
    emit countChanged();
    emit totalCountChanged();
}

void PointsModel::removePoint(const qint64 visualRow) {
    if (!_source || visualRow < 0 || visualRow >= rowCount()) return;
    const int actual = resolveRow(static_cast<int>(visualRow));

    _selfModifying = true;
    beginRemoveRows({}, static_cast<int>(visualRow), static_cast<int>(visualRow));
    _points.removeAt(actual);
    if (_selectionActive) {
        _filteredIndices.removeAt(static_cast<int>(visualRow));
        for (int &fi: _filteredIndices) if (fi > actual) --fi;
    }
    endRemoveRows();

    _source->removePoint(actual);
    _selfModifying = false;
    emit countChanged();
    emit totalCountChanged();
}

void PointsModel::setPoint(const qint64 visualRow, qreal x, qreal y) {
    if (!_source || visualRow < 0 || visualRow >= rowCount()) return;
    const int actual = resolveRow(static_cast<int>(visualRow));

    _selfModifying = true;
    _points[actual] = {x, y};
    const QModelIndex mi = index(static_cast<int>(visualRow));
    emit dataChanged(mi, mi, {XRole, YRole});

    _source->setPoint(actual, {x, y});
    _selfModifying = false;
}

QPointF PointsModel::pointAt(const int visualRow) const {
    if (visualRow < 0 || visualRow >= static_cast<int>(_filteredIndices.size())) return {};
    return _points.at(_filteredIndices.at(visualRow));
}

void PointsModel::onPointsChanged() {
    if (_selfModifying) return;
    beginResetModel();
    _points = _source->allPoints();
    if (_selectionActive) {
        _filteredIndices.clear();
        for (int i = 0; i < static_cast<int>(_points.size()); ++i)
            if (_selectionRect.contains(_points[i]))
                _filteredIndices.append(i);
    }
    endResetModel();
    emit countChanged();
    emit totalCountChanged();
}

void PointsModel::onFitUpdated() {
    if (_selfModifying || rowCount() == 0) return;
    emit dataChanged(index(0), index(rowCount() - 1), {ErrorRole});
}

void PointsModel::rebuildFilter() {
    beginResetModel();
    _filteredIndices.clear();
    if (_selectionActive)
        for (int i = 0; i < static_cast<int>(_points.size()); ++i)
            if (_selectionRect.contains(_points[i]))
                _filteredIndices.append(i);
    endResetModel();
    emit countChanged();
}

int PointsModel::resolveRow(const int visualRow) const {
    return _selectionActive ? _filteredIndices.at(visualRow) : visualRow;
}
