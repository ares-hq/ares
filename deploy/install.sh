#!/usr/bin/env bash
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "run as root" >&2; exit 1; }

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

id -u ares >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin ares
install -d -m 755 -o ares -g ares /var/lib/ares
install -d -m 755 /usr/local/lib/ares
install -d -m 750 /etc/ares

install -m 755 "$here/update.sh" /usr/local/lib/ares/update.sh
install -m 644 "$here"/systemd/* /etc/systemd/system/

if [ ! -e /etc/ares/env ]; then
    install -m 600 /dev/null /etc/ares/env
    cat > /etc/ares/env <<'ENV'
DISCORD_TOKEN=
SUPABASE_URL=
SUPABASE_KEY=
FIRST_USERNAME=
FIRST_PASS=
ENV
    echo "fill in /etc/ares/env, then rerun this script"
    exit 0
fi
chmod 600 /etc/ares/env

systemctl daemon-reload
/usr/local/lib/ares/update.sh

systemctl enable --now ares-bot.service
systemctl enable --now ares-db.timer ares-db-full.timer ares-update.timer

systemctl --no-pager status ares-bot.service | head -5
systemctl --no-pager list-timers 'ares-*'
