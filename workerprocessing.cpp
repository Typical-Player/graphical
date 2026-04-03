#include "workerprocessing.h"
#include "pointprocessing.h"

workerprocessing::workerprocessing(QObject* parent) : QObject(parent) {}

void workerprocessing::requestCancellation() {
	_canceled.storeRelease(1);
}

void workerprocessing::run(const QList<QPointF>& points, const pointprocessing::PlotType plotType) {
	_canceled.storeRelease(0);

	if (points.isEmpty()) {
		emit error("No points provided");
		return;
	}

	Result result{};
	bool ok = true;

	switch (plotType) {
	case pointprocessing::LINEAL: fitLinear(points, result, ok);
		break;
	case pointprocessing::CUADRATIC: fitQuadratic(points, result, ok);
		break;
	case pointprocessing::EXPONENTIAL: fitExponential(points, result, ok);
		break;
	}

	if (isCanceled()) {
		emit canceled();
		return;
	}

	if (!ok) {
		return;
	}

	emit finished(result);
}

bool workerprocessing::isCanceled() const {
	return _canceled.loadAcquire() != 0;
}

void workerprocessing::fitLinear(const QList<QPointF>& points, Result& result, bool& ok) {
	const auto n = points.size();
	if (n < 2) {
		emit error("Need at least 2 points for linear fit");
		ok = false;
		return;
	}

	g_matrix<double> X(n);
	QList<double> y(n);

	for (int i = 0; i < n; i++) {
		if (isCanceled()) {
			emit canceled();
			return;
		}
		X._data[i] = {1.0, points[i].x()};
		y[i] = points[i].y();
	}

	const auto beta = solve(X, y);
	compute(points, result, beta, pointprocessing::LINEAL);
}

void workerprocessing::fitQuadratic(const QList<QPointF>& points, Result& result, bool& ok) {
	const auto n = points.size();
	if (n < 3) {
		emit error("Need at least 3 points for quadratic fit");
		ok = false;
		return;
	}

	g_matrix<double> X(n);
	QList<double> y(n);

	for (int i = 0; i < n; i++) {
		if (isCanceled()) {
			emit canceled();
			return;
		}
		double x = points[i].x();
		X._data[i] = {1.0, x, x * x};
		y[i] = points[i].y();
	}

	const auto beta = solve(X, y);
	compute(points, result, beta, pointprocessing::CUADRATIC);
}

void workerprocessing::fitExponential(const QList<QPointF>& points, Result& result, bool& ok) {
	const auto n = points.size();
	if (n < 2) {
		emit error("Need at least 2 points for exponential fit");
		ok = false;
		return;
	}

	g_matrix<double> X(n);
	QList<double> y(n);

	for (int i = 0; i < n; i++) {
		if (isCanceled()) {
			emit canceled();
			return;
		}
		const double yi = points[i].y();
		if (yi <= 0.0) {
			emit error(QString("Exponential fit requires Y > 0, got Y=%1 at index %2")
			           .arg(yi).arg(i));
			ok = false;
			return;
		}
		X._data[i] = {1.0, points[i].x()};
		y[i] = std::log(yi);
	}

	auto beta = solve(X, y);

	const QList recovered = {std::exp(beta[0]), beta[1]};
	compute(points, result, recovered, pointprocessing::EXPONENTIAL);
}

void workerprocessing::compute(const QList<QPointF>& points, Result& result, const QList<double>& beta,
                               const pointprocessing::PlotType plotType) {
	const auto n = points.size();
	double sumY = 0;
	for (const QPointF& p : points) sumY += p.y();
	const double meanY = sumY / static_cast<double>(n);

	double sse = 0, sst = 0;

	for (const QPointF& p : points) {
		double yHat = 0;
		const double x = p.x();
		switch (plotType) {
		case 0: yHat = beta[0] + beta[1] * x;
			break;
		case 1: yHat = beta[0] + beta[1] * x + beta[2] * x * x;
			break;
		case 2: yHat = beta[0] * std::exp(beta[1] * x);
			break;
		}
		sse += (p.y() - yHat) * (p.y() - yHat);
		sst += (p.y() - meanY) * (p.y() - meanY);
	}

	const double r2 = sst > 1e-12 ? 1.0 - sse / sst : 1.0;

	switch (plotType) {
	case 0:
		result.eqRes = QString("y = %1x + %2  (R²=%3)")
		               .arg(beta[1], 0, 'f', 4)
		               .arg(beta[0], 0, 'f', 4)
		               .arg(r2, 0, 'f', 4);
		break;
	case 1:
		result.eqRes = QString("y = %1x² + %2x + %3  (R²=%4)")
		               .arg(beta[2], 0, 'f', 4)
		               .arg(beta[1], 0, 'f', 4)
		               .arg(beta[0], 0, 'f', 4)
		               .arg(r2, 0, 'f', 4);
		break;
	case 2:
		result.eqRes = QString("y = %1·e^(%2x)  (R²=%3)")
		               .arg(beta[0], 0, 'f', 4)
		               .arg(beta[1], 0, 'f', 4)
		               .arg(r2, 0, 'f', 4);
		break;
	}
}

QList<double> workerprocessing::solve(const g_matrix<double>& X, const QList<double>& Y) {
	auto Xt = X.transpose();
	const auto XtX = Xt * X;
	const auto XtY = Xt * Y;

	return XtX.inverse() * XtY;
}
