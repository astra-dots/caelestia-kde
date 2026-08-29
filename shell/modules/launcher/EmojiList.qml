pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities

    property string currentCategory: "recents"
    property int selectedIndex: 0
    property string hoveredEmojiName: ""
    property string hoveredEmojiChar: ""

    // Skin Tone Variant Popup state
    property var activeVariantData: null
    property real variantPopupX: 0
    property real variantPopupY: 0

    readonly property string actionPrefix: GlobalConfig.launcher.actionPrefix || ">"
    readonly property string rawSearchText: search.text
    readonly property string searchQuery: {
        const prefix = actionPrefix + "emoji ";
        if (rawSearchText.startsWith(prefix)) {
            return rawSearchText.slice(prefix.length).trim();
        }
        if (rawSearchText === (actionPrefix + "emoji")) {
            return "";
        }
        return "";
    }

    readonly property bool isSearching: searchQuery.length > 0

    readonly property var currentItems: {
        if (isSearching) {
            return Emojis.search(searchQuery);
        }
        return Emojis.getItemsForCategory(currentCategory);
    }

    readonly property int count: currentItems ? currentItems.length : 0

    readonly property int columns: 8

    function nextCategory(): void {
        root.dismissVariantPopup();
        const cats = Emojis.categories;
        if (!cats || cats.length === 0) return;
        const idx = cats.findIndex(c => c.id === root.currentCategory);
        const nextIdx = (idx + 1) % cats.length;
        root.currentCategory = cats[nextIdx].id;
        root.selectedIndex = 0;
        ensureTabVisible(nextIdx);
        emojiGrid.positionViewAtBeginning();
    }

    function prevCategory(): void {
        root.dismissVariantPopup();
        const cats = Emojis.categories;
        if (!cats || cats.length === 0) return;
        const idx = cats.findIndex(c => c.id === root.currentCategory);
        const prevIdx = (idx - 1 + cats.length) % cats.length;
        root.currentCategory = cats[prevIdx].id;
        root.selectedIndex = 0;
        ensureTabVisible(prevIdx);
        emojiGrid.positionViewAtBeginning();
    }

    function moveLeft(): void {
        root.dismissVariantPopup();
        if (root.selectedIndex > 0) {
            root.selectedIndex -= 1;
            ensureGridItemVisible(root.selectedIndex);
        }
    }

    function moveRight(): void {
        root.dismissVariantPopup();
        if (root.selectedIndex < root.count - 1) {
            root.selectedIndex += 1;
            ensureGridItemVisible(root.selectedIndex);
        }
    }

    function moveUp(): void {
        root.dismissVariantPopup();
        if (root.selectedIndex >= root.columns) {
            root.selectedIndex -= root.columns;
            ensureGridItemVisible(root.selectedIndex);
        }
    }

    function moveDown(): void {
        root.dismissVariantPopup();
        if (root.selectedIndex + root.columns < root.count) {
            root.selectedIndex += root.columns;
            ensureGridItemVisible(root.selectedIndex);
        }
    }

    function activateSelected(): void {
        if (root.activeVariantData) {
            root.dismissVariantPopup();
            return;
        }
        if (root.selectedIndex >= 0 && root.selectedIndex < root.count) {
            const item = root.currentItems[root.selectedIndex];
            if (item && item.ch) {
                copyEmoji(item.ch, item.name || "");
            }
        }
    }

    function copyEmoji(ch: string, name: string): void {
        if (!ch) return;
        root.dismissVariantPopup();
        root.visibilities.launcher = false;
        Quickshell.execDetached(["wl-copy", ch]);
        Emojis.recordUsage(ch);
        if (GlobalConfig.utilities.toasts.clipboardChanged) {
            Toaster.toast(qsTr("Copied to clipboard"), ch + " " + name, "emoji_emotions");
        }
    }

    function showVariantPopup(modelData: var, itemX: real, itemY: real, itemW: real, itemH: real): void {
        if (!modelData || !modelData.variants || modelData.variants.length <= 1) return;
        root.activeVariantData = modelData;
        const totalW = modelData.variants.length * 40 + 16;
        let px = itemX + (itemW / 2) - (totalW / 2);
        if (px < 8) px = 8;
        if (px + totalW > root.width - 8) px = root.width - totalW - 8;
        let py = itemY - 50;
        if (py < 40) py = itemY + itemH + 6;
        root.variantPopupX = px;
        root.variantPopupY = py;
    }

    function dismissVariantPopup(): void {
        root.activeVariantData = null;
    }

    function ensureTabVisible(index: int): void {
        const targetX = index * (38 + 4);
        if (targetX < tabsFlickable.contentX) {
            tabsFlickable.contentX = targetX;
        } else if (targetX + 42 > tabsFlickable.contentX + tabsFlickable.width) {
            tabsFlickable.contentX = targetX + 42 - tabsFlickable.width;
        }
    }

    function ensureGridItemVisible(index: int): void {
        const row = Math.floor(index / root.columns);
        const itemY = row * 46;
        if (itemY < emojiGrid.contentY) {
            emojiGrid.contentY = itemY;
        } else if (itemY + 46 > emojiGrid.contentY + emojiGrid.height) {
            emojiGrid.contentY = itemY + 46 - emojiGrid.height;
        }
    }

    implicitWidth: Math.max(Tokens.sizes.launcher.itemWidth * 1.15, 510)
    implicitHeight: 380

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.small

        // Category Tabs Bar (Gboard & KDE style with animated sliding pill)
        Item {
            id: topBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            visible: !root.isSearching

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainer
            }

            // Entire top tab bar mouse wheel area
            MouseArea {
                anchors.fill: parent
                z: 5
                acceptedButtons: Qt.NoButton
                onWheel: event => {
                    if (event.angleDelta.y > 0 || event.angleDelta.x < 0) {
                        root.prevCategory();
                    } else if (event.angleDelta.y < 0 || event.angleDelta.x > 0) {
                        root.nextCategory();
                    }
                }
            }

            Flickable {
                id: tabsFlickable
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                contentWidth: tabsRow.implicitWidth
                contentHeight: height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Item {
                    id: tabsContainer
                    width: tabsRow.implicitWidth
                    height: tabsFlickable.height

                    // Fluid sliding pill indicator
                    Item {
                        id: tabIndicator
                        readonly property int targetIdx: {
                            const idx = Emojis.categories.findIndex(c => c.id === root.currentCategory);
                            return idx >= 0 ? idx : 0;
                        }

                        x: targetIdx * (38 + 4)
                        width: 38
                        height: 34
                        anchors.verticalCenter: parent.verticalCenter
                        z: 0

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primary
                        }

                        Behavior on x {
                            Anim {
                                duration: 160
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    Row {
                        id: tabsRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        z: 1

                        Repeater {
                            id: tabsRepeater
                            model: Emojis.categories

                            delegate: Item {
                                id: tabItem
                                required property var modelData
                                required property int index

                                readonly property bool isSelected: root.currentCategory === modelData.id
                                implicitWidth: 38
                                implicitHeight: 34

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: tabItem.modelData.icon || "help"
                                    fontStyle: Tokens.font.icon.medium
                                    color: tabItem.isSelected ? Colours.palette.m3onPrimary : (tabMouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant)

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.dismissVariantPopup();
                                        root.currentCategory = tabItem.modelData.id;
                                        root.selectedIndex = 0;
                                        root.ensureTabVisible(tabItem.index);
                                        emojiGrid.positionViewAtBeginning();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Search Active Indicator Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            visible: root.isSearching

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium

                MaterialIcon {
                    text: "search"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Results for \"%1\" (%2 found)").arg(root.searchQuery).arg(root.count)
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                    Layout.fillWidth: true
                }
            }
        }

        // Emoji Grid Container
        Item {
            id: gridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridView {
                id: emojiGrid
                anchors.fill: parent
                cellWidth: Math.floor(width / root.columns)
                cellHeight: 46
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 80
                reuseItems: true

                model: ScriptModel {
                    values: root.currentItems
                    onValuesChanged: {
                        emojiGrid.positionViewAtBeginning();
                        root.selectedIndex = 0;
                        root.dismissVariantPopup();
                    }
                }

                delegate: Item {
                    id: emojiCell
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === index
                    readonly property bool hasVariants: emojiCell.modelData?.variants && emojiCell.modelData.variants.length > 1

                    width: emojiGrid.cellWidth
                    height: emojiGrid.cellHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Tokens.rounding.medium
                        color: emojiCell.isSelected ? Colours.palette.m3surfaceContainerHighest : (cellMouse.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }
                    }

                    StyledText {
                        id: emojiGlyph
                        anchors.centerIn: parent
                        text: emojiCell.modelData?.ch ?? ""
                        font.family: "Noto Color Emoji, Twemoji, emoji"
                        font.pixelSize: 26
                        renderType: Text.QtRendering
                    }

                    // Subtle indicator in bottom-right corner for emojis that have skin tone variants
                    StyledRect {
                        width: 4
                        height: 4
                        radius: 2
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.6
                        visible: emojiCell.hasVariants
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onEntered: {
                            root.selectedIndex = emojiCell.index;
                            if (emojiCell.modelData) {
                                root.hoveredEmojiName = emojiCell.modelData.name || "";
                                root.hoveredEmojiChar = emojiCell.modelData.ch || "";
                            }
                        }

                        onExited: {
                            if (root.hoveredEmojiChar === emojiCell.modelData?.ch) {
                                root.hoveredEmojiName = "";
                                root.hoveredEmojiChar = "";
                            }
                        }

                        onClicked: mouse => {
                            if (!emojiCell.modelData || !emojiCell.modelData.ch) return;
                            const ch = emojiCell.modelData.ch;
                            const name = emojiCell.modelData.name || "";

                            if (mouse.button === Qt.LeftButton) {
                                if (root.activeVariantData) {
                                    root.dismissVariantPopup();
                                    return;
                                }
                                root.copyEmoji(ch, name);
                            } else if (mouse.button === Qt.RightButton) {
                                if (emojiCell.hasVariants) {
                                    const mapped = emojiCell.mapToItem(gridContainer, 0, 0);
                                    root.showVariantPopup(emojiCell.modelData, mapped.x, mapped.y, emojiCell.width, emojiCell.height);
                                }
                            }
                        }
                    }
                }
            }

            // Floating "Clear Recents" Action Button (FAB style in bottom right)
            StyledRect {
                id: clearRecentsFab
                visible: !root.isSearching && root.currentCategory === "recents" && Emojis.recents.length > 0
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: 32
                height: 32
                radius: Tokens.rounding.full
                color: clearFabMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
                z: 20
                scale: clearFabMouse.pressed ? 0.92 : (clearFabMouse.containsMouse ? 1.08 : 1.0)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "delete_sweep"
                    fontStyle: Tokens.font.icon.small
                    color: clearFabMouse.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    id: clearFabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.hoveredEmojiName = qsTr("Clear recents");
                        root.hoveredEmojiChar = "";
                    }
                    onExited: {
                        if (root.hoveredEmojiName === qsTr("Clear recents")) {
                            root.hoveredEmojiName = "";
                        }
                    }
                    onClicked: Emojis.clearRecents()
                }

                Behavior on scale {
                    Anim { duration: 120 }
                }
                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            // Floating Skin Tone Variants Popup Bar (Gboard / iOS / Discord style)
            StyledRect {
                id: variantPopup
                visible: root.activeVariantData !== null
                x: root.variantPopupX
                y: root.variantPopupY
                implicitWidth: variantRow.implicitWidth + 12
                implicitHeight: 50
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHighest
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
                z: 100

                Row {
                    id: variantRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: root.activeVariantData ? root.activeVariantData.variants : []

                        delegate: Item {
                            id: vItem
                            required property var modelData
                            required property int index

                            implicitWidth: 40
                            implicitHeight: 40

                            StyledRect {
                                anchors.fill: parent
                                radius: Tokens.rounding.full
                                color: vMouse.containsMouse ? Colours.palette.m3primaryContainer : "transparent"
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: vItem.modelData ?? ""
                                font.family: "Noto Color Emoji, Twemoji, emoji"
                                font.pixelSize: 26
                                renderType: Text.QtRendering
                            }

                            MouseArea {
                                id: vMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    const variantCh = vItem.modelData;
                                    root.hoveredEmojiChar = variantCh;
                                    let toneName = "";
                                    if (vItem.index === 0) toneName = "Default";
                                    else if (vItem.index === 1) toneName = "Light skin tone";
                                    else if (vItem.index === 2) toneName = "Medium-light skin tone";
                                    else if (vItem.index === 3) toneName = "Medium skin tone";
                                    else if (vItem.index === 4) toneName = "Medium-dark skin tone";
                                    else if (vItem.index === 5) toneName = "Dark skin tone";
                                    
                                    const baseName = root.activeVariantData?.name || "";
                                    root.hoveredEmojiName = toneName ? `${baseName} (${toneName})` : baseName;
                                }

                                onExited: {
                                    if (root.hoveredEmojiChar === vItem.modelData) {
                                        root.hoveredEmojiName = "";
                                        root.hoveredEmojiChar = "";
                                    }
                                }

                                onClicked: {
                                    const variantCh = vItem.modelData;
                                    root.copyEmoji(variantCh, root.hoveredEmojiName || root.activeVariantData?.name || "");
                                }
                            }
                        }
                    }
                }

                Behavior on opacity {
                    Anim { duration: 120 }
                }
                Behavior on scale {
                    Anim { duration: 120 }
                }
            }

            // Clean custom empty state
            Item {
                anchors.centerIn: parent
                visible: root.count === 0
                width: parent.width
                height: 140

                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isSearching ? "sentiment_dissatisfied" : "history_toggle_off"
                        fontStyle: Tokens.font.icon.extraLarge
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isSearching ? qsTr("No emojis found for \"%1\"").arg(root.searchQuery) : qsTr("No recent emojis yet")
                        font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isSearching ? qsTr("Try searching for smileys, animals, flags, etc.") : qsTr("Click any emoji to add to recents • Right-click for skin tones")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3outline
                    }
                }
            }
        }

        // Bottom Info / Tooltip Bar
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerLowest

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium

                StyledText {
                    text: root.hoveredEmojiChar ? (root.hoveredEmojiChar + "  " + root.hoveredEmojiName) : qsTr("Click to copy • Right-click for skin tones")
                    font: Tokens.font.label.small
                    color: root.hoveredEmojiChar ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        if (root.isSearching) return qsTr("%1 matches").arg(root.count);
                        const cat = Emojis.categories.find(c => c.id === root.currentCategory);
                        return cat ? (cat.name + " (" + root.count + ")") : "";
                    }
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                }
            }
        }
    }
}
