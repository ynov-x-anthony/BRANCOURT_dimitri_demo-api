#!/bin/bash

docker rm -f demo-api demo-db api 2>/dev/null || true
docker network rm demo_front demo_back 2>/dev/null || true

docker build -t demo-api:1.0 ./api

docker network create demo_front
docker network create demo_back

docker run -d --name demo-db \
  --network demo_back \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

until docker exec demo-db pg_isready -U demo > /dev/null 2>&1; do
  sleep 2
done
sleep 2

docker run -d --name demo-api \
  --network demo_back \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

# Connexion au second réseau
docker network connect demo_front demo-api

sleep 3

echo -e "\n================ VÉRIFICATIONS ================"

echo -e "\n[1] Résolution DNS de demo-db depuis demo-api :"
docker exec demo-api getent hosts demo-db

echo -e "\n[2] Test d'isolation depuis un conteneur tiers sur demo_front (échec attendu) :"
docker run --rm --network demo_front alpine nc -zv demo-db 5432 || echo "-> Isolation confirmée : demo-db est injoignable depuis demo_front."

echo -e "\n[3] Adresses IPv4 par réseau :"
echo "Conteneur demo-db :"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAMConfig}} {{.IPAddress}}{{"\n"}}{{end}}' demo-db
echo "Conteneur demo-api :"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAMConfig}} {{.IPAddress}}{{"\n"}}{{end}}' demo-api

echo -e "[4] Test HTTP sur localhost:8080/products :"
curl -s localhost:8080/products
echo -e "\n===============================================\n"

echo "--- 5. Nettoyage final ---"
docker rm -f demo-api demo-db
docker network rm demo_front demo_back
