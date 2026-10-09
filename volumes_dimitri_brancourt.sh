#!/bin/bash
set -e

echo "--- 0. Nettoyage initial (au cas où) ---"
docker rm -f api demo-db 2>/dev/null || true
docker network rm demo_net 2>/dev/null || true

echo "--- 1. Build de l'image de l'API ---"
docker build -t demo-api:1.0 ./api

echo "--- Création du réseau ---"
docker network create demo_net || true

echo "--- 2. Création du volume nommé ---"
docker volume create demo_pgdata

echo "--- 3. Lancement du conteneur demo-db ---"
docker run -d --name demo-db \
  --network demo_net \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

echo "--- 4. Attente de la base de données ---"
until docker exec demo-db pg_isready -U demo; do
  echo "En attente de PostgreSQL..."
  sleep 2
done
sleep 2 

echo "--- 5. Lancement du conteneur API ---"
docker run -d --name api \
  --network demo_net \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  demo-api:1.0

echo "Attente du démarrage de l'API..."
sleep 3

echo "--- 6. Ajout d'un produit ---"
curl -s -X POST -H 'content-type: application/json' \
  -d '{"name":"Casquette Démo","price_cents":1200}' localhost:8080/products
echo -e "\n"

echo "--- 7. Suppression et recréation de demo-db ---"
docker rm -f demo-db

docker run -d --name demo-db \
  --network demo_net \
  -v demo_pgdata:/var/lib/postgresql/data \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

until docker exec demo-db pg_isready -U demo; do
  echo "En attente de PostgreSQL (après recréation)..."
  sleep 2
done

echo "--- Relance de l'API pour reconnecter la DB ---"
docker rm -f api
docker run -d --name api \
  --network demo_net \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  demo-api:1.0

sleep 3

echo "--- 8. Vérifications finales ---"
echo "> Volume Docker :"
docker volume ls | grep demo_pgdata
echo "> Liste des produits (API) :"
curl -s localhost:8080/products
echo ""
