#!/usr/bin/env python3
"""Generate rmf-msgs.repos and rmf-core.repos from upstream's rmf.repos,
pinned per pins.py.

Ported from openrmf-demos-on-openshift's hummingbird/scripts/filter-rmf-repos.py,
split to emit two subsets instead of one filtered copy — see pins.py's
docstring for why the split exists. The shape-check (fail loudly if
rmf.repos gained/lost a repo since PINS was captured) carries over
unchanged: this build must never silently pull an unpinned repo.

Usage:
    python3 generate-repos.py <rmf.repos source> <msgs output> <core output>
"""
import sys

import yaml

from pins import ALL_PINS, CORE_REPOS, MSGS_REPOS

src, msgs_dst, core_dst = sys.argv[1], sys.argv[2], sys.argv[3]

with open(src) as f:
    d = yaml.safe_load(f)

# We clone demonstrations/rmf_demos ourselves, pinned to RMF_DEMOS_COMMIT
# in images/rmf-demos/Containerfile — drop rmf.repos' own floating-`main`
# entry for it before the shape check below.
d["repositories"].pop("demonstrations/rmf_demos", None)

missing = set(d["repositories"]) - set(ALL_PINS)
extra = set(ALL_PINS) - set(d["repositories"])
if missing or extra:
    sys.exit(
        f"rmf.repos changed shape since pins.py was captured — "
        f"missing pins: {missing or None}, stale pins: {extra or None}. "
        f"Re-run `git ls-remote` for any new/changed repos and update pins.py."
    )

for subset, dst in ((MSGS_REPOS, msgs_dst), (CORE_REPOS, core_dst)):
    out = {"repositories": {}}
    for name, sha in subset.items():
        entry = dict(d["repositories"][name])
        entry["version"] = sha
        out["repositories"][name] = entry
    with open(dst, "w") as f:
        yaml.safe_dump(out, f)
