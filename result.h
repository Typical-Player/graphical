#ifndef GRAPHICAL_RESULT_H
#define GRAPHICAL_RESULT_H

#include <QObject>
#include <qqmlintegration.h>

struct Result {
	Q_GADGET
	QML_VALUE_TYPE(result)

public:
	QString eqRes{};
	double betaA{};
	double betaB{};
	double betaC{};
};

#endif //GRAPHICAL_RESULT_H
