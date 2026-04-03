#ifndef GRAPHICAL_POINTPROCESSING_H
#define GRAPHICAL_POINTPROCESSING_H

#include <QtQmlIntegration/qqmlintegration.h>
#include <QScatterSeries>
#include <QThread>
#include "result.h"

class workerprocessing;

class pointprocessing : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_NAMED_ELEMENT(PointProcessing)

	Q_PROPERTY(qint64 error READ error NOTIFY errorChanged FINAL)
	Q_PROPERTY(Progress progress READ progress NOTIFY progressChanged FINAL)
	Q_PROPERTY(QScatterSeries* series READ series WRITE setSeries NOTIFY seriesChanged FINAL REQUIRED)
	Q_PROPERTY(PlotType plotType READ plotType WRITE setPlotType NOTIFY plotTypeChanged FINAL)
	Q_PROPERTY(QString resultEquation READ resultEquation NOTIFY resultEquationChanged FINAL)

public:
	explicit pointprocessing(QObject* parent = nullptr);
	~pointprocessing() override;

	enum PlotType {
		LINEAL,
		CUADRATIC,
		EXPONENTIAL,
	};

	Q_ENUM(PlotType)

	enum Progress {
		NOTFIRED,
		PROCESSING,
		ERROR,
		CANCELED,
		READY,
	};

	Q_ENUM(Progress)


	[[nodiscard]] qint64 error() const;

	[[nodiscard]] Progress progress() const;

	[[nodiscard]] QString resultEquation() const;

	[[nodiscard]] QScatterSeries* series() const;
	void setSeries(QScatterSeries* scatterSeries);

	[[nodiscard]] PlotType plotType() const;
	void setPlotType(PlotType plotType);

	//? Process the plot with the currently set scatterseries object data,
	//? if that data changes, the processing task will be canceled.
	Q_INVOKABLE void processPlot();

	Q_INVOKABLE void requestCancel();

private slots:
	void onWorkerFinished(const Result& result);
	void onWorkerError(const QString& err);
	void onWorkerCanceled();
	void onDataChanged();

signals:
	void errorChanged();
	void progressChanged();
	void seriesChanged();
	void plotTypeChanged();
	void resultEquationChanged();

	void requestRun(const QList<QPointF>& points, PlotType plotType);

private:
	void fireWorker();

	qint64 _error{};
	QScatterSeries* _series{};
	PlotType _plotType{};
	Progress _progress{};
	QString _resultEquation{};

	workerprocessing* _worker{};
	QThread* _workerThread{};

	bool _pendingRestart{};
};


#endif //GRAPHICAL_POINTPROCESSING_H
