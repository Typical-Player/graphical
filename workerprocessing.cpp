#include "workerprocessing.h"
#include <QDebug>
#include <QThread>

workerprocessing::workerprocessing(QObject* parent) : QObject(parent) {}

void workerprocessing::requestCancellation() {
	_canceled.storeRelease(1);
}

void workerprocessing::run(const QList<QPointF>& points, int plotType) {
	_canceled.storeRelease(0);

	if (points.isEmpty()) {
		emit error("No points provided");
		return;
	}

	Result result{};

	constexpr int steps = 10;
	for (int i = 0; i < steps; i++) {
		if (isCanceled()) {
			emit canceled();
			return;
		}

		QThread::msleep(200);

		qDebug() << "Worker step" << (i + 1) << "/" << steps;
	}

	if (isCanceled()) {
		emit canceled();
		return;
	}

	result.eqRes = QString("y = 3.14x + 2.71  (plotType=%1, n=%2)").arg(plotType).arg(points.size());
	result.error = 0;

	emit finished(result);
}

bool workerprocessing::isCanceled() const {
	return _canceled.loadAcquire() != 0;
}
