#!/usr/bin/env sh
set -eu

forgejo migrate --config /etc/forgejo/app.ini --work-path /var/lib/forgejo

ID=$(forgejo admin auth list --config /etc/forgejo/app.ini | grep authentik | cut -f1)
SUBCMD=add-oauth

forgejo forgejo-cli actions register \
    --config /etc/forgejo/app.ini \
    --work-path /var/lib/forgejo \
    --name runner \
    --seccret-file /run/secrets/forgejo-runner-token

if [ -n "$ID" ]; then
    SUBCMD="update-oauth --id $ID"
fi

forgejo admin auth $SUBCMD \
    --config /etc/forgejo/app.ini \
    --work-path /var/lib/forgejo \
    --name authentik \
    --provider openidConnect \
    --key "$(cat /run/secrets/forgejo-oauth-client-id)" \
    --secret "$(cat /run/secrets/forgejo-oauth-client-secret)" \
    --auto-discover-url "https://auth.$DOMAIN/application/o/forgejo/.well-known/openid-configuration" \
    --scopes openid \
    --scopes profile \
    --scopes email \
    --group-claim-name groups \
    --admin-group "admins"

