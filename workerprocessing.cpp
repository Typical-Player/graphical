#include "workerprocessing.h"
#include "pointprocessing.h"

workerprocessing::workerprocessing(QObject* parent) : QObject(parent) {}

void workerprocessing::requestCancellation() {
	_canceled.storeRelease(1);
}

void workerprocessing::run(const QList<QPointF>& points, const pointprocessing::PlotType plotType,
                           const bool useFractions) {
	_canceled.storeRelease(0);

	if (points.isEmpty()) {
		emit error("No points provided");
		return;
	}

	Result result{};
	bool ok = true;

	switch (plotType) {
	case pointprocessing::LINEAL: fitLinear(points, result, ok, useFractions);
		break;
	case pointprocessing::CUADRATIC: fitQuadratic(points, result, ok, useFractions);
		break;
	case pointprocessing::EXPONENTIAL: fitExponential(points, result, ok, useFractions);
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

void workerprocessing::fitLinear(const QList<QPointF>& points, Result& result, bool& ok, const bool useFractions) {
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

	fillMatrices(result, X, y, beta);
	compute(points, result, beta, pointprocessing::LINEAL, useFractions);
}

void workerprocessing::fitQuadratic(const QList<QPointF>& points, Result& result, bool& ok, const bool useFractions) {
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

	fillMatrices(result, X, y, beta);
	compute(points, result, beta, pointprocessing::CUADRATIC, useFractions);
}

void workerprocessing::fitExponential(const QList<QPointF>& points, Result& result, bool& ok, const bool useFractions) {
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

	fillMatrices(result, X, y, recovered);
	compute(points, result, recovered, pointprocessing::EXPONENTIAL, useFractions);
}

//? https://stackoverflow.com/questions/26643695/converting-a-floating-point-decimal-value-to-a-fraction
QString workerprocessing::calculateEuclideanFraction(const double input) {
	const double integer = std::floor(input);
	const double frac = input - integer;

	constexpr long precision = 1000000000;

	const long long gcdVal = gcd(static_cast<long>(round(frac * precision)), precision);
	const long long denominator = precision / gcdVal;
	const long long numerator = static_cast<long>(round(frac * precision)) / gcdVal;

	return QString::number(static_cast<long long>(integer) * denominator + numerator) + "/" +
		QString::number(denominator);
}

long workerprocessing::gcd(const long a, const long b) {
	if (a == 0) return b;
	if (b == 0) return a;

	if (a < b) return gcd(a, b % a);

	return gcd(b, a % b);
}

void workerprocessing::compute(const QList<QPointF>& points, Result& result, const QList<double>& beta,
                               const pointprocessing::PlotType plotType, const bool useFractions) {
	const auto n = points.size();
	double sumY = 0;

	for (const QPointF& p : points) {
		sumY += p.y();
	}

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
		               .arg(prettyPrint(std::round(beta[1] * 1000.0) / 1000.0, useFractions))
		               .arg(prettyPrint(std::round(beta[0] * 1000.0) / 1000.0, useFractions))
		               .arg(r2, 0, 'f', 4);
		result.betaA = beta[0];
		result.betaB = beta[1];
		break;
	case 1:
		result.eqRes = QString("y = %1x² + %2x + %3  (R²=%4)")
		               .arg(prettyPrint(std::round(beta[2] * 1000.0) / 1000.0, useFractions))
		               .arg(prettyPrint(std::round(beta[1] * 1000.0) / 1000.0, useFractions))
		               .arg(prettyPrint(std::round(beta[0] * 1000.0) / 1000.0, useFractions))
		               .arg(r2, 0, 'f', 4);
		result.betaA = beta[0];
		result.betaB = beta[1];
		result.betaC = beta[2];
		break;
	case 2:
		result.eqRes = QString("y = %1·e^(%2x)  (R²=%3)")
		               .arg(prettyPrint(std::round(beta[0] * 1000.0) / 1000.0, useFractions))
		               .arg(prettyPrint(std::round(beta[1] * 1000.0) / 1000.0, useFractions))
		               .arg(r2, 0, 'f', 4);
		result.betaA = beta[0];
		result.betaB = beta[1];
		break;
	}
}

QList<double> workerprocessing::solve(const g_matrix<double>& X, const QList<double>& Y) {
	auto Xt = X.transpose();
	const auto XtX = Xt * X;
	const auto XtY = Xt * Y;

	return XtX.inverse() * XtY;
}

void workerprocessing::fillMatrices(Result& res, const g_matrix<double>& X, const QList<double>& Y,
                                    const QList<double>& beta) {
	res.sr.aMat = X._data;
	res.sr.bMat = QList<QList<double>>();
	res.sr.bMat.push_back(Y);

	const auto ata = X.transpose() * X;
	const auto atainv = ata.inverse();

	res.sr.atMat = X.transpose()._data;
	res.sr.ataMat = ata._data;
	res.sr.atainvMat = atainv._data;
	res.sr.atbMat = QList<QList<double>>();
	res.sr.atbMat.push_back(X.transpose() * Y);

	res.sr.resMat = QList<QList<double>>();
	res.sr.resMat.push_back(beta);
}

QString workerprocessing::prettyPrint(const double number, const bool useFractions) {
	if (!useFractions) return QString("%1").arg(number, 0, 'f', 4);
	return calculateEuclideanFraction(number);
}
