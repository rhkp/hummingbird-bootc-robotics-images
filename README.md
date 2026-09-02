# hummingbird-bootc-robotics-images

Container images for the OpenRMF office/hotel/airport demos, built
exclusively on [Project Hummingbird](https://hummingbird-project.io/)'s
bootc-os base image. This repo replaces the scattered, mixed-lineage image
build efforts previously spread across `bootc/`, `hummingbird/`,
`bootc-vm/`, and `common/` in the `openrmf-demos-on-openshift` repo with one
unified architecture.

Consumed by `openrmf-demos-on-openshift` purely via published image tags in
Helm `values.yaml` — no shared files, no submodules between the two repos.

## Repo-wide conventions (non-negotiable)

The old repo's real problem wasn't any single Containerfile — four
different answers coexisted for the same handful of questions ("how do we
get ROS2 onto a dnf base", "how do we work around Hummingbird's
`$releasever`", "does this image build from source or bind a prebuilt image
unchanged"). This repo makes each question have exactly one answer, applied
identically everywhere:

1. **Every image is `FROM quay.io/hummingbird-community/bootc-os`**,
   directly or via a `base/` image that is itself `FROM bootc-os`. No
   image is `FROM` anything else, ever.
2. **Any package Hummingbird's own catalog lacks goes through exactly one
   shared script**, `base/scripts/enable-fedora-repos.sh` — never a
   hand-rolled repo file.
3. **Any image that needs ROS2/RMF derives from the shared
   `hbr-ros-base` → `hbr-rmf-msgs` → `hbr-rmf-core` chain.** No image
   hand-rolls its own `micromamba create`/RoboStack channel setup.
4. **Every deployed Pod-style app image is multi-stage**: a builder stage
   that installs/fetches/compiles, and a runtime stage that starts fresh
   `FROM bootc-os` and copies in only what's needed to run. Same OpenShift
   arbitrary-UID pattern (`USER 1001`, group 0, `g+rwX`) everywhere.
5. **`images/bootc-vm-host` is the one deliberate exception to #4** — a
   real bootable host OS (its own kernel, systemd PID1), not a Pod image.

## Architecture

```
<registry>/hbr-ros-base        bootc-os + Fedora fallback repo + micromamba +
  (builder-tier, never deployed)  ros_env (ros-base + rmw_zenoh_cpp + colcon +
                                   compilers=1.11.0 pin) + build toolchain
        │
        ├─▶ hbr-rmf-msgs   (builder-tier: vcs-import + colcon-build ONLY the
        │        │          4 pure interface repos — rmf_api_msgs,
        │        │          rmf_building_map_msgs, rmf_internal_msgs,
        │        │          rmf_visualization_msgs. Mirrors upstream's own
        │        │          `ros-jazzy-rmf-*-msgs` apt package boundary.)
        │        │
        │        ├─▶ hbr-rmf-core   (builder-tier: + boost-devel/tinyxml-devel/
        │        │        │          asio-devel/websocketpp, the remaining 13
        │        │        │          repos — rmf_traffic, rmf_ros2,
        │        │        │          rmf_simulation, etc. — + patches)
        │        │        │
        │        │        └─▶ images/rmf-demos     (deployed: + Gazebo/Nav2/
        │        │                                   RViz, rmf_demos itself —
        │        │                                   office scope for v1)
        │        │
        │        └─▶ images/rmf-web-zenoh    (deployed: + pnpm/Node, rmf-web's
        │                                      api_server built from source —
        │                                      does NOT need hbr-rmf-core)
        │
        └─▶ images/zenoh-router   (deployed: builder stage IS hbr-ros-base
                                    unmodified — its env already equals
                                    zenoh-router's full dependency set)

images/novnc            bootc-os directly — no ROS dependency at all.

images/bootc-vm-host    bootc-os host OS (NVIDIA/akmod, firewalld, TLS cert,
                         Quadlet units binding the images above by tag).
```

### Why 3 "fat" builder-tier images that are never deployed

`hbr-ros-base`/`hbr-rmf-msgs`/`hbr-rmf-core` intentionally carry full build
toolchains and are multi-GB — they exist purely so the slowest, most
fragile step (RoboStack env creation, GCC pin, RMF-core colcon build) is
built and cached exactly once, in one place. Every leaf image's builder
stage does `FROM <registry>/hbr-rmf-core:<tag>` (or `hbr-ros-base`/
`hbr-rmf-msgs` directly, for leaves that don't need the heavier layers)
instead of re-deriving RoboStack setup from scratch.

### Why `hbr-rmf-msgs` is its own layer

`images/rmf-web-zenoh` only needs the RMF message packages, never the heavy
C++ (`rmf_traffic`, `rmf_fleet_adapter`, `rmf_websocket`). Chaining it off
`hbr-rmf-core` would drag `boost-devel`/`tinyxml-devel`/`asio-devel`/
`websocketpp` into its build for no reason — this mirrors upstream
rmf-web's own CI, which pulls `ros-jazzy-rmf-*-msgs` (not `rmf-dev`) for
exactly the same reason.

## Package provenance (why Fedora appears alongside Hummingbird)

`bootc-os` is ~95% genuine Hummingbird-rebuilt (`.hum1`) content. Our own
package list is similarly lopsided: the entire build toolchain
(`curl`/`tar`/`gcc`/`cmake`/`git`/etc.) resolves from Hummingbird's own
catalog, with the Fedora fallback repo (`base/scripts/enable-fedora-repos.sh`)
covering only:
- A handful of transitive deps Hummingbird's catalog is missing for
  otherwise-present packages (e.g. `cmake` needing `libjsoncpp`).
- The GL/X11/desktop-rendering stack (`mesa-libGL`, `Xvfb`, `x11vnc`,
  `openbox`, `tinyxml`) — genuinely absent from Hummingbird entirely, since
  Project Hummingbird's mission is minimal hardened server/CLI images, not
  GPU-rendering desktop stacks. Needed for `images/rmf-demos` only.
- RPM Fusion + NVIDIA driver packages — needed only by
  `images/bootc-vm-host`'s GPU support, a real bootable host, not a
  minimal-hardened-server workload at all.

## Registry

| Image | Registry ref | Deployed? |
|---|---|---|
| ros-base | `<registry>/hbr-ros-base` | No — builder-tier only |
| rmf-msgs | `<registry>/hbr-rmf-msgs` | No — builder-tier only |
| rmf-core | `<registry>/hbr-rmf-core` | No — builder-tier only |
| rmf-demos | `<registry>/hbr-rmf-demos` | Yes |
| zenoh-router | `<registry>/hbr-zenoh-router` | Yes |
| novnc | `<registry>/hbr-novnc` | Yes |
| rmf-web-zenoh | `<registry>/hbr-rmf-web-zenoh` | Yes |
| bootc-vm-host | `<registry>/hbr-bootc-vm-host` | Yes (VM, not Pod) |

## Building

Run on the x86_64 build VM (podman) — base images are amd64-only, this
cannot build on Apple Silicon.

```bash
# Build one image (and everything it needs to resolve its FROM chain must
# already be pushed, or built earlier in the same session):
build/build.sh base/ros-base
build/build.sh base/rmf-msgs
build/build.sh base/rmf-core
build/build.sh images/rmf-demos

# Or build the entire dependency graph in order:
build/build-all.sh [--push]
```

Every build arg comes from `versions.env` — the single source of truth for
base image tags, the GCC/compiler pin, and every source commit pin. Update
it deliberately, not as a side effect of an unrelated change.

## Status

- [x] Phase 0 — scaffold, `versions.env`, shared scripts, this README
- [ ] Phase 1 — `hbr-ros-base` built + pushed + smoke-tested
- [ ] Phase 2 — `hbr-rmf-msgs` built + pushed + smoke-tested (confirm the 4
      interface repos build standalone — the one real open unknown)
- [ ] Phase 3 — `hbr-rmf-core` built + pushed + smoke-tested
- [ ] Phase 4 — `images/rmf-demos` built + validated at parity with the old
      repo's `hummingbird/office-values.yaml` deployment
- [ ] Phase 5 — `images/zenoh-router` built + validated
- [ ] Phase 6 — `images/novnc` built + validated
- [ ] Phase 7 — `images/rmf-web-zenoh` built + validated (highest
      uncertainty — pnpm/Node build behavior against bootc-os unverified)
- [ ] Phase 8 — `images/bootc-vm-host` built + validated on real GPU hardware
- [ ] Phase 9 — `openrmf-demos-on-openshift` cut over to these tags,
      `bootc/`, `hummingbird/`, `common/Dockerfile` etc. retired there

## Open follow-ups (deferred, not blockers)

- **hotel/airport parity**: `images/rmf-demos` is office-scope only for v1
  — stock `rmf_demos_maps` generation needs `fiona`, which genuinely
  conflicts with the rest of the RoboStack conda environment. Needs an
  isolated conda env for map codegen, or generating maps in a separate
  non-conda stage.
- **`ghcr.io/open-rmf/rmf-web/demo-dashboard`**: companion image to
  api-server, same rmf-web repo/CI, currently referenced directly from
  upstream in the demo repo's `values.yaml`. Not in scope here unless the
  same rebuild-from-source treatment is wanted for it too.
- **`bootc-os:latest` reproducibility**: every image floats on `:latest`
  for the base image with no digest pin, unlike every source dependency
  (which is pinned to a commit SHA). Worth revisiting once this repo has a
  release cadence.
- **`ament_cmake_catch2`**: pulled into `hbr-rmf-core` even though the
  image build never runs tests — possible future trim via `COLCON_IGNORE`.
