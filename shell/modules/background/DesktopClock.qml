pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import "clockfaces"

Item {
    id: root

    readonly property string clockStyle: Config.background.desktopClock.style || "classic"
    property real clockScale: Config.background.desktopClock.scale
    readonly property bool bgEnabled: (root.clockStyle === "classic" || root.clockStyle === "giant") && Config.background.desktopClock.background.enabled
    readonly property bool invertColors: Config.background.desktopClock.invertColors
    readonly property bool useLightSet: Colours.light ? !invertColors : invertColors
    readonly property color safePrimary: useLightSet ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeSecondary: useLightSet ? Colours.palette.m3secondaryContainer : Colours.palette.m3secondary
    readonly property color safeTertiary: useLightSet ? Colours.palette.m3tertiaryContainer : Colours.palette.m3tertiary
    readonly property string clockFont: GlobalConfig.appearance.font.clock || "Sans Serif"
    readonly property string sansFont: GlobalConfig.appearance.font.body.family || "Sans Serif"

    implicitWidth: faceLoader.item ? faceLoader.item.implicitWidth : 300
    implicitHeight: faceLoader.item ? faceLoader.item.implicitHeight : 150

    Item {
        id: clockContainer
        anchors.fill: parent

        StyledRect {
            id: backgroundPlate
            visible: root.bgEnabled
            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.clockScale
            opacity: Config.background.desktopClock.background.opacity
            color: Colours.palette.m3surface
            border.color: Colours.palette.m3outlineVariant
            border.width: 1
        }

        Loader {
            id: faceLoader
            anchors.centerIn: parent

            sourceComponent: {
                switch (root.clockStyle) {
                    case "cookie": return cookieComp;
                    case "giant": return giantComp;
                    case "pill": return pillComp;
                    case "radial": return radialComp;
                    case "classic":
                    default: return classicComp;
                }
            }
        }
    }

    Component {
        id: cookieComp
        CookieClock {
            clockScale: root.clockScale
            safePrimary: root.safePrimary
            safeSecondary: root.safeSecondary
            safeTertiary: root.safeTertiary
            sansFont: root.sansFont
        }
    }

    Component {
        id: giantComp
        GiantDigitalClock {
            clockScale: root.clockScale
            safePrimary: root.safePrimary
            safeSecondary: root.safeSecondary
            safeTertiary: root.safeTertiary
            clockFont: root.clockFont
            sansFont: root.sansFont
        }
    }

    Component {
        id: pillComp
        PillClock {
            clockScale: root.clockScale
            safePrimary: root.safePrimary
            safeSecondary: root.safeSecondary
            safeTertiary: root.safeTertiary
            clockFont: root.clockFont
            sansFont: root.sansFont
        }
    }

    Component {
        id: radialComp
        RadialClock {
            clockScale: root.clockScale
            safePrimary: root.safePrimary
            safeSecondary: root.safeSecondary
            safeTertiary: root.safeTertiary
            clockFont: root.clockFont
            sansFont: root.sansFont
        }
    }

    Component {
        id: classicComp
        ClassicClock {
            clockScale: root.clockScale
            safePrimary: root.safePrimary
            safeSecondary: root.safeSecondary
            safeTertiary: root.safeTertiary
            clockFont: root.clockFont
            sansFont: root.sansFont
        }
    }

    Behavior on clockScale {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
