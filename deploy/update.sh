#!/usr/bin/env bash
set -euo pipefail

REPO="${ARES_REPO:-ares-hq/ares}"
ASSET="ares-x86_64-linux-musl.tar.gz"
STATE=/var/lib/ares/release

latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/$REPO/releases/latest")
case "$latest" in
    */releases/tag/*) tag=${latest##*/} ;;
    *) echo "$REPO has no published release" >&2; exit 1 ;;
esac

if [ "$tag" = "$(cat "$STATE" 2>/dev/null || true)" ]; then
    echo "already on $tag"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/$ASSET" "https://github.com/$REPO/releases/download/$tag/$ASSET"
tar -xzf "$tmp/$ASSET" -C "$tmp"
(cd "$tmp" && sha256sum -c SHA256SUMS --quiet)

for bin in ares-bot ares-db; do
    install -m 755 "$tmp/$bin" "/usr/local/bin/.$bin.new"
    mv -f "/usr/local/bin/.$bin.new" "/usr/local/bin/$bin"
done
install -d -m 755 -o ares -g ares /var/lib/ares
printf '%s\n' "$tag" > "$STATE"

systemctl restart ares-bot.service
echo "installed $tag"
