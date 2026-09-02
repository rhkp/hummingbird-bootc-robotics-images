"""Single source of truth for every rmf.repos commit pin used in this repo.

Upstream's own rmf.repos (https://github.com/open-rmf/rmf/blob/main/rmf.repos)
only ever points at floating `main`/`master` branches — without pinning,
a future rebuild could silently pull different, possibly incompatible
commits for any of these 17 repos. Pins below were captured via
`git ls-remote` shortly after a confirmed-green build on the bootc lineage
this repo replaces — update them deliberately when intentionally moving to
newer upstream commits, not as a side effect of an unrelated rebuild.

Split into two constants because they feed two different images (see
README.md's `hbr-rmf-msgs` vs `hbr-rmf-core` split):
  - MSGS_REPOS: pure interface/message packages, no heavy C++ deps
    (boost/tinyxml/websocketpp/asio). Consumed by both hbr-rmf-core AND
    images/rmf-web-zenoh (which needs messages but never the heavy libs).
    This mirrors upstream's own `ros-jazzy-rmf-*-msgs` apt metapackage
    boundary — not an arbitrary split.
  - CORE_REPOS: everything else — rmf_traffic, rmf_ros2 (rmf_fleet_adapter,
    rmf_websocket), rmf_simulation, rmf_task, rmf_traffic_editor, rmf_utils,
    rmf_visualization, rmf_battery, ament_cmake_catch2, and the 3 vendor
    packages. Consumed only by hbr-rmf-core (and transitively rmf-demos).

`demonstrations/rmf_demos` is deliberately excluded from both — this repo
clones it separately (images/rmf-demos/Containerfile), pinned to its own
commit (versions.env's RMF_DEMOS_COMMIT), instead of the floating `main`
ref rmf.repos itself points at.
"""

MSGS_REPOS = {
    "rmf/rmf_api_msgs": "f61c13048a2b00063c22cf955f4b279053eccba2",
    "rmf/rmf_building_map_msgs": "0a49bd88ae5d1a2ec8f332a1a1c1e5807b9e16d6",
    "rmf/rmf_internal_msgs": "3d4df023bacaf7a091564e98f4aff0776f72a612",
    "rmf/rmf_visualization_msgs": "91ce3fdd1449108d551917f541345db27fa7eac0",
}

CORE_REPOS = {
    "rmf/ament_cmake_catch2": "cc92786410161958d4252e0c611c2db4701655cc",
    "rmf/rmf_battery": "cbd434039806f9d2cc74191a971969a715d1bb4f",
    "rmf/rmf_ros2": "9fb15ac02db25773ab12dcaf423bec8114d842e1",
    "rmf/rmf_simulation": "ec6add4a842a5051a070fafb146208e7f2aa9742",
    "rmf/rmf_task": "3943e852dc44414bdb38c57c10da6c8e29618c06",
    "rmf/rmf_traffic": "39f09e7971c8e666e12c8e9b12199014f631c0bb",
    "rmf/rmf_traffic_editor": "922a66315fb374a8c4640a4f25ad447c4c58b218",
    "rmf/rmf_utils": "54cc7f6842b88b72bd125d34a8000833dd2b8a38",
    "rmf/rmf_visualization": "6c06184c3ec33441b2f94d356c2d43df4233b74a",
    "thirdparty/menge_vendor": "9ac199bf09142be4030ce021a5b9955247717f83",
    "thirdparty/nlohmann_json_schema_validator_vendor": "43358d96f0a458f798d2d347d18ef7177042d304",
    "thirdparty/pybind11_json_vendor": "cba8192a27a3424ba093079352b3a16187824732",
}

ALL_PINS = {**MSGS_REPOS, **CORE_REPOS}
