#ifndef GRAPHICAL_FITCONTROLLER_H
#define GRAPHICAL_FITCONTROLLER_H

#include <QThread>
#include <QTimer>
#include <QtQmlIntegration/qqmlintegration.h>
#include "pointdata.h"
#include "plottypes.h"
#include "result.h"

class workerprocessing;

class FitController : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(PointData* source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(PlotTypes::PlotType plotType READ plotType WRITE setPlotType NOTIFY plotTypeChanged FINAL)
    Q_PROPERTY(bool useFractions READ useFractions WRITE setUseFractions NOTIFY useFractionsChanged FINAL)

    Q_PROPERTY(Progress progress READ progress NOTIFY progressChanged FINAL)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged FINAL)
    Q_PROPERTY(QString resultEquation READ resultEquation NOTIFY resultChanged FINAL)
    Q_PROPERTY(SidebarResult resultMatrices READ resultMatrices NOTIFY resultChanged FINAL)
    Q_PROPERTY(PlotTypes::PlotType resolvedFitType READ resolvedFitType NOTIFY resultChanged FINAL)

public:
    enum Progress { NOTFIRED, PROCESSING, ERROR, CANCELED, READY };

    Q_ENUM(Progress)

    explicit FitController(QObject *parent = nullptr);

    ~FitController() override;

    [[nodiscard]] PointData *source() const;

    void setSource(PointData *source);

    [[nodiscard]] PlotTypes::PlotType plotType() const;

    void setPlotType(PlotTypes::PlotType plotType);

    [[nodiscard]] bool useFractions() const;

    void setUseFractions(bool useFractions);

    [[nodiscard]] Progress progress() const;

    [[nodiscard]] QString error() const;

    [[nodiscard]] QString resultEquation() const;

    [[nodiscard]] SidebarResult resultMatrices() const;

    [[nodiscard]] PlotTypes::PlotType resolvedFitType() const;

    [[nodiscard]] double betaA() const { return _bA; }
    [[nodiscard]] double betaB() const { return _bB; }
    [[nodiscard]] double betaC() const { return _bC; }

public slots:
    [[nodiscard]] double evaluateAt(double x) const;

    [[nodiscard]] double residualFor(const QPointF &point) const;
    [[nodiscard]] double residualFor(int idx) const;

signals:
    void sourceChanged();

    void plotTypeChanged();

    void useFractionsChanged();

    void progressChanged();

    void errorChanged();

    void resultChanged();

    void requestRun(const QList<QPointF> &points, PlotTypes::PlotType plotType, bool useFractions);

private slots:
    void onInputChanged();

    void onWorkerFinished(const Result &result);

    void onWorkerError(const QString &err);

    void onWorkerCanceled();

    void fire();

private:
    void scheduleRun();

    void setProgress(Progress p);

    PointData *_source{};
    PlotTypes::PlotType _plotType{};
    bool _useFractions{};

    workerprocessing *_worker{};
    QThread *_workerThread{};
    QTimer *_debounce{};
    bool _pendingRestart{};

    Progress _progress{NOTFIRED};
    QString _error{};
    QString _resultEquation{};
    SidebarResult _sdRes{};
    double _bA{}, _bB{}, _bC{};
    PlotTypes::PlotType _resolvedFitType{};
};

#endif
