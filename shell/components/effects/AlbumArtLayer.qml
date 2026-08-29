pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

ShaderEffect {
    id: root

    required property var maskSource
    property bool isHovered: false

    readonly property real targetIntensity: (AlbumArtEffects.enabled && !root.isHovered) ? 1.0 : 0.0

    property real intensity: targetIntensity
    property real itemWidth: root.width
    property real itemHeight: root.height
    property real time: 0.0
    property real smoothing: AlbumArtEffects.smoothing ? 1.0 : 0.0

    Behavior on intensity {
        Anim {
            duration: 350
        }
    }

    NumberAnimation {
        target: root
        property: "time"
        from: 0
        to: 3600
        duration: 3600000
        loops: Animation.Infinite
        running: AlbumArtEffects.enabled && (AlbumArtEffects.effectType === "gradient" || AlbumArtEffects.effectType === "smear") && root.visible
    }

    fragmentShader: AlbumArtEffects.getShaderUrl()
}
