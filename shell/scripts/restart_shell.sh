#!/bin/bash

# Wipe stale Quickshell socket locks and orphan bridge servers
rm -rf "${XDG_RUNTIME_DIR:-/run/user/$UID}/quickshell/"*
pkill -f "spotify_bridge.py" 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user is-active plasma-caelestia.service >/dev/null 2>&1 || systemctl --user is-enabled plasma-caelestia.service >/dev/null 2>&1; then
        exec systemctl --user restart plasma-caelestia.service
    fi

    if systemctl --user is-active app-caelestiashell@autostart.service >/dev/null 2>&1 || systemctl --user is-enabled app-caelestiashell@autostart.service >/dev/null 2>&1; then
        exec systemctl --user restart app-caelestiashell@autostart.service
    fi
fi

/usr/bin/caelestia shell -k 2>/dev/null
sleep 1.3

source /etc/profile 2>/dev/null || true
[ -f ~/.profile ] && source ~/.profile 2>/dev/null || true
[ -f ~/.bashrc ] && source ~/.bashrc 2>/dev/null || true
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"
export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"
export QS_NO_RELOAD_POPUP=1
export QS_DROP_EXPENSIVE_FONTS=1
export QS_DISABLE_CRASH_HANDLER=1
export QSG_RENDER_LOOP=threaded
export QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

exec /usr/bin/caelestia shell -d
