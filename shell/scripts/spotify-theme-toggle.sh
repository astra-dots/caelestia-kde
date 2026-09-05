#!/usr/bin/env bash
CURRENT=$(curl -s http://127.0.0.1:8999/theme-mode 2>/dev/null | grep -o '"mode": *"[^"]*"' | cut -d'"' -f4)
if [ "$CURRENT" = "system" ]; then
    NEXT="song"
else
    NEXT="system"
fi
curl -s -X POST -H "Content-Type: application/json" -d "{\"mode\": \"$NEXT\"}" http://127.0.0.1:8999/theme-mode > /dev/null
echo "Switched Spotify theme to: $NEXT"
