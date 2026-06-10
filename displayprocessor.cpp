#include "displayprocessor.h"

#include "third_party/lttb.hpp"

DisplayProcessor::DisplayProcessor(QObject *parent) : QObject(parent) {
    _series = new QScatterSeries(this);

    _fitSeries = new QLineSeries(this);
    _fitSeries->setStrokeStyle(QLineSeries::StrokeStyle::DashLine);
    _fitSeries->setColor(QColor(0, 0, 0));

    _residualSeries = new QLineSeries(this);
    QColor residualColor(255, 0, 0);
    residualColor.setAlpha(120);
    _residualSeries->setColor(residualColor);

    _selectionFitSeries = new QLineSeries(this);
    _selectionFitSeries->setStrokeStyle(QLineSeries::StrokeStyle::DashLine);
    _selectionFitSeries->setColor(QColor::fromRgbF(0.85, 0.45, 0.10));

    _autoCheckTimer = new QTimer(this);
    _autoCheckTimer->setInterval(1000);
    _autoCheckTimer->setSingleShot(false);
    connect(_autoCheckTimer, &QTimer::timeout, this, &DisplayProcessor::evaluateAutoPerformance);
    _autoCheckTimer->start();

    _resizeTimer = new QTimer(this);
    _resizeTimer->setInterval(500);
    _resizeTimer->setSingleShot(true);

    connect(this, &DisplayProcessor::fitSamplesChanged, this, [this] {
        resampleFitSeries();
        resampleSelectionFitSeries();
    });

    connect(this, &DisplayProcessor::plotAreaChanged, this, [this] {
        _lagSampleCount = 0;
        _frameTimer.restart();
        _resizeTimer->start();
        resampleDisplaySeries();
    });
}

DisplayProcessor::~DisplayProcessor() {
}

PointData *DisplayProcessor::source() const {
    return _source;
}

void DisplayProcessor::setSource(PointData *s) {
    if (_source == s) return;
    if (_source) disconnect(_source, &PointData::pointsChanged, this, &DisplayProcessor::onPointsChanged);
    _source = s;
    if (_source) connect(_source, &PointData::pointsChanged, this, &DisplayProcessor::onPointsChanged);
    emit sourceChanged();
    if (_source) onPointsChanged();
}

FitController *DisplayProcessor::fit() const {
    return _fit;
}

void DisplayProcessor::setFit(FitController *f) {
    if (_fit == f) return;
    if (_fit) disconnect(_fit, &FitController::resultChanged, this, &DisplayProcessor::onFitResultChanged);
    _fit = f;
    if (_fit) connect(_fit, &FitController::resultChanged, this, &DisplayProcessor::onFitResultChanged);
    emit fitChanged();
}

PointData *DisplayProcessor::selectionSource() const {
    return _selectionSource;
}

void DisplayProcessor::setSelectionSource(PointData *s) {
    if (_selectionSource == s) return;
    if (_selectionSource)
        disconnect(_selectionSource, &PointData::pointsChanged,
                   this, &DisplayProcessor::onSelectionFitResultChanged);
    _selectionSource = s;
    if (_selectionSource)
        connect(_selectionSource, &PointData::pointsChanged,
                this, &DisplayProcessor::onSelectionFitResultChanged);
    emit selectionSourceChanged();
}

FitController *DisplayProcessor::selectionFit() const {
    return _selectionFit;
}

void DisplayProcessor::setSelectionFit(FitController *f) {
    if (_selectionFit == f) return;
    if (_selectionFit)
        disconnect(_selectionFit, &FitController::resultChanged,
                   this, &DisplayProcessor::onSelectionFitResultChanged);
    _selectionFit = f;
    if (_selectionFit)
        connect(_selectionFit, &FitController::resultChanged,
                this, &DisplayProcessor::onSelectionFitResultChanged);
    emit selectionFitChanged();
}

QScatterSeries *DisplayProcessor::pointSeries() const {
    return _series;
}

QLineSeries *DisplayProcessor::fitSeries() const {
    return _fitSeries;
}

QLineSeries *DisplayProcessor::residualSeries() const {
    return _residualSeries;
}

QLineSeries *DisplayProcessor::selectionFitSeries() const {
    return _selectionFitSeries;
}

