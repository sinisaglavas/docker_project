.PHONY: dev deploy stop clean

# Pokretanje lokalnog DEV okruženja (bez VM)
dev: clean
	@echo "Pokrećem DEV okruženje..."
	docker compose -f compose.dev.yaml up -d --build
	@echo "Aplikacija je dostupna na http://localhost:8099"

# Pokretanje DEPLOY okruženja (za VM / DockerHub)
deploy: clean
	@echo "Pokrećem DEPLOY okruženje..."
	docker compose -f compose.deploy.yaml up -d
	@echo "Deploy uspešno pokrenut!"

# Gašenje svih kontejnera i čišćenje zaostalih mreža
stop:
	@echo "Gasim sva aktivna okruženja..."
	-docker compose -f compose.dev.yaml down --remove-orphans
	-docker compose -f compose.deploy.yaml down --remove-orphans

# Čišćenje Laravel keša i popravka dozvola (Rešava HTTP 500 grešku)
clean: stop
	@echo "Čistim Laravel keš i logove, podešavam dozvole..."
	-sudo rm -rf bootstrap/cache/*.php storage/framework/views/*.php storage/logs/*.log
	-mkdir -p storage/logs && touch storage/logs/laravel.log
	-sudo chmod -R 777 storage bootstrap/cache
