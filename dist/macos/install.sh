#!/bin/bash
# Установка ciadpi как пользовательского LaunchAgent-сервиса (без root).
#
# Использование:
#   ./install.sh [опции ciadpi...]
#   ./install.sh --disorder 1 --auto=torst --tlsrec 1+s
#
# Без опций используется пресет: --disorder 1 --auto=torst --tlsrec 1+s
# Бинарь берётся из CIADPI_BIN или из корня репозитория (нужен `make`).
# Plist рендерится из шаблона byedpi.plist (той же директории).
set -euo pipefail

LABEL="com.user.ciadpi"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
TPL="$DIR/byedpi.plist"
BIN="${CIADPI_BIN:-$REPO/ciadpi}"
INSTALL_BIN="$HOME/.local/bin/ciadpi"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/ciadpi.log"
DOMAIN="gui/$(id -u)"

[ "$(uname -s)" = "Darwin" ] || { echo "только macOS"; exit 1; }
[ -x "$BIN" ] || { echo "бинарь не найден: $BIN (выполните make)"; exit 1; }
[ -f "$TPL" ] || { echo "шаблон не найден: $TPL"; exit 1; }

OPTS=("$@")
if [ ${#OPTS[@]} -eq 0 ]; then
    OPTS=(--disorder 1 --auto=torst --tlsrec 1+s)
fi

# не допускаем символов, ломающих XML
for o in "${OPTS[@]}"; do
    case "$o" in
        *[\<\>\&\$\`]*) echo "недопустимый символ в опции: $o"; exit 1 ;;
    esac
done

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cp "$BIN" "$INSTALL_BIN"

# экранируем спецсимволы gsub-замены awk (& и \)
esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//&/\\&}"; printf '%s' "$s"; }

ARGS="$(esc "        <string>$INSTALL_BIN</string>")"$'\n'
for o in "${OPTS[@]}"; do
    ARGS+="$(esc "        <string>$o</string>")"$'\n'
done
ARGS="${ARGS%$'\n'}"

sed "s|@LOG@|$LOG|g" "$TPL" \
    | BLOCK="$ARGS" awk '{ gsub(/@ARGS@/, ENVIRON["BLOCK"]) } 1' > "$PLIST"

# перезагружаем сервис, если уже был загружен
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST"
sleep 1

if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    PID=$(launchctl print "$DOMAIN/$LABEL" 2>/dev/null | awk '/pid = [0-9]+/{print $3; exit}')
    echo "OK: $LABEL установлен, pid=${PID:-?}"
    echo "  бинарь: $INSTALL_BIN"
    echo "  опции:  ${OPTS[*]}"
    echo "  лог:    $LOG"
    echo "  plist:  $PLIST"
else
    echo "FAIL: сервис не запущен, смотрите log show --last 2m --predicate process==\"launchd\""
    exit 1
fi
