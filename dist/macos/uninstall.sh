#!/bin/bash
# Удаление LaunchAgent-сервиса ciadpi.
#
# Использование:
#   ./uninstall.sh          — снять сервис и удалить plist/лог
#   ./uninstall.sh --purge  — дополнительно удалить бинарь ~/.local/bin/ciadpi
set -euo pipefail

LABEL="com.user.ciadpi"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/ciadpi.log"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
rm -f "$LOG"
echo "сервис $LABEL удалён"

if [ "${1:-}" = "--purge" ]; then
    rm -f "$HOME/.local/bin/ciadpi"
    echo "бинарь удалён"
fi
