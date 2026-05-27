#ifndef PLOTTYPES_H
#define PLOTTYPES_H

#include <QObject>

namespace PlotTypes {
Q_NAMESPACE

enum PlotType {
    LINEAL,
    CUADRATIC,
    EXPONENTIAL,
    AUTOMATIC_FIT,
};

Q_ENUM_NS(PlotType)
}

#endif // PLOTTYPES_H
