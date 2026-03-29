# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Traefik reverse proxy setup via Docker Compose for the server at `strg-c.de` and its subdomains. TLS certificates are provisioned automatically via ACME (Let's Encrypt).

## Key Design Decisions

- Traefik is the single entry point for all HTTP/HTTPS traffic on the server
- All subdomains of `strg-c.de` are routed through Traefik
- ACME challenge handles certificate provisioning and renewal automatically
- Each service is added to Traefik via Docker labels — no manual routing config files

## Architecture

```
docker-compose.yml         # Main Traefik service definition
traefik.yml                # Static Traefik configuration (entrypoints, providers, ACME)
data/
  acme.json              # ACME certificate storage (chmod 600, not in git)
  traefik.log            # Traefik access log (optional)
```

Services that need to be exposed define Traefik labels in their own `docker-compose.yml` and join the shared `traefik` Docker network.

## Common Operations

```bash
# Start Traefik
docker compose up -d

# View logs
docker compose logs -f traefik

# Reload config (static config requires restart; dynamic config reloads automatically)
docker compose restart traefik

# Validate traefik.yml before applying
docker run --rm -v $(pwd)/traefik.yml:/traefik.yml traefik:v3 traefik --configFile=/traefik.yml --help
```

## Critical File Permissions

```bash
# acme.json must be 600 or Traefik will refuse to start
chmod 600 data/acme.json
```

## Network Setup

A shared external Docker network named `traefik` must exist:

```bash
docker network create traefik
```

All services that Traefik should route to must join this network.

## ACME / TLS Notes

- ACME resolver is named `letsencrypt` in `traefik.yml`
- HTTP challenge (`tlsChallenge` or `httpChallenge`) is used — port 80 must be reachable
- `acme.json` persists certificates across container restarts — back it up
- For wildcard certs, a DNS challenge provider must be configured

## Adding a New Service

In the service's `docker-compose.yml`:

```yaml
networks:
  - traefik

labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`sub.strg-c.de`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"

networks:
  traefik:
    external: true
```
