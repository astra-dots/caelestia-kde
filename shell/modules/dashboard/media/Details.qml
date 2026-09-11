import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services
import qs.utils

ColumnLayout {
    id: root

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    spacing: Tokens.spacing.extraSmall

    Timer {
        running: root.visible && (Players.active?.isPlaying ?? false)
        interval: 100
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    MarqueeText {
        Layout.fillWidth: true
        text: Players.active?.trackTitle ?? ""
        font: Tokens.font.title.large
    }

    MarqueeText {
        Layout.fillWidth: true
        text: Players.active?.trackArtist || qsTr("Unknown artist")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.title.medium
    }

    MarqueeText {
        Layout.fillWidth: true
        text: Players.active?.trackAlbum || qsTr("Unknown album")
        color: Colours.palette.m3secondary
        font: Tokens.font.title.medium
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.small
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextMetrics {
            id: timeMetrics

            text: Players.active ? root.lengthStr(Math.max(Players.active.position, Players.active.length)).replace(/[1-9]/g, "0") : "00:00"
            font: Tokens.font.label.medium
        }

        StyledText {
            id: positionLabel

            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(positionSlider.isSeeking ? (positionSlider.seekPosition * (Players.active?.length ?? 0)) : (Players.active?.position ?? -1))
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }

        StyledSlider {
            id: positionSlider

            property bool isSeeking: false
            property real seekPosition: 0

            Timer {
                id: seekTimeoutTimer
                interval: 350
                repeat: false
                onTriggered: positionSlider.isSeeking = false
            }

            Layout.fillWidth: true
            animateChanges: false
            value: isSeeking ? seekPosition : (Players.active ? Players.active.position / (Players.active.length || 1) : 0)
            enabled: Players.active?.canSeek ?? false
            wavy: true
            animateWave: Players.active?.isPlaying ?? false
            waveFrequency: 5
            waveDuration: 2000
            interactionOnMove: false
            onInteraction: value => {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported) {
                    positionSlider.isSeeking = true;
                    positionSlider.seekPosition = value;
                    seekTimeoutTimer.restart();
                    active.position = value * active.length;
                }
            }

            Connections {
                target: Players
                function onActiveChanged() {
                    positionSlider.isSeeking = false;
                    seekTimeoutTimer.stop();
                }
            }

            Connections {
                target: Players.active
                ignoreUnknownSignals: true
                function onPostTrackChanged() {
                    positionSlider.isSeeking = false;
                    seekTimeoutTimer.stop();
                }
                function onPositionChanged() {
                    if (positionSlider.isSeeking) {
                        const cur = Players.active ? Players.active.position / (Players.active.length || 1) : 0;
                        const maxDiff = 1.5 / Math.max(1, Players.active?.length ?? 1);
                        if (Math.abs(cur - positionSlider.seekPosition) <= maxDiff) {
                            positionSlider.isSeeking = false;
                            seekTimeoutTimer.stop();
                        }
                    }
                }
            }

            Binding {
                target: positionLabel
                property: "text"
                value: root.lengthStr(positionSlider.pos * (Players.active?.length ?? 0))
                when: positionSlider.dragging
            }
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(Players.active?.length ?? -1)
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ButtonRow {
        Layout.topMargin: Tokens.spacing.small
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        IconButton {
            type: IconButton.Tonal
            icon: "shuffle"
            isRound: true
            shapeMorph: true
            checked: Players.active?.shuffle ?? false
            font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
            disabled: !Players.active?.shuffleSupported
            onClicked: Players.active.shuffle = !Players.active?.shuffle
            implicitWidth: Math.round(implicitHeight * 0.9)
        }

        IconButton {
            id: previousBtn

            type: IconButton.Tonal
            icon: "skip_previous"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !Players.active?.canGoPrevious
            onClicked: Players.active?.previous()
        }

        IconButton {
            id: playPauseBtn

            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            isRound: true
            shapeMorph: true
            fillWidth: true
            checked: Players.active?.isPlaying ?? false
            font: Tokens.font.icon.large
            disabled: !Players.active?.canTogglePlaying
            onClicked: Players.active?.togglePlaying()
        }

        IconButton {
            id: nextBtn

            type: IconButton.Tonal
            icon: "skip_next"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !Players.active?.canGoNext
            onClicked: Players.active?.next()
        }

        IconButton {
            type: IconButton.Tonal
            icon: Players.active?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            isRound: true
            shapeMorph: true
            checked: Players.active?.loopState === MprisLoopState.Track || Players.active?.loopState === MprisLoopState.Playlist
            font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
            disabled: !Players.active?.loopSupported
            onClicked: {
                const state = Players.active.loopState;
                if (state === MprisLoopState.None)
                    Players.active.loopState = MprisLoopState.Track;
                else if (state === MprisLoopState.Track)
                    Players.active.loopState = MprisLoopState.Playlist;
                else
                    Players.active.loopState = MprisLoopState.None;
            }
            implicitWidth: Math.round(implicitHeight * 0.9)
        }

        IconButton {
            id: likeBtn
            type: IconButton.Tonal
            icon: "favorite"
            isRound: true
            shapeMorph: true
            isToggle: true
            checked: SpotifyService.isLiked
            activeColour: Colours.palette.m3primary
            activeOnColour: Colours.palette.m3onPrimary
            font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
            visible: SpotifyService.isSpotify
            onClicked: SpotifyService.toggleLike()
            implicitWidth: Math.round(implicitHeight * 0.9)
        }
    }

    // --- Application Volume Slider for Active Media Player ---
    RowLayout {
        id: playerVolumeRow

        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        spacing: Tokens.spacing.small
        visible: Players.active !== null

        property real vol: Players.active?.volume ?? 0
        property real lastNonZeroVol: 1.0

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: Icons.getVolumeIcon(playerVolumeRow.vol, playerVolumeRow.vol <= 0.001)
            onClicked: {
                if (!Players.active)
                    return;
                if (playerVolumeRow.vol > 0.001) {
                    playerVolumeRow.lastNonZeroVol = playerVolumeRow.vol;
                    Players.active.volume = 0;
                } else {
                    Players.active.volume = playerVolumeRow.lastNonZeroVol > 0 ? playerVolumeRow.lastNonZeroVol : 1.0;
                }
            }
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: 24

            onWheel: event => {
                if (!Players.active)
                    return;
                const step = 0.05;
                const cur = Math.round((Players.active.volume ?? 0) * 100) / 100;
                if (event.angleDelta.y > 0)
                    Players.active.volume = Math.min(1.0, Math.round((cur + step) * 100) / 100);
                else if (event.angleDelta.y < 0)
                    Players.active.volume = Math.max(0.0, Math.round((cur - step) * 100) / 100);
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 8

                value: Players.active?.volume ?? 0
                onInteraction: v => {
                    if (Players.active)
                        Players.active.volume = Math.max(0, Math.min(1, Math.round(v * 100) / 100));
                }
            }
        }

        StyledText {
            text: `${Math.round((Players.active?.volume ?? 0) * 100)}%`
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
        }
    }

    // --- Spotify Exclusive: Up Next Expandable Card ---
    Item {
        id: upcomingContainer

        Layout.topMargin: Tokens.spacing.small
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? (hoverArea.containsMouse ? 84 : 28) : 0
        visible: SpotifyService.isSpotify && SpotifyService.hasUpcoming
        clip: true

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Rectangle {
            id: upcomingBg

            anchors.fill: parent
            radius: Tokens.rounding.medium
            color: hoverArea.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 1) : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
            border.color: hoverArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            border.width: hoverArea.containsMouse ? 1 : 0

            Behavior on color {
                CAnim {}
            }
            Behavior on border.width {
                CAnim {}
            }
            Behavior on border.color {
                CAnim {}
            }

            // Collapsed View
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small
                opacity: hoverArea.containsMouse ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MaterialIcon {
                    text: "queue_music"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3primary
                }

                StyledText {
                    text: qsTr("Up Next:")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3primary
                }

                MarqueeText {
                    Layout.fillWidth: true
                    text: `${SpotifyService.upcomingTitle} • ${SpotifyService.upcomingArtist}`
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                MaterialIcon {
                    text: "expand_more"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Expanded View (on Hover)
            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium
                opacity: hoverArea.containsMouse ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                // Album Art Thumbnail with Material 3 Expressive Shape (Cookie9Sided)
                Item {
                    id: thumbContainer
                    implicitWidth: 48
                    implicitHeight: 48
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    width: 48
                    height: 48
                    Layout.alignment: Qt.AlignVCenter

                    readonly property bool isHovered: hoverArea.containsMouse && hoverArea.mouseX >= 0 && hoverArea.mouseX <= (thumbContainer.x + thumbContainer.width + 12)

                    Item {
                        id: thumbShapeWrapper
                        anchors.fill: parent
                        layer.enabled: true

                        MaterialShape {
                            id: thumbShape
                            anchors.centerIn: parent
                            implicitSize: parent.width
                            shape: (thumbContainer.isHovered && AlbumArtEffects.enabled) ? MaterialShape.Square : MaterialShape.Cookie9Sided
                            color: Colours.palette.m3surfaceContainerLowest
                        }
                    }

                    FadeImage {
                        id: thumbImage
                        anchors.fill: parent
                        source: SpotifyService.upcomingArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: SpotifyService.upcomingArtUrl.length > 0

                        layer.enabled: true
                        layer.effect: AlbumArtLayer {
                            maskSource: thumbShapeWrapper
                            isHovered: thumbContainer.isHovered
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "music_note"
                        fontStyle: Tokens.font.icon.medium
                        color: Colours.palette.m3primary
                        visible: !SpotifyService.upcomingArtUrl || thumbImage.status !== Image.Ready
                    }
                }

                // Track Details Column with Marquee Scrolling
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    RowLayout {
                        spacing: Tokens.spacing.extraSmall
                        MaterialIcon {
                            text: "queue_music"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                        StyledText {
                            text: qsTr("UP NEXT")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3primary
                        }
                    }

                    MarqueeText {
                        Layout.fillWidth: true
                        text: SpotifyService.upcomingTitle
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    MarqueeText {
                        Layout.fillWidth: true
                        text: SpotifyService.upcomingArtist
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // Skip / Play Next Action Button
                IconButton {
                    type: IconButton.Tonal
                    icon: "skip_next"
                    isRound: true
                    shapeMorph: true
                    font: Tokens.font.icon.small
                    implicitWidth: 34
                    implicitHeight: 34
                    activeColour: Colours.palette.m3primary
                    activeOnColour: Colours.palette.m3onPrimary
                    onClicked: SpotifyService.skipNext()
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SpotifyService.skipNext()
            }
        }
    }
}
