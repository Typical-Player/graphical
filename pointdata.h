#ifndef GRAPHICAL_POINTDATA_H
#define GRAPHICAL_POINTDATA_H

#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QPointF>

class PointData : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointsChanged FINAL)
    Q_PROPERTY(QList<QPointF> allPoints READ allPoints NOTIFY pointsChanged FINAL)

public:
    explicit PointData(QObject *parent = nullptr);

    [[nodiscard]] QList<QPointF> allPoints() const;

    [[nodiscard]] int pointCount() const;

public slots:
    [[nodiscard]] QPointF pointAt(qint64 idx) const;

    void addPoint(const QPointF &point);

    void addPoints(const QList<QPointF> &points);

    void removePoint(qint64 idx);

    void setPoint(qint64 idx, const QPointF &point);

    void setAllPoints(const QList<QPointF> &points);

    void clear();

signals:
    void pointsChanged();

private:
    QList<QPointF> _points{};
};

#endif
