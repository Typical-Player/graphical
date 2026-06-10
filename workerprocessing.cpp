#include "workerprocessing.h"
#include "pointprocessing.h"
#include <QMutexLocker>

workerprocessing::workerprocessing(QObject* parent) : QObject(parent) {}

void workerprocessing::requestCancellation() {
	_canceled.storeRelease(1);
}

void workerprocessing::run(const QList<QPointF>& points, const PlotTypes::PlotType plotType,
                           const bool useFractions) {
	_canceled.storeRelease(0);

	if (points.isEmpty()) {
		emit error("No points provided");
		return;
	}

	Result result{};
	bool ok = true;

	switch (plotType) {
    case PlotTypes::LINEAL: fitLinear(points, result, ok, useFractions);
		break;
    case PlotTypes::CUADRATIC: fitQuadratic(points, result, ok, useFractions);
		break;
    case PlotTypes::EXPONENTIAL: fitExponential(points, result, ok, useFractions);
		break;
    case PlotTypes::AUTOMATIC_FIT: fitAutomatic(points, result, ok, useFractions);
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

	try {
		const auto beta = solve(X, y);
		fillMatrices(result, X, y, beta, useFractions);
		compute(points, result, beta, PlotTypes::LINEAL, useFractions);
	} catch (const std::invalid_argument& e) {
		emit error(QString("Linear fit failed: %1").arg(e.what()));
		ok = false;
	}
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

	try {
		const auto beta = solve(X, y);
		fillMatrices(result, X, y, beta, useFractions);
		compute(points, result, beta, PlotTypes::CUADRATIC, useFractions);
	} catch (const std::invalid_argument& e) {
		emit error(QString("Quadratic fit failed: %1").arg(e.what()));
		ok = false;
	}
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

	try {
		auto beta = solve(X, y);
		const QList recovered = {std::exp(beta[0]), beta[1]};
		fillMatrices(result, X, y, recovered, useFractions);
		compute(points, result, recovered, PlotTypes::EXPONENTIAL, useFractions);
	} catch (const std::invalid_argument& e) {
		emit error(QString("Exponential fit failed: %1").arg(e.what()));
		ok = false;
	}
}

void workerprocessing::fitAutomatic(const QList<QPointF> &points, Result &result, bool &ok, bool useFractions)
{
    struct Candidate {
        Result result;
        double sse = std::numeric_limits<double>::infinity();
        PlotTypes::PlotType type{};
        bool valid = false;
    };

    auto tryFit = [&](auto fitFn, PlotTypes::PlotType type) -> Candidate {
        Result r{};
        bool fitOk = true;
    	try {
    		(this->*fitFn)(points, r, fitOk, useFractions);
    	} catch (const std::invalid_argument&) {
    		fitOk = false;
    	}
        if (!fitOk || isCanceled()) return {};

        double sse = 0;
        for (const QPointF& p : points) {
            double yHat = 0;
            const double x = p.x();
            switch (type) {
            case PlotTypes::LINEAL:      yHat = r.betaA + r.betaB * x; break;
            case PlotTypes::CUADRATIC:   yHat = r.betaA + r.betaB * x + r.betaC * x * x; break;
            case PlotTypes::EXPONENTIAL: yHat = r.betaA * std::exp(r.betaB * x); break;
            default: break;
            }
            if (!std::isfinite(yHat)) { sse = std::numeric_limits<double>::infinity(); break; }
            const double diff = p.y() - yHat;
            sse += diff * diff;
        }

        const int paramCount = (type == PlotTypes::CUADRATIC) ? 3 : 2;
        const int n = points.size();
        const double adjustedSse = sse * (1.0 + static_cast<double>(paramCount) / n);

        return { r, adjustedSse, type, true };
    };

    std::array candidates = {
        tryFit(&workerprocessing::fitLinear,      PlotTypes::LINEAL),
        tryFit(&workerprocessing::fitQuadratic,   PlotTypes::CUADRATIC),
        tryFit(&workerprocessing::fitExponential, PlotTypes::EXPONENTIAL),
    };

    if (isCanceled()) { emit canceled(); return; }

    const auto best = std::min_element(candidates.begin(), candidates.end(),
                                        [](const Candidate& a, const Candidate& b) {
                                            if (!a.valid) return false;
                                            if (!b.valid) return true;
                                            return a.sse < b.sse;
                                        });

    if (best == candidates.end() || !best->valid) {
        emit error("Automatic fit: no valid model found");
        ok = false;
        return;
    }

    const QString modelName = [&] {
        switch (best->type) {
        case PlotTypes::LINEAL:      return QStringLiteral("Linear");
        case PlotTypes::CUADRATIC:   return QStringLiteral("Quadratic");
        case PlotTypes::EXPONENTIAL: return QStringLiteral("Exponential");
        default:                           return QStringLiteral("Unknown");
        }
    }();

    result = best->result;
    result.eqRes = QStringLiteral("[Auto->%1] ").arg(modelName) + result.eqRes;
    result.selectedPlotType = best->type;
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
                               const PlotTypes::PlotType plotType, const bool useFractions) {
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
        case PlotTypes::AUTOMATIC_FIT:
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
    case PlotTypes::AUTOMATIC_FIT:
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
                                    const QList<double>& beta, const bool useFractions) {
	const QString sentinel = "dots";
	const qint64 rRes = res.sr.rowResolution;
	const qint64 cRes = res.sr.colResolution;

	auto at_d = X.transpose();
	const auto ata_d = at_d * X;
	const auto atainv_d = ata_d.inverse();
	const auto atb_temp = at_d * Y;

	res.sr.aMat = sliceMatrix(matToStrings(X, useFractions), rRes, cRes, sentinel);
	res.sr.bMat = sliceMatrix(vecToColMat(Y, useFractions), rRes, 1, sentinel);
	res.sr.atMat = sliceMatrix(matToStrings(at_d, useFractions), rRes, cRes, sentinel);
	res.sr.ataMat = sliceMatrix(matToStrings(ata_d, useFractions), rRes, cRes, sentinel);
	res.sr.atainvMat = sliceMatrix(matToStrings(atainv_d, useFractions), rRes, cRes, sentinel);
	res.sr.atbMat = sliceMatrix(vecToColMat(atb_temp, useFractions), rRes, 1, sentinel);
	res.sr.resMat = sliceMatrix(vecToColMat(beta, useFractions), rRes, 1, sentinel);
}

QList<QString> workerprocessing::sliceRow(const QList<QString>& row, const qint64 resolution,
                                          const QString& sentinel) {
	const qint64 total = row.size();
	if (total <= resolution) return row;

	const qint64 half = resolution / 2;
	QList<QString> result;
	result.reserve(resolution + 1);

	for (qint64 i = 0; i < half; i++) result.push_back(row[i]);

	result.push_back(sentinel);

	for (qint64 i = total - half; i < total; i++) result.push_back(row[i]);

	return result;
}

QList<QList<QString>> workerprocessing::sliceMatrix(const QList<QList<QString>>& mat,
                                                    const qint64 rowRes, const qint64 colRes,
                                                    const QString& sentinel) {
	const qint64 totalRows = mat.size();
	QList<QList<QString>> result;

	auto processRow = [&](const qint64 rowIdx) {
		result.push_back(sliceRow(mat[rowIdx], colRes, sentinel));
	};

	if (totalRows <= rowRes) {
		for (qint64 i = 0; i < totalRows; i++) processRow(i);
		return result;
	}

	const qint64 half = rowRes / 2;

	for (qint64 i = 0; i < half; i++) processRow(i);

	QList<QString> sentinelRow;
	const qint64 slicedCols = std::min(totalRows > 0 ? mat[0].size() : 0LL,
	                                   colRes) + (mat[0].size() > colRes ? 1 : 0);

	for (qint64 i = 0; i < slicedCols; i++) sentinelRow.push_back(sentinel);

	result.push_back(sentinelRow);

	for (qint64 i = totalRows - half; i < totalRows; i++) processRow(i);

	return result;
}

QString workerprocessing::prettyPrint(const double number, const bool useFractions) {
	if (!useFractions) return QString("%1").arg(number, 0, 'f', 4);
	return calculateEuclideanFraction(number);
}

QList<QList<QString>> workerprocessing::vecToColMat(const QList<double>& input, const bool useFractions) {
	QList<QList<QString>> out;
	for (const auto& d : std::as_const(input)) {
		out.push_back({prettyPrint(std::round(d * 1000.0) / 1000.0, useFractions)});
	}
	return out;
}

QList<QList<QString>> workerprocessing::matToStrings(const g_matrix<double>& input, const bool useFractions) {
	QList<QList<QString>> out;
	for (const auto& row : std::as_const(input._data)) {
		QList<QString> rowStr;
		std::transform(row.begin(), row.end(), std::back_inserter(rowStr),
		               [&](const double x) {
			               return prettyPrint(std::round(x * 1000.0) / 1000.0, useFractions);
		               });
		out.push_back(rowStr);
	}
	return out;
}

#include "moc_workerprocessing.cpp"
