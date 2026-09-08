#!/usr/bin/env bash
set -eo pipefail

set +u
source /opt/micromamba/envs/ros_env/setup.bash
source "${RMF_WS}/install/setup.bash"

export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_ROUTER_ENDPOINT="${ZENOH_ROUTER_ENDPOINT:-tcp/localhost:7447}"
export ZENOH_CONFIG_OVERRIDE="connect/endpoints=[\"${ZENOH_ROUTER_ENDPOINT}\"]"
export ROS_LOG_DIR="${ROS_LOG_DIR:-/opt/rmf/.ros/log}"
export HOME="${HOME:-/opt/rmf}"
