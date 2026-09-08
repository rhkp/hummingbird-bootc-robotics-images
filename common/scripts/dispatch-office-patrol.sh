#!/usr/bin/env bash
set -euo pipefail

source /opt/rmf/scripts/ros-env.sh

DISPATCH_MARKER="${DISPATCH_MARKER:-/opt/rmf/.ros/.office-dispatch-done}"
READY_WAIT_SECONDS="${READY_WAIT_SECONDS:-30}"
STARTUP_WAIT_SECONDS="${STARTUP_WAIT_SECONDS:-0}"
DISPATCH_START="${DISPATCH_START:-coe}"
DISPATCH_GOAL="${DISPATCH_GOAL:-lounge}"
DISPATCH_LOOPS="${DISPATCH_LOOPS:-3}"

if [[ -f "${DISPATCH_MARKER}" ]]; then
  echo "[office/dispatch] Patrol already submitted; holding container open."
  exec tail -f /dev/null
fi

if (( STARTUP_WAIT_SECONDS > 0 )); then
  echo "[office/dispatch] Initial delay ${STARTUP_WAIT_SECONDS}s..."
  sleep "${STARTUP_WAIT_SECONDS}"
fi

/opt/rmf/scripts/wait-for-topic.sh /fleet_states
echo "[office/dispatch] Simulation ready; waiting ${READY_WAIT_SECONDS}s for adapters..."
sleep "${READY_WAIT_SECONDS}"

echo "[office/dispatch] Dispatching patrol: ${DISPATCH_START} -> ${DISPATCH_GOAL} (${DISPATCH_LOOPS} loops)..."
ros2 run rmf_demos_tasks dispatch_patrol \
  -p "${DISPATCH_START}" "${DISPATCH_GOAL}" \
  -n "${DISPATCH_LOOPS}" \
  --use_sim_time

touch "${DISPATCH_MARKER}"
echo "[office/dispatch] Patrol submitted; holding container open."
exec tail -f /dev/null
