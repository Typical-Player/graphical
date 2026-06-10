#ifndef GRAPHICAL_POINTSMODEL_H
#define GRAPHICAL_POINTSMODEL_H

#include <QAbstractListModel>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QRectF>
#include "pointdata.h"
#include "fitcontroller.h"

class PointsModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(PointData* source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(FitController* fit READ fit WRITE setFit NOTIFY fitChanged FINAL)

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged FINAL)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged FINAL)
    Q_PROPERTY(bool selectionActive READ selectionActive WRITE setSelectionActive NOTIFY selectionActiveChanged FINAL)
    Q_PROPERTY(QRectF selectionRect READ selectionRect WRITE setSelectionRect NOTIFY selectionRectChanged FINAL)

public:
    enum Roles {
        XRole = Qt::UserRole + 1,
        YRole,
        ErrorRole,
        SourceIndexRole
    };

    Q_ENUM(Roles)

    explicit PointsModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;

    [[nodiscard]] int totalCount() const;

    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    bool setData(const QModelIndex &index, const QVariant &value, int role) override;

    [[nodiscard]] Qt::ItemFlags flags(const QModelIndex &index) const override;

    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] PointData *source() const;

    void setSource(PointData *s);

    [[nodiscard]] FitController *fit() const;

    void setFit(FitController *f);

    [[nodiscard]] bool selectionActive() const;

    void setSelectionActive(bool active);

    [[nodiscard]] QRectF selectionRect() const;

    void setSelectionRect(const QRectF &rect);

public slots:
    Q_INVOKABLE void appendPoint(qreal x, qreal y);

    Q_INVOKABLE void removePoint(qint64 visualRow);

    Q_INVOKABLE void setPoint(qint64 visualRow, qreal x, qreal y);

    Q_INVOKABLE [[nodiscard]] QPointF pointAt(int visualRow) const;

signals:
    void sourceChanged();

    void fitChanged();

    void countChanged();

    void totalCountChanged();

    void selectionActiveChanged();

    void selectionRectChanged();

private slots:
    void onPointsChanged(); // was onBackendDataChanged
    void onFitUpdated();

private:
    void rebuildFilter();

    [[nodiscard]] int resolveRow(int visualRow) const;

    PointData *_source{};
    FitController *_fit{};

    QList<QPointF> _points{};
    QList<int> _filteredIndices{};
    bool _selfModifying{false};
    bool _selectionActive{false};
    QRectF _selectionRect{};
};

#endif
