pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0))

    property date currentDate: new Date()
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()
    readonly property int nonAnimCurrMonth: currentDate.getMonth()
    readonly property int nonAnimCurrYear: currentDate.getFullYear()

    property int animDirection: 1
    property real animTranslate: 0
    property real animOpacity: 1

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.currentDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.currentDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);
    }

    width: Math.max(400 * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    spacing: Tokens.spacing.small * scaleOffset

    StyledText {
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        text: qsTr("Calendar")
        font.weight: 500
        font.pointSize: Tokens.font.body.medium.pointSize * root.fontScale
    }

    CustomMouseArea {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2 * root.scaleOffset

        onWheel: event => root.onWheel(event)

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large * root.scaleOffset
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            ColumnLayout {
                id: inner

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium * root.scaleOffset
                spacing: Tokens.spacing.extraSmall

                RowLayout {
                    id: monthNavigationRow

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    IconButton {
                        isRound: true
                        icon: "chevron_left"
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                        padding: Tokens.padding.small * root.scaleOffset
                        onClicked: root.currentDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.extraSmall * 2

                        StateLayer {
                            color: Colours.palette.m3primary
                            radius: pressed ? Tokens.rounding.small : height / 2
                            disabled: {
                                const now = new Date();
                                return root.nonAnimCurrMonth === now.getMonth() && root.nonAnimCurrYear === now.getFullYear();
                            }
                            onClicked: root.currentDate = new Date()

                            Behavior on radius {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }

                        StyledText {
                            id: monthYearDisplay

                            opacity: root.animOpacity
                            transform: Translate {
                                x: root.animTranslate
                            }

                            anchors.centerIn: parent
                            text: grid.title
                            color: Colours.palette.m3primary
                            font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                        }
                    }

                    IconButton {
                        isRound: true
                        icon: "chevron_right"
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                        padding: Tokens.padding.small * root.scaleOffset
                        onClicked: root.currentDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)
                    }
                }

                DayOfWeekRow {
                    id: daysRow

                    Layout.fillWidth: true
                    locale: grid.locale

                    delegate: StyledText {
                        required property var model

                        horizontalAlignment: Text.AlignHCenter
                        text: model.shortName
                        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                        color: (model.day === 0 || model.day === 6) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                        renderType: Text.QtRendering
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: grid.implicitHeight

                    opacity: root.animOpacity
                    transform: Translate {
                        x: root.animTranslate
                    }

                    MonthGrid {
                        id: grid

                        month: root.currMonth
                        year: root.currYear

                        anchors.fill: parent

                        spacing: 2
                        locale: Qt.locale()

                        delegate: Item {
                            id: dayItem

                            required property var model

                            implicitWidth: implicitHeight
                            implicitHeight: text.implicitHeight + Tokens.padding.small

                            StyledText {
                                id: text

                                anchors.centerIn: parent

                                horizontalAlignment: Text.AlignHCenter
                                text: grid.locale.toString(dayItem.model.day)
                                color: {
                                    const dayOfWeek = dayItem.model.date.getDay();
                                    if (dayOfWeek === 0 || dayOfWeek === 6)
                                        return Colours.palette.m3tertiary;

                                    return Colours.palette.m3onSurfaceVariant;
                                }
                                opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                                font: Tokens.font.body.small
                                renderType: Text.QtRendering
                            }
                        }
                    }

                    MaterialShape {
                        id: todayIndicator

                        readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
                        property Item today

                        onTodayItemChanged: {
                            if (todayItem)
                                today = todayItem;
                        }

                        x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                        y: today ? today.y - Tokens.padding.extraSmall - 1 : 0

                        implicitSize: today ? Math.max(today.implicitWidth, today.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                        shape: MaterialShape.Sunny

                        clip: true
                        color: Colours.palette.m3primary

                        opacity: todayItem ? 1 : 0

                        Colouriser {
                            x: -todayIndicator.x
                            y: -todayIndicator.y

                            implicitWidth: grid.width
                            implicitHeight: grid.height

                            source: grid
                            sourceColor: Colours.palette.m3onSurface
                            colorizationColor: Colours.palette.m3onPrimary
                        }

                        Behavior on x {
                            Anim {}
                        }

                        Behavior on y {
                            Anim {}
                        }
                    }
                }
            }
        }
    }
}
