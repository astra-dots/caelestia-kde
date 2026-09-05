import "../../../components/controls"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    property bool open
    readonly property real padding: Tokens.padding.large

    property bool spotifyAvailable: false
    property string spotifyThemeMode: "song"

    Process {
        id: fetchThemeModeProc
        command: ["curl", "-s", "http://127.0.0.1:8999/theme-mode"]
        stdout: StdioCollector {
            id: themeModeStdout
        }
        onExited: {
            try {
                const data = JSON.parse(themeModeStdout.text);
                if (data && data.mode) {
                    root.spotifyAvailable = true;
                    root.spotifyThemeMode = data.mode;
                }
            } catch (e) {}
        }
    }

    Process {
        id: setThemeModeProc
        stdout: StdioCollector {}
        onExited: {
            fetchThemeModeProc.running = true;
        }
    }

    function toggleSpotifyTheme() {
        const nextMode = (root.spotifyThemeMode === "system") ? "song" : "system";
        root.spotifyThemeMode = nextMode;
        setThemeModeProc.command = ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify({ mode: nextMode }), "http://127.0.0.1:8999/theme-mode"];
        setThemeModeProc.running = true;
    }

    Component.onCompleted: {
        fetchThemeModeProc.running = true;
    }

    onOpenChanged: {
        if (root.open) {
            fetchThemeModeProc.running = true;
        }
    }

    Timer {
        interval: 2500
        running: root.open
        repeat: true
        onTriggered: fetchThemeModeProc.running = true
    }

    implicitWidth: btn.implicitWidth * 0.9
    implicitHeight: btn.implicitHeight * 0.9

    BlobGroup {
        id: blobGroup

        color: Colours.palette.m3surfaceContainerHighest
        smoothing: root.Tokens.rounding.medium
        cornerFill: false

        Behavior on color {
            CAnim {}
        }
    }

    BlobRect {
        id: btnRect

        anchors.fill: parent
        anchors.margins: !btn.pressed && btn.containsMouse ? -Tokens.padding.extraSmall : 0
        group: blobGroup
        radius: Tokens.rounding.medium

        Behavior on anchors.margins {
            Anim {}
        }
    }

    BlobRect {
        id: rect

        anchors.right: parent.right
        anchors.top: parent.top

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: Tokens.rounding.medium
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                rect.anchors.rightMargin: root.width - root.Tokens.spacing.small
                rect.anchors.topMargin: -root.Tokens.padding.medium
                rect.implicitWidth: Math.max(layout.implicitWidth, placeholder.implicitWidth) + root.padding * 2
                rect.implicitHeight: Math.max(layout.implicitHeight, placeholder.implicitHeight) + root.padding * 2
                content.opacity: 1
            }
        }

        transitions: Transition {
            Anim {
                properties: "rightMargin,implicitWidth"
            }
            Anim {
                properties: "topMargin,implicitHeight"
                easing: root.Tokens.anim.expressiveFastSpatial
            }
            Anim {
                property: "opacity"
                type: Anim.DefaultEffects
            }
        }

        Behavior on implicitWidth {
            Anim {}
        }

        Behavior on implicitHeight {
            Anim {}
        }

        Item {
            id: content

            anchors.fill: parent
            clip: true
            opacity: 0
            state: Lyrics.loading || !Lyrics.hasLyrics ? "" : "hasLyrics"

            states: State {
                name: "hasLyrics"

                PropertyChanges {
                    layout.opacity: 1
                    placeholder.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: "hasLyrics"

                    SequentialAnimation {
                        Anim {
                            target: layout
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: placeholder
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                    }
                },
                Transition {
                    to: "hasLyrics"

                    SequentialAnimation {
                        Anim {
                            target: placeholder
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: layout
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                    }
                }
            ]

            ColumnLayout {
                id: layout

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall
                opacity: 0

                StyledText {
                    text: qsTr("Backend: %1").arg(LyricsBackend.toString(Lyrics.backend))
                    color: Colours.palette.m3onSurfaceVariant
                    animate: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        Layout.maximumWidth: Tokens.sizes.dashboard.mediaTabWidth / 2
                        text: qsTr("Selected candidate: %1 | %2 | %3").arg(Lyrics.selectedCandidate.title).arg(Lyrics.selectedCandidate.artist).arg(Lyrics.selectedCandidate.album)
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        animate: true
                    }

                    IconButton {
                        icon: "refresh"
                        type: IconButton.Text
                        onClicked: Lyrics.refresh()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Offset: %1 ms").arg(Math.round(Lyrics.offset))
                        color: Colours.palette.m3onSurfaceVariant
                        animate: true
                    }

                    IconButton {
                        icon: "restart_alt"
                        type: IconButton.Text
                        visible: Math.round(Lyrics.offset) !== 0
                        onClicked: Lyrics.offset = 0
                    }

                    IconButton {
                        icon: "remove"
                        type: IconButton.Text
                        onClicked: Lyrics.offset -= 50
                    }

                    IconButton {
                        icon: "add"
                        type: IconButton.Text
                        onClicked: Lyrics.offset += 50
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall
                    visible: root.spotifyAvailable

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Theme: %1").arg(root.spotifyThemeMode === "system" ? qsTr("System Colors") : qsTr("Song Colors"))
                        color: Colours.palette.m3onSurfaceVariant
                        animate: true
                    }

                    IconButton {
                        icon: root.spotifyThemeMode === "system" ? "palette" : "music_note"
                        type: IconButton.Text
                        onClicked: root.toggleSpotifyTheme()
                    }
                }
            }

            Item {
                id: placeholder

                anchors.centerIn: parent
                implicitWidth: placeholderText.implicitWidth
                implicitHeight: placeholderText.implicitHeight

                StyledText {
                    id: placeholderText

                    text: Lyrics.loading ? qsTr("Loading...") : qsTr("No lyrics found")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                    animate: true
                }
            }
        }
    }

    MouseArea {
        id: btn

        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.open = !root.open

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: "more_vert"
            fontStyle: Tokens.font.icon.medium
        }
    }
}
