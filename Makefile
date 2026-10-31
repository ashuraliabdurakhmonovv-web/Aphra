.PHONY: up down logs backend-test mobile-test admin-build

up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

backend-test:
	cd apps/backend && pytest

mobile-test:
	cd apps/mobile && flutter test

admin-build:
	cd apps/admin && npm run build

