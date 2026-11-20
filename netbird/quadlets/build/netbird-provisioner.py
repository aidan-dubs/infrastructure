#!/usr/bin/env python3
import os
import requests
from pathlib import Path


domain = os.getenv('DOMAIN')


nb_url = f"https://net.{domain}"
auth_url = f"https://auth.{domain}"
auth_api = f"{auth_url}/api/"
idp_name = "authentik"
issuer = f"{auth_url}/application/o/netbird/"


netbird_oauth_client_secret = Path(
    "/run/secrets/netbird-oauth-client-secret").read_text(encoding="utf-8")
netbird_oauth_client_id = Path(
    "/run/secrets/netbird-oauth-client-id").read_text(encoding="utf-8")
netbird_bootstrap_pass = Path(
    "/run/secrets/netbird-bootstrap-pass").read_text(encoding="utf-8")

setup_resp = requests.post(f"{auth_api}setup", json={
    "email": f"nbadmin@{domain}",
    "name": "Netbird Admin",
    "password": netbird_bootstrap_pass,
    "create": True,
    "pat_expire_in": 7
})
