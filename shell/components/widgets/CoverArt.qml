pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    readonly property alias shape: shape
    readonly property bool isHovered: hoverArea.containsMouse
    property int defaultShape: MaterialShape.Cookie12Sided
    property bool shrinkOnHover: false

    property bool hadPrevious
    property color fallbackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

    CustomMouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    // Slight glow to separate from bg
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 1
        shadowColor: Colours.palette.m3outline
        shadowOpacity: 0.3
    }

    Behavior on fallbackColour {
        CAnim {}
    }

    Item {
        id: visualContainer
        anchors.fill: parent
        scale: (root.shrinkOnHover && root.isHovered && AlbumArtEffects.enabled) ? 0.82 : 1.0

        Behavior on scale {
            Anim {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: shapeWrapper

            anchors.fill: parent
            layer.enabled: true
            opacity: root.fallbackColour.a

            MaterialShape {
                id: shape

                implicitSize: root.width
                shape: (root.isHovered && AlbumArtEffects.enabled) ? MaterialShape.Square : root.defaultShape
                color: Qt.alpha(root.fallbackColour, 1)

                property real baseAngle: 0
                property real currentRotation: 0

                rotation: currentRotation

                // Smooth continuous spin when playing and not hovered
                FrameAnimation {
                    running: Players.active?.isPlaying && !(root.isHovered && AlbumArtEffects.enabled)
                    onTriggered: {
                        shape.baseAngle = (shape.baseAngle - (frameTime * (360.0 / 23.5))) % 36000.0;
                        shape.currentRotation = shape.baseAngle;
                    }
                }

                // Smooth alignment to nearest upright 90-degree multiple on hover (max 45 deg delta)
                Connections {
                    target: root
                    function onIsHoveredChanged(): void {
                        if (!AlbumArtEffects.enabled) return;
                        if (root.isHovered) {
                            const curr = shape.currentRotation;
                            const norm = ((curr % 360) + 360) % 360;
                            const delta = (Math.round(norm / 90) * 90) - norm;
                            alignAnim.to = curr + delta;
                            alignAnim.restart();
                        } else {
                            alignAnim.stop();
                            shape.baseAngle = shape.currentRotation;
                        }
                    }
                }

                NumberAnimation on currentRotation {
                    id: alignAnim
                    running: false
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: image.status === Image.Error ? "broken_image" : "art_track"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size((parent.width * 0.35) || 1).build()
            opacity: image.status === Image.Null || image.status === Image.Error ? 1 : 0
            animate: true

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            anchors.centerIn: parent
            asynchronous: true
            active: opacity > 0
            opacity: image.status === Image.Loading ? 1 : 0

            sourceComponent: LoadingIndicator {
                implicitSize: root.width * 0.3
                color: Colours.palette.m3primaryContainer
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        FadeImage {
            id: image

            anchors.fill: parent

            source: Players.getArtUrl(Players.active)

            layer.enabled: true
            layer.effect: AlbumArtLayer {
                maskSource: shapeWrapper
                isHovered: root.isHovered
            }
        }
    }
}
