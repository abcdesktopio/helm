#!/usr/bin/env bash
#
# rotate-mongo-password.sh
#
# Rotates MongoDB root and pyos application user passwords, then updates the
# corresponding Kubernetes Secret so it stays in sync with what MongoDB
# actually expects.
#
# IMPORTANT: this script changes passwords INSIDE MongoDB first, then updates
# the Secret. It must never do the reverse (Secret first) or authentication
# will break until both sides match again.
#
# Required environment variables (can be exported, or passed inline):
#   NAMESPACE            Kubernetes namespace (default: abcdesktop)
#   MONGO_POD            Pod to exec into for mongosh (default: mongodb-od-0)
#   MONGO_SECRET_NAME     Secret name holding current credentials (default: secret-mongodb)
#   MONGO_PASSWORD_LENGTH Length of generated passwords (default: 24)
#   MONGO_RESTART_TARGETS Space-separated list of "kind/name" workloads to restart
#                         after rotation, e.g. "deployment/py-od-deployment"
#                         (default: deployment/py-od-deployment)
#
set -euo pipefail

NAMESPACE="${NAMESPACE:-abcdesktop}"
MONGO_POD="${MONGO_POD:-mongodb-od-0}"
MONGO_SECRET_NAME="${MONGO_SECRET_NAME:-secret-mongodb}"
MONGO_PASSWORD_LENGTH="${MONGO_PASSWORD_LENGTH:-24}"
MONGO_RESTART_TARGETS="${MONGO_RESTART_TARGETS:-deployment/py-od-deployment}"

log()  { echo -e "\033[1;34m[rotate-mongo]\033[0m $*"; }
fail() { echo -e "\033[1;31m[rotate-mongo] ERROR:\033[0m $*" >&2; exit 1; }

command -v kubectl >/dev/null 2>&1 || fail "kubectl not found in PATH"

# -----------------------------------------------------------------------------
# 0. Confirmation
# -----------------------------------------------------------------------------
echo ""
echo "This will rotate the MongoDB root and pyos passwords in namespace '${NAMESPACE}'"
echo "(pod: ${MONGO_POD}, secret: ${MONGO_SECRET_NAME})."
read -r -p "Continue? [y/N] " CONFIRM
[[ "${CONFIRM}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# -----------------------------------------------------------------------------
# 1. Read current credentials from the existing Secret
# -----------------------------------------------------------------------------
log "Reading current credentials from Secret/${MONGO_SECRET_NAME}..."

get_field() {
  kubectl get secret "${MONGO_SECRET_NAME}" -n "${NAMESPACE}" \
    -o jsonpath="{.data.$1}" | base64 -d
}

CURRENT_ROOT_USER="$(get_field MONGO_ROOT_USERNAME)"
CURRENT_ROOT_PASSWORD="$(get_field MONGO_ROOT_PASSWORD)"
CURRENT_PYOS_USER="$(get_field MONGO_USERNAME)"
MONGO_DBS_LIST="$(get_field MONGO_DBS_LIST)"

[[ -n "${CURRENT_ROOT_PASSWORD}" ]] || fail "could not read current root password from Secret"
[[ -n "${MONGO_DBS_LIST}" ]] || fail "could not read MONGO_DBS_LIST from Secret"

# -----------------------------------------------------------------------------
# 2. Generate new passwords (alphanumeric only: safe in mongodb:// URIs)
# -----------------------------------------------------------------------------
log "Generating new passwords (${MONGO_PASSWORD_LENGTH} alphanumeric chars)..."

gen_password() {
  # NOTE: `tr` receives SIGPIPE (exit 141) once `head -c` has read enough
  # bytes and closes its end of the pipe. This is expected and harmless, but
  # `pipefail` (enabled above) would otherwise propagate that 141 as the
  # exit status of this whole pipeline and abort the script under `set -e`.
  # The trailing `|| true` absorbs it: `head`'s actual output is unaffected.
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "${MONGO_PASSWORD_LENGTH}" || true
}

NEW_ROOT_PASSWORD="$(gen_password)"
NEW_PYOS_PASSWORD="$(gen_password)"

# -----------------------------------------------------------------------------
# 3. Change passwords inside MongoDB itself (source of truth)
# -----------------------------------------------------------------------------
log "Changing root password inside MongoDB..."

kubectl exec -i "${MONGO_POD}" -n "${NAMESPACE}" -- mongosh \
  -u "${CURRENT_ROOT_USER}" -p "${CURRENT_ROOT_PASSWORD}" \
  --authenticationDatabase admin --quiet \
  --eval "db.getSiblingDB('admin').changeUserPassword('${CURRENT_ROOT_USER}', '${NEW_ROOT_PASSWORD}')"

log "Changing '${CURRENT_PYOS_USER}' password on each database in MONGO_DBS_LIST..."

IFS=',' read -r -a DB_ARRAY <<< "${MONGO_DBS_LIST}"
for db in "${DB_ARRAY[@]}"; do
  log "  -> ${db}"
  kubectl exec -i "${MONGO_POD}" -n "${NAMESPACE}" -- mongosh \
    -u "${CURRENT_ROOT_USER}" -p "${NEW_ROOT_PASSWORD}" \
    --authenticationDatabase admin --quiet \
    --eval "db.getSiblingDB('${db}').changeUserPassword('${CURRENT_PYOS_USER}', '${NEW_PYOS_PASSWORD}')"
done

# -----------------------------------------------------------------------------
# 4. Update the Kubernetes Secret to match
# -----------------------------------------------------------------------------
log "Updating Secret/${MONGO_SECRET_NAME} with new values..."

NEW_USERS_LIST="${CURRENT_PYOS_USER}:readWrite:${NEW_PYOS_PASSWORD}"
NEW_MONGODB_URL="mongodb://${CURRENT_PYOS_USER}:${NEW_PYOS_PASSWORD}@mongodb"

kubectl create secret generic "${MONGO_SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --from-literal=MONGO_ROOT_USERNAME="${CURRENT_ROOT_USER}" \
  --from-literal=MONGO_ROOT_PASSWORD="${NEW_ROOT_PASSWORD}" \
  --from-literal=MONGO_USERNAME="${CURRENT_PYOS_USER}" \
  --from-literal=MONGO_PASSWORD="${NEW_PYOS_PASSWORD}" \
  --from-literal=MONGO_USERS_LIST="${NEW_USERS_LIST}" \
  --from-literal=MONGO_DBS_LIST="${MONGO_DBS_LIST}" \
  --from-literal=MONGODB_URL="${NEW_MONGODB_URL}" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Secret updated."

# -----------------------------------------------------------------------------
# 5. Restart workloads that read MONGODB_URL, so they pick up the new value
# -----------------------------------------------------------------------------
# Note: mongodb-od itself does NOT need a restart — it does not re-read
# MONGODB_URL, only its own admin/MONGO_ROOT_* credential files.
if [[ -n "${MONGO_RESTART_TARGETS}" ]]; then
  for target in ${MONGO_RESTART_TARGETS}; do
    log "Restarting ${target} to pick up the new MONGODB_URL..."
    kubectl rollout restart "${target}" -n "${NAMESPACE}" \
      || fail "failed to restart ${target} - rotate the credentials back or restart it manually"
    kubectl rollout status "${target}" -n "${NAMESPACE}" --timeout=120s
  done
else
  log "MONGO_RESTART_TARGETS is empty - no workload restarted automatically."
fi

log "Done. Root and pyos passwords have been rotated, the Secret updated, and"
log "dependent workloads restarted."