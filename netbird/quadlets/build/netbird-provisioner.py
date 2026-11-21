#!/usr/bin/env python3
import os
import requests
from pathlib import Path
import time


domain = os.getenv('DOMAIN')


nb_url = f"https://net.{domain}"
nb_api = f"{nb_url}/api"
auth_url = f"https://auth.{domain}"
idp_name = "authentik"
issuer = f"{auth_url}/application/o/netbird/"


netbird_oauth_client_secret = Path(
    "/run/secrets/netbird-oauth-client-secret").read_text(encoding="utf-8")
netbird_oauth_client_id = Path(
    "/run/secrets/netbird-oauth-client-id").read_text(encoding="utf-8")
netbird_bootstrap_pass = Path(
    "/run/secrets/netbird-bootstrap-pass").read_text(encoding="utf-8")

token_file = Path("/pat/token")
token = ""

start = time.monotonic()

while time.monotonic() - start < 30:
    try:
        response = requests.get(nb_api)
        if response.status_code in [404, 401] or response.status_code < 400:
            break

    except requests.exceptions.RequestException:
        pass
    print("waiting for api")
    time.sleep(5)

if not token_file.is_file() or not token_file.read_text().strip():
    setup_resp = requests.post(f"{nb_api}/setup", json={
        "email": f"nbadmin@{domain}",
        "name": "Netbird Admin",
        "password": netbird_bootstrap_pass,
        "create_pat": True,
        "pat_expire_in": 7
    })

    print(setup_resp.request)

    print(setup_resp.status_code, setup_resp.text, flush=True)
    setup_resp.raise_for_status()

    setup_json = setup_resp.json()
    token = setup_json.get("personal_access_token")
    if not token:
        raise RuntimeError(f"No PAT in setup response: {setup_json}")

    token_file.write_text(token)

else:
    token = token_file.read_text().strip()

headers = {
    "Accept": "application/json",
    "Authorization": f"Token {token}",
}

print("Getting identity-providers")

idps_r = requests.get(f"{nb_api}/identity-providers", headers=headers)


idps_j = idps_r.json()

idp_id = next(
    (item["id"] for item in idps_j if item.get("name") == idp_name),
    None,
)

print("Getting accounts")
accounts_r = requests.get(f"{nb_api}/accounts", headers=headers)

accounts_j = accounts_r.json()


account_id = accounts_j[0]["id"]


print("Getting account settings")
account_settings = accounts_j[0]["settings"]

if not account_settings.get("extra"):
    account_settings["extra"] = {}

account_settings["extra"]["user_approval_required"] = False
account_settings["jwt_groups_enabled"] = True
account_settings["jwt_groups_claim_name"] = "groups"
account_settings["dns_domain"] = f"n.{domain}"

print("Setting account settings")
settings_r = requests.put(f"{nb_api}/accounts/{account_id}",
                          headers=headers, json={"settings": account_settings})

print(settings_r.status_code, settings_r.text)
settings_r.raise_for_status()

authentik_provider = {
    "type": "oidc",
    "name": idp_name,
    "issuer": issuer,
    "client_id": netbird_oauth_client_id,
    "client_secret": netbird_oauth_client_secret
}


if idp_id is not None:
    print("Updating identity-providers")
    requests.put(f"{nb_api}/identity-providers",
                 headers=headers, json=authentik_provider)
else:
    print("Creating identity-provider")
    requests.post(f"{nb_api}/identity-providers",
                  headers=headers, json=authentik_provider)


users_r = requests.get(f"{nb_api}/users", headers=headers)

users_j = users_r.json()


for user in users_j:
    if user["role"] != "admin":
        requests.put(
            f"{nb_api}/users/{user['id']}",
            headers=headers,
            json={"role": "admin"}).raise_for_status()
