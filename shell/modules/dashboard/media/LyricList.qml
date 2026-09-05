pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    readonly property real fadeAmount: 0.1
    property bool flag
    property list<string> lyricList: Lyrics.lyrics

    readonly property bool useSpicy: SpotifyService.isSpotify && SpotifyService.hasSpicyLyrics
    readonly property bool hasLyrics: useSpicy || Lyrics.hasLyrics

    onVisibleChanged: {
        if (!visible) {
            if (typeof lyrics !== "undefined" && lyrics) {
                lyrics.isReady = false;
            }
        } else {
            Qt.callLater(() => {
                if (typeof lyrics !== "undefined" && lyrics && lyrics.height > 100) {
                    lyrics.jumpToCurrent(true);
                }
            });
        }
    }

    function reloadTrack() {
        if (typeof lyrics !== "undefined" && lyrics) {
            lyrics.isReady = false;
        }
        const p = Players.active;
        if (p) {
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
        } else {
            Lyrics.clearTrack();
        }
    }

    Component.onCompleted: {
        root.reloadTrack();
    }

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask

        Rectangle {
            id: mask

            layer.enabled: true
            visible: false
            implicitWidth: root.width
            implicitHeight: root.height

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 0
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: 1 - root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 1
                }
            }
        }
    }

    state: {
        flag; // For some reason it doesn't update sometimes, so use this to force an update
        if (root.hasLyrics)
            return "hasLyrics";
        if (Lyrics.loading && !root.useSpicy)
            return "loading";
        return "noLyrics";
    }

    states: [
        State {
            name: "loading"

            PropertyChanges {
                loadingIndicator.opacity: 1
                lyrics.opacity: 0
                noLyrics.opacity: 0
            }
        },
        State {
            name: "hasLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: lyrics.isReady ? 1 : 0
                noLyrics.opacity: 0
            }
        },
        State {
            name: "noLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 0
                noLyrics.opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: "loading"

            SequentialAnimation {
                Anim {
                    target: loadingIndicator
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [lyrics, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "hasLyrics"

            SequentialAnimation {
                Anim {
                    target: lyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "noLyrics"

            SequentialAnimation {
                Anim {
                    target: noLyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, lyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        }
    ]

    Connections {
        function onActiveChanged() {
            root.reloadTrack();
        }

        target: Players
    }

    Connections {
        function onPostTrackChanged() {
            root.reloadTrack();
        }

        target: Players.active
        ignoreUnknownSignals: true
    }

    Connections {
        function onHasLyricsChanged() {
            root.flag = !root.flag;
            if (typeof lyrics !== "undefined" && lyrics) {
                lyrics.isReady = false;
            }
        }

        target: Lyrics
    }

    Connections {
        function onSpicyLyricsChanged() {
            root.flag = !root.flag;
            if (typeof lyrics !== "undefined" && lyrics) {
                lyrics.isReady = false;
                Qt.callLater(() => lyrics.jumpToCurrent(true));
            }
        }

        target: SpotifyService
    }

    Loader {
        id: loadingIndicator

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.large

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: shape.implicitSize + Tokens.padding.medium * 2
                implicitHeight: shape.implicitSize + Tokens.padding.medium * 2
                color: Colours.palette.m3primaryContainer
                radius: Tokens.rounding.full

                LoadingIndicator {
                    id: shape

                    anchors.centerIn: parent
                    implicitSize: Math.round(Tokens.sizes.dashboard.mediaSectionWidth / 5)
                    containsIcon: true // This removes the pentagon, which is not centered
                }
            }

            StyledText {
                text: qsTr("Loading lyrics...")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: noLyrics

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "sentiment_sad"
                fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: qsTr("No lyrics found")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.medium
            }
        }
    }

    Timer {
        id: syncTimer
        running: Players.active?.isPlaying ?? false
        interval: 60
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (Players.active) {
                Players.active.positionChanged();
            }
        }
    }

    StyledListView {
        id: lyrics

        property bool isReady: false
        property bool userScrolling: false

        anchors.fill: parent
        anchors.topMargin: parent.height * root.fadeAmount / 2
        anchors.bottomMargin: parent.height * root.fadeAmount / 2

        displayMarginBeginning: anchors.topMargin
        displayMarginEnd: anchors.bottomMargin

        model: root.useSpicy ? SpotifyService.lyricLines : root.lyricList

        Timer {
            id: settleTimer
            interval: 60
            onTriggered: {
                if (lyrics.currentIndex >= 0 && lyrics.count > 0 && lyrics.height > 100) {
                    lyrics.positionViewAtIndex(lyrics.currentIndex, ListView.Center);
                    lyrics.isReady = true;
                }
            }
        }

        function jumpToCurrent(forceInstant = false) {
            if (currentIndex >= 0 && count > 0 && height > 0) {
                if (forceInstant || !isReady) {
                    isReady = false;
                    positionViewAtIndex(currentIndex, ListView.Center);
                    settleTimer.restart();
                } else {
                    positionViewAtIndex(currentIndex, ListView.Center);
                }
            }
        }

        onCountChanged: {
            jumpToCurrent(true);
        }
        onHeightChanged: {
            if (height > 100) {
                if (!isReady) {
                    jumpToCurrent(true);
                } else {
                    positionViewAtIndex(currentIndex, ListView.Center);
                }
            }
        }
        onModelChanged: {
            isReady = false;
            Qt.callLater(() => jumpToCurrent(true));
        }

        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                lyrics.model; // Force update when lyrics change
                const pos = Players.active?.position ?? 0;
                if (root.useSpicy) {
                    return SpotifyService.indexForTime(pos);
                }
                return Lyrics.indexForTime(pos);
            });
            jumpToCurrent(true);
        }

        Timer {
            id: userScrollTimer
            interval: 3500
            onTriggered: {
                lyrics.userScrolling = false;
                if (lyrics.currentIndex >= 0 && lyrics.count > 0) {
                    lyrics.positionViewAtIndex(lyrics.currentIndex, ListView.Center);
                }
            }
        }

        onMovementStarted: {
            userScrolling = true;
            userScrollTimer.stop();
        }

        onMovementEnded: {
            userScrollTimer.restart();
        }

        highlightRangeMode: userScrolling ? ListView.NoHighlightRange : ListView.StrictlyEnforceRange
        highlightMoveDuration: isReady ? Tokens.anim.durations.large : 0
        highlightMoveVelocity: -1
        preferredHighlightBegin: (height - (currentItem?.implicitHeight ?? 0)) / 2
        preferredHighlightEnd: (height + (currentItem?.implicitHeight ?? 0)) / 2

        spacing: Tokens.spacing.extraSmall
        opacity: 0

        delegate: Item {
            id: lyricItem

            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem
            property real effectScale: isCurrent ? 1 : 0

            readonly property string lineText: typeof modelData === "string" ? modelData : (modelData?.text ?? "")
            readonly property var syllables: (typeof modelData === "object" && modelData?.syllables) ? modelData.syllables : []
            readonly property bool hasSyllables: syllables.length > 0
            readonly property real lineStartTime: (typeof modelData === "object" && modelData?.startTime !== undefined) ? modelData.startTime : -1

            width: lyrics.width
            implicitWidth: lyrics.width
            implicitHeight: Math.max(contentLoader.implicitHeight, 24) + (Tokens.padding.extraSmall * 2)

            Behavior on effectScale {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            Loader {
                id: contentLoader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium

                sourceComponent: lyricItem.hasSyllables ? syllableFlowComponent : simpleLineComponent
            }

            Component {
                id: simpleLineComponent

                StyledText {
                    id: lyricText

                    width: contentLoader.width
                    text: lyricItem.lineText || ". . ."
                    horizontalAlignment: Text.AlignLeft
                    color: lyricItem.isCurrent
                        ? Colours.palette.m3primary
                        : mouse.containsMouse
                            ? Colours.palette.m3onSurface
                            : Colours.palette.m3outline
                    font: lyricItem.isCurrent ? Tokens.font.title.small : Tokens.font.body.medium
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                    layer.enabled: lyricItem.effectScale > 0
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Colours.palette.m3primary
                        shadowOpacity: 0.6 * lyricItem.effectScale
                        shadowBlur: 0.5 * lyricItem.effectScale
                        blur: 0.0
                    }
                }
            }

            Component {
                id: syllableFlowComponent

                Flow {
                    id: flowLayout

                    width: contentLoader.width
                    spacing: 0

                    Repeater {
                        model: lyricItem.syllables

                        delegate: Item {
                            id: wordItem

                            required property var modelData
                            required property int index

                            readonly property string wText: modelData.text || ""
                            readonly property real wStart: Number(modelData.startTime) || 0
                            readonly property real wEnd: Number(modelData.endTime) || (wStart + 0.4)

                            readonly property real currentPos: Players.active?.position ?? 0
                            readonly property bool isWordPast: lyricItem.isCurrent && currentPos >= wEnd
                            readonly property bool isWordActive: lyricItem.isCurrent && currentPos >= wStart && currentPos < wEnd

                            implicitWidth: wordText.implicitWidth
                            implicitHeight: wordText.implicitHeight

                            StyledText {
                                id: wordText

                                anchors.centerIn: parent
                                text: wordItem.wText
                                font: lyricItem.isCurrent ? Tokens.font.title.small : Tokens.font.body.medium

                                color: {
                                    if (!lyricItem.isCurrent) {
                                        return mouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline;
                                    }
                                    if (wordItem.isWordActive || wordItem.isWordPast) {
                                        return Colours.palette.m3primary;
                                    }
                                    return Qt.alpha(Colours.palette.m3onSurface, 0.4);
                                }

                                scale: wordItem.isWordActive ? 1.05 : 1.0
                                Behavior on scale {
                                    Anim {
                                        duration: 100
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                layer.enabled: wordItem.isWordActive
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Colours.palette.m3primary
                                    shadowOpacity: 0.8
                                    shadowBlur: 0.6
                                    blur: 0.0
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = Players.active;
                                    if (p && wordItem.wStart >= 0) {
                                        p.position = wordItem.wStart;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                z: -1
                onClicked: {
                    const p = Players.active;
                    if (p) {
                        if (root.useSpicy && lyricItem.lineStartTime >= 0) {
                            p.position = lyricItem.lineStartTime;
                        } else {
                            const time = Lyrics.timeForIndex(lyricItem.index);
                            if (time >= 0) {
                                p.position = time;
                            }
                        }
                    }
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
