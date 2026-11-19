set dotenv-load

user  := "containers"
count := "65536"

help:
    @just --list


[default]
all: caddy restart reload

tmpfiles:
    sudo systemd-tmpfiles --dry-run --create
    sudo systemd-tmpfiles --create

restart: tmpfiles
    sudo systemctl restart authentik

reload: tmpfiles
    sudo systemctl reload caddy

containers-user:
    #!/usr/bin/env bash

    RANGE="1000000:1048576"
    POD_USER=containers

    if ! id -u "${POD_USER}" &>/dev/null; then
        useradd --create-home --shell /usr/sbin/nologin "${POD_USER}"
        echo "created user '${POD_USER}'"
    fi

    if grep -qE "^${POD_USER}:" "/etc/subgid"; then
        sed "s/${POD_USER}:[[:digit:]]*:[[:digit:]]*$/${POD_USER}:${RANGE}/" /etc/subgid
    else
        echo "${POD_USER}:${RANGE}" >> /etc/subgid
    fi

    if grep -qE "^${POD_USER}:" "/etc/subuid"; then
        sed "s/${POD_USER}:[[:digit:]]*:[[:digit:]]*$/${POD_USER}:${RANGE}/" /etc/subuid
    else
        echo "${POD_USER}:${RANGE}" >> /etc/subuid
    fi

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

setup: env containers-user secrets

caddy: setup
    sudo podman quadlet install --application caddy --reload-systemd --replace ./caddy/quadlets/
    sudo install -CD ./caddy/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD ./caddy/Caddyfile /etc/caddy/

forgejo: setup
    #!/usr/bin/env bash
    set -euo pipefail

    sudo podman quadlet install --application forgjeo --reload-systemd --replace ./forgejo/quadlets/
    TMPFILE=$(mktemp --suffix .conf) || exit 1
    trap 'rm -f "$TMPFILE"' EXIT

    envsubst '$DOMAIN' < ./forgejo/app.ini > $TMPFILE
    sudo install -CD $TMPFILE /etc/forgejo/app.ini

    sudo install -CD ./forgejo/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD ./forgejo/forge.caddy /etc/caddy/caddy.d/

authentik: setup
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
