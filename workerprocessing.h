#ifndef GRAPHICAL_WORKERPROCESSING_H
#define GRAPHICAL_WORKERPROCESSING_H

#include "matrix.h"
#include "result.h"
#include "pointprocessing.h"
#include <QMutex>

class workerprocessing : public QObject {
	Q_OBJECT

public:
	explicit workerprocessing(QObject* parent = nullptr);

	void requestCancellation();
	[[nodiscard]] QString calculateEuclideanFraction(double input);

public slots:
	void run(const QList<QPointF>& points, pointprocessing::PlotType plotType, bool useFractions);

signals:
	void finished(const Result& result);
	void canceled();
	void error(QString err);

private:
	[[nodiscard]] bool isCanceled() const;

	void fitLinear(const QList<QPointF>& points, Result& result, bool& ok, bool useFractions);
	void fitQuadratic(const QList<QPointF>& points, Result& result, bool& ok, bool useFractions);
	void fitExponential(const QList<QPointF>& points, Result& result, bool& ok, bool useFractions);

	[[nodiscard]] static long gcd(long a, long b);

	void compute(const QList<QPointF>& points, Result& result, const QList<double>& beta,
	             pointprocessing::PlotType plotType, bool useFractions);
	[[nodiscard]] static QList<double> solve(const g_matrix<double>& X, const QList<double>& Y);

	static void fillMatrices(Result& res, const g_matrix<double>& X, const QList<double>& Y, const QList<double>& beta);

	[[nodiscard]] QString prettyPrint(double number, bool useFractions);

	QMutex _euclideanMutex{};
	QAtomicInt _canceled{0};
};


#endif //GRAPHICAL_WORKERPROCESSING_H
