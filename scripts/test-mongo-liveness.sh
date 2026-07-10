#!/usr/bin/env bash
#
# test-mongo-liveness.sh
#
# Verifies that the mongodb livenessProbe actually triggers a container
# restart when it fails, by temporarily forcing the probe command to fail
# ("exit 1"), watching the restart count, then restoring the original
# StatefulSet definition.
#
# To keep the test fast and unambiguous, the StatefulSet is temporarily
# scaled down to 1 replica (only mongodb-od-0 is affected) before the probe
# is broken, then scaled back up to its original replica count during
# restoration.
#
# WARNING: this test forces the mongodb-od-0 container to be recreated.
# If mongo.persistence.enabled is false (the chart default), MongoDB data
# lives in an emptyDir and WILL BE LOST when the container restarts.
#
# Required tools: kubectl, helm, jq
#
set -uo pipefail   # NOTE: no `-e` here on purpose - see restore() below.

NAMESPACE="${NAMESPACE:-abcdesktop}"
RELEASE="${RELEASE:-abcdesktop}"
LOCAL_CHART="${LOCAL_CHART:-./charts/abcdesktop}"
VALUES="${VALUES:--f values.yaml}"
STATEFULSET="${STATEFULSET:-mongodb-od}"
MONGO_POD="${MONGO_POD:-mongodb-od-0}"
MONGO_CONTAINER="${MONGO_CONTAINER:-mongodb}"
LIVENESS_TEST_TIMEOUT="${LIVENESS_TEST_TIMEOUT:-180}"
POLL_INTERVAL=5

log()  { echo -e "\033[1;34m[test-liveness]\033[0m $*"; }
warn() { echo -e "\033[1;33m[test-liveness] WARNING:\033[0m $*"; }
fail() { echo -e "\033[1;31m[test-liveness] FAIL:\033[0m $*" >&2; }

command -v kubectl >/dev/null 2>&1 || { fail "kubectl not found in PATH"; exit 1; }
command -v helm    >/dev/null 2>&1 || { fail "helm not found in PATH"; exit 1; }
command -v jq      >/dev/null 2>&1 || { fail "jq not found in PATH"; exit 1; }

ORIGINAL_PROBE_CMD=""
ORIGINAL_REPLICAS=""
RESTORED=0

# -----------------------------------------------------------------------------
# Restore: best-effort, every step runs regardless of earlier failures.
# Step A (fast path, no Helm involved) is the one that actually guarantees a
# working probe again. Step B (Helm) is a "nice to have" full reconciliation.
# -----------------------------------------------------------------------------
restore() {
  if [[ "${RESTORED}" -eq 1 ]]; then
    return
  fi
  RESTORED=1
  echo ""
  log "--- Restoring original state ---"

  # Step A: put the original liveness probe command back, directly.
  if [[ -n "${ORIGINAL_PROBE_CMD}" ]]; then
    log "Step A: restoring the original livenessProbe command via kubectl patch..."
    local restore_patch_file
    restore_patch_file="$(mktemp)"
    cat > "${restore_patch_file}" <<EOF
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe/exec/command",
    "value": ${ORIGINAL_PROBE_CMD}
  }
]
EOF
    if kubectl patch statefulset "${STATEFULSET}" -n "${NAMESPACE}" \
      --type=json --patch-file "${restore_patch_file}"; then
      log "Step A: OK - livenessProbe command restored."
    else
      fail "Step A: kubectl patch failed - the probe may still be broken!"
      fail "Manual fix: re-run 'helm upgrade --install ${RELEASE} ${LOCAL_CHART} -n ${NAMESPACE} ${VALUES}'"
    fi
    rm -f "${restore_patch_file}"
  else
    warn "Step A: no original probe command was captured - skipping direct restore."
  fi

  # Scale back up to the original replica count, if it was reduced.
  if [[ -n "${ORIGINAL_REPLICAS}" && "${ORIGINAL_REPLICAS}" -gt 1 ]]; then
    log "Scaling ${STATEFULSET} back up to ${ORIGINAL_REPLICAS} replicas..."
    kubectl scale statefulset "${STATEFULSET}" -n "${NAMESPACE}" --replicas="${ORIGINAL_REPLICAS}" \
      || fail "Could not scale back to ${ORIGINAL_REPLICAS} replicas - please do it manually."
  fi

  # Step B: best-effort full reconciliation via Helm. --force replaces the
  # resource instead of patching it, which avoids field-manager ownership
  # conflicts left over from our kubectl patch calls above.
  log "Step B: reconciling the full chart state via 'helm upgrade --force' (best effort)..."
  # shellcheck disable=SC2086
  if helm upgrade --install "${RELEASE}" "${LOCAL_CHART}" \
      --namespace "${NAMESPACE}" ${VALUES} --force >/dev/null 2>&1; then
    log "Step B: OK - helm upgrade succeeded."
  else
    warn "Step B: 'helm upgrade --force' failed. This is NOT necessarily critical:"
    warn "the actual liveness probe was already restored directly in Step A."
    warn "Run 'helm upgrade --install ${RELEASE} ${LOCAL_CHART} -n ${NAMESPACE} ${VALUES}' manually to confirm drift is resolved."
  fi

  kubectl rollout status statefulset/"${STATEFULSET}" -n "${NAMESPACE}" --timeout=180s || true
  log "--- Restore sequence finished ---"
}
trap restore EXIT

# -----------------------------------------------------------------------------
# 0. Persistence check + confirmation
# -----------------------------------------------------------------------------
PERSISTENCE_ENABLED="$(helm get values "${RELEASE}" -n "${NAMESPACE}" -a -o json 2>/dev/null \
  | jq -r '.mongo.persistence.enabled // false')"

