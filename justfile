set dotenv-load

help:
    @just --list


[default]
all: core forgejo netbird restart reload

selinux:
    #!/usr/bin/env bash

    set -euo pipefail

    for file in /etc/custom-selinux/*.mods; do
        sudo semanage import -f "$file"
    done

tmpfiles:
    sudo systemd-tmpfiles --create --prefix=/var --prefix=/etc

core-tmpfiles:
    sudo systemd-tmpfiles --create --prefix=/var --prefix=/etc

daemon-reload:
    sudo systemctl daemon-reload


post: tmpfiles selinux daemon-reload

restart: post
    sudo systemctl restart authentik.target forgejo netbird-server netbird-dashboard

reload: post
    sudo systemctl reload caddy

containers-user:
    #!/usr/bin/env bash

    set -euo pipefail

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

    envsubst '$DOMAIN' < ./common/environment.d/domain.conf > $TMPFILE
    sudo install -CD -m 644 -o root -g root $TMPFILE /etc/environment.d/domain.conf

    envsubst '$DOMAIN' < ./common/systemd/system.conf.d/domain-env.conf > $TMPFILE
    sudo install -CD -m 644 -o root -g root $TMPFILE /etc/systemd/system.conf.d/domain-env.conf

    sudo install -CD -m 644 -o root -g root ./common/containers/systemd/container.d/10-domain.conf /etc/containers/systemd/container.d/10-domain.conf
    sudo install -CD -m 644 -o root -g root ./common/containers/systemd/container.d/10-domain.conf /etc/containers/systemd/users/container.d/10-domain.conf

secrets:
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-gen /usr/local/bin/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-gen@.service /etc/systemd/system/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-exist /usr/local/bin/
    sudo install -CD -m 755 -o root -g root ./secrets/podman-secret-exists@.service /etc/systemd/system/

common: 
    sudo install -CD -m 755 -o root -g root ./common/tmpfiles.d/* /etc/tmpfiles.d/
    sudo systemd-tmpfiles --create --prefix=/var --prefix=/etc

setup: common env containers-user secrets

core: caddy authentik core-tmpfiles

caddy: setup
    sudo rm -rf /etc/containers/systemd/caddy/

    sudo podman quadlet install --application caddy --reload-systemd --replace ./caddy/quadlets/


    sudo install -CD -m 755 -o root -g root ./caddy/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD -m 755 -o root -g root ./caddy/Caddyfile /etc/caddy/
    sudo install -CD -m 755 -o root -g root ./caddy/selinux/caddy.mods /etc/custom-selinux/

authentik: setup
    sudo install -CD ./authentik/systemd/system/authentik.target /etc/systemd/system/

    sudo rm -rf /etc/containers/systemd/authentik/

    sudo podman quadlet install --application authentik --reload-systemd --replace ./authentik/quadlets/

    sudo install -CD ./authentik/authentik.caddy /etc/caddy/caddy.d/
    sudo install -CD -m 755 -o root -g root ./authentik/tmpfiles.d/* /etc/tmpfiles.d/


forgejo: core
    #!/usr/bin/env bash
    set -euo pipefail

    sudo podman quadlet install --application forgjeo --reload-systemd --replace ./forgejo/quadlets/

    TMPFILE=$(mktemp --suffix .conf) || exit 1
    trap 'rm -f "$TMPFILE"' EXIT

    envsubst '$DOMAIN' < ./forgejo/app.ini > $TMPFILE
    sudo install -CD $TMPFILE /etc/forgejo/app.ini

    sudo install -CD ./forgejo/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD ./forgejo/forge.caddy /etc/caddy/caddy.d/
    sudo install -CD -m 755 -o root -g root ./forgejo/selinux/forgejo.mods /etc/custom-selinux/
    sudo install -CD -m 755 -o root -g root ./forgejo/authentik/forgejo.yaml /etc/authentik/blueprints/
    sudo install -CD -m 755 -o root -g root ./forgejo/authentik/forgejo-secret.conf /etc/containers/systemd/authentik/auth-secrets.container.d/

netbird: core
    #!/usr/bin/env bash
    set -euo pipefail

    sudo podman quadlet install --application netbird --reload-systemd --replace ./netbird/quadlets/

    TMPFILE=$(mktemp --suffix .conf) || exit 1
    trap 'rm -f "$TMPFILE"' EXIT

    envsubst '$DOMAIN' < ./netbird/config.yaml > $TMPFILE
    sudo install -CD -m 755 -o root -g root $TMPFILE /etc/netbird/config.yaml

    sudo install -CD ./netbird/netbird.caddy /etc/caddy/caddy.d/
    sudo install -CD ./netbird/tmpfiles.d/* /etc/tmpfiles.d/
    sudo install -CD -m 755 -o root -g root ./netbird/authentik/netbird.yaml /etc/authentik/blueprints/
    sudo install -CD -m 755 -o root -g root ./netbird/authentik/netbird-secret.conf /etc/containers/systemd/authentik/auth-secrets.container.d/


netbird-reset: netbird
    sudo systemctl stop netbird-server netbird-dashboard netbird-provisioner
    sudo podman volume rm netbird-data netbird-pat
    sudo systemctl start netbird-server netbird-dashboard 
    sleep 20
    sudo systemctl restart netbird-provisioner-build netbird-provisioner

print-secrets:
    #!/usr/bin/env bash
    echo "Netbird bootstrap:"
    sudo podman secret inspect --showsecret --format "{{{{.SecretData}}}}" netbird-bootstrap-pass
    echo "Authentik bootstrap:"
    sudo podman secret inspect --showsecret --format "{{{{.SecretData}}}}" AUTHENTIK_BOOTSTRAP_PASSWORD

# forgejo-runner:
#     sudo podman quadlet install --application forgejo-runner --reload-systemd --replace ./forgejo-runner/quadlets/
#
