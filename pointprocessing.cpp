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
	_fitSeries = new QLineSeries(this);

	_fitSeries->setStrokeStyle(QLineSeries::StrokeStyle::DashLine);
	QColor color;
	color.setRgb(0, 0, 0);
	_fitSeries->setColor(color);

	_debounceTimer = new QTimer(this);
	_debounceTimer->setInterval(1000);
	_debounceTimer->setSingleShot(true);

	connect(_series, &QScatterSeries::pointReplaced, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointsReplaced, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointAdded, this, &pointprocessing::onDataChanged);
	connect(_series, &QScatterSeries::pointRemoved, this, &pointprocessing::onDataChanged);
	connect(this, &pointprocessing::plotTypeChanged, this, &pointprocessing::onDataChanged);
	connect(this, &pointprocessing::useFractionsChanged, this, &pointprocessing::onDataChanged);

	connect(_debounceTimer, &QTimer::timeout, this, &pointprocessing::fireWorker);

	connect(this, &pointprocessing::fitSamplesChanged, this, [this] {
		this->updateFitRange(_lastXMin, _lastXMax, _YMin, _YMax);
	});

	_workerThread->start();
}

pointprocessing::~pointprocessing() {
	_worker->requestCancellation();
	_workerThread->quit();
	_workerThread->wait();
	delete _worker;
}

QString pointprocessing::error() const {
	return _error;
}

pointprocessing::Progress pointprocessing::progress() const {
	return _progress;
}

QString pointprocessing::resultEquation() const {
	return _resultEquation;
}

SidebarResult pointprocessing::resultMatrices() const
{
    return _sdRes;
}

QScatterSeries* pointprocessing::pointSeries() const {
	return _series;
}

QLineSeries* pointprocessing::fitSeries() const {
	return _fitSeries;
}

pointprocessing::PlotType pointprocessing::plotType() const {
	return _plotType;
}

void pointprocessing::setPlotType(const PlotType plotType) {
	if (_plotType == plotType) return;

	_plotType = plotType;
	emit plotTypeChanged();
}

qint64 pointprocessing::fitSamples() const {
	return _fitSamples;
}

void pointprocessing::setFitSamples(const qint64 fitSamples) {
	if (_fitSamples == fitSamples) return;

	_fitSamples = fitSamples;
	emit fitSamplesChanged();
}

bool pointprocessing::useFractions() const {
	return _useFractions;
}

void pointprocessing::setUseFractions(const bool useFractions) {
	if (_useFractions == useFractions) return;

	_useFractions = useFractions;
	emit useFractionsChanged();
}

void pointprocessing::updateFitRange(const double xMin, const double xMax, const double yMin, const double yMax) {
	_lastXMin = xMin;
	_lastXMax = xMax;
	_YMax = yMax;
	_YMin = yMin;

	if (_progress != READY) return;
	resampleFitSeries(xMin, xMax);
}

void pointprocessing::clear() const {
	_fitSeries->clear();
	_series->clear();
}

void pointprocessing::onWorkerFinished(const Result& result) {
	_resultEquation = result.eqRes;

	if (_pendingRestart) {
		_pendingRestart = false;
		_debounceTimer->start();
		return;
	}

	if (_debounceTimer->isActive()) return;

	_bA = result.betaA;
	_bB = result.betaB;
	_bC = result.betaC;
    _sdRes = result.sr;

	resampleFitSeries(_lastXMin, _lastXMax);
	emit errorChanged();
	emit resultEquationChanged();
    emit resultMatricesChanged();
	setProgress(READY);
}

void pointprocessing::onWorkerError(const QString& err) {
	_fitSeries->clear();
	_error = err;
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

	emit requestRun(_series->points(), _plotType, _useFractions);
}

void pointprocessing::setProgress(const Progress progress) {
	if (_progress == progress) return;

	_progress = progress;
	emit progressChanged();
}

void pointprocessing::resampleFitSeries(const double xMin, const double xMax) const {
	QList<QPointF> points;
	points.reserve(_fitSamples + 1);

	const double step = (xMax - xMin) / static_cast<double>(_fitSamples);


	for (int i = 0; i <= _fitSamples; ++i) {
		double x = xMin + i * step;
		double y = 0;

		switch (_plotType) {
		case LINEAL: y = _bA + _bB * x;
			break;
		case CUADRATIC: y = _bA + _bB * x + _bC * x * x;
			break;
		case EXPONENTIAL: {
			const double expo = _bB * x;
			if (expo > 700.0 || expo < -700.0) continue;
			y = _bA * std::exp(expo);
			break;
		}
		}
		if (const double pad = (_YMax - _YMin) * .5; y < _YMin - pad || y > _YMax + pad) continue;

		if (!std::isfinite(y)) continue;

		points.append({x, y});
	}

	_fitSeries->replace(points);
}
