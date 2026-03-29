.PHONY: up down logs restart gen-password network

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f traefik

restart:
	docker compose restart traefik

gen-password:
	@echo "Enter username (default: admin):"
	@read USER; USER=$${USER:-admin}; \
	htpasswd -nB $$USER | sed 's/\$$/\$\$\$\$/g' | \
	xargs -I{} echo "Add to .env: DASHBOARD_USERS={}"

network:
	docker network inspect traefik >/dev/null 2>&1 || docker network create traefik
