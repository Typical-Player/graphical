#ifndef GRAPHICAL_GRAPHUTILS_H
#define GRAPHICAL_GRAPHUTILS_H
#include <QtQmlIntegration/qqmlintegration.h>
#include <QValueAxis>
#include <QRandomGenerator>
#include "pointprocessing.h"

class graphutils : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_NAMED_ELEMENT(GraphUtils)
	Q_PROPERTY(pointprocessing* backend READ backend WRITE setBackend NOTIFY backendChanged REQUIRED FINAL)
	Q_PROPERTY(QValueAxis* xAxis READ xAxis WRITE setXAxis NOTIFY xAxisChanged REQUIRED FINAL)
	Q_PROPERTY(QValueAxis* yAxis READ yAxis WRITE setYAxis NOTIFY yAxisChanged REQUIRED FINAL)
	Q_PROPERTY(QRectF plotArea READ plotArea WRITE setPlotArea NOTIFY plotAreaChanged REQUIRED FINAL)

public:
	explicit graphutils(QObject* parent = nullptr);

	[[nodiscard]] QRectF plotArea() const;
	void setPlotArea(const QRectF& plotArea);

	[[nodiscard]] pointprocessing* backend() const;
	void setBackend(pointprocessing* backend);

	[[nodiscard]] QValueAxis* xAxis() const;
	void setXAxis(QValueAxis* xAxis);

	[[nodiscard]] QValueAxis* yAxis() const;
	void setYAxis(QValueAxis* yAxis);

	Q_INVOKABLE void addPoint(qint64 mouseX, qint64 mouseY, qint64 count, qint64 radius);
	Q_INVOKABLE void erasePoints(qint64 mouseX, qint64 mouseY, qint64 brushSize) const;

	Q_INVOKABLE void recenter() const;

signals:
	void backendChanged();
	void xAxisChanged();
	void yAxisChanged();
	void plotAreaChanged();

private:
	[[nodiscard]] bool checkValid() const;

	pointprocessing* _backend{};
	QValueAxis* _xAxis{};
	QValueAxis* _yAxis{};
	QRectF _plotArea{};
	QRandomGenerator _rand{};
};


#endif //GRAPHICAL_GRAPHUTILS_H
