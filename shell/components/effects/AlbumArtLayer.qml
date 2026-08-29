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

    fragmentShader: AlbumArtEffects.getShaderUrl()
}
