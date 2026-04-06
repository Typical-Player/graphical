#ifndef GRAPHICAL_RESULT_H
#define GRAPHICAL_RESULT_H

#include <QObject>
#include <qqmlintegration.h>
#include <QList>

struct SidebarResult {
	Q_GADGET
	QML_VALUE_TYPE(sidebarResult)
	Q_PROPERTY(qint64 colResolution MEMBER colResolution FINAL)
	Q_PROPERTY(qint64 rowResolution MEMBER rowResolution FINAL)
	Q_PROPERTY(QList<QList<double>> aMat MEMBER aMat FINAL)
	Q_PROPERTY(QList<QList<double>> bMat MEMBER bMat FINAL)
	Q_PROPERTY(QList<QList<double>> atMat MEMBER atMat FINAL)
	Q_PROPERTY(QList<QList<double>> ataMat MEMBER ataMat FINAL)
	Q_PROPERTY(QList<QList<double>> atainvMat MEMBER atainvMat FINAL)
	Q_PROPERTY(QList<QList<double>> atbMat MEMBER atbMat FINAL)
	Q_PROPERTY(QList<QList<double>> resMat MEMBER resMat FINAL)

public:
	qint64 colResolution{4};
	qint64 rowResolution{4};

	QList<QList<double>> aMat{};
	QList<QList<double>> bMat{};
	QList<QList<double>> atMat{};
	QList<QList<double>> ataMat{};
	QList<QList<double>> atainvMat{};
	QList<QList<double>> atbMat{};

	QList<QList<double>> resMat{};

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
};

#endif //GRAPHICAL_RESULT_H
