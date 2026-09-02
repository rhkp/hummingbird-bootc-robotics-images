#!/usr/bin/env bash
# Build a single image directory against versions.env.
#
# Usage: build/build.sh <dir> [--push]
#   build/build.sh base/ros-base
#   build/build.sh images/rmf-demos --push
#
# Always builds from the repo root as context (every Containerfile's COPY
# paths are repo-root-relative — e.g. `COPY common/models/...`,
# `COPY base/scripts/...`), and always resolves `FROM <registry>/hbr-X:${BASE_TAG}`
# against RELEASE_TAG, not an unrelated leftover `:latest` from a previous run.
#
# Requires versions.env (gitignored, per-deployer — copy versions.env.example
# and set REGISTRY to your own quay.io/Docker Hub namespace).
#
# Run on the x86_64 build VM (podman) — base images are amd64-only, not
# local Mac builds.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

dir="${1:?usage: build.sh <dir> [--push]}"
push=false
[ "${2:-}" = "--push" ] && push=true

if [ ! -f "${dir}/Containerfile" ]; then
  echo "error: ${dir}/Containerfile not found" >&2
  exit 1
fi

if [ ! -f versions.env ]; then
  echo "error: versions.env not found. Set it up with:" >&2
  echo "  cp versions.env.example versions.env" >&2
  echo "  # then edit REGISTRY to your own quay.io/Docker Hub namespace" >&2
  exit 1
fi

# shellcheck disable=SC1091
source versions.env

name="hbr-$(basename "${dir}")"

build_args=(--build-arg "BASE_TAG=${RELEASE_TAG}")
while IFS='=' read -r key value; do
  case "${key}" in
    ''|'#'*) continue ;;
  esac
  build_args+=(--build-arg "${key}=${value}")
done < versions.env

echo "==> Building ${REGISTRY}/${name}:${RELEASE_TAG} from ${dir}/Containerfile"
podman build "${build_args[@]}" \
  -t "${REGISTRY}/${name}:${RELEASE_TAG}" \
  -t "${REGISTRY}/${name}:latest" \
  -f "${dir}/Containerfile" .

if ${push}; then
  podman push "${REGISTRY}/${name}:${RELEASE_TAG}"
  podman push "${REGISTRY}/${name}:latest"
fi
