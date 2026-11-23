set dotenv-load
set unstable

mod authentik
mod caddy
mod common
mod forgejo
mod homarr
mod netbird
mod open-webui
mod openproject
mod openspeedtest
mod secrets

help:
    @just --list

[default]
all: secrets::install authentik::install caddy::install netbird::install openspeedtest::install  forgejo::install open-webui::install openproject::install homarr::install common::post

regen-mods:
    for d in */; do [ -f "$d/justfile" ] && echo "mod ${d%/}"; done > mods.just

print-secrets:
    #!/usr/bin/env bash
    echo "Netbird bootstrap:"
    sudo podman secret inspect --showsecret --format "{{{{.SecretData}}}}" netbird-bootstrap-pass
    echo "Authentik bootstrap:"
    sudo podman secret inspect --showsecret --format "{{{{.SecretData}}}}" AUTHENTIK_BOOTSTRAP_PASSWORD
    echo "Openproject bootstrap:"
    sudo podman secret inspect --showsecret --format "{{{{.SecretData}}}}" openproject-bootstrap-pass

lint-just:
    find . -type f \( -iname 'justfile' -o -iname '.justfile' -o -iname '*.just' \) -print0 | xargs -0 -n1 just --fmt --check --justfile

fmt-just:
    find . -type f \( -iname 'justfile' -o -iname '.justfile' -o -iname '*.just' \) -print0 | xargs -0 -n1 just --fmt --justfile
