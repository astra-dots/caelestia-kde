import "media"
import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    property DashboardState dashState: null

    readonly property bool isMediaActive: {
        if (!visibilities?.dashboard) return false;
        if (!dashState) return true;
        const loader = root.parent as Loader;
        return loader ? (dashState.currentTab === loader.index) : true;
    }

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight + 52

    BackgroundShapes {
        anchors.fill: parent
        active: root.isMediaActive
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        CoverVisualiser {
            Layout.fillHeight: true
            implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
            active: root.isMediaActive && (Players.active?.isPlaying ?? false)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            state: Players.active ? "" : "noMedia"

            states: State {
                name: "noMedia"

                PropertyChanges {
                    noMedia.opacity: 1
                    content.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: ""

                    ParallelAnimation {
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                    }
                },
                Transition {
                    to: ""

                    ParallelAnimation {
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                    }
                }
            ]

            Loader {
                id: noMedia

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Tokens.padding.extraLarge * 2
                asynchronous: true
                active: opacity > 0
                opacity: 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.small

                    MaterialShape {
                        Layout.topMargin: (pathBounds().height - implicitSize) / 2
                        Layout.bottomMargin: (pathBounds().height - implicitSize) / 2 + Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.palette.m3primaryContainer
                        implicitSize: icon.implicitHeight + Tokens.padding.extraLarge * 2
                        shape: MaterialShape.ClamShell

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: "queue_music"
                            fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                            color: Colours.palette.m3onPrimaryContainer
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Nothing playing")
                        font: Tokens.font.headline.medium
                    }

                    StyledText {
                        text: qsTr("Play something for it to show up here!")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }

                    IconTextButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.spacing.small
                        icon: "headphones"
                        text: qsTr("Open Spotify")
                        type: ButtonBase.Tonal
                        isRound: true

                        onClicked: {
                            if (root.visibilities) {
                                root.visibilities.dashboard = false;
                            }
                            Quickshell.execDetached(["gtk-launch", "spotify-launcher"]);
                        }
                    }
                }
            }

            Loader {
                id: content

                anchors.fill: parent
                asynchronous: false
                active: Boolean(Players.active)

                sourceComponent: RowLayout {
                    spacing: Tokens.spacing.extraLarge

                    Details {
                        Layout.fillWidth: true
                        isMediaActive: root.isMediaActive
                    }

                    LyricsAndSelector {
                        isMediaActive: root.isMediaActive
                        Layout.fillHeight: true
                        implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
                    }
                }
            }
        }
    }
}
