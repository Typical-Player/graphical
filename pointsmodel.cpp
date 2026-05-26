#include "pointsmodel.h"

PointsModel::PointsModel(QObject* parent) : QAbstractListModel(parent) {}

int PointsModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(_points.size());
}

QVariant PointsModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= static_cast<int>(_points.size()))
        return {};
    const auto& p = _points.at(index.row());
    switch (role) {
        case XRole: return p.x();
        case YRole: return p.y();
        default:    return {};
    }
}

bool PointsModel::setData(const QModelIndex& index, const QVariant& value, int role) {
    if (!index.isValid() || index.row() >= static_cast<int>(_points.size()))
        return false;
    auto& p = _points[index.row()];
    switch (role) {
        case XRole: p.setX(value.toReal()); break;
        case YRole: p.setY(value.toReal()); break;
        default: return false;
    }
    emit dataChanged(index, index, {role});
    return true;
}

Qt::ItemFlags PointsModel::flags(const QModelIndex& index) const {
    if (!index.isValid()) return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

QHash<int, QByteArray> PointsModel::roleNames() const {
    return {
        { XRole, "px" },
        { YRole, "py" },
    };
}

pointprocessing* PointsModel::backend() const { return _backend; }

void PointsModel::setBackend(pointprocessing* backend) {
    if (_backend == backend) return;
    if (_backend)
        disconnect(_backend, &pointprocessing::dataChanged, this, &PointsModel::onBackendDataChanged);
    _backend = backend;
    if (_backend) {
        connect(_backend, &pointprocessing::dataChanged, this, &PointsModel::onBackendDataChanged);
        onBackendDataChanged();
    }
    emit backendChanged();
}

void PointsModel::appendPoint(qreal x, qreal y) {
    if (!_backend) return;
    _selfModifying = true;
    const int row = static_cast<int>(_points.size());
    beginInsertRows({}, row, row);
    _points.append({x, y});
    endInsertRows();
    _backend->addPoint({x, y});
    _selfModifying = false;
    emit countChanged();
}

void PointsModel::removePoint(qint64 idx) {
    if (!_backend || idx < 0 || idx >= static_cast<qint64>(_points.size())) return;
    _selfModifying = true;
    const int row = static_cast<int>(idx);
    beginRemoveRows({}, row, row);
    _points.removeAt(row);
    endRemoveRows();
    _backend->removePoint(idx);
    _selfModifying = false;
    emit countChanged();
}

void PointsModel::setPoint(qint64 idx, qreal x, qreal y) {
    if (!_backend || idx < 0 || idx >= static_cast<qint64>(_points.size())) return;
    _selfModifying = true;
    _points[static_cast<int>(idx)] = {x, y};
    const QModelIndex mi = index(static_cast<int>(idx));
    emit dataChanged(mi, mi, {XRole, YRole});
    _backend->setPoint(idx, {x, y});
    _selfModifying = false;
}

void PointsModel::onBackendDataChanged() {
    if (_selfModifying) return;
    beginResetModel();
    _points = _backend->allPoints();
    endResetModel();
    emit countChanged();
}