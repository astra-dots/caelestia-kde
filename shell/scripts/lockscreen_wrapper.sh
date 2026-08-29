#!/bin/bash
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml:${QML2_IMPORT_PATH}"
export QML_IMPORT_PATH="$HOME/.local/lib/qt6/qml:${QML_IMPORT_PATH}"
export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"
export LD_LIBRARY_PATH="$HOME/.local/lib/qt6/qml/Caelestia/lib:${LD_LIBRARY_PATH}"
export QS_NO_RELOAD_POPUP=1
export QS_DISABLE_CRASH_HANDLER=1
exec quickshell -p "$HOME/.config/quickshell/caelestia/lockscreen.qml"
