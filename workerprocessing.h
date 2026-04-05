#ifndef GRAPHICAL_WORKERPROCESSING_H
#define GRAPHICAL_WORKERPROCESSING_H

#include "matrix.h"
#include "result.h"
#include "pointprocessing.h"

class workerprocessing : public QObject {
	Q_OBJECT

public:
	explicit workerprocessing(QObject* parent = nullptr);
	void requestCancellation();

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

	[[nodiscard]] static QString calculateEuclideanFraction(double input);
	[[nodiscard]] static long gcd(long a, long b);

	static void compute(const QList<QPointF>& points, Result& result, const QList<double>& beta,
	                    pointprocessing::PlotType plotType, bool useFractions);
	[[nodiscard]] static QList<double> solve(const g_matrix<double>& X, const QList<double>& Y);

	[[nodiscard]] static QString prettyPrint(double number, bool useFractions);

	QAtomicInt _canceled{0};
};


#endif //GRAPHICAL_WORKERPROCESSING_H
