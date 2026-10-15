#!/bin/bash
# Включить системный SOCKS-прокси (macOS) на ciadpi.
#
# Использование:
#   ./socks.sh on [порт]     — включить (порт по умолчанию 1080)
#   ./socks.sh off           — выключить
#
# Сетевой сервис берётся автоматически (активный по умолчанию маршрут),
# либо задаётся переменной NETWORK_SERVICE.
set -euo pipefail

# определяем активный интерфейс и его имя сетевого сервиса
detect_service() {
    local dev name
    dev=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
    [ -n "$dev" ] || { echo "не могу определить активный интерфейс"; exit 1; }
    name=$(networksetup -listallhardwareports |
        awk -v d="$dev" '/Hardware Port:/{port=$0; sub("Hardware Port: ","",port)}
             /Device:/{if ($2==d) {print port; exit}}')
    [ -n "$name" ] || { echo "не могу найти сетевой сервис для $dev"; exit 1; }
    echo "$name"
}

SERVICE="${NETWORK_SERVICE:-$(detect_service)}"
ACTION="${1:-on}"
PORT="${2:-${CIADPI_PORT:-1080}}"

case "$ACTION" in
    on)
        networksetup -setsocksfirewallproxy "$SERVICE" 127.0.0.1 "$PORT"
        networksetup -setsocksfirewallproxystate "$SERVICE" on
        networksetup -setproxybypassdomains "$SERVICE" "*.local" "169.254.0.0/16" >/dev/null || true
        echo "SOCKS-прокси 127.0.0.1:$PORT включён ($SERVICE)"
        ;;
    off)
        networksetup -setsocksfirewallproxystate "$SERVICE" off
        echo "SOCKS-прокси выключен ($SERVICE)"
        ;;
    status)
        networksetup -getsocksfirewallproxy "$SERVICE"
        ;;
    *)
        echo "использование: $0 on|off|status [порт]"
        exit 1
        ;;
esac
