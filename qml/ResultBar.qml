import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtQuick.Particles
import QtQuick.Effects
import graphical

Rectangle {
	id: root
	required property PointProcessing backend

	clip: true

	function statusColor(): string {
		switch (backend.progress) {
			case PointProcessing.PROCESSING:
				return "#1a3a5c";
			case PointProcessing.READY:
				return "#1a3d1a";
			case PointProcessing.ERROR:
				return "#4a1a1a";
			case PointProcessing.CANCELED:
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
		switch (root.backend.progress) {
			case PointProcessing.NOTFIRED:
				return "Ready";
			case PointProcessing.PROCESSING:
				return "Processing...";
			case PointProcessing.CANCELED:
				return "Canceled";
			case PointProcessing.ERROR:
				return "Error | code: " + root.backend.error;
			case PointProcessing.READY:
				return "Best fit: " + root.backend.resultEquation;
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

			readonly property bool processing: root.backend.progress === PointProcessing.PROCESSING

			emitRate: processing ? 10 : 5
			lifeSpan: processing ? 1800 : 4000
			lifeSpanVariation: processing ? 600 : 1500

			velocity: AngleDirection {
				angle: 0
				angleVariation: 360
				magnitude: particleEmitter.processing ? 55 : 6
				magnitudeVariation: particleEmitter.processing ? 30 : 4
			}

			size: 100
			sizeVariation: 10
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

                Label {
                    id: statusLabel
                    text: root.statusText()
                    color: root.backend.progress === PointProcessing.READY ? "#80ff80" : "white"
                    font.family: "Helvetica"
                    font.pointSize: 24
                    font.bold: true

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation {
                                target: statusLabel
                                property: "opacity"
                                to: 0
                                duration: 120
                            }
                            PropertyAction {
                                target: statusLabel
                                property: "text"
                            }
                            NumberAnimation {
                                target: statusLabel
                                property: "opacity"
                                to: 1
                                duration: 120
                            }
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 240
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                RowLayout {
                    visible: root.backend.hasSelectionResult ||
                        root.backend.selectionProgress === PointProcessing.PROCESSING
                    spacing: 6

                    Rectangle {
                        width: 3
                        height: selectionEquationLabel.implicitHeight
                        radius: 1
                        color: Qt.rgba(0.85, 0.45, 0.10, 1.0)
                        visible: root.backend.hasSelectionResult
                    }

                    Label {
                        id: selectionEquationLabel
                        visible: root.backend.hasSelectionResult
                        text: "Selection: " + root.backend.selectionResultEquation
                        color: Qt.rgba(1.0, 0.75, 0.45, 1.0)
                        font.family: "Helvetica"
                        font.pointSize: 11
                        font.bold: true

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: selectionEquationLabel
                                    property: "opacity"
                                    to: 0
                                    duration: 120
                                }
                                PropertyAction {
                                    target: selectionEquationLabel
                                    property: "text"
                                }
                                NumberAnimation {
                                    target: selectionEquationLabel
                                    property: "opacity"
                                    to: 1
                                    duration: 120
                                }
                            }
                        }
                    }

                    Spinner {
                        running: root.backend.selectionProgress === PointProcessing.PROCESSING
                        visible: running
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Spinner {
                running: root.backend.progress === PointProcessing.PROCESSING
                visible: running
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }
        }
    }
}
