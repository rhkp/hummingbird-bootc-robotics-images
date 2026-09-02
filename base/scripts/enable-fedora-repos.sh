#!/usr/bin/env bash
# THE canonical fix for Hummingbird bootc-os's /etc/os-release VERSION_ID
# being a date string (e.g. "20251124"), not a Fedora release number — this
# breaks any repo file that uses $releasever in its baseurl/metalink,
# including repo files bundled inside RPMs we don't control (e.g. RPM
# Fusion's own release RPMs, installed by images/bootc-vm-host).
#
# Setting /etc/dnf/vars/releasever FIRST (rather than hand-writing a repo
# file with a hardcoded baseurl) is what makes this a single, general fix
# instead of a per-repo-file patch: once the dnf var resolves correctly,
# every repo file that uses $releasever — ours below, or a third party's —
# resolves correctly too.
set -euo pipefail
RELEASE="${1:?usage: enable-fedora-repos.sh <fedora-release-number>}"

echo "${RELEASE}" > /etc/dnf/vars/releasever

printf '%s\n' \
  '[fedora]' \
  'name=Fedora $releasever' \
  'baseurl=https://dl.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/' \
  'enabled=1' \
  'gpgcheck=0' \
  'skip_if_unavailable=True' \
  > /etc/yum.repos.d/fedora.repo

printf '%s\n' \
  '[fedora-updates]' \
  'name=Fedora $releasever updates' \
  'baseurl=https://dl.fedoraproject.org/pub/fedora/linux/updates/$releasever/Everything/$basearch/' \
  'enabled=1' \
  'gpgcheck=0' \
  'skip_if_unavailable=True' \
  > /etc/yum.repos.d/fedora-updates.repo
