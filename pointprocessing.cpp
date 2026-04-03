#include "pointprocessing.h"
#include "workerprocessing.h"

pointprocessing::pointprocessing(QObject* parent) : QObject(parent) {
	_workerThread = new QThread(this);
	_worker = new workerprocessing;
	_worker->moveToThread(_workerThread);
	connect(this, &pointprocessing::requestRun, _worker, &workerprocessing::run);
	connect(_worker, &workerprocessing::finished, this, &pointprocessing::onWorkerFinished);
	connect(_worker, &workerprocessing::canceled, this, &pointprocessing::onWorkerCanceled);
	connect(_worker, &workerprocessing::error, this, &pointprocessing::onWorkerError);

	_workerThread->start();
}

pointprocessing::~pointprocessing() {
	_workerThread->quit();
	_workerThread->wait();
}

qint64 pointprocessing::error() const {
	return _error;
}

pointprocessing::Progress pointprocessing::progress() const {
	return _progress;
}

QString pointprocessing::resultEquation() const {
	return _resultEquation;
}

QScatterSeries* pointprocessing::series() const {
	return _series;
}

void pointprocessing::setSeries(QScatterSeries* scatterSeries) {
	if (_series) disconnect(_series, nullptr, this, nullptr);

	_series = scatterSeries;

	connect(_series, &QScatterSeries::pointReplaced, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointAdded, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointReplaced, this, &pointprocessing::onDataChanged);

	emit seriesChanged();
}

pointprocessing::PlotType pointprocessing::plotType() const {
	return _plotType;
}

void pointprocessing::setPlotType(const PlotType plotType) {
	if (_plotType == plotType) return;

	_plotType = plotType;
	emit plotTypeChanged();
}

void pointprocessing::processPlot() {
	if (!_series) return;

	if (_progress == PROCESSING) {
		_pendingRestart = true;
		_worker->requestCancellation();
		return;
	}

	fireWorker();
}

void pointprocessing::requestCancel() {
	if (_progress != PROCESSING) return;

	_pendingRestart = false;
	_worker->requestCancellation();
}

void pointprocessing::onWorkerFinished(const Result& result) {
	if (_error != result.error) {
		_error = result.error;
		emit errorChanged();
	}

	if (_resultEquation != result.eqRes) {
		_resultEquation = result.eqRes;
		emit resultEquationChanged();
	}

	_progress = READY;
	emit progressChanged();
}

void pointprocessing::onWorkerError(const QString& err) {
	qWarning() << "WORKER ERROR: " << err;
	_progress = ERROR;
	emit progressChanged();
}

void pointprocessing::onWorkerCanceled() {
	_progress = CANCELED;
	emit progressChanged();

	if (_pendingRestart) fireWorker();
}

void pointprocessing::onDataChanged() {
	if (_progress != PROCESSING) return;
	_pendingRestart = true;
	_worker->requestCancellation();
}

void pointprocessing::fireWorker() {
	_pendingRestart = false;
	_progress = PROCESSING;
	emit progressChanged();

	auto points = _series->points();
	emit requestRun(points, _plotType);
}
