#!/usr/bin/env bash
# Installs the micromamba binary. Used exactly once, inside hbr-ros-base —
# every downstream image inherits micromamba via `COPY --from=... /opt/micromamba`,
# never reinstalls it (see README.md rule #3).
set -euo pipefail

# bootc-os's minimal filesystem package doesn't pre-create /usr/local/bin
# (unlike a traditional full-FHS image such as centos-bootc) — create it first.
mkdir -p /usr/local/bin
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xvj -C /usr/local/bin/ --strip-components=1 bin/micromamba
