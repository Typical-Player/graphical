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

	_series = new QScatterSeries(this);
	_debounceTimer = new QTimer(this);
	_debounceTimer->setInterval(500);
	_debounceTimer->setSingleShot(true);

	connect(_series, &QScatterSeries::pointReplaced, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointAdded, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointRemoved, this, &pointprocessing::onDataChanged);
	connect(this, &pointprocessing::plotTypeChanged, this, &pointprocessing::onDataChanged);

	connect(_debounceTimer, &QTimer::timeout, this, &pointprocessing::fireWorker);

	_workerThread->start();
}

pointprocessing::~pointprocessing() {
	_worker->requestCancellation();
	_workerThread->quit();
	_workerThread->wait();
	delete _worker;
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

QScatterSeries* pointprocessing::pointSeries() const {
	return _series;
}

pointprocessing::PlotType pointprocessing::plotType() const {
	return _plotType;
}

void pointprocessing::setPlotType(const PlotType plotType) {
	if (_plotType == plotType) return;

	_plotType = plotType;
	emit plotTypeChanged();
}

void pointprocessing::onWorkerFinished(const Result& result) {
	_error = result.error;
	_resultEquation = result.eqRes;

	if (_pendingRestart) {
		_pendingRestart = false;
		_debounceTimer->start();
		return;
	}

	if (_debounceTimer->isActive()) return;

	emit errorChanged();
	emit resultEquationChanged();
	setProgress(READY);
}

void pointprocessing::onWorkerError(const QString& err) {
	qWarning() << "WORKER ERROR: " << err;
	setProgress(ERROR);
}

void pointprocessing::onWorkerCanceled() {
	if (_pendingRestart || _debounceTimer->isActive()) {
		_pendingRestart = false;
		_debounceTimer->start();
		return;
	}
	setProgress(CANCELED);
}

void pointprocessing::onDataChanged() {
	if (progress() == PROCESSING) {
		_pendingRestart = true;
		_worker->requestCancellation();
		return;
	}

	setProgress(PROCESSING);
	_debounceTimer->start();
}

void pointprocessing::fireWorker() {
	_pendingRestart = false;
	setProgress(PROCESSING);

	emit requestRun(_series->points(), _plotType);
}

void pointprocessing::setProgress(Progress progress) {
	if (_progress == progress) return;
	
	_progress = progress;
	emit progressChanged();
}
