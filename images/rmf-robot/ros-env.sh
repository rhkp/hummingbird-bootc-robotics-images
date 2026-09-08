#!/usr/bin/env bash
set -eo pipefail

# ROS setup scripts reference unset variables, so source them with nounset
# disabled. This image intentionally has no RMF workspace overlay: the world
# pod owns RMF coordination and the robot only runs Nav2/SLAM/TF.
set +u
source /opt/micromamba/envs/ros_env/setup.bash

export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_ROUTER_ENDPOINT="${ZENOH_ROUTER_ENDPOINT:-tcp/localhost:7447}"
export ZENOH_CONFIG_OVERRIDE="connect/endpoints=[\"${ZENOH_ROUTER_ENDPOINT}\"]"
export ROS_LOG_DIR="${ROS_LOG_DIR:-/opt/rmf/.ros/log}"
export HOME="${HOME:-/opt/rmf}"
