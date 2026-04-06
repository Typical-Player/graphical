#ifndef GRAPHICAL_POINTPROCESSING_H
#define GRAPHICAL_POINTPROCESSING_H

#include <QtQmlIntegration/qqmlintegration.h>
#include <QScatterSeries>
#include <QThread>
#include "result.h"
#include <QTimer>
#include <QLineSeries>

class workerprocessing;

class pointprocessing : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_NAMED_ELEMENT(PointProcessing)

	Q_PROPERTY(QScatterSeries* pointSeries READ pointSeries CONSTANT)
	Q_PROPERTY(QLineSeries* fitSeries READ fitSeries CONSTANT)
    Q_PROPERTY(SidebarResult resultMatrices READ resultMatrices NOTIFY resultMatricesChanged FINAL)
	Q_PROPERTY(QString error READ error NOTIFY errorChanged FINAL)
	Q_PROPERTY(Progress progress READ progress NOTIFY progressChanged FINAL)
	Q_PROPERTY(PlotType plotType READ plotType WRITE setPlotType NOTIFY plotTypeChanged FINAL)
	Q_PROPERTY(QString resultEquation READ resultEquation NOTIFY resultEquationChanged FINAL)
	Q_PROPERTY(qint64 fitSamples READ fitSamples WRITE setFitSamples NOTIFY fitSamplesChanged FINAL)
	Q_PROPERTY(bool useFractions READ useFractions WRITE setUseFractions NOTIFY useFractionsChanged FINAL)

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


	[[nodiscard]] QString error() const;

	[[nodiscard]] Progress progress() const;

	[[nodiscard]] QString resultEquation() const;

    [[nodiscard]] SidebarResult resultMatrices() const;

	[[nodiscard]] QScatterSeries* pointSeries() const;

	[[nodiscard]] QLineSeries* fitSeries() const;

	[[nodiscard]] PlotType plotType() const;
	void setPlotType(PlotType plotType);

	[[nodiscard]] qint64 fitSamples() const;
	void setFitSamples(qint64 fitSamples);

	[[nodiscard]] bool useFractions() const;
	void setUseFractions(bool useFractions);

	Q_INVOKABLE void updateFitRange(double xMin, double xMax, double yMin, double yMax);

	Q_INVOKABLE void clear() const;

private slots:
	void onWorkerFinished(const Result& result);
	void onWorkerError(const QString& err);
	void onWorkerCanceled();
	void onDataChanged();

signals:
	void errorChanged();
	void progressChanged();
	void plotTypeChanged();
	void resultEquationChanged();
	void fitSamplesChanged();
	void useFractionsChanged();
    void resultMatricesChanged();

    void requestRun(const QList<QPointF>& points, pointprocessing::PlotType plotType, bool useFractions);

private:
	void fireWorker();
	void setProgress(Progress progress);
	void resampleFitSeries(double xMin, double xMax) const;

	QString _error{};
	QScatterSeries* _series{};
	QLineSeries* _fitSeries{};
	PlotType _plotType{};
	Progress _progress{};
	QString _resultEquation{};
	double _bA{};
	double _bB{};
	double _bC{};

	double _lastXMin{};
	double _lastXMax{};
	double _YMin{};
	double _YMax{};

	qint64 _fitSamples{200};

	workerprocessing* _worker{};
	QThread* _workerThread{};

    SidebarResult _sdRes{};

	QTimer* _debounceTimer{};

	bool _pendingRestart{};
	bool _useFractions{};
};


#endif //GRAPHICAL_POINTPROCESSING_H