echo ""
if [[ "${PERSISTENCE_ENABLED}" != "true" ]]; then
  warn "mongo.persistence.enabled does not appear to be 'true'."
  warn "MongoDB data likely lives in an emptyDir and WILL BE LOST when the"
  warn "container restarts during this test."
fi
echo "This test will temporarily:"
echo "  1. scale ${STATEFULSET} down to 1 replica (only ${MONGO_POD} remains),"
echo "  2. break its liveness probe to verify Kubernetes restarts it,"
echo "  3. restore the original probe and scale back up."
read -r -p "Continue? [y/N] " CONFIRM
[[ "${CONFIRM}" =~ ^[Yy]$ ]] || { echo "Aborted."; trap - EXIT; exit 0; }

# -----------------------------------------------------------------------------
# 1. Capture original state (needed for a reliable restore)
# -----------------------------------------------------------------------------
log "Capturing original livenessProbe command and replica count..."
ORIGINAL_PROBE_CMD="$(kubectl get statefulset "${STATEFULSET}" -n "${NAMESPACE}" -o json \
  | jq -c '.spec.template.spec.containers[0].livenessProbe.exec.command')"
ORIGINAL_REPLICAS="$(kubectl get statefulset "${STATEFULSET}" -n "${NAMESPACE}" -o json \
  | jq -r '.spec.replicas')"

if [[ -z "${ORIGINAL_PROBE_CMD}" || "${ORIGINAL_PROBE_CMD}" == "null" ]]; then
  fail "Could not read the current livenessProbe command - aborting before touching anything."
  trap - EXIT
  exit 1
fi
log "Original replicas: ${ORIGINAL_REPLICAS}"

# -----------------------------------------------------------------------------
# 2. Isolate mongodb-od-0: scale down to 1 replica if needed
# -----------------------------------------------------------------------------
if [[ "${ORIGINAL_REPLICAS}" -gt 1 ]]; then
  log "Scaling ${STATEFULSET} down to 1 replica to isolate ${MONGO_POD}..."
  kubectl scale statefulset "${STATEFULSET}" -n "${NAMESPACE}" --replicas=1
  log "Waiting for scale-down to complete..."
  ELAPSED=0
  while [[ "${ELAPSED}" -lt 120 ]]; do
    COUNT="$(kubectl get pods -n "${NAMESPACE}" -l run=mongodb-od --no-headers 2>/dev/null | wc -l)"
    [[ "${COUNT}" -eq 1 ]] && break
    sleep 5
    ELAPSED=$((ELAPSED + 5))
  done
  log "Scale-down done (${COUNT:-?} pod(s) remaining)."
fi

# -----------------------------------------------------------------------------
# 3. Baseline restart count
# -----------------------------------------------------------------------------
log "Reading baseline restart count for container '${MONGO_CONTAINER}'..."
BASELINE_RESTARTS="$(kubectl get pod "${MONGO_POD}" -n "${NAMESPACE}" \
  -o jsonpath="{.status.containerStatuses[?(@.name=='${MONGO_CONTAINER}')].restartCount}")"
log "Baseline restarts: ${BASELINE_RESTARTS}"

# -----------------------------------------------------------------------------
# 4. Inject a guaranteed-failing liveness probe
# -----------------------------------------------------------------------------
log "Patching StatefulSet/${STATEFULSET} with a failing liveness probe (exit 1)..."
PATCH_FILE="$(mktemp)"
cat > "${PATCH_FILE}" <<'EOF'
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe/exec/command",
    "value": ["sh", "-c", "exit 1"]
  }
]
EOF
kubectl patch statefulset "${STATEFULSET}" -n "${NAMESPACE}" \
  --type=json --patch-file "${PATCH_FILE}"
rm -f "${PATCH_FILE}"

log "Waiting for ${MONGO_POD} to be recreated with the broken probe..."
kubectl wait --for=condition=Ready pod/"${MONGO_POD}" -n "${NAMESPACE}" --timeout=90s || true

# -----------------------------------------------------------------------------
# 5. Wait for the kubelet to detect the failure and restart the container
# -----------------------------------------------------------------------------
log "Waiting up to ${LIVENESS_TEST_TIMEOUT}s for the container to be restarted..."
ELAPSED=0
DETECTED=0
CURRENT_RESTARTS="${BASELINE_RESTARTS}"

while [[ "${ELAPSED}" -lt "${LIVENESS_TEST_TIMEOUT}" ]]; do
  CURRENT_RESTARTS="$(kubectl get pod "${MONGO_POD}" -n "${NAMESPACE}" \
    -o jsonpath="{.status.containerStatuses[?(@.name=='${MONGO_CONTAINER}')].restartCount}" \
    2>/dev/null || echo "${BASELINE_RESTARTS}")"
  if [[ "${CURRENT_RESTARTS}" -gt "${BASELINE_RESTARTS}" ]]; then
    DETECTED=1
    break
  fi
  sleep "${POLL_INTERVAL}"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
  log "  ...${ELAPSED}s elapsed, restarts still at ${CURRENT_RESTARTS}"
done

echo ""
if [[ "${DETECTED}" -eq 1 ]]; then
  log "PASS: restart count went from ${BASELINE_RESTARTS} to ${CURRENT_RESTARTS}."
  log "The liveness probe correctly triggered a container restart."
  RESULT=0
else
  fail "restart count never increased after ${LIVENESS_TEST_TIMEOUT}s."
  fail "The liveness probe did NOT trigger a restart as expected."
  RESULT=1
fi

# restore() runs automatically via the EXIT trap
exit "${RESULT}"