#!/usr/bin/env bash
# Wait until a ROS 2 topic appears (requires ros-env to be sourced).
set -euo pipefail

TOPIC="${1:?Usage: wait-for-topic.sh <topic> [timeout_seconds]}"
TIMEOUT="${2:-600}"
INTERVAL="${WAIT_INTERVAL:-5}"

echo "[wait] Waiting for topic ${TOPIC} (timeout ${TIMEOUT}s)..."
elapsed=0
# Do not use grep -q here: with pipefail enabled, grep exits as soon as it
# finds a match and ros2 can receive SIGPIPE, making an available topic look
# like a failed check.  Let grep consume the complete ROS graph output.
until ros2 topic list 2>/dev/null | grep -Fx "${TOPIC}" >/dev/null; do
  if (( elapsed >= TIMEOUT )); then
    echo "[wait] Timed out waiting for ${TOPIC}" >&2
    exit 1
  fi
  sleep "${INTERVAL}"
  elapsed=$((elapsed + INTERVAL))
done
echo "[wait] Topic ${TOPIC} is available."
