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
            if (SpotifyService.isSpotify && !SpotifyService.hasSpicyLyrics) {
                SpotifyService.requestLyrics();
            }
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
        interval: 25
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

        NumberAnimation {
            id: scrollAnim
            target: lyrics
            property: "contentY"
            duration: Tokens.anim.durations.large
            easing.type: Easing.OutCubic
        }

        Timer {
            id: settleTimer
            interval: 60
            onTriggered: {
                if (lyrics.count > 0 && lyrics.height > 100) {
                    if (lyrics.currentIndex >= 0) {
                        lyrics.positionViewAtIndex(lyrics.currentIndex, ListView.Center);
                    } else {
                        lyrics.positionViewAtIndex(0, ListView.Beginning);
                    }
                    lyrics.isReady = true;
                }
            }
        }

        function scrollToCurrent(instant = false) {
            if (count === 0 || height <= 0) return;

            if (currentIndex < 0) {
                if (instant || !isReady) {
                    scrollAnim.stop();
                    positionViewAtIndex(0, ListView.Beginning);
                } else if (!userScrolling) {
                    scrollAnim.stop();
                    scrollAnim.to = 0;
                    scrollAnim.start();
                }
                return;
            }

            if (instant || !isReady) {
                scrollAnim.stop();
                positionViewAtIndex(currentIndex, ListView.Center);
                return;
            }

            if (userScrolling) return;

            Qt.callLater(() => {
                if (currentItem && !userScrolling) {
                    const itemCenter = currentItem.y + (currentItem.height / 2);
                    const maxScroll = Math.max(0, lyrics.contentHeight - lyrics.height);
                    const targetY = Math.max(0, Math.min(itemCenter - (lyrics.height / 2), maxScroll));
                    if (Math.abs(lyrics.contentY - targetY) > lyrics.height * 2.5) {
                        positionViewAtIndex(currentIndex, ListView.Center);
                    } else {
                        scrollAnim.stop();
                        scrollAnim.to = targetY;
                        scrollAnim.start();
                    }
                } else if (!currentItem && currentIndex >= 0) {
                    positionViewAtIndex(currentIndex, ListView.Center);
                }
            });
        }

        function jumpToCurrent(forceInstant = false) {
            scrollToCurrent(forceInstant);
        }

        onCountChanged: {
            scrollToCurrent(true);
        }
        onHeightChanged: {
            if (height > 100) {
                if (!isReady) {
                    scrollToCurrent(true);
                    settleTimer.restart();
                }
            }
        }
        onModelChanged: {
            isReady = false;
            Qt.callLater(() => {
                scrollToCurrent(true);
                settleTimer.restart();
            });
        }
        onCurrentIndexChanged: {
            if (count > 0 && height > 0) {
                if (!isReady) {
                    scrollToCurrent(true);
                    settleTimer.restart();
                } else {
                    scrollToCurrent(false);
                }
            }
        }

        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                lyrics.model; // Force update when lyrics change
                if (root.useSpicy) {
                    return SpotifyService.indexForTime(SpotifyService.effectivePosition);
                }
                const pos = (Players.active?.position ?? 0) + (Lyrics.offset / 1000.0);
                return Lyrics.indexForTime(pos);
            });
            scrollToCurrent(true);
        }

        Timer {
            id: userScrollTimer
            interval: 3500
            onTriggered: {
                lyrics.userScrolling = false;
                lyrics.scrollToCurrent(false);
            }
        }

        onMovementStarted: {
            scrollAnim.stop();
            userScrolling = true;
            userScrollTimer.stop();
        }

        onMovementEnded: {
            userScrollTimer.restart();
        }

        highlightRangeMode: ListView.NoHighlightRange

        spacing: Tokens.spacing.extraSmall
        opacity: 0
        visible: opacity > 0

        delegate: Item {
            id: lyricItem

            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property real currentPos: root.useSpicy
                ? SpotifyService.effectivePosition
                : ((Players.active?.position ?? 0) + (Lyrics.offset / 1000.0))

            readonly property string lineText: typeof modelData === "string" ? modelData : (modelData?.text ?? "")
            readonly property var syllables: (typeof modelData === "object" && modelData?.syllables) ? modelData.syllables : []
            readonly property bool hasSyllables: syllables.length > 0
            readonly property real lineStartTime: (typeof modelData === "object" && modelData?.startTime !== undefined) ? Number(modelData.startTime) : -1
            readonly property real lineEndTime: {
                let end = -1;
                if (typeof modelData === "object" && modelData?.endTime !== undefined && Number(modelData.endTime) > 0) {
                    end = Number(modelData.endTime);
                }
                if (syllables.length > 0) {
                    const last = syllables[syllables.length - 1];
                    if (last && last.endTime !== undefined && Number(last.endTime) > 0) {
                        end = Math.max(end, Number(last.endTime));
                    }
                }
                if (backgroundLines.length > 0) {
                    for (let b = 0; b < backgroundLines.length; b++) {
                        const bg = backgroundLines[b];
                        if (bg && bg.endTime !== undefined && Number(bg.endTime) > 0) {
                            end = Math.max(end, Number(bg.endTime));
                        }
                    }
                }
                return end;
            }

            readonly property bool isLineActive: isCurrent && currentPos >= lineStartTime && (lineEndTime <= 0 || currentPos < lineEndTime)
            property real effectScale: isLineActive ? 1 : 0

            readonly property var backgroundLines: (typeof modelData === "object" && modelData?.background) ? modelData.background : []
            readonly property bool hasBackground: backgroundLines.length > 0

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

                sourceComponent: (lyricItem.hasSyllables || lyricItem.hasBackground) ? syllableFlowComponent : simpleLineComponent
            }

            Component {
                id: simpleLineComponent

                Column {
                    width: contentLoader.width
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        id: lyricText

                        width: parent.width
                        text: lyricItem.lineText || (lyricItem.hasBackground ? "" : ". . .")
                        visible: text.length > 0
                        horizontalAlignment: Text.AlignLeft
                        color: lyricItem.isLineActive
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

                    Repeater {
                        model: lyricItem.backgroundLines

                        delegate: StyledText {
                            required property var modelData
                            width: parent.width
                            text: typeof modelData === "string" ? modelData : (modelData?.text ?? "")
                            font: Tokens.font.body.small
                            color: lyricItem.isLineActive ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.7)
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }
                }
            }

            Component {
                id: syllableFlowComponent

                Item {
                    id: flowWrapper

                    width: contentLoader.width
                    implicitWidth: contentLoader.width
                    implicitHeight: mainColumn.implicitHeight
                    height: implicitHeight

                    Column {
                        id: mainColumn

                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Tokens.spacing.extraSmall

                        // 1. Main Lead Vocal Flow (when syllables are present)
                        Flow {
                            id: flowLayout

                            visible: (lyricItem?.hasSyllables ?? false)
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 0

                            StyledText {
                                id: spaceMetric

                                visible: false
                                text: " "
                                font: (lyricItem?.isCurrent ?? false) ? Tokens.font.title.small : Tokens.font.body.medium
                            }

                            Repeater {
                                model: lyricItem?.syllables ?? []

                                delegate: Item {
                                    id: wordItem

                                    required property var modelData
                                    required property int index

                                    readonly property string rawText: modelData.text || ""
                                    readonly property real wStart: Number(modelData.startTime) || 0
                                    readonly property real wEnd: Number(modelData.endTime) || (wStart + 0.4)
                                    readonly property bool isPartOfWord: Boolean(modelData.isPartOfWord)
                                    readonly property bool hasTrailingSpace: rawText.endsWith(" ")
                                    readonly property bool needsSpace: !isPartOfWord || hasTrailingSpace
                                    readonly property string displayText: rawText.trim()

                                    readonly property real currentPos: lyricItem?.currentPos ?? 0

                                    readonly property bool isWordPast: (lyricItem?.isLineActive ?? false) && currentPos >= wEnd
                                    readonly property bool isWordActive: (lyricItem?.isLineActive ?? false) && currentPos >= wStart && currentPos < wEnd
                                    readonly property real fillProgress: {
                                        if (!(lyricItem?.isLineActive ?? false) || currentPos < wStart) return 0.0;
                                        if (currentPos >= wEnd) return 1.0;
                                        const dur = Math.max(0.04, wEnd - wStart);
                                        return Math.min(1.0, Math.max(0.0, (currentPos - wStart) / dur));
                                    }

                                    implicitWidth: baseText.implicitWidth + (needsSpace ? spaceMetric.implicitWidth : 0)
                                    implicitHeight: baseText.implicitHeight

                                    StyledText {
                                        id: baseText

                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        text: wordItem.displayText
                                        font: (lyricItem?.isCurrent ?? false) ? Tokens.font.title.small : Tokens.font.body.medium

                                        color: {
                                            if (!(lyricItem?.isLineActive ?? false)) {
                                                return wordMouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline;
                                            }
                                            if (wordItem.isWordPast) {
                                                return Colours.palette.m3primary;
                                            }
                                            if (wordMouse.containsMouse) {
                                                return Colours.palette.m3onSurface;
                                            }
                                            return Qt.alpha(Colours.palette.m3onSurface, 0.4);
                                        }
                                    }

                                    Item {
                                        id: activeClip

                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        clip: true
                                        width: Math.min(baseText.implicitWidth, Math.round(baseText.implicitWidth * wordItem.fillProgress))
                                        visible: (lyricItem?.isLineActive ?? false) && width > 0

                                        StyledText {
                                            id: activeText

                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            width: baseText.implicitWidth
                                            height: baseText.implicitHeight
                                            text: wordItem.displayText
                                            font: (lyricItem?.isCurrent ?? false) ? Tokens.font.title.small : Tokens.font.body.medium
                                            color: Colours.palette.m3primary

                                            layer.enabled: wordItem.isWordActive
                                            layer.effect: MultiEffect {
                                                shadowEnabled: true
                                                shadowColor: Colours.palette.m3primary
                                                shadowOpacity: 0.85
                                                shadowBlur: 0.55
                                                blur: 0.0
                                            }
                                        }
                                    }

                                    scale: wordItem.isWordActive ? 1.04 : 1.0
                                    transformOrigin: Item.Left
                                    Behavior on scale {
                                        Anim {
                                            duration: 80
                                            easing.type: Easing.OutQuad
                                        }
                                    }

                                    MouseArea {
                                        id: wordMouse

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
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

                        // Plain lead text if line has no syllables but has text (and background lyrics)
                        StyledText {
                            id: plainLeadText

                            visible: !(lyricItem?.hasSyllables ?? false) && (lyricItem?.lineText ?? "").length > 0
                            width: parent.width
                            text: lyricItem?.lineText ?? ""
                            horizontalAlignment: Text.AlignLeft
                            color: (lyricItem?.isLineActive ?? false) ? Colours.palette.m3primary : Colours.palette.m3outline
                            font: (lyricItem?.isCurrent ?? false) ? Tokens.font.title.small : Tokens.font.body.medium
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        // 2. Background Vocals (Small Lyrics flowing horizontally with syllable wipe)
                        Repeater {
                            model: lyricItem?.backgroundLines ?? []

                            delegate: Item {
                                id: bgLineItem

                                required property var modelData
                                required property int index

                                readonly property var bgSyllables: modelData?.syllables ?? []
                                readonly property bool bgHasSyllables: bgSyllables.length > 0
                                readonly property string bgText: modelData?.text ?? ""
                                readonly property real bgStart: Number(modelData?.startTime) || -1
                                readonly property real bgEnd: {
                                    let end = -1;
                                    if (modelData?.endTime !== undefined && Number(modelData.endTime) > 0) {
                                        end = Number(modelData.endTime);
                                    }
                                    if (bgSyllables.length > 0) {
                                        const last = bgSyllables[bgSyllables.length - 1];
                                        if (last && last.endTime !== undefined && Number(last.endTime) > 0) {
                                            end = Math.max(end, Number(last.endTime));
                                        }
                                    }
                                    return end;
                                }

                                width: mainColumn.width
                                implicitWidth: mainColumn.width
                                implicitHeight: bgFlow.implicitHeight
                                height: implicitHeight

                                StyledText {
                                    id: bgSpaceMetric

                                    visible: false
                                    text: " "
                                    font: Tokens.font.body.small
                                }

                                Flow {
                                    id: bgFlow

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    spacing: 0

                                    Repeater {
                                        model: bgLineItem.bgHasSyllables
                                            ? bgLineItem.bgSyllables
                                            : (bgLineItem.bgText.length > 0 ? [ { "text": bgLineItem.bgText, "startTime": bgLineItem.bgStart, "endTime": bgLineItem.bgEnd, "isPartOfWord": false } ] : [])

                                        delegate: Item {
                                            id: bgWordItem

                                            required property var modelData
                                            required property int index

                                            readonly property string rawText: modelData.text || ""
                                            readonly property real wStart: Number(modelData.startTime) || 0
                                            readonly property real wEnd: Number(modelData.endTime) || (wStart + 0.4)
                                            readonly property bool isPartOfWord: Boolean(modelData.isPartOfWord)
                                            readonly property bool hasTrailingSpace: rawText.endsWith(" ")
                                            readonly property bool needsSpace: !isPartOfWord || hasTrailingSpace
                                            readonly property string displayText: rawText.trim()

                                            readonly property real currentPos: lyricItem?.currentPos ?? 0
                                            readonly property bool isWordPast: (lyricItem?.isLineActive ?? false) && currentPos >= wEnd
                                            readonly property bool isWordActive: (lyricItem?.isLineActive ?? false) && currentPos >= wStart && currentPos < wEnd
                                            readonly property real fillProgress: {
                                                if (!(lyricItem?.isLineActive ?? false) || currentPos < wStart) return 0.0;
                                                if (currentPos >= wEnd) return 1.0;
                                                const dur = Math.max(0.04, wEnd - wStart);
                                                return Math.min(1.0, Math.max(0.0, (currentPos - wStart) / dur));
                                            }

                                            implicitWidth: bgBaseText.implicitWidth + (needsSpace ? bgSpaceMetric.implicitWidth : 0)
                                            implicitHeight: bgBaseText.implicitHeight
                                            width: implicitWidth
                                            height: implicitHeight

                                            StyledText {
                                                id: bgBaseText

                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                text: bgWordItem.displayText
                                                font: Tokens.font.body.small

                                                color: {
                                                    if (!(lyricItem?.isLineActive ?? false)) {
                                                        return bgWordMouse.containsMouse ? Colours.palette.m3onSurface : Qt.alpha(Colours.palette.m3outline, 0.7);
                                                    }
                                                    if (bgWordItem.isWordPast) {
                                                        return Colours.palette.m3primary;
                                                    }
                                                    if (bgWordMouse.containsMouse) {
                                                        return Colours.palette.m3onSurface;
                                                    }
                                                    return Qt.alpha(Colours.palette.m3onSurface, 0.45);
                                                }
                                            }

                                            Item {
                                                id: bgActiveClip

                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                clip: true
                                                width: Math.min(bgBaseText.implicitWidth, Math.round(bgBaseText.implicitWidth * bgWordItem.fillProgress))
                                                visible: (lyricItem?.isLineActive ?? false) && width > 0

                                                StyledText {
                                                    anchors.left: parent.left
                                                    anchors.top: parent.top
                                                    width: bgBaseText.implicitWidth
                                                    height: bgBaseText.implicitHeight
                                                    text: bgWordItem.displayText
                                                    font: Tokens.font.body.small
                                                    color: Colours.palette.m3primary

                                                    layer.enabled: bgWordItem.isWordActive
                                                    layer.effect: MultiEffect {
                                                        shadowEnabled: true
                                                        shadowColor: Colours.palette.m3primary
                                                        shadowOpacity: 0.8
                                                        shadowBlur: 0.5
                                                        blur: 0.0
                                                    }
                                                }
                                            }

                                            scale: bgWordItem.isWordActive ? 1.04 : 1.0
                                            transformOrigin: Item.Left
                                            Behavior on scale {
                                                Anim {
                                                    duration: 80
                                                    easing.type: Easing.OutQuad
                                                }
                                            }

                                            MouseArea {
                                                id: bgWordMouse

                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    const p = Players.active;
                                                    if (p && bgWordItem.wStart >= 0) {
                                                        p.position = bgWordItem.wStart;
                                                    }
                                                }
                                            }
                                        }
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
                hoverEnabled: !lyricItem.hasSyllables
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
