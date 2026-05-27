#ifndef GRAPHICAL_POINTPROCESSING_H
#define GRAPHICAL_POINTPROCESSING_H

#include <QtQmlIntegration/qqmlintegration.h>
#include <QScatterSeries>
#include <QThread>
#include "result.h"
#include "plottypes.h"
#include <QTimer>
#include <QLineSeries>
#include <QElapsedTimer>

class workerprocessing;

class pointprocessing : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_NAMED_ELEMENT(PointProcessing)

    Q_PROPERTY(QScatterSeries* pointSeries READ pointSeries CONSTANT)
    Q_PROPERTY(QLineSeries* fitSeries READ fitSeries CONSTANT)
    Q_PROPERTY(QLineSeries* residualSeries READ residualSeries CONSTANT)
    Q_PROPERTY(SidebarResult resultMatrices READ resultMatrices NOTIFY resultMatricesChanged FINAL)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged FINAL)
    Q_PROPERTY(Progress progress READ progress NOTIFY progressChanged FINAL)
    Q_PROPERTY(PlotTypes::PlotType plotType READ plotType WRITE setPlotType NOTIFY plotTypeChanged FINAL)
    Q_PROPERTY(
        PerformanceMode performanceMode READ performanceMode WRITE setPerformanceMode NOTIFY performanceModeChanged
            FINAL)
    Q_PROPERTY(
        PerformanceMode resolvedPerformance READ resolvedPerformance NOTIFY resolvedPerformanceChanged FINAL)
    Q_PROPERTY(QString resultEquation READ resultEquation NOTIFY resultEquationChanged FINAL)
    Q_PROPERTY(qint64 fitSamples READ fitSamples WRITE setFitSamples NOTIFY fitSamplesChanged FINAL)
    Q_PROPERTY(bool useFractions READ useFractions WRITE setUseFractions NOTIFY useFractionsChanged FINAL)
    Q_PROPERTY(QRectF plotArea READ plotArea WRITE setPlotArea NOTIFY plotAreaChanged FINAL)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY dataChanged FINAL)

public:
    explicit pointprocessing(QObject* parent = nullptr);
    ~pointprocessing() override;

    enum Progress {
        NOTFIRED,
        PROCESSING,
        ERROR,
        CANCELED,
        READY,
    };

    Q_ENUM(Progress)

    enum PerformanceMode {
        AUTOMATIC,
        HIGHPERFORMANCE,
        LOWPERFORMANCE,
        ORIGINAL
    };

    Q_ENUM(PerformanceMode)

    [[nodiscard]] QString error() const;

    [[nodiscard]] Progress progress() const;

    [[nodiscard]] QString resultEquation() const;

    [[nodiscard]] SidebarResult resultMatrices() const;

    [[nodiscard]] QScatterSeries* pointSeries() const;

    [[nodiscard]] QLineSeries* fitSeries() const;

    [[nodiscard]] QLineSeries* residualSeries() const;

    [[nodiscard]] PlotTypes::PlotType plotType() const;
    void setPlotType(PlotTypes::PlotType plotType);

    [[nodiscard]] qint64 fitSamples() const;
    void setFitSamples(qint64 fitSamples);

    [[nodiscard]] bool useFractions() const;
    void setUseFractions(bool useFractions);

    [[nodiscard]] QRectF plotArea() const;
    void setPlotArea(const QRectF& plotArea);

    [[nodiscard]] PerformanceMode performanceMode() const;
    void setPerformanceMode(PerformanceMode performanceMode);

    [[nodiscard]] PerformanceMode resolvedPerformance() const;

    Q_INVOKABLE void addPoint(const QPointF& point);
    Q_INVOKABLE void addPoints(const QList<QPointF>& points);
    Q_INVOKABLE void removePoint(qint64 idx);

    Q_INVOKABLE void updateFitRange(double xMin, double xMax, double yMin, double yMax);

    Q_INVOKABLE void clear();

    Q_INVOKABLE [[nodiscard]] const QList<QPointF>& allPoints() const;
    void setAllPoints(const QList<QPointF>& points);

    Q_INVOKABLE void setPoint(qint64 idx, const QPointF& point);

    Q_INVOKABLE [[nodiscard]] double  residualAt(qint64 idx) const;
    Q_INVOKABLE [[nodiscard]] QPointF pointAt(qint64 idx) const;
    [[nodiscard]] int pointCount() const;

private slots:
    void onWorkerFinished(const Result& result);
    void onWorkerError(const QString& err);
    void onWorkerCanceled();
    void onDataChanged();
    void onPeformanceModeChanged();

signals:
    void errorChanged();
    void progressChanged();
    void plotTypeChanged();
    void resultEquationChanged();
    void fitSamplesChanged();
    void useFractionsChanged();
    void resultMatricesChanged();
    void plotAreaChanged();
    void performanceModeChanged();
    void resolvedPerformanceChanged();

    void dataChanged();

    void requestRun(const QList<QPointF>& points, PlotTypes::PlotType plotType, bool useFractions);

private:
    void fireWorker();
    void setProgress(Progress progress);
    void resampleResidualSeries(const QList<QPointF>& visiblePoints);
    void resampleFitSeries(double xMin, double xMax) const;
    [[nodiscard]] static QList<QPointF> decimate(const QList<QPointF>& points, double xMin, double xMax, int maxPoints);
    void resampleDisplaySeries(double xMin, double xMax);
    [[nodiscard]] static QList<QPointF> reducePointClouds(const QList<QPointF>& points, double xMin, double xMax,
                                                          double yMin, double yMax, const QSizeF& plotSizePx,
                                                          qint64 cellPx);

    void evaluateAutoPerformance();

    QList<QPointF> _allPoints{};

    QString _error{};
    QScatterSeries* _series{};
    QRectF _plotArea{};
    QLineSeries* _fitSeries{};
    QLineSeries* _residualSeries{};
    PlotTypes::PlotType _plotType{};
    PlotTypes::PlotType _resolvedFitType{};
    Progress _progress{};
    PerformanceMode _performanceMode{};
    PerformanceMode _resolvedMode = HIGHPERFORMANCE;

    QElapsedTimer _frameTimer;
    QTimer* _autoCheckTimer{};
    QTimer* _resizeTimer{};
    int _lagSampleCount = 0;

    static constexpr int AUTO_POINT_THRESHOLD = 5000;
    static constexpr int LAG_THRESHOLD_MS = 100;
    static constexpr int LAG_SAMPLES_NEEDED = 5;
    static constexpr int HIGH_MAX_POINTS = 2000;
    static constexpr int LOW_MAX_POINTS = 500;

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