#!/usr/bin/env sh
set -eu

forgejo migrate --config /etc/forgejo/app.ini --work-path /var/lib/forgejo

forgejo--config /etc/forgejo/app.ini --work-path /var/lib/forgejo admin user create --username admin --password <PASSWORD> --email admin@example.com --admin

ID=$(forgejo admin auth list --config /etc/forgejo/app.ini | grep authentik | cut -f1)
SUBCMD=add-oauth

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
    --scopes groups \
    --admin-group "admins"
