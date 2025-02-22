docker compose -f docker-compose/compose.yml down

docker compose -f docker-compose/compose.yml up -d --force-recreate --build

# docker compose -f docker-compose/compose.yml up -d --build key-server
