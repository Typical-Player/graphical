#ifndef GRAPHICAL_DISPLAYPROCESSOR_H
#define GRAPHICAL_DISPLAYPROCESSOR_H

#include <QScatterSeries>
#include <QLineSeries>
#include <QElapsedTimer>
#include <QRectF>
#include <QtQmlIntegration/qqmlintegration.h>
#include "pointdata.h"
#include "fitcontroller.h"

class DisplayProcessor : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(PointData* source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(FitController* fit READ fit WRITE setFit NOTIFY fitChanged FINAL)
    Q_PROPERTY(
        PointData* selectionSource READ selectionSource WRITE setSelectionSource NOTIFY selectionSourceChanged FINAL)
    Q_PROPERTY(FitController* selectionFit READ selectionFit WRITE setSelectionFit NOTIFY selectionFitChanged FINAL)

    Q_PROPERTY(QScatterSeries* pointSeries READ pointSeries CONSTANT)
    Q_PROPERTY(QLineSeries* fitSeries READ fitSeries CONSTANT)
    Q_PROPERTY(QLineSeries* residualSeries READ residualSeries CONSTANT)
    Q_PROPERTY(QLineSeries* selectionFitSeries READ selectionFitSeries CONSTANT)

    Q_PROPERTY(
        PerformanceMode performanceMode READ performanceMode WRITE setPerformanceMode NOTIFY performanceModeChanged
        FINAL)
    Q_PROPERTY(PerformanceMode resolvedPerformance READ resolvedPerformance NOTIFY resolvedPerformanceChanged FINAL)
    Q_PROPERTY(QRectF plotArea READ plotArea WRITE setPlotArea NOTIFY plotAreaChanged FINAL)
    Q_PROPERTY(qint64 fitSamples READ fitSamples WRITE setFitSamples NOTIFY fitSamplesChanged FINAL)

public:
    enum PerformanceMode { AUTOMATIC, HIGHPERFORMANCE, LOWPERFORMANCE, ORIGINAL };

    Q_ENUM(PerformanceMode)

    explicit DisplayProcessor(QObject *parent = nullptr);

    ~DisplayProcessor() override;

    [[nodiscard]] PointData *source() const;

    void setSource(PointData *s);

    [[nodiscard]] FitController *fit() const;

    void setFit(FitController *f);

    [[nodiscard]] PointData *selectionSource() const;

    void setSelectionSource(PointData *s);

    [[nodiscard]] FitController *selectionFit() const;

    void setSelectionFit(FitController *f);

    [[nodiscard]] QScatterSeries *pointSeries() const;

    [[nodiscard]] QLineSeries *fitSeries() const;

    [[nodiscard]] QLineSeries *residualSeries() const;

    [[nodiscard]] QLineSeries *selectionFitSeries() const;

    [[nodiscard]] PerformanceMode performanceMode() const;

    void setPerformanceMode(PerformanceMode m);

    [[nodiscard]] PerformanceMode resolvedPerformance() const;

    [[nodiscard]] QRectF plotArea() const;

    void setPlotArea(const QRectF &r);

    [[nodiscard]] qint64 fitSamples() const;

    void setFitSamples(qint64 n);

    Q_INVOKABLE void updateFitRange(double xMin, double xMax, double yMin, double yMax);

signals:
    void sourceChanged();

    void fitChanged();

    void selectionSourceChanged();

    void selectionFitChanged();

    void performanceModeChanged();

    void resolvedPerformanceChanged();

    void plotAreaChanged();

    void fitSamplesChanged();

private slots:
    void onPointsChanged();

    void onFitResultChanged();

    void onSelectionFitResultChanged() const;

    void evaluateAutoPerformance();

private:
    void resampleDisplaySeries();

    void resampleFitSeries() const;

    void resampleResidualSeries(const QList<QPointF> &visible) const;

    void resampleSelectionFitSeries() const;

    [[nodiscard]] static QList<QPointF> decimate(const QList<QPointF> &pts, double xMin, double xMax, int maxPoints);

    [[nodiscard]] static QList<QPointF> reducePointClouds(const QList<QPointF> &pts, double xMin, double xMax,
                                                          double yMin, double yMax,
                                                          const QSizeF &plotSizePx, qint64 cellPx);

    PointData *_source{};
    FitController *_fit{};
    PointData *_selectionSource{};
    FitController *_selectionFit{};

    QScatterSeries *_series{};
    QLineSeries *_fitSeries{};
    QLineSeries *_residualSeries{};
    QLineSeries *_selectionFitSeries{};

    QRectF _plotArea{};
    qint64 _fitSamples{200};
    double _lastXMin{}, _lastXMax{}, YMin{}, YMax{};

    PerformanceMode _performanceMode{};
    PerformanceMode _resolvedMode{HIGHPERFORMANCE};
    QElapsedTimer _frameTimer;
    QTimer *_autoCheckTimer{};
    QTimer *_resizeTimer{};
    int _lagSampleCount{};

    static constexpr int AUTO_POINT_THRESHOLD = 5000;
    static constexpr int LAG_THRESHOLD_MS = 100;
    static constexpr int LAG_SAMPLES_NEEDED = 5;
    static constexpr int HIGH_MAX_POINTS = 2000;
    static constexpr int LOW_MAX_POINTS = 500;
};

#endif