DisplayProcessor::PerformanceMode DisplayProcessor::performanceMode() const {
    return _performanceMode;
}

void DisplayProcessor::setPerformanceMode(const PerformanceMode m) {
    if (_performanceMode == m) return;
    _performanceMode = m;
    emit performanceModeChanged();
    resampleDisplaySeries();
}

DisplayProcessor::PerformanceMode DisplayProcessor::resolvedPerformance() const {
    return _resolvedMode;
}

QRectF DisplayProcessor::plotArea() const {
    return _plotArea;
}

void DisplayProcessor::setPlotArea(const QRectF &r) {
    if (_plotArea == r) return;
    _plotArea = r;
    emit plotAreaChanged();
}

qint64 DisplayProcessor::fitSamples() const {
    return _fitSamples;
}

void DisplayProcessor::setFitSamples(const qint64 n) {
    if (_fitSamples == n) return;
    _fitSamples = n;
    emit fitSamplesChanged();
}

void DisplayProcessor::updateFitRange(const double xMin, const double xMax, const double yMin, const double yMax) {
    _lastXMin = xMin;
    _lastXMax = xMax;
    this->YMax = yMax;
    this->YMin = yMin;

    resampleDisplaySeries();
    resampleFitSeries();
    resampleSelectionFitSeries();
}

void DisplayProcessor::onPointsChanged() {
    resampleDisplaySeries();
    if (_fit && _fit->progress() == FitController::READY) {
        resampleFitSeries();
    } else {
        _fitSeries->clear();
        _residualSeries->clear();
    }
}

void DisplayProcessor::onFitResultChanged() {
    if (!_fit || _fit->progress() != FitController::READY) return;
    resampleFitSeries();
    resampleDisplaySeries();
}

void DisplayProcessor::onSelectionFitResultChanged() const {
    if (_selectionFit && _selectionFit->progress() == FitController::ERROR) {
        _selectionFitSeries->clear();
        return;
    }

    if (!_selectionFit || _selectionFit->progress() != FitController::READY) return;
    resampleSelectionFitSeries();
}

void DisplayProcessor::evaluateAutoPerformance() {
    if (_performanceMode != AUTOMATIC || !_source) return;

    const PerformanceMode previous = _resolvedMode;

    if (_source->pointCount() > AUTO_POINT_THRESHOLD) {
        _resolvedMode = LOWPERFORMANCE;
    } else if (!_resizeTimer->isActive()) {
        if (const qint64 elapsed = _frameTimer.elapsed(); elapsed > LAG_THRESHOLD_MS) {
            _lagSampleCount++;
            if (_lagSampleCount >= LAG_SAMPLES_NEEDED)
                _resolvedMode = LOWPERFORMANCE;
        } else {
            _lagSampleCount = qMax(0, _lagSampleCount - 1);
            if (_lagSampleCount == 0)
                _resolvedMode = HIGHPERFORMANCE;
        }
    }

    if (_resolvedMode != previous) {
        resampleDisplaySeries();
        emit resolvedPerformanceChanged();
    }
}

void DisplayProcessor::resampleDisplaySeries() {
    if (!_source) return;
    _frameTimer.restart();

    const PerformanceMode effective = _performanceMode == AUTOMATIC
                                          ? _resolvedMode
                                          : _performanceMode;

    if (_performanceMode == ORIGINAL) {
        _series->replace(_source->allPoints());
        if (_fit && _fit->progress() == FitController::READY)
            resampleResidualSeries(_source->allPoints());
        else
            _residualSeries->clear();
        _frameTimer.restart();
        return;
    }

    const double cellPx = effective == LOWPERFORMANCE ? 25.0 : 15.0;
    const qint64 lttbThreshold = effective == LOWPERFORMANCE ? 5000 : 20000;
    const int lttbCap = effective == LOWPERFORMANCE ? LOW_MAX_POINTS : HIGH_MAX_POINTS;

    QList<QPointF> visible;
    visible.reserve(_source->pointCount());
    for (const auto &p: _source->allPoints())
        if (p.x() >= _lastXMin && p.x() <= _lastXMax)
            visible.append(p);

    const QList<QPointF> reduced = reducePointClouds(
        visible, _lastXMin, _lastXMax, YMin, YMax,
        QSizeF(_plotArea.width(), _plotArea.height()), cellPx);

    const QList<QPointF> displayPoints = reduced.size() <= lttbThreshold
                                             ? reduced
                                             : decimate(reduced, _lastXMin, _lastXMax, lttbCap);

    _series->replace(displayPoints);

    if (_fit && _fit->progress() == FitController::READY)
        resampleResidualSeries(displayPoints);
    else
        _residualSeries->clear();

    _frameTimer.restart();
}

