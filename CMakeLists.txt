cmake_minimum_required(VERSION 3.16)

project(graphical VERSION 0.9 LANGUAGES CXX)

set(APP_NAME "${PROJECT_NAME}")
set(APP_VERSION "${PROJECT_VERSION}")

configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/AppConfig.h.in
        ${CMAKE_CURRENT_BINARY_DIR}/AppConfig.h
        @ONLY
)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_QML_GENERATE_QMLLS_INI ON)

set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Graphs Svg)

qt_standard_project_setup(REQUIRES 6.10)
qt_policy(SET QTP0004 NEW)

qt_add_executable(appgraphical
        assets/assets.qrc
        main.cpp
        workerprocessing.cpp
        workerprocessing.h
        result.h
        matrix.h
        third_party/lttb.hpp
        pointsmodel.cpp
        pointsmodel.h
)

qt_add_qml_module(appgraphical
        URI graphical
        QML_FILES
        qml/Main.qml
        qml/Graph.qml
        qml/ResultBar.qml
        qml/TopToolbar.qml
        qml/AboutDialog.qml
        qml/GuideOverlay.qml
        qml/BrushGuide.qml
        qml/PlotPoint.qml
        qml/GraphInteractions.qml
        qml/GraphicalDialog.qml
        qml/ProcessingSidebarWrapper.qml
        qml/ProcessingSidebar.qml
        qml/Matrix.qml
        qml/Spinner.qml
        qml/RightSidebar.qml
        qml/PointInputDelegate.qml
        SOURCES
        pointprocessing.cpp
        pointprocessing.h
        graphutils.cpp
        graphutils.h
        SOURCES plottypes.h
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appgraphical PROPERTIES
        #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appgraphical
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE TRUE
        WIN32_EXECUTABLE TRUE
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
)

target_include_directories(appgraphical PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(appgraphical
        PRIVATE Qt6::Quick
        PRIVATE Qt6::Graphs
        PRIVATE Qt6::Svg
)

install(TARGETS appgraphical
        BUNDLE DESTINATION .
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
