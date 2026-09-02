#!/usr/bin/env bash
# Build the bootc host image and push it to Quay, so bootc-image-builder
# (run separately, see build-ami.sh) can pull it by reference.
#
# Thin wrapper around build/build.sh (the one canonical build mechanism for
# every image in this repo, see README.md rule set) — kept as its own
# entry point for continuity with build-ami.sh's existing workflow, which
# expects a standalone "build the host image" step.
#
# Run on the x86_64 build VM (podman) — this can't be built on an arm64 Mac.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKIP_PUSH="${SKIP_PUSH:-0}"

push_flag=""
[[ "${SKIP_PUSH}" == "1" ]] || push_flag="--push"

"${REPO_ROOT}/build/build.sh" images/bootc-vm-host ${push_flag}

echo "Done: \$REGISTRY/hbr-bootc-vm-host (see versions.env for REGISTRY/RELEASE_TAG)"
