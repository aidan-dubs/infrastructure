# Infrastructure

This repo is how I deploy most of my self-hosted services. I run as many things as possible rootless
podman quadlets. I have a single Dell Poweredge r730 running a Fedora IoT edition.
<!-- image built using [aidanlw505/os-images](https://github.com/aidanlw505/os-images). -->

## Todo

**Main Sevices**

- [x] Caddy
- [x] Authentik
- [x] NetBird
- [x] Forgejo
  - [ ] Forgejo Runner
- [ ] Homarr
- [ ] Smallstep
- [ ] Syncthing
- [X] OpenWebui
  - [X] Olla
  - [X] Ollama
  - [X] Terminal
- [ ] Mail
- [ ] Jellyfin
- [ ] Immich

**Features part of each service**

- [ ] Auto update timer
- [ ] Easy SSO setup with Authentik
- [ ] Easy secret generation and tracking
