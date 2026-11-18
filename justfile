set dotenv-load

[default]
help:
    @just --list


all: env secrets forgjeo authentik caddy

env:
    #!/usr/bin/env bash
    set -euo pipefail

    : "${DOMAIN:?DOMAIN is unset. Add it to a .env file}"

    TMPFILE=$(mktemp --suffix .conf) || exit 1
    trap 'rm -f "$TMPFILE"' EXIT

    envsubst '$DOMAIN' < ./etc/environment.d/domain.conf > $TMPFILE
    sudo install -CD -m 644 -o root -g root $TMPFILE /etc/environment.d/domain.conf

    envsubst '$DOMAIN' < ./etc/systemd/system.conf.d/domain-env.conf > $TMPFILE
    sudo install -CD -m 644 -o root -g root $TMPFILE /etc/systemd/system.conf.d/domain-env.conf

secrets:
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-gen /usr/local/bin/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-gen@.service /etc/systemd/system/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-exist /usr/local/bin/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-exists@.service /etc/systemd/system/

caddy: env
    sudo podman quadlet install --application caddy --reload-systemd --replace ./caddy/quadlets/
    sudo install -CD ./caddy/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD ./caddy/Caddyfile /etc/caddy/

forgejo: env secrets
    #!/usr/bin/env bash
    set -euo pipefail

    sudo podman quadlet install --application forgjeo --reload-systemd --replace ./forgejo/quadlets/
    TMPFILE=$(mktemp --suffix .conf) || exit 1
    trap 'rm -f "$TMPFILE"' EXIT

    envsubst '$DOMAIN' < ./forgejo/app.ini > $TMPFILE
    sudo install -CD $TMPFILE /etc/forgejo/app.ini

    sudo install -CD ./forgejo/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD ./forgejo/forge.caddy /etc/caddy/caddy.d/

authentik: env secrets
    sudo podman quadlet install --application authentik --reload-systemd --replace ./authentik/quadlets/

    sudo install -CD ./authentik/authentik.caddy /etc/caddy/caddy.d/

# forgejo-runner:
#     sudo podman quadlet install --application forgejo-runner --reload-systemd --replace ./forgejo-runner/quadlets/
#
# netbird: 
#     sudo podman quadlet install --application netbird --reload-systemd --replace ./netbird/quadlets/
#     sudo install -CD -m 755 -o root -g root ./netbird/management.json /etc/netbird/management.json
#     sudo install -CD -m 755 -o root -g root ./netbird/turnserver.conf /etc/turnserver.conf
#     sudo install -CD -m 755 -o root -g root ./netbird/netbird.caddy /etc/caddy/caddy.d/netbird.conf
