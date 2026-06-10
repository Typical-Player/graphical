#include "fitcontroller.h"
#include "workerprocessing.h"

FitController::FitController(QObject *parent) : QObject(parent) {
    _workerThread = new QThread(this);
    _worker = new workerprocessing;
    _worker->moveToThread(_workerThread);

    connect(this, &FitController::requestRun, _worker, &workerprocessing::run);
    connect(_worker, &workerprocessing::finished, this, &FitController::onWorkerFinished);
    connect(_worker, &workerprocessing::canceled, this, &FitController::onWorkerCanceled);
    connect(_worker, &workerprocessing::error, this, &FitController::onWorkerError);

    _debounce = new QTimer(this);
    _debounce->setInterval(1000);
    _debounce->setSingleShot(true);
    connect(_debounce, &QTimer::timeout, this, &FitController::fire);

    connect(this, &FitController::plotTypeChanged, this, &FitController::onInputChanged);
    connect(this, &FitController::useFractionsChanged, this, &FitController::onInputChanged);

    _workerThread->start();
}

FitController::~FitController() {
    _worker->requestCancellation();
    _workerThread->quit();
    _workerThread->wait();
    delete _worker;
}

PointData *FitController::source() const {
    return _source;
}

void FitController::setSource(PointData *source) {
    if (_source == source) return;
    if (_source)
        disconnect(_source, &PointData::pointsChanged,
                   this, &FitController::onInputChanged);
    _source = source;
    if (_source)
        connect(_source, &PointData::pointsChanged,
                this, &FitController::onInputChanged);
    emit sourceChanged();
    if (_source) onInputChanged();
}

PlotTypes::PlotType FitController::plotType() const {
    return _plotType;
}

void FitController::setPlotType(const PlotTypes::PlotType plotType) {
    if (_plotType == plotType) return;
    _plotType = plotType;
    emit plotTypeChanged();
}

bool FitController::useFractions() const {
    return _useFractions;
}

void FitController::setUseFractions(const bool useFractions) {
    if (_useFractions == useFractions) return;
    _useFractions = useFractions;
    emit useFractionsChanged();
}

FitController::Progress FitController::progress() const {
    return _progress;
}

QString FitController::error() const {
    return _error;
}

QString FitController::resultEquation() const {
    return _resultEquation;
}

SidebarResult FitController::resultMatrices() const {
    return _sdRes;
}

PlotTypes::PlotType FitController::resolvedFitType() const {
    return _resolvedFitType;
}

double FitController::evaluateAt(const double x) const {
    if (_progress != READY) return qQNaN();

    switch (_resolvedFitType) {
        case PlotTypes::LINEAL:
            return _bA + _bB * x;
        case PlotTypes::CUADRATIC:
            return _bA + _bB * x + _bC * x * x;
        case PlotTypes::EXPONENTIAL: {
            const double expo = _bB * x;
            if (expo > 700.0 || expo < -700.0) return qQNaN();
            return _bA * std::exp(expo);
        }
        case PlotTypes::AUTOMATIC_FIT:
            return qQNaN();
    }
    return qQNaN();
}

double FitController::residualFor(const QPointF &point) const {
    return point.y() - evaluateAt(point.x());
}

double FitController::residualFor(const int idx) const {
    if (idx >= _source->pointCount() || idx < 0) return {};
    const auto point = _source->pointAt(idx);
    return point.y() - evaluateAt(point.x());
}

void FitController::onInputChanged() {
    if (!_source || _source->pointCount() < 2) {
        _debounce->stop();
        setProgress(NOTFIRED);
        return;
    }

    if (_progress == PROCESSING) {
        _pendingRestart = true;
        _worker->requestCancellation();
        return;
    }

    scheduleRun();
}

void FitController::onWorkerFinished(const Result &result) {
    if (_pendingRestart) {
        _pendingRestart = false;
        _debounce->start();
        return;
    }

    if (_debounce->isActive()) return;

    _resultEquation = result.eqRes;
    _bA = result.betaA;
    _bB = result.betaB;
    _bC = result.betaC;
    _sdRes = result.sr;

    _resolvedFitType = _plotType == PlotTypes::AUTOMATIC_FIT
                           ? result.selectedPlotType
                           : _plotType;

    setProgress(READY);
    emit errorChanged();
    emit resultChanged();
}

void FitController::onWorkerError(const QString &err) {
    _error = err;
    setProgress(ERROR);
}

void FitController::onWorkerCanceled() {
    if (_pendingRestart || _debounce->isActive()) {
        _pendingRestart = false;
        _debounce->start();
        return;
    }
    setProgress(CANCELED);
}

void FitController::fire() {
    _pendingRestart = false;
    setProgress(PROCESSING);

    emit requestRun(_source->allPoints(), _plotType, _useFractions);
}

void FitController::scheduleRun() {
    setProgress(PROCESSING);
    _debounce->start();
}

void FitController::setProgress(const Progress p) {
    if (_progress == p) return;
    _progress = p;
    emit progressChanged();
}
