import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool isMediaActive: false

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.bottomMargin: -Tokens.spacing.medium
            spacing: Tokens.spacing.medium
            z: 1

            MaterialIcon {
                Layout.topMargin: Math.round(fontInfo.pointSize * 0.12)
                text: "lyrics"
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Lyrics")
                font: Tokens.font.title.medium
            }

            LyricsInfo {}
        }

        LyricList {
            isMediaActive: root.isMediaActive
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            id: bottomRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconButton {
                id: spotifyThemeBtn

                visible: SpotifyService.isSpotify
                type: IconButton.Tonal
                isRound: true
                shapeMorph: true
                icon: SpotifyService.themeMode === "system" ? "palette" : "music_note"
                implicitHeight: playerSelector.expandBtn?.implicitHeight ?? (label.implicitHeight + padding * 2)
                implicitWidth: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                onClicked: SpotifyService.toggleThemeMode()

                Tooltip {
                    target: spotifyThemeBtn
                    text: SpotifyService.themeMode === "system"
                        ? qsTr("Spotify Theme: System Colors\nClick to switch to Song Colors")
                        : qsTr("Spotify Theme: Song Colors\nClick to switch to System Colors")
                }
            }

            SplitButton {
                id: playerSelector

                Layout.alignment: Qt.AlignVCenter
                type: SplitButton.Tonal
                disabled: !Players.list.length
                active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
                menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData

                menuItems: playerList.instances
                fallbackIcon: "music_off"
                fallbackText: qsTr("No players")

                readonly property real availableWidth: layout.width - (spotifyThemeBtn.visible ? (spotifyThemeBtn.implicitWidth + bottomRow.spacing) : 0)
                minLeftWidth: Math.max(0, availableWidth - expandBtn.implicitWidth - spacing)
                label.Layout.maximumWidth: Math.max(0, minLeftWidth - iconLabel.implicitWidth - textRow.spacing - textRow.anchors.horizontalCenterOffset / 2 - horizontalPadding * 2)
                label.elide: Text.ElideRight

                stateLayer.disabled: true
                menuOnTop: true

                Variants {
                    id: playerList

                    model: Players.list

                    PlayerItem {}
                }
            }
        }
    }

    component PlayerItem: MenuItem {
        required property MprisPlayer modelData

        icon: modelData === Players.active ? "check" : ""
        text: Players.getIdentity(modelData)
        activeIcon: "animated_images"
    }
}