void DisplayProcessor::resampleFitSeries() const {
    if (!_fit || _fit->progress() != FitController::READY) {
        _fitSeries->clear();
        return;
    }

    QList<QPointF> points;
    points.reserve(_fitSamples + 1);

    const double step = (_lastXMax - _lastXMin) / static_cast<double>(_fitSamples);

    for (int i = 0; i <= _fitSamples; ++i) {
        double x = _lastXMin + i * step;
        auto y = _fit->evaluateAt(x);
        if (y == qQNaN()) continue;
        points.append({x, y});
    }

    _fitSeries->replace(points);
}

void DisplayProcessor::resampleResidualSeries(const QList<QPointF> &visible) const {
    if (!_fit || _fit->progress() != FitController::READY) {
        _residualSeries->clear();
        return;
    }

    QList<QPointF> lines;
    lines.reserve(visible.size() * 3);

    for (const auto &p: visible) {
        const double x = p.x();
        const double y = p.y();

        const double yHat = _fit->evaluateAt(x);
        if (yHat == qQNaN()) continue;

        lines.append(QPointF(x, y));
        lines.append(QPointF(x, yHat));
        lines.append(QPointF(qQNaN(), qQNaN()));
    }

    _residualSeries->replace(lines);
}

void DisplayProcessor::resampleSelectionFitSeries() const {
    QList<QPointF> points;
    points.reserve(_fitSamples + 1);

    const double step = (_lastXMax - _lastXMin) / static_cast<double>(_fitSamples);

    for (int i = 0; i <= _fitSamples; ++i) {
        double x = _lastXMin + i * step;
        double y = _selectionFit->evaluateAt(x);
        if (!std::isfinite(y)) continue;
        if (const double pad = (YMax - YMin) * .5; y < YMin - pad || y > YMax + pad) continue;
        if (y == qQNaN()) continue;

        points.append({x, y});
    }

    _selectionFitSeries->replace(points);
}

QList<QPointF> DisplayProcessor::decimate(const QList<QPointF> &pts, const double xMin, const double xMax,
                                          const int maxPoints) {
    struct Point {
        qreal x, y;
    };
    using Lttb = LargestTriangleThreeBuckets<Point, qreal, &Point::x, &Point::y>;

    QList<Point> visible;
    visible.reserve(pts.size());
    for (const auto &p: pts)
        if (p.x() >= xMin && p.x() <= xMax)
            visible.append({p.x(), p.y()});

    QList<Point> out;
    out.resize(qMin(maxPoints, visible.size()));
    Lttb::Downsample(visible.data(), visible.size(), out.data(), out.size());

    QList<QPointF> result;
    result.reserve(out.size());
    for (const auto &[x, y]: out)
        result.append({x, y});

    return result;
}

QList<QPointF> DisplayProcessor::reducePointClouds(const QList<QPointF> &pts, const double xMin, const double xMax,
                                                   const double yMin,
                                                   const double yMax, const QSizeF &plotSizePx, const qint64 cellPx) {
    const double cellW = cellPx * (xMax - xMin) / plotSizePx.width();
    const double cellH = cellPx * (yMax - yMin) / plotSizePx.height();

    if (cellW <= 0 || cellH <= 0)
        return pts;

    struct Bucket {
        double sumX = 0, sumY = 0;
        int count = 0;
    };

    QHash<QPair<int, int>, Bucket> grid;

    for (const auto &p: pts) {
        const int col = static_cast<int>(std::floor(p.x() / cellW));
        const int row = static_cast<int>(std::floor(p.y() / cellH));
        auto &[sumX, sumY, count] = grid[qMakePair(col, row)];
        sumX += p.x();
        sumY += p.y();
        count++;
    }

    QList<QPointF> result;
    result.reserve(grid.size());
    for (const auto &[sumX, sumY, count]: std::as_const(grid))
        result.append({sumX / count, sumY / count});

    return result;
}
