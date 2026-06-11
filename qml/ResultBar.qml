import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtQuick.Particles
import QtQuick.Effects
import graphical

Rectangle {
    id: root
    required property FitController fit
    required property FitController selectionFit

    clip: true

    function statusColor(): string {
        switch (fit.progress) {
            case FitController.PROCESSING:
                return "#1a3a5c";
            case FitController.READY:
                return "#1a3d1a";
            case FitController.ERROR:
                return "#4a1a1a";
            case FitController.CANCELED:
                return "#3a3a1a";
            default:
                return "#2a2a2a";
        }
    }

    color: root.statusColor()
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    function statusText(): string {
        switch (root.fit.progress) {
            case FitController.NOTFIRED:
                return "Ready";
            case FitController.PROCESSING:
                return "Processing...";
            case FitController.CANCELED:
                return "Canceled";
            case FitController.ERROR:
                return "Error | message: " + root.fit.error;
            case FitController.READY:
                return "Best fit: " + root.fit.resultEquation;
            default:
                return "";
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMultiplier: 2.5
        }

        ParticleSystem {
            id: particleSystem
            anchors.fill: parent
            running: true
        }

        ImageParticle {
            system: particleSystem
            source: "qrc:///particleresources/fuzzydot.png"
            alpha: 0.05
            alphaVariation: 0.1
            color: Qt.lighter(root.statusColor())
            entryEffect: ImageParticle.Fade
        }

        Emitter {
            id: particleEmitter
            system: particleSystem
            anchors.fill: parent

            readonly property bool processing: root.fit.progress === FitController.PROCESSING

            emitRate: processing ? 50 : 5
            lifeSpan: processing ? 1800 : 4000
            lifeSpanVariation: processing ? 600 : 1500

            velocity: AngleDirection {
                angle: 0
                angleVariation: 360
                magnitude: particleEmitter.processing ? 100 : 6
                magnitudeVariation: particleEmitter.processing ? 100 : 4
            }

            size: processing ? 200 : 100
            sizeVariation: processing ? 50 : 10
            endSize: 0
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Qt.darker(root.statusColor())
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MarqueeLabel {
                    id: statusLabel
                    Layout.fillWidth: true
                    text: root.statusText()
                    color: root.fit.progress === FitController.READY ? "#80ff80" : "white"
                    font.family: "Helvetica"
                    font.pointSize: 24
                    font.bold: true

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation {
                                target: statusLabel; property: "opacity";
                                to: 0; duration: 120
                            }
                            PropertyAction {
                                target: statusLabel; property: "text"
                            }
                            NumberAnimation {
                                target: statusLabel; property: "opacity";
                                to: 1; duration: 120
                            }
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 240; easing.type: Easing.InOutQuad
                        }
                    }
                }

                RowLayout {
                    visible: root.selectionFit.progress === FitController.PROCESSING
                        || root.selectionFit.progress === FitController.READY
                    spacing: 6

                    Rectangle {
                        implicitWidth: 3
                        implicitHeight: 20
                        color: Qt.rgba(0.85, 0.45, 0.10, 1.0)
                    }

                    MarqueeLabel {
                        id: selectionEquationLabel
                        Layout.fillWidth: true
                        text: "Selection: " + root.selectionFit.resultEquation
                        color: Qt.rgba(1.0, 0.75, 0.45, 1.0)
                        font.family: "Helvetica"
                        font.pointSize: 11
                        font.bold: true

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: selectionEquationLabel; property: "opacity";
                                    to: 0; duration: 120
                                }
                                PropertyAction {
                                    target: selectionEquationLabel; property: "text"
                                }
                                NumberAnimation {
                                    target: selectionEquationLabel; property: "opacity";
                                    to: 1; duration: 120
                                }
                            }
                        }
                    }

                    Spinner {
                        running: root.selectionFit.progress === FitController.PROCESSING
                        visible: running
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Spinner {
                running: root.fit.progress === FitController.PROCESSING
                visible: running
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }
        }
    }
}
