# Demo API — Stack Docker Compose

Stack complète conteneurisée comprenant une API Node.js (`demo-api`), une base de données PostgreSQL 16 (`db`) et une interface d'administration de base de données (`adminer`), orchestrée via Docker Compose.

## Prérequis

- **Docker Engine** & **Docker Compose** (v2+)
- Environnement Linux / WSL2

## Installation et configuration

1. **Cloner le dépôt :**
   ```bash
   git clone <URL_DE_TON_REPO_GITHUB>
   cd BRANCOURT_dimitri_demo-api
   ```

2. **Configurer les variables d'environnement :**
   ```bash
   cp .env.example .env
   ```

3. **Configurer le secret du mot de passe de la base de données (Docker Secrets) :**
   ```bash
   mkdir -p secrets
   echo -n "demo" > secrets/db_password.txt
   ```

## Démarrage de la stack

Pour construire l'image de l'API et démarrer l'ensemble des services en arrière-plan :

```bash
docker compose up -d --build
```

## Services et URLs disponibles

| Service | URL locale | Description |
| :--- | :--- | :--- |
| **API (`/health`)** | `http://localhost:8080/health` | Vérification de santé de l'API |
| **API (`/products`)** | `http://localhost:8080/products` | Liste et création des produits (GET / POST) |
| **Adminer** | `http://localhost:8081` | Interface web SQL (Système: `PostgreSQL`, Serveur: `db`, Utilisateur: `demo`, Mot de passe: `demo`, Base: `demo`) |
| **PostgreSQL** | *Non exposé sur l'hôte* | Isolé uniquement sur le réseau interne `back` |

## Vérifications et preuves de fonctionnement

### État des services (`docker compose ps`)

Commande exécutée :
```bash
docker compose ps
```

Extrait de sortie montrant `db` à l'état `healthy` et `api` à l'état `Up` :
```text
NAME           IMAGE                COMMAND                  SERVICE   CREATED         STATUS                   PORTS
demo-adminer   adminer:4            "entrypoint.sh docke…"   adminer   3 minutes ago   Up 3 minutes             0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp
demo-api       demo-api:1.0         "docker-entrypoint.s…"   api       3 minutes ago   Up 3 minutes (healthy)   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp
demo-db        postgres:16-alpine   "docker-entrypoint.s…"   db        3 minutes ago   Up 3 minutes (healthy)   5432/tcp
```

### Test des endpoints et de la persistance

```bash
# Lecture des produits initiaux
curl -s localhost:8080/products

# Ajout d'un nouveau produit
curl -s -X POST -H 'content-type: application/json' \
  -d '{"name":"Gourde","price_cents":900}' localhost:8080/products

# Arrêt et redémarrage de la stack (le volume pgdata conserve "Gourde")
docker compose down
docker compose up -d
curl -s localhost:8080/products
```

## Arrêt et remise à zéro

- **Arrêter les conteneurs (en conservant les données SQL) :**
  ```bash
  docker compose down
  ```

- **Repartir de zéro (supprimer les conteneurs, réseaux ET le volume de données `pgdata`) :**
  ```bash
  docker compose down -v
  ```