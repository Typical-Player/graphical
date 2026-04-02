#ifndef GRAPHICAL_WORKERPROCESSING_H
#define GRAPHICAL_WORKERPROCESSING_H

#include <QObject>
#include <qqmlintegration.h>
#include <QPointF>

#include "result.h"

class workerprocessing : public QObject {
	Q_OBJECT

public:
	explicit workerprocessing(QObject* parent = nullptr);
	void requestCancellation();

public slots:
	void run(const QList<QPointF>& points, int plotType);

signals:
	void finished(const Result& result);
	void canceled();
	void error(QString err);

private:
	[[nodiscard]] bool isCanceled() const;

	QAtomicInt _canceled{0};
};


#endif //GRAPHICAL_WORKERPROCESSING_H
