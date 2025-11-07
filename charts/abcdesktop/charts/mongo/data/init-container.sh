#!/bin/bash
set -euo pipefail

echo "🧩 Preparing MongoDB configuration..."
mkdir -p /work/config
cp /input/mongod.conf /work/config/mongod.conf
cp /input/mongod.keyfile /work/config/mongod.keyfile
chown -R mongodb:mongodb /work/config
chmod 700 /work/config
chmod 400 /work/config/mongod.keyfile
mkdir -p /data/db
chown -R mongodb:mongodb /data/db
mkdir -p /var/log/mongodb
touch /var/log/mongodb/mongod.log
chown -R mongodb:mongodb /var/log/mongodb
chmod 666 /var/log/mongodb/mongod.log
echo "🧩 Preparing MongoDB done..."