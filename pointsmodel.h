#ifndef GRAPHICAL_POINTSMODEL_H
#define GRAPHICAL_POINTSMODEL_H

#include <QAbstractListModel>
#include <QtQmlIntegration/qqmlintegration.h>
#include "pointprocessing.h"

class PointsModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_NAMED_ELEMENT(PointsModel)

    Q_PROPERTY(pointprocessing* backend READ backend WRITE setBackend NOTIFY backendChanged FINAL)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)

public:
    enum Roles {
        XRole = Qt::UserRole + 1,
        YRole,
    };
    Q_ENUM(Roles)

    explicit PointsModel(QObject* parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex& parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    [[nodiscard]] Qt::ItemFlags flags(const QModelIndex& index) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] pointprocessing* backend() const;
    void setBackend(pointprocessing* backend);

    Q_INVOKABLE void appendPoint(qreal x, qreal y);
    Q_INVOKABLE void removePoint(qint64 idx);
    Q_INVOKABLE void setPoint(qint64 idx, qreal x, qreal y);

    signals:
        void backendChanged();
    void countChanged();

private slots:
    void onBackendDataChanged();

private:
    pointprocessing* _backend{};
    QList<QPointF>   _points{};
    bool             _selfModifying{false};
};

#endif // GRAPHICAL_POINTSMODEL_H