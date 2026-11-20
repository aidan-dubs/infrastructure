#!/usr/bin/env bash

NB_URL="https://net.${DOMAIN}"
AUTH_URL="https://auth.${DOMAIN}"
IDP_NAME="authentik"
ISSUER="https://auth.${DOMAIN}/application/o/netbird/"

set -euo pipefail

secrets=(
    netbird-oauth-client-secret
    netbird-oauth-client-id
    netbird-bootstrap-pass
)

for sec in "${secrets[@]}"; do
    if [ ! -f "/run/secrets/$sec" ]; then
        echo "$sec secret not setup"
        exit 1
    fi
done

response=$(
    curl --fail-with-body -sS -X POST "${NB_URL}/api/setup" \
        -H "Content-Type: application/json" \
    -d '{
            "email": "nbadmin@'"$DOMAIN"'",
            "name": "Netbird Admin",
            "password": "'"$(cat /run/secrets/netbird-bootstrap-pass)"'",
            "create_pat": true,
            "pat_expire_in": 7
        }'
)


token=$(echo "$response" | jq -r ".personal_access_token")

idps=$( curl -fsS -X GET "${NB_URL}/api/identity-providers" -H 'Accept: application/json' -H "Authorization: Token $token" )

idp_id=$(echo "$idps" | jq -r --arg name "$IDP_NAME" '.[] | select(.name == $name) | .id' | head -n1)


accounts=$(curl -s -X GET "${NB_URL}/api/accounts" \
        -H "Accept: application/json" \
    -H "Authorization: Token $token")

account_id=$(echo "$accounts" | jq -r '.[0].id')

account_settings=$(echo "$accounts" | jq '{settings: (.[0].settings |
    .extra.user_approval_required = false |
    .jwt_groups_enabled = true |
    .jwt_groups_claim_name = "groups" |
)}')

curl -X PUT "${NB_URL}/api/accounts/${account_id}" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Token $token" \
    --data-raw "$account_settings"


# if [ -n "$idp_id" ]; then
#
#     curl --fail-with-body -sS -X PUT "${NB_URL}/api/identity-providers/${idp_id}" \
    #         -H 'Accept: application/json' \
    #         -H 'Content-Type: application/json' \
    #         -H "Authorization: Token $token" \
    #     --data-raw '{
#             "type": "oidc",
#             "name": "'"$IDP_NAME"'",
#             "issuer": "'"$ISSUER"'",
#             "client_id": "'"$(cat /run/secrets/netbird-oauth-client-id)"'",
#             "client_secret": "'"$(cat /run/secrets/netbird-oauth-client-secret)"'"
#         }'
# else
#     curl --fail-with-body -sS -X POST "${NB_URL}/api/identity-providers" \
    #         -H 'Accept: application/json' \
    #         -H 'Content-Type: application/json' \
    #         -H "Authorization: Token $token" \
    #     --data-raw '{
#             "type": "oidc",
#             "name": "'"$IDP_NAME"'",
#             "issuer": "'"$ISSUER"'",
#             "client_id": "'"$(cat /run/secrets/netbird-oauth-client-id)"'",
#             "client_secret": "'"$(cat /run/secrets/netbird-oauth-client-secret)"'"
#         }'
# fi
