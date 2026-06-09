#include "pointprocessing.h"
#include "workerprocessing.h"
#include "third_party/lttb.hpp"

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

    _residualSeries = new QLineSeries(this);

    QColor residualColor;
    residualColor.setRgb(255, 0, 0);
    residualColor.setAlpha(120);

    _residualSeries->setColor(residualColor);

    _fitSeries->setStrokeStyle(QLineSeries::StrokeStyle::DashLine);
    QColor color;
    color.setRgb(0, 0, 0);
    _fitSeries->setColor(color);

    _debounceTimer = new QTimer(this);
    _debounceTimer->setInterval(1000);
    _debounceTimer->setSingleShot(true);

    _autoCheckTimer = new QTimer(this);
    _autoCheckTimer->setInterval(1000);
    _autoCheckTimer->setSingleShot(false);
    connect(_autoCheckTimer, &QTimer::timeout, this, &pointprocessing::evaluateAutoPerformance);
    _autoCheckTimer->start();

    _resizeTimer = new QTimer(this);
    _resizeTimer->setInterval(500);
    _resizeTimer->setSingleShot(true);

    connect(this, &pointprocessing::dataChanged, this, &pointprocessing::onDataChanged);
    connect(this, &pointprocessing::plotTypeChanged, this, &pointprocessing::onDataChanged);
    connect(this, &pointprocessing::useFractionsChanged, this, &pointprocessing::onDataChanged);
    connect(this, &pointprocessing::performanceModeChanged, this, &pointprocessing::onPeformanceModeChanged);

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

SidebarResult pointprocessing::resultMatrices() const {
    return _sdRes;
}

QScatterSeries* pointprocessing::pointSeries() const {
    return _series;
}

QLineSeries* pointprocessing::fitSeries() const {
    return _fitSeries;
}

QLineSeries* pointprocessing::residualSeries() const {
    return _residualSeries;
}

PlotTypes::PlotType pointprocessing::plotType() const {
    return _plotType;
}

