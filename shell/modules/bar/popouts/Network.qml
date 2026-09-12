pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property string connectingToSsid: ""
    property string view: "wireless" // Kept for backward compatibility
    property var passwordNetwork: null
    property bool showPasswordDialog: false
    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: GlobalConfig.bar.perElementPreviewScale ? (!isNaN(GlobalConfig.bar.previewScales.network) ? GlobalConfig.bar.previewScales.network : 0.0) : 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real elementFontOffset: GlobalConfig.bar.perElementFontScale ? (!isNaN(GlobalConfig.bar.previewFontScales.network) ? GlobalConfig.bar.previewFontScales.network : 0.0) : 0.0
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0) + elementFontOffset)

    readonly property bool useTwoColumns: width >= 480 * scaleOffset

    spacing: Tokens.spacing.medium * scaleOffset
    width: Math.max(540 * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        Layout.rightMargin: Tokens.padding.small * root.scaleOffset

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Network")
            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
        }

        IconButton {
            id: networkSettingsBtn
            type: IconButton.Text
            isRound: true
            icon: "settings"
            font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
            onClicked: root.popouts.detachRequested("network")

            Tooltip {
                target: networkSettingsBtn
                text: qsTr("Network Settings")
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitWidth: cardLayout.implicitWidth + Tokens.padding.medium * 2 * root.scaleOffset
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2 * root.scaleOffset
        radius: Tokens.rounding.medium * root.scaleOffset
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        GridLayout {
            id: cardLayout

            width: parent.width - Tokens.padding.medium * 2 * root.scaleOffset
            x: Tokens.padding.medium * root.scaleOffset
            y: Tokens.padding.medium * root.scaleOffset
            columns: root.useTwoColumns ? 3 : 1
            columnSpacing: Tokens.spacing.large * root.scaleOffset
            rowSpacing: Tokens.spacing.medium * root.scaleOffset

            // =================================================================
            //  Column 1: Wireless (WiFi)
            // =================================================================
            ColumnLayout {
                id: wifiCol
                Layout.fillWidth: true
                Layout.preferredWidth: root.useTwoColumns ? Math.round(260 * root.scaleOffset) : -1
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.small * root.scaleOffset

                StyledText {
                    Layout.topMargin: Tokens.padding.small * root.scaleOffset
                    Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                    text: qsTr("Wireless")
                    font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                }

                Toggle {
                    label: qsTr("Enabled")
                    checked: Nmcli.wifiEnabled
                    toggle.onToggled: Nmcli.enableWifi(checked)
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.extraSmall * root.scaleOffset
                    Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                    text: qsTr("%1 networks available").arg(Nmcli.networks.length) // qmllint disable missing-property
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                }

                Repeater {
                    model: ScriptModel {
                        values: [...Nmcli.networks].sort((a, b) => {
                            if (a.active !== b.active)
                                return b.active - a.active;
                            return b.strength - a.strength;
                        }).slice(0, GlobalConfig.nexus.maxNetworksShown || 6)
                    }

                    RowLayout {
                        id: networkItem

                        required property Nmcli.AccessPoint modelData
                        readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
                        readonly property bool loading: networkItem.isConnecting

                        Layout.fillWidth: true
                        Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                        spacing: Tokens.spacing.small * root.scaleOffset

                        opacity: 0
                        scale: 0.7

                        Component.onCompleted: {
                            opacity = 1;
                            scale = 1;
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        MaterialIcon {
                            animate: true
                            text: Icons.getNetworkIcon(networkItem.modelData.strength)
                            color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale
                        }

                        StyledText {
                            Layout.leftMargin: Tokens.spacing.extraSmall * root.scaleOffset
                            Layout.rightMargin: Tokens.spacing.extraSmall * root.scaleOffset
                            Layout.fillWidth: true
                            text: networkItem.modelData.ssid
                            elide: Text.ElideRight
                            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).build()
                            color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: networkItem.modelData.security.length > 0
                            text: "lock"
                            fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: wirelessConnectIcon.implicitHeight + Tokens.padding.extraSmall * root.scaleOffset

                            radius: Tokens.rounding.full * root.scaleOffset
                            color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                            CircularIndicator {
                                anchors.fill: parent
                                running: networkItem.loading
                            }

                            StateLayer {
                                color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                disabled: networkItem.loading

                                onClicked: {
                                    if (networkItem.modelData.active) {
                                        Nmcli.disconnectFromNetwork();
                                    } else {
                                        root.connectingToSsid = networkItem.modelData.ssid;
                                        NetworkConnection.handleConnect(networkItem.modelData, null, network => {
                                            root.showPasswordDialog = true;
                                            root.passwordNetwork = network;
                                            root.popouts.currentName = "wirelesspassword";
                                        });
                                    }
                                }
                            }

                            MaterialIcon {
                                id: wirelessConnectIcon

                                anchors.centerIn: parent
                                animate: true
                                text: networkItem.modelData.active ? "link_off" : "link"
                                color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale

                                opacity: networkItem.loading ? 0 : 1

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.topMargin: Tokens.spacing.small * root.scaleOffset
                    Layout.fillWidth: true
                    implicitHeight: rescanBtn.implicitHeight + Tokens.padding.small * root.scaleOffset

                    radius: Tokens.rounding.full * root.scaleOffset
                    color: Colours.palette.m3primaryContainer

                    StateLayer {
                        color: Colours.palette.m3onPrimaryContainer
                        disabled: Nmcli.scanning || !Nmcli.wifiEnabled
                        onClicked: Nmcli.rescanWifi()
                    }

                    RowLayout {
                        id: rescanBtn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small * root.scaleOffset
                        opacity: Nmcli.scanning ? 0 : 1

                        MaterialIcon {
                            id: scanIcon

                            Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
                            animate: true
                            text: "wifi_find"
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale
                        }

                        StyledText {
                            Layout.topMargin: -Math.round(scanIcon.fontInfo.pointSize * 0.0575)
                            text: qsTr("Rescan networks")
                            color: Colours.palette.m3onPrimaryContainer
                            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).build()
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    CircularIndicator {
                        anchors.centerIn: parent
                        strokeWidth: Tokens.padding.extraSmall / 2 * root.scaleOffset
                        bgColour: "transparent"
                        implicitSize: parent.implicitHeight - Tokens.padding.large * root.scaleOffset
                        running: Nmcli.scanning
                    }
                }
            }

            // =================================================================
            //  Column 2: Divider
            // =================================================================
            Rectangle {
                visible: root.useTwoColumns
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Colours.palette.m3outlineVariant
                opacity: 0.25
            }

            // =================================================================
            //  Column 3: Ethernet & VPN
            // =================================================================
            ColumnLayout {
                id: ethCol
                Layout.fillWidth: true
                Layout.preferredWidth: root.useTwoColumns ? Math.round(240 * root.scaleOffset) : -1
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.small * root.scaleOffset

                StyledText {
                    Layout.topMargin: Tokens.padding.small * root.scaleOffset
                    Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                    text: qsTr("Ethernet")
                    font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.extraSmall * root.scaleOffset
                    Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                    text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                }

                Repeater {
                    model: ScriptModel {
                        values: [...Nmcli.ethernetDevices].sort((a, b) => {
                            if (a.connected !== b.connected)
                                return b.connected - a.connected;
                            return (a.interface || "").localeCompare(b.interface || "");
                        }).slice(0, 4)
                    }

                    RowLayout {
                        id: ethernetItem

                        required property var modelData
                        readonly property bool loading: false

                        Layout.fillWidth: true
                        Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                        spacing: Tokens.spacing.small * root.scaleOffset

                        opacity: 0
                        scale: 0.7

                        Component.onCompleted: {
                            opacity = 1;
                            scale = 1;
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        MaterialIcon {
                            text: "cable"
                            color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: ethernetItem.modelData.interface || qsTr("Unknown")
                                elide: Text.ElideRight
                                font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).build()
                                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }

                            StyledText {
                                visible: ethernetItem.modelData.connected && (Nmcli.ethernetDeviceDetails?.ipAddress || ethernetItem.modelData.connection)
                                Layout.fillWidth: true
                                text: {
                                    const ip = Nmcli.ethernetDeviceDetails?.ipAddress;
                                    const con = ethernetItem.modelData.connection;
                                    if (ip && con) return `${con} (${ip})`;
                                    return con || ip || "";
                                }
                                elide: Text.ElideRight
                                font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale * 0.9).build()
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall * root.scaleOffset

                            radius: Tokens.rounding.full * root.scaleOffset
                            color: Qt.alpha(Colours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                            CircularIndicator {
                                anchors.fill: parent
                                running: ethernetItem.loading
                            }

                            StateLayer {
                                color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                disabled: ethernetItem.loading

                                onClicked: {
                                    if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                                        Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                                    } else {
                                        Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.interface || "", () => {});
                                    }
                                }
                            }

                            MaterialIcon {
                                id: connectIcon

                                anchors.centerIn: parent
                                animate: true
                                text: ethernetItem.modelData.connected ? "link_off" : "link"
                                color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                fontStyle.pointSize: Tokens.font.icon.medium.pointSize * root.fontScale

                                opacity: ethernetItem.loading ? 0 : 1

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: Nmcli.ethernetDevices.length === 0
                    Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                    text: qsTr("No Ethernet devices found")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                }


            }
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.popouts.currentName === "wirelesspassword") {
                        root.popouts.currentName = "network";
                    }
                }
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning && typeof scanIcon !== "undefined" && scanIcon)
                scanIcon.rotation = 0;
        }

        target: Nmcli
    }

    Connections {
        function onCurrentNameChanged(): void {
            if (root.popouts.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.popouts
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
        spacing: Tokens.spacing.medium * root.scaleOffset

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).build()
        }

        StyledSwitch {
            id: toggle
        }
    }
}
