pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils

Item {
    id: root

    property DrawerVisibilities visibilities: null
    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    readonly property real arcCoverGap: Tokens.spacing.extraSmall

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.mediaWidth

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    CircularProgress {
        id: prog

        anchors.centerIn: cover
        implicitSize: cover.width + root.arcCoverGap + thickness * 2

        fgColour: Colours.palette.m3primary
        strokeWidth: Tokens.sizes.dashboard.mediaProgressThickness
        startAngle: -90 - sweepAngle / 2
        sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
        value: root.playerProgress

        wavy: true
        waveFrequency: 8
        waveDuration: 2000
        wavePaused: !Players.active?.isPlaying
    }

    CoverArt {
        id: cover

        shrinkOnHover: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium + root.arcCoverGap + prog.thickness
        implicitHeight: width
    }

    readonly property bool hasMedia: !!Players.active

    MarqueeText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.medium

        horizontalAlignment: Text.AlignHCenter
        text: root.hasMedia ? (Players.active.trackTitle || qsTr("Unknown title")) : qsTr("No media playing")
        color: Colours.palette.m3primary
        font: Tokens.font.title.small

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
    }

    MarqueeText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        horizontalAlignment: Text.AlignHCenter
        text: root.hasMedia ? (Players.active.trackAlbum || qsTr("Unknown album")) : qsTr("Ready to play")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
    }

    MarqueeText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        horizontalAlignment: Text.AlignHCenter
        text: root.hasMedia ? (Players.active.trackArtist || qsTr("Unknown artist")) : ""
        visible: root.hasMedia && text.length > 0
        color: Colours.palette.m3secondary
        font: Tokens.font.body.small

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
    }

    ButtonRow {
        id: controls

        anchors.top: root.hasMedia ? (artist.visible ? artist.bottom : album.bottom) : album.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.medium
        anchors.margins: Tokens.padding.large

        visible: root.hasMedia
        spacing: Tokens.spacing.extraSmall

        IconButton {
            type: IconButton.Tonal
            icon: "skip_previous"
            isRound: true
            shapeMorph: true
            disabled: !Players.active?.canGoPrevious
            onClicked: Players.active?.previous()
        }

        IconButton {
            fillWidth: true
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            isRound: true
            shapeMorph: true
            checked: Players.active?.isPlaying ?? false
            disabled: !Players.active?.canTogglePlaying
            onClicked: Players.active?.togglePlaying()
        }

        IconButton {
            type: IconButton.Tonal
            icon: "skip_next"
            isRound: true
            shapeMorph: true
            disabled: !Players.active?.canGoNext
            onClicked: Players.active?.next()
        }
    }

    IconTextButton {
        id: launchButton

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.medium

        visible: !root.hasMedia
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

    Item {
        id: bongocat

        anchors.top: root.hasMedia ? controls.bottom : launchButton.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small
        anchors.bottomMargin: Tokens.padding.large
        anchors.margins: Tokens.padding.extraLargeIncreased

        AnimatedImage {
            id: gif

            anchors.fill: parent

            playing: Players.active?.isPlaying ?? false
            speed: Audio.beatTracker.bpm / Config.general.mediaGifSpeedAdjustment // qmllint disable unresolved-type
            source: Paths.absolutePath(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
            visible: !Config.dashboard.useMediaShapes
        }

        MultiEffect {
            anchors.fill: gif
            source: gif

            visible: Config.dashboard.colorizeMediaGif && !Config.dashboard.useMediaShapes
            colorization: 1
            colorizationColor: Colours.palette.m3primary
        }

        MediaShapes {
            anchors.fill: parent
            visible: Config.dashboard.useMediaShapes
        }
    }
}
