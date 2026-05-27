#ifndef GRAPHICAL_RESULT_H
#define GRAPHICAL_RESULT_H

#include <QObject>
#include <qqmlintegration.h>
#include <QList>
#include "plottypes.h"

struct SidebarResult {
	Q_GADGET
	QML_VALUE_TYPE(sidebarResult)
	Q_PROPERTY(qint64 colResolution MEMBER colResolution FINAL)
	Q_PROPERTY(qint64 rowResolution MEMBER rowResolution FINAL)
	Q_PROPERTY(QList<QList<QString>> aMat MEMBER aMat FINAL)
	Q_PROPERTY(QList<QList<QString>> bMat MEMBER bMat FINAL)
	Q_PROPERTY(QList<QList<QString>> atMat MEMBER atMat FINAL)
	Q_PROPERTY(QList<QList<QString>> ataMat MEMBER ataMat FINAL)
	Q_PROPERTY(QList<QList<QString>> atainvMat MEMBER atainvMat FINAL)
	Q_PROPERTY(QList<QList<QString>> atbMat MEMBER atbMat FINAL)
	Q_PROPERTY(QList<QList<QString>> resMat MEMBER resMat FINAL)

public:
	qint64 colResolution{4};
	qint64 rowResolution{4};

	QList<QList<QString>> aMat{};
	QList<QList<QString>> bMat{};
	QList<QList<QString>> atMat{};
	QList<QList<QString>> ataMat{};
	QList<QList<QString>> atainvMat{};
	QList<QList<QString>> atbMat{};

	QList<QList<QString>> resMat{};

	bool operator==(const SidebarResult& other) const {
		return other.colResolution == colResolution &&
			other.rowResolution == rowResolution &&
			other.aMat == aMat &&
			other.bMat == bMat &&
			other.atMat == atMat &&
			other.ataMat == ataMat &&
			other.atainvMat == atainvMat &&
			other.atbMat == atbMat &&
			other.resMat == resMat;
	}
};

struct Result {
	Q_GADGET
	QML_VALUE_TYPE(result)
	Q_PROPERTY(QString eqRes MEMBER eqRes FINAL)
	Q_PROPERTY(double betaA MEMBER betaA FINAL)
	Q_PROPERTY(double betaB MEMBER betaB FINAL)
	Q_PROPERTY(double betaC MEMBER betaC FINAL)
	Q_PROPERTY(SidebarResult sr MEMBER sr FINAL)

public:
	QString eqRes{};
	double betaA{};
	double betaB{};
	double betaC{};
	SidebarResult sr{};
    PlotTypes::PlotType selectedPlotType = PlotTypes::LINEAL;
};

#endif //GRAPHICAL_RESULT_H
