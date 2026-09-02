#!/usr/bin/env bash
# Walks the full dependency graph in order (see README.md's layered
# architecture diagram) and builds every image against versions.env.
#
# Usage: build/build-all.sh [--push]
#
# Run on the x86_64 build VM (podman) — base images are amd64-only.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

push_flag=""
[ "${1:-}" = "--push" ] && push_flag="--push"

# Base/builder-tier images, in strict dependency order — each FROMs the
# previous one at ${RELEASE_TAG}.
BASE_IMAGES=(
  base/ros-base
  base/rmf-msgs
  base/rmf-core
)

# Leaf/deployed images. rmf-demos and rmf-web-zenoh depend on the base
# chain above; zenoh-router depends only on hbr-ros-base (already built);
# novnc has no ROS dependency at all. Order here doesn't matter beyond the
# base images already being built — listed in the order they appear in
# README.md's dependency graph for readability.
LEAF_IMAGES=(
  images/rmf-demos
  images/rmf-web-zenoh
  images/zenoh-router
  images/novnc
)

# bootc-vm-host has no build-time FROM dependency on anything above, but
# its Quadlet units reference the leaf images' tags at deploy time — build
# it last so a fresh push of the leaves always precedes it.
HOST_IMAGE=images/bootc-vm-host

for dir in "${BASE_IMAGES[@]}" "${LEAF_IMAGES[@]}" "${HOST_IMAGE}"; do
  build/build.sh "${dir}" ${push_flag}
done
