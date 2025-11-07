#!/bin/bash
set -euo pipefail

# --- Variables ---
NAMESPACE="${NAMESPACE:-database-v3}"
SERVICE="${SERVICE:-mongodb-service}"
STATEFULSET_NAME="${STATEFULSET_NAME:-mongodb-dev-statefulset}"
REPLICAS="${REPLICAS:-3}"   # 🆕 Nombre de réplicas à ajuster dynamiquement
MONGO_USER="${MONGO_INITDB_ROOT_USERNAME:-admin}"
MONGO_PASSWORD="${MONGO_INITDB_ROOT_PASSWORD:-veryStrongPassword}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"

# --- Construire dynamiquement la liste des hôtes ---
HOSTS=()
for i in $(seq 0 $((REPLICAS - 1))); do
    HOSTS+=("${STATEFULSET_NAME}-${i}.${SERVICE}.${NAMESPACE}.svc.cluster.local:27017")
done
PRIMARY="${HOSTS[0]}"

echo "📡 Configured hosts:"
printf ' - %s\n' "${HOSTS[@]}"

# --- Attente que les nœuds soient prêts ---
echo "⏳ Waiting for MongoDB nodes to be reachable..."
for host in "${HOSTS[@]}"; do
    until mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
            --authenticationDatabase "$MONGO_AUTH_DB" \
            --host "$host" --quiet \
            --eval 'db.adminCommand({ping:1})' >/dev/null 2>&1; do
    echo "... $host not ready yet ..."
    sleep 2
    done
done
echo "✅ All nodes respond to ping."

# --- Vérifier si le ReplicaSet est déjà initialisé ---
RS_OK=$(mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
        --authenticationDatabase "$MONGO_AUTH_DB" \
        --host "$PRIMARY" --quiet \
        --eval 'rs.status().ok' || echo "0")

if [ "$RS_OK" != "1" ]; then
    echo "🆕 Initializing replica set..."

    # Générer la configuration JSON pour rs.initiate()
    CONFIG="{ _id: 'rs0', members: ["
    for i in "${!HOSTS[@]}"; do
    CONFIG="${CONFIG}{ _id: ${i}, host: '${HOSTS[$i]}' }"
    if [ "$i" -lt "$((REPLICAS - 1))" ]; then
        CONFIG="${CONFIG}, "
    fi
    done
    CONFIG="${CONFIG}] }"

    mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
            --authenticationDatabase "$MONGO_AUTH_DB" \
            --host "$PRIMARY" --quiet \
            --eval "rs.initiate(${CONFIG}); print('✅ Replica set initialized successfully');"

    echo "⏳ Waiting for PRIMARY election..."
    for i in $(seq 1 60); do
    STATE=$(mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
                    --authenticationDatabase "$MONGO_AUTH_DB" \
                    --host "$PRIMARY" --quiet \
                    --eval 'rs.status().members.filter(m=>m.self)[0].stateStr' || echo "")
    if [ "$STATE" == "PRIMARY" ]; then
        echo "✅ Primary elected"
        break
    fi
    sleep 2
    done
else
    echo "✅ Replica set already initialized."
fi

# --- Création du root user si manquant ---
USER_EXISTS=$(mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
                    --authenticationDatabase "$MONGO_AUTH_DB" \
                    --host "$PRIMARY" --quiet \
                    --eval "db.getUser('$MONGO_USER')" || echo "")

if [ -z "$USER_EXISTS" ]; then
    echo "👤 Creating root user: $MONGO_USER"
    mongosh --host "$PRIMARY" --quiet <<EOF
use admin
db.createUser({
    user: "$MONGO_USER",
    pwd: "$MONGO_PASSWORD",
    roles: [{ role: "root", db: "admin" }]
})
EOF
    echo "✅ Root user created successfully"
fi

echo "🎉 MongoDB replica set is ready"
