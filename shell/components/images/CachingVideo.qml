import QtQuick

Item {
    id: root

    property string path
    property var screen
    property bool isFirstInstance: false
    property bool playing: false
    property int fillMode: 0
    property int playbackState: 0

    function checkPauseState() {}
    function checkMuteState() {}
}