void pointprocessing::setPlotType(const PlotTypes::PlotType plotType) {
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

QRectF pointprocessing::plotArea() const {
    return _plotArea;
}

void pointprocessing::setPlotArea(const QRectF& plotArea) {
    if (_plotArea == plotArea) return;

    _lagSampleCount = 0;
    _frameTimer.restart();
    _resizeTimer->start();

    _plotArea = plotArea;
    emit plotAreaChanged();
}

pointprocessing::PerformanceMode pointprocessing::performanceMode() const {
    return _performanceMode;
}

void pointprocessing::setPerformanceMode(const PerformanceMode performanceMode) {
    if (_performanceMode == performanceMode) return;

    _performanceMode = performanceMode;
    emit performanceModeChanged();
}

pointprocessing::PerformanceMode pointprocessing::resolvedPerformance() const {
    return _resolvedMode;
}

void pointprocessing::addPoint(const QPointF& point) {
    _allPoints.append(point);
    resampleDisplaySeries(_lastXMin, _lastXMax);
    emit dataChanged();
}

void pointprocessing::addPoints(const QList<QPointF>& points) {
    _allPoints.append(points);
    resampleDisplaySeries(_lastXMin, _lastXMax);
    emit dataChanged();
}

void pointprocessing::removePoint(const qint64 idx) {
    _allPoints.removeAt(idx);
    resampleDisplaySeries(_lastXMin, _lastXMax);
    emit dataChanged();
}

void pointprocessing::updateFitRange(const double xMin, const double xMax, const double yMin, const double yMax) {
    _lastXMin = xMin;
    _lastXMax = xMax;
    _YMax = yMax;
    _YMin = yMin;

    resampleDisplaySeries(xMin, xMax);

    if (_progress != READY) return;
    resampleFitSeries(xMin, xMax);
}

void pointprocessing::clear() {
    _fitSeries->clear();
    _allPoints.clear();
    _series->clear();
}

const QList<QPointF>& pointprocessing::allPoints() const {
    return _allPoints;
}

void pointprocessing::setAllPoints(const QList<QPointF>& points) {
    _allPoints = points;
    resampleDisplaySeries(_lastXMin, _lastXMax);
    emit dataChanged();
}

void pointprocessing::setPoint(qint64 idx, const QPointF& point) {
    if (idx < 0 || idx >= static_cast<qint64>(_allPoints.size())) return;
    _allPoints[static_cast<int>(idx)] = point;
    emit dataChanged();
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

    _resolvedFitType = (_plotType == PlotTypes::AUTOMATIC_FIT)
                           ? result.selectedPlotType
                           : _plotType;

    setProgress(READY);

    resampleFitSeries(_lastXMin, _lastXMax);
    resampleResidualSeries(_series->points());

    emit errorChanged();
    emit resultEquationChanged();
    emit resultMatricesChanged();
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

void pointprocessing::onPeformanceModeChanged() {
    _lagSampleCount = 0;
    resampleDisplaySeries(_lastXMin, _lastXMax);
}

void pointprocessing::fireWorker() {
    _pendingRestart = false;
    setProgress(PROCESSING);

    emit requestRun(_allPoints, _plotType, _useFractions);
}

void pointprocessing::setProgress(const Progress progress) {
    if (_progress == progress) return;

    _progress = progress;
    emit progressChanged();
}

void pointprocessing::resampleResidualSeries(const QList<QPointF>& visiblePoints) {
    if (_progress != READY) {
        _residualSeries->clear();
        return;
    }

    QList<QPointF> lines;
    lines.reserve(visiblePoints.size() * 3);

    for (const auto& p : visiblePoints) {
        const double x = p.x();
        const double y = p.y();

        double yHat = 0.0;

        switch (_resolvedFitType) {
        case PlotTypes::LINEAL:
            yHat = _bA + _bB * x;
            break;

        case PlotTypes::CUADRATIC:
            yHat = _bA + _bB * x + _bC * x * x;
            break;

        case PlotTypes::EXPONENTIAL:
            yHat = _bA * std::exp(_bB * x);
            break;

        case PlotTypes::AUTOMATIC_FIT:
            continue;
        }

        if (!std::isfinite(yHat))
            continue;

        lines.append(QPointF(x, y));
        lines.append(QPointF(x, yHat));
        lines.append(QPointF(qQNaN(), qQNaN()));
    }

    _residualSeries->replace(lines);
}

void pointprocessing::resampleFitSeries(const double xMin, const double xMax) const {
    QList<QPointF> points;
    points.reserve(_fitSamples + 1);

    const double step = (xMax - xMin) / static_cast<double>(_fitSamples);

    for (int i = 0; i <= _fitSamples; ++i) {
        double x = xMin + i * step;
        double y = 0;

        switch (_resolvedFitType) {
        case PlotTypes::LINEAL:
            y = _bA + _bB * x;
            break;
        case PlotTypes::CUADRATIC:
            y = _bA + _bB * x + _bC * x * x;
            break;
        case PlotTypes::EXPONENTIAL: {
            const double expo = _bB * x;
            if (expo > 700.0 || expo < -700.0) continue;
            y = _bA * std::exp(expo);
            break;
        }
        case PlotTypes::AUTOMATIC_FIT:
            continue;
        }

        if (const double pad = (_YMax - _YMin) * .5; y < _YMin - pad || y > _YMax + pad) continue;

        if (!std::isfinite(y)) continue;

        points.append({x, y});
    }

    _fitSeries->replace(points);
}

QList<QPointF> pointprocessing::decimate(const QList<QPointF>& points, const double xMin, const double xMax,
                                         const int maxPoints) {
    struct Point {
        qreal x, y;
    };
    using Lttb = LargestTriangleThreeBuckets<Point, qreal, &Point::x, &Point::y>;

    QList<Point> visible;
    visible.reserve(points.size());
    for (const auto& p : points)
        if (p.x() >= xMin && p.x() <= xMax)
            visible.append({p.x(), p.y()});

    QList<Point> out;
    out.resize(qMin(maxPoints, visible.size()));
    Lttb::Downsample(visible.data(), visible.size(), out.data(), out.size());

    QList<QPointF> result;
    result.reserve(out.size());
    for (const auto& [x, y] : out)
        result.append({x, y});

    return result;
}

void pointprocessing::resampleDisplaySeries(const double xMin, const double xMax) {
    _frameTimer.restart();

    const PerformanceMode effective = (_performanceMode == AUTOMATIC)
                                          ? _resolvedMode
                                          : _performanceMode;

    if (_performanceMode == ORIGINAL) {
        _series->replace(_allPoints);
        resampleResidualSeries(_allPoints);
        this->_frameTimer.restart();
        return;
    }

    const double cellPx = (effective == LOWPERFORMANCE) ? 25.0 : 15.0;
    const qint64 lttbThreshold = (effective == LOWPERFORMANCE) ? 5000 : 20000;
    const int lttbCap = (effective == LOWPERFORMANCE) ? LOW_MAX_POINTS : HIGH_MAX_POINTS;

    QList<QPointF> visible;
    visible.reserve(_allPoints.size());
    for (const auto& p : std::as_const(_allPoints))
        if (p.x() >= xMin && p.x() <= xMax)
            visible.append(p);

    const QList<QPointF> reduced = reducePointClouds(
        visible, xMin, xMax, _YMin, _YMax,
        QSizeF(_plotArea.width(), _plotArea.height()),
        cellPx
        );

    if (reduced.size() <= lttbThreshold) {
        _series->replace(reduced);
        resampleResidualSeries(reduced);
    }
    else {
        _series->replace(decimate(reduced, xMin, xMax, lttbCap));
        resampleResidualSeries(decimate(reduced, xMin, xMax, lttbCap));
    }

    _frameTimer.restart();
}

QList<QPointF> pointprocessing::reducePointClouds(const QList<QPointF>& points, const double xMin, const double xMax,
                                                  const double yMin,
                                                  const double yMax, const QSizeF& plotSizePx, const qint64 cellPx) {
    const double cellW = cellPx * (xMax - xMin) / plotSizePx.width();
    const double cellH = cellPx * (yMax - yMin) / plotSizePx.height();

    if (cellW <= 0 || cellH <= 0)
        return points;

    struct Bucket {
        double sumX = 0, sumY = 0;
        int count = 0;
    };

    QHash<QPair<int, int>, Bucket> grid;

    for (const auto& p : points) {
        const int col = static_cast<int>(std::floor(p.x() / cellW));
        const int row = static_cast<int>(std::floor(p.y() / cellH));
        auto& [sumX, sumY, count] = grid[qMakePair(col, row)];
        sumX += p.x();
        sumY += p.y();
        count++;
    }

    QList<QPointF> result;
    result.reserve(grid.size());
    for (const auto& [sumX, sumY, count] : std::as_const(grid))
        result.append({sumX / count, sumY / count});

    return result;
}

void pointprocessing::evaluateAutoPerformance() {
    if (_performanceMode != AUTOMATIC) return;

    const PerformanceMode previous = _resolvedMode;

    if (_allPoints.size() > AUTO_POINT_THRESHOLD) {
        _resolvedMode = LOWPERFORMANCE;
    }
    else if (!_resizeTimer->isActive()) {
        if (const qint64 elapsed = _frameTimer.elapsed(); elapsed > LAG_THRESHOLD_MS) {
            _lagSampleCount++;
            if (_lagSampleCount >= LAG_SAMPLES_NEEDED)
                _resolvedMode = LOWPERFORMANCE;
        }
        else {
            _lagSampleCount = qMax(0, _lagSampleCount - 1);
            if (_lagSampleCount == 0)
                _resolvedMode = HIGHPERFORMANCE;
        }
    }

    if (_resolvedMode != previous) {
        resampleDisplaySeries(_lastXMin, _lastXMax);
        emit resolvedPerformanceChanged();
    }
}

double pointprocessing::residualAt(qint64 idx) const {
    if (idx < 0 || idx >= static_cast<qint64>(_allPoints.size()) || _progress != READY)
        return std::numeric_limits<double>::quiet_NaN();

    const double x = _allPoints[static_cast<int>(idx)].x();
    const double y = _allPoints[static_cast<int>(idx)].y();
    double yHat = 0.0;

    switch (_resolvedFitType) {
    case PlotTypes::LINEAL:      yHat = _bA + _bB * x;                break;
    case PlotTypes::CUADRATIC:   yHat = _bA + _bB * x + _bC * x * x; break;
    case PlotTypes::EXPONENTIAL: yHat = _bA * std::exp(_bB * x);      break;
    case PlotTypes::AUTOMATIC_FIT:
        return std::numeric_limits<double>::quiet_NaN();
    }

    return y - yHat;
}

QPointF pointprocessing::pointAt(qint64 idx) const {
    if (idx < 0 || idx >= static_cast<qint64>(_allPoints.size())) return {};
    return _allPoints[static_cast<int>(idx)];
}

double pointprocessing::evaluateFitAt(double x) const {
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

int pointprocessing::pointCount() const {
    return static_cast<int>(_allPoints.size());
}

#include "moc_pointprocessing.cpp"