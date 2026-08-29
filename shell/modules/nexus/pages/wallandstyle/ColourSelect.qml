pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Strings.localizeEnglishSpelling(qsTr("Colours"))
    isSubPage: true

    Component.onCompleted: {
        Schemes.reload();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.padding.small
        }

        // Standard Connected Navigation Rows
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                icon: "settings_suggest"
                label: qsTr("Advanced Material You Settings")
                status: qsTr("Configure advanced color engine settings and integrations")
                onClicked: root.nState.openSubPage(9)
            }

            NavRow {
                last: true
                icon: "palette"
                label: qsTr("Extracted Color Palette Inspector")
                status: qsTr("View all extracted tokens and copyable hex codes")
                onClicked: root.nState.openSubPage(10)
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.small
            text: qsTr("Color Theme")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: [
                    {
                        name: qsTr("Dark"),
                        description: qsTr("Dark theme mode"),
                        icon: "dark_mode",
                        mode: "dark"
                    },
                    {
                        name: qsTr("Light"),
                        description: qsTr("Light theme mode"),
                        icon: "light_mode",
                        mode: "light"
                    }
                ]

                StyledRect {
                    id: modeDelegateRect

                    required property var modelData

                    readonly property bool isSelected: (modelData?.mode === "light") === Colours.light

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    implicitHeight: modeCol.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.large
                    color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant

                    StateLayer {
                        radius: parent.radius
                        onClicked: Colours.setMode(modeDelegateRect.modelData?.mode)
                    }

                    RowLayout {
                        id: modeCol

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            Layout.alignment: Qt.AlignTop
                            text: modeDelegateRect.modelData?.icon ?? ""
                            fontStyle: Tokens.font.icon.large
                            color: modeDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: modeDelegateRect.modelData?.name ?? ""
                                font: Tokens.font.body.small
                                color: modeDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: modeDelegateRect.modelData?.description ?? ""
                                font: Tokens.font.label.small
                                color: modeDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Schemes")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: Schemes.list
                
                StyledRect {
                    id: delegateRect

                    required property var modelData
                    
                    readonly property bool isSelected: `${modelData?.name} ${modelData?.flavour}` === Schemes.currentScheme
                    
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: schemeRow.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.large
                    color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant
                    
                    StateLayer {
                        radius: parent.radius
                        onClicked: delegateRect.modelData?.onClicked(null)
                    }
                    
                    RowLayout {
                        id: schemeRow

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium
                        
                        StyledRect {
                            id: preview
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            
                            border.width: 1
                            border.color: Qt.alpha(`#${delegateRect.modelData?.colours?.outline}`, 0.5)

                            color: `#${delegateRect.modelData?.colours?.surface}`
                            radius: Tokens.rounding.full

                            Item {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right

                                width: parent.width / 2
                                clip: true

                                StyledRect {
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right

                                    width: preview.width
                                    color: `#${delegateRect.modelData?.colours?.primary}`
                                    radius: Tokens.rounding.full
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: delegateRect.modelData?.flavour ?? ""
                                font: Tokens.font.body.small
                                color: delegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: delegateRect.modelData?.name ?? ""
                                font: Tokens.font.label.small
                                color: delegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            }
                        }
                        
                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            visible: delegateRect.isSelected
                            text: "check"
                            color: Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Variants")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraLarge
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: M3Variants.list
                
                StyledRect {
                    id: varDelegateRect

                    required property var modelData
                    
                    readonly property bool isSelected: modelData?.variant === Schemes.currentVariant
                    
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    implicitHeight: varCol.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.large
                    color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant
                    
                    StateLayer {
                        radius: parent.radius
                        onClicked: varDelegateRect.modelData?.onClicked(null)
                    }
                    
                    RowLayout {
                        id: varCol

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium
                        
                        MaterialIcon {
                            Layout.alignment: Qt.AlignTop
                            text: varDelegateRect.modelData?.icon ?? ""
                            fontStyle: Tokens.font.icon.large
                            color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: varDelegateRect.modelData?.name ?? ""
                                font: Tokens.font.body.small
                                color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: varDelegateRect.modelData?.description ?? ""
                                font: Tokens.font.label.small
                                color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
