pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities
    property var parentList: null

    property string displayText
    property int expandedIndex: -1
    property real expandedItemHeight: 0

    onExpandedIndexChanged: {
        if (expandedIndex === -1)
            expandedItemHeight = 0;
    }

    onDisplayTextChanged: {
        root.expandedIndex = -1;
    }

    header: Item {
        visible: root.parentList?.showAllApps && root.search.text.length === 0
        implicitWidth: root.width
        implicitHeight: visible ? (headerRow.implicitHeight + Tokens.spacing.medium) : 0

        RowLayout {
            id: headerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.small
            anchors.bottomMargin: Tokens.spacing.small

            StyledText {
                text: qsTr("All Applications")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
                renderType: Text.QtRendering
            }

            Item { Layout.fillWidth: true }

            IconTextButton {
                icon: "arrow_back"
                text: qsTr("Back to Pinned")
                type: TextButton.Tonal
                onClicked: {
                    if (root.parentList)
                        root.parentList.showAllApps = false;
                }
            }
        }
    }

    readonly property string requestedState: stateForText(search.text)
    readonly property string displayState: stateForText(displayText)

    function syncDisplayText(): void {
        if (visibilities.launcher && requestedState === displayState)
            displayText = search.text;
    }

    function stateForText(text: string): string {
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant", "emoji", "clipboard", "windows"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    function resultsForText(text: string): var {
        switch (stateForText(text)) {
        case "actions":
            return Actions.query(text);
        case "calc":
            return [0];
        case "scheme":
            return Schemes.query(text);
        case "variant":
            return M3Variants.query(text);
        case "emoji": {
            const prefix = GlobalConfig.launcher.actionPrefix;
            const q = root._debouncedSearchText.slice((prefix + "emoji ").length).toLowerCase();
            if (!q)
                return Emojis.getSortedItems();
            return Emojis.search(q);
        }
        case "clipboard": {
            const prefix = GlobalConfig.launcher.actionPrefix;
            const q = root.search.text.slice((prefix + "clipboard ").length).toLowerCase();
            if (!q)
                return Clipboard.getSortedItems();
            return Clipboard.items.filter(function (item) {
                return item.preview.toLowerCase().includes(q);
            });
        }
        case "windows":
            return Windows.items;
        default: {
            if (!text) {
                const all = DesktopEntries.applications.values.filter(a => a && a.id && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id));
                return [...all].sort((a, b) => (a.name || "").localeCompare(b.name || ""));
            }
            return Apps.search(text);
        }
        }
    }

    model: ScriptModel {
        values: root.resultsForText(root.displayText)
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: {
        if (root.count === 0)
            return 0;

        if (root.displayState === "clipboard") {
            const maxItems = Math.min(Config.launcher.maxShown, root.count);
            const res = root.resultsForText(root.displayText);
            if (!res || res.length === 0)
                return 0;

            let totalH = 0;
            let expandedHandled = false;
            for (let i = 0; i < maxItems && i < res.length; i++) {
                const item = res[i];
                const isImg = item && (item.isImage === true || (typeof item.preview === "string" && item.preview.indexOf("[[ binary data") !== -1));
                let itemH = isImg ? (Tokens.sizes.launcher.itemHeight * 2) : Tokens.sizes.launcher.itemHeight;
                if (root.expandedIndex === i) {
                    itemH = root.expandedItemHeight > 0 ? root.expandedItemHeight : (isImg ? 300 : (Tokens.sizes.launcher.itemHeight + 120));
                    expandedHandled = true;
                }
                totalH += itemH + root.spacing;
            }
            if (!expandedHandled && root.expandedIndex >= 0 && root.expandedIndex < res.length) {
                const expItem = res[root.expandedIndex];
                const isImg = expItem && (expItem.isImage === true || (typeof expItem.preview === "string" && expItem.preview.indexOf("[[ binary data") !== -1));
                const baseH = isImg ? (Tokens.sizes.launcher.itemHeight * 2) : Tokens.sizes.launcher.itemHeight;
                const fullH = root.expandedItemHeight > 0 ? root.expandedItemHeight : (isImg ? 300 : (Tokens.sizes.launcher.itemHeight + 120));
                totalH += Math.max(0, fullH - baseH);
            }
            return Math.max(0, totalH - root.spacing);
        }

        return Math.max(0, (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing);
    }
    cacheBuffer: Tokens.sizes.launcher.itemHeight * 10

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    property string _debouncedSearchText: search.text

    Timer {
        id: searchDebounceTimer

        interval: 80
        onTriggered: root._debouncedSearchText = search.text
    }
    Connections {
        target: search

        function onTextChanged(): void {
            if (root.state === "emoji") {
                searchDebounceTimer.restart();
            } else {
                root._debouncedSearchText = search.text;
            }
        }
    }

    state: visibilities.launcher ? requestedState : displayState

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
        if (state === "emoji")
            Emojis.reload();
        if (state === "clipboard")
            Clipboard.reload();
            
        if (state !== "scheme" && state !== "variant") {
            Colours.showPreview = false;
        }
    }

    onCurrentItemChanged: {
        if (state === "scheme" || state === "variant") {
            if (currentItem && currentItem.modelData)
                previewTimer.restart();
        }
    }

    Component.onDestruction: {
        Colours.showPreview = false;
    }

    Timer {
        id: previewTimer

        interval: 100
        onTriggered: {
            if (!root.currentItem || !root.currentItem.modelData) return;
            if (root.state === "scheme") {
                const schemeData = root.currentItem.modelData;
                Colours.load(JSON.stringify({ name: schemeData.name, flavour: schemeData.flavour, variant: Colours.variant, mode: Colours.light ? "light" : "dark", colours: schemeData.colours }), true);
                Colours.showPreview = true;
            } else if (root.state === "variant") {
                const variantData = root.currentItem.modelData;
                M3Variants.previewVariant(variantData.variant);
            }
        }
    }

    Component.onCompleted: displayText = search.text

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                root.delegate: variantItem
            }
        },
        State {
            name: "emoji"

            PropertyChanges {
                root.delegate: emojiItem
            }
        },
        State {
            name: "clipboard"

            PropertyChanges {
                root.delegate: clipItem
            }
        },
        State {
            name: "windows"

            PropertyChanges {
                root.delegate: windowsItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                target: root
                property: "delegate"
                value: null
            }
            ScriptAction {
                script: root.displayText = root.search.text
            }
            PropertyAction {
                target: root
                property: "delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Component {
        id: emojiItem

        EmojiItem {
            list: root
        }
    }

    Component {
        id: clipItem

        ClipItem {
            list: root
        }
    }

    Component {
        id: windowsItem

        WindowSwitcherItem {
            list: root
        }
    }

    Connections {
        function onTextChanged() {
            root.syncDisplayText();
        }

        target: root.search
    }

    Connections {
        function onLauncherChanged() {
            root.syncDisplayText();
            if (!root.visibilities.launcher)
                root.expandedIndex = -1;
        }

        target: root.visibilities
    }
}
