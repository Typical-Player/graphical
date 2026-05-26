#include "pointsmodel.h"
#include <limits>

PointsModel::PointsModel(QObject *parent) : QAbstractListModel(parent) {
}

int PointsModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return _selectionActive
               ? static_cast<int>(_filteredIndices.size())
               : static_cast<int>(_points.size());
}

int PointsModel::totalCount() const { return static_cast<int>(_points.size()); }

QVariant PointsModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= rowCount()) return {};
    const int actual = resolveRow(index.row());
    if (actual < 0 || actual >= static_cast<int>(_points.size())) return {};

    const auto &p = _points.at(actual);
    switch (role) {
        case XRole: return p.x();
        case YRole: return p.y();
        case ErrorRole: return _backend
                                   ? _backend->residualAt(actual)
                                   : std::numeric_limits<double>::quiet_NaN();
        case SourceIndexRole: return actual;
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

pointprocessing *PointsModel::backend() const { return _backend; }

void PointsModel::setBackend(pointprocessing *backend) {
    if (_backend == backend) return;
    if (_backend) {
        disconnect(_backend, &pointprocessing::dataChanged, this, &PointsModel::onBackendDataChanged);
        disconnect(_backend, &pointprocessing::resultEquationChanged, this, &PointsModel::onFitUpdated);
    }
    _backend = backend;
    if (_backend) {
        connect(_backend, &pointprocessing::dataChanged, this, &PointsModel::onBackendDataChanged);
        connect(_backend, &pointprocessing::resultEquationChanged, this, &PointsModel::onFitUpdated);
        onBackendDataChanged();
    }
    emit backendChanged();
}

bool PointsModel::selectionActive() const { return _selectionActive; }

void PointsModel::setSelectionActive(bool active) {
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

void PointsModel::appendPoint(qreal x, qreal y) {
    if (!_backend) return;
    _selfModifying = true;
    const QPointF pt{x, y};
    const int newActualIdx = static_cast<int>(_points.size());
    const bool inSel = !_selectionActive || _selectionRect.contains(pt);

    if (inSel) {
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

    _backend->addPoint(pt);
    _selfModifying = false;
    emit countChanged();
    emit totalCountChanged();
}

void PointsModel::removePoint(qint64 visualRow) {
    if (!_backend) return;
    if (visualRow < 0 || visualRow >= rowCount()) return;

    const int actual = resolveRow(static_cast<int>(visualRow));
    _selfModifying = true;
    beginRemoveRows({}, static_cast<int>(visualRow), static_cast<int>(visualRow));
    _points.removeAt(actual);
    if (_selectionActive) {
        _filteredIndices.removeAt(static_cast<int>(visualRow));
        for (int &fi: _filteredIndices) if (fi > actual) --fi;
    }
    endRemoveRows();
    _backend->removePoint(actual);
    _selfModifying = false;
    emit countChanged();
    emit totalCountChanged();
}

void PointsModel::setPoint(qint64 visualRow, qreal x, qreal y) {
    if (!_backend || visualRow < 0 || visualRow >= rowCount()) return;
    const int actual = resolveRow(static_cast<int>(visualRow));
    _selfModifying = true;
    _points[actual] = {x, y};
    const QModelIndex mi = index(static_cast<int>(visualRow));
    emit dataChanged(mi, mi, {XRole, YRole});
    _backend->setPoint(actual, {x, y});
    _selfModifying = false;
}

void PointsModel::onBackendDataChanged() {
    if (_selfModifying) return;
    beginResetModel();
    _points = _backend->allPoints();
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

int PointsModel::resolveRow(int visualRow) const {
    return _selectionActive ? _filteredIndices.at(visualRow) : visualRow;
}
