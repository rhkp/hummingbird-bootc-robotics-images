#!/usr/bin/env bash
# Wait until a ROS 2 service appears (requires ros-env to be sourced).
set -euo pipefail

SERVICE="${1:?Usage: wait-for-service.sh <service> [timeout_seconds]}"
TIMEOUT="${2:-600}"
INTERVAL="${WAIT_INTERVAL:-5}"

echo "[wait] Waiting for service ${SERVICE} (timeout ${TIMEOUT}s)..."
elapsed=0
# Do not use grep -q here: with pipefail enabled, grep exits as soon as it
# finds a match and ros2 can receive SIGPIPE, making an available service look
# like a failed check.  Let grep consume the complete ROS graph output.
until ros2 service list 2>/dev/null | grep -Fx "${SERVICE}" >/dev/null; do
  if (( elapsed >= TIMEOUT )); then
    echo "[wait] Timed out waiting for ${SERVICE}" >&2
    exit 1
  fi
  sleep "${INTERVAL}"
  elapsed=$((elapsed + INTERVAL))
done
echo "[wait] Service ${SERVICE} is available."
