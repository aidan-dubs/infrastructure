#!/bin/sh
set -eu
umask 022
for f in /run/secrets/*; do
    [ -e "$f" ] || continue
    n=$(basename "$f")
    cp -L "$f" "/secrets/.$n.tmp"
    chmod 0444 "/secrets/.$n.tmp"
    mv -f "/secrets/.$n.tmp" "/secrets/$n"
done
for f in /secrets/*; do
    [ -e "$f" ] || continue
    [ -e "/run/secrets/$(basename "$f")" ] || rm -f "$f"
done
exec sleep infinity
