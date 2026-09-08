# hummingbird-bootc-robotics-images

Container images for OpenRMF demos built on Project Hummingbird's `bootc-os` base image. This repo unifies image builds, replacing scattered efforts across multiple repositories.

## Repo-wide Conventions

1. **Base Image**: Every image is `FROM quay.io/hummingbird-community/bootc-os`.
2. **Package Management**: Use `base/scripts/enable-fedora-repos.sh` for packages not in Hummingbird's catalog.
3. **ROS2/RMF Chain**: Derive from `hbr-ros-base` → `hbr-rmf-msgs` → `hbr-rmf-core`.
4. **Multi-stage Builds**: Deployed images use multi-stage builds with a builder and runtime stage.
5. **Bootable Host**: `images/bootc-vm-host` is a bootable host OS.

## Architecture

```
<registry>/hbr-ros-base        bootc-os + Fedora fallback repo + micromamba + ros_env + build toolchain
        │
        ├─▶ hbr-rmf-msgs   (builder-tier: vcs-import + colcon-build for RMF message packages)
        │        │
        │        ├─▶ hbr-rmf-core   (builder-tier: colcon-build for RMF core packages)
        │        │        │
        │        │        └─▶ images/rmf-demos     (deployed: Gazebo/RViz, RMF world + fleet adapter)
        │        │
        │        ├─▶ images/rmf-tools       (deployed: fleet monitor/dispatch/coordinator)
        │        └─▶ images/rmf-web-zenoh    (deployed: pnpm/Node, rmf-web's api_server)
        │
        ├─▶ images/rmf-robot       (deployed: Nav2/SLAM/TF/Zenoh runtime)
        └─▶ images/zenoh-router    (deployed: zenoh-router)

images/novnc            bootc-os (no ROS dependency)
images/bootc-vm-host    bootc-os host OS (NVIDIA/akmod, firewalld, TLS cert, Quadlet units)
```

## Building

Run on the x86_64 build VM (podman):

```bash
# Build one image:
build/build.sh base/ros-base

# Or build the entire dependency graph:
build/build-all.sh [--push]
```

## Registry

| Image | Registry ref | Deployed? |
|---|---|---|
| ros-base | `<registry>/hbr-ros-base` | No |
| rmf-msgs | `<registry>/hbr-rmf-msgs` | No |
| rmf-core | `<registry>/hbr-rmf-core` | No |
| rmf-demos | `<registry>/hbr-rmf-demos` | Yes |
| rmf-robot | `<registry>/hbr-rmf-robot` | Yes |
| rmf-tools | `<registry>/hbr-rmf-tools` | Yes |
| zenoh-router | `<registry>/hbr-zenoh-router` | Yes |
| novnc | `<registry>/hbr-novnc` | Yes |
| rmf-web-zenoh | `<registry>/hbr-rmf-web-zenoh` | Yes |
| bootc-vm-host | `<registry>/hbr-bootc-vm-host` | Yes |

## Status

- [x] Phase 0 — scaffold, `versions.env`, shared scripts, README
- [ ] Phase 1 — `hbr-ros-base` built + pushed + smoke-tested
- [ ] Phase 2 — `hbr-rmf-msgs` built + pushed + smoke-tested
- [ ] Phase 3 — `hbr-rmf-core` built + pushed + smoke-tested
- [ ] Phase 4 — `images/rmf-demos` built + validated
- [ ] Phase 5 — `images/zenoh-router` built + validated
- [ ] Phase 6 — `images/novnc` built + validated
- [ ] Phase 7 — `images/rmf-web-zenoh` built + validated
- [ ] Phase 8 — `images/bootc-vm-host` built + validated
- [ ] Phase 9 — `openrmf-demos-on-openshift` cut over to these tags

## Open Follow-ups

- **hotel/airport parity**: `images/rmf-demos` is office-scope only.
- **robot runtime**: `hbr-rmf-robot` is the default Nav2/SLAM runtime; custom robot images can be selected by the deployment repository.
- **`ghcr.io/open-rmf/rmf-web/demo-dashboard`**: companion image.
- **`bootc-os:latest` reproducibility**: every image floats on `:latest`.
- **`ament_cmake_catch2`**: pulled into `hbr-rmf-core` but not used.
