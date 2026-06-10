#ifndef GRAPHICAL_GRAPHUTILS_H
#define GRAPHICAL_GRAPHUTILS_H
#include <QtQmlIntegration/qqmlintegration.h>
#include <QValueAxis>
#include <QRandomGenerator>
#include <QRectF>

#include "pointdata.h"

class graphutils : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_NAMED_ELEMENT(GraphUtils)
	Q_PROPERTY(PointData* data READ data WRITE setData NOTIFY dataChanged REQUIRED FINAL)
	Q_PROPERTY(QValueAxis* xAxis READ xAxis WRITE setXAxis NOTIFY xAxisChanged REQUIRED FINAL)
	Q_PROPERTY(QValueAxis* yAxis READ yAxis WRITE setYAxis NOTIFY yAxisChanged REQUIRED FINAL)
	Q_PROPERTY(QRectF plotArea READ plotArea WRITE setPlotArea NOTIFY plotAreaChanged REQUIRED FINAL)

public:
	explicit graphutils(QObject* parent = nullptr);

	[[nodiscard]] QRectF plotArea() const;
	void setPlotArea(const QRectF& plotArea);

	[[nodiscard]] PointData* data() const;
	void setData(PointData* data);

	[[nodiscard]] QValueAxis* xAxis() const;
	void setXAxis(QValueAxis* xAxis);

	[[nodiscard]] QValueAxis* yAxis() const;
	void setYAxis(QValueAxis* yAxis);

public slots:
	void addPoint(qint64 mouseX, qint64 mouseY, qint64 count, qint64 radius);
	void erasePoints(qint64 mouseX, qint64 mouseY, qint64 brushSize) const;
	void recenter() const;
	[[nodiscard]] int nearestPointIndex(qreal mouseX, qreal mouseY, qreal thresholdPx) const;

signals:
	void dataChanged();
	void xAxisChanged();
	void yAxisChanged();
	void plotAreaChanged();

private:
	[[nodiscard]] bool checkValid() const;

	PointData* _pointData{};
	QValueAxis* _xAxis{};
	QValueAxis* _yAxis{};
	QRectF _plotArea{};
	QRandomGenerator _rand{};
};


#endif //GRAPHICAL_GRAPHUTILS_H
