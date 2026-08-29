pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property FileDialog facePicker

    property color pfpFallbackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property string greetingText: ""

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    Behavior on pfpFallbackColour {
        CAnim {}
    }

    function updateGreeting(): void {
        const username = SysInfo.user || Paths.user || "User";
        const name = username.charAt(0).toUpperCase() + username.slice(1);
        const greetings = ["Hello", "Hey", "Hi", "Greetings", "Welcome", "Welcome back"];
        const chosen = greetings[Math.floor(Math.random() * greetings.length)];
        root.greetingText = `${chosen}, ${name}!`;
    }

    Component.onCompleted: root.updateGreeting()

    Connections {
        target: root.visibilities

        function onDashboardChanged(): void {
            if (root.visibilities.dashboard)
                root.updateGreeting();
        }
    }

    Item {
        id: pfpContainer

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: logoShape.right
        anchors.leftMargin: -(Tokens.padding.largeIncreased + Tokens.padding.extraLarge) / 2
        implicitWidth: height

        MaterialShape {
            id: shape

            anchors.centerIn: parent
            implicitSize: parent.height
            shape: GlobalConfig.dashboard.profilePicShape
            color: Qt.alpha(root.pfpFallbackColour, 1)
            opacity: root.pfpFallbackColour.a
            layer.enabled: true

            MouseArea {
                id: mouse

                containmentMask: QtObject {
                    function contains(pt: point): bool {
                        return shape.contains(pt) && !logoShape.contains(mouse.mapToItem(logoShape, pt));
                    }
                }

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.visibilities.dashboard = false;
                    root.facePicker.open();
                }
            }
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: Mask {
                maskSource: shape
            }

            Loader {
                anchors.centerIn: parent
                asynchronous: true
                active: pfp.status !== Image.Ready

                sourceComponent: MaterialIcon {
                    text: "person_add"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.extraLarge
                    fill: 1
                    grade: -2
                }
            }

            CachingImage {
                id: pfp

                anchors.fill: parent
                path: `${Paths.home}/.face`
            }

            StyledRect {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, pfp.status === Image.Ready ? 0.4 : 0)
                opacity: mouse.containsMouse ? 1 : 0
                layer.enabled: opacity < 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MaterialShape {
                    anchors.centerIn: parent
                    implicitSize: parent.height * 0.7
                    shape: MaterialShape.Diamond
                    color: Colours.palette.m3primary
                    scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1 : 0.7

                    Behavior on color {
                        CAnim {}
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "person_edit"
                        color: Colours.palette.m3onPrimary
                        fontStyle: Tokens.font.icon.large
                    }
                }
            }
        }
    }

    MaterialShape {
        id: logoShape

        x: Tokens.padding.extraSmall
        implicitSize: Tokens.sizes.dashboard.logoSize + Tokens.padding.small * 2
        shape: MaterialShape.Gem
        color: Colours.palette.m3primaryContainer

        Behavior on color {
            CAnim {}
        }

        Loader {
            anchors.centerIn: parent
            sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : osLogo
        }
    }

    Component {
        id: osLogo

        ColouredIcon {
            id: icon

            source: SysInfo.osLogo
            implicitSize: Tokens.sizes.dashboard.logoSize
            colour: Colours.palette.m3onPrimaryContainer
        }
    }

    Component {
        id: caelestiaLogo

        Logo {
            implicitWidth: Tokens.sizes.dashboard.logoSize
            implicitHeight: Tokens.sizes.dashboard.logoSize
            topColour: Colours.palette.m3primary
            bottomColour: Colours.palette.m3onPrimaryContainer
        }
    }

    StyledRect {
        id: bubble1

        anchors.left: pfpContainer.right
        anchors.verticalCenter: pfpContainer.verticalCenter
        anchors.leftMargin: 4
        anchors.verticalCenterOffset: 6

        implicitWidth: 6
        implicitHeight: 6
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer
    }

    StyledRect {
        id: bubble2

        anchors.left: bubble1.right
        anchors.verticalCenter: bubble1.verticalCenter
        anchors.leftMargin: 3
        anchors.verticalCenterOffset: -6

        implicitWidth: 10
        implicitHeight: 10
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer
    }

    StyledRect {
        id: wmContainer

        readonly property int maxTextWidth: Math.max(80, root.width - (bubble2.x + bubble2.width + 4) - Tokens.padding.medium * 2)

        anchors.left: bubble2.right
        anchors.leftMargin: 4
        anchors.verticalCenter: pfpContainer.verticalCenter

        radius: Tokens.rounding.largeIncreased
        color: Colours.palette.m3secondaryContainer
        implicitWidth: wmText.width + Tokens.padding.medium * 2
        implicitHeight: wmText.implicitHeight + Tokens.padding.small * 2

        StyledText {
            id: wmText

            anchors.centerIn: parent
            width: Math.min(implicitWidth, wmContainer.maxTextWidth)
            text: root.greetingText
            color: Colours.palette.m3onSecondaryContainer
            font: Tokens.font.body.builders.medium.vaxis("slnt", -4).build()
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
