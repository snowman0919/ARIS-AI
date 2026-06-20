# ARIS Autonomous Run Log

Append one dated entry per milestone attempt (newest at the bottom). **The owner reads this first
in the morning** — be precise and honest: what was built, which completion criteria passed (with
numbers), what is stubbed/blocked and why, and the exact next step. See `HANDOFF.md` §10 for the
rules of this run.

Entry format:

```
## <YYYY-MM-DD HH:MM> — V<n>: <title> — [DONE | WIP | BLOCKED]
- Built:        <files/packages added or changed>
- Verified:     <completion criteria + measured result, e.g. "tracking err 0.21 m < 0.3 m">
- Build/tests:  <ros2-build green? N unit tests pass?>
- Commit:       <short hash + message>
- Stubbed/blocked: <what is not real yet, and why>
- Next:         <the precise next step>
```

---

## 2026-06-21 — Starting point (handoff baseline)
- State: §4 interface contract + V0 done & verified. `nix develop -c just ros2-build` green
  (7 packages); integration smoke + 13 unit tests pass.
- Sim is a Python kinematic node (not Gazebo). `/odometry/filtered` and `map→odom` are V1
  placeholders. Real-mode HAL is a stub.
- Next: **V1 — teach-and-repeat** (HANDOFF §8).

## 2026-06-21 02:06 KST — V1: Teach-and-Repeat — DONE
- Built:        Added `aris_planning.route` ROS-free CSV/waypoint core, `path_recorder_node`,
  `path_recorder.launch.py`, `route_file` plumbing in `local_planner_node`, bringup/autonomous
  route launch args, `just path-record`, and a bounded `just v1-smoke` teach/repeat check.
- Verified:     Automated teach/repeat in sim recorded `/odometry/filtered` during teleop mode to
  `/aris/data/routes/v1_smoke_route_20260620_170559.csv` (36 waypoints, 7.499 m), replayed that
  exact CSV in auto mode, and measured `max_lateral_error=0.000 m` (< 0.3 m) over 426 odometry
  samples with `max_x=7.273 m`.
- Build/tests:  `nix develop -c just ros2-build` green (7 packages; setuptools warning only);
  `python3 -m pytest src -q` inside the ROS container green (`25 passed`); `nix develop -c just
  auto-sim` green; `nix develop -c just v1-smoke` green.
- Commit:       `c4d2897` — `V1: teach-and-repeat (verified: route smoke 0.000m)`.
- Stubbed/blocked: V1 still uses the known placeholder sim localization: `vehicle_sim_node`
  publishes `/odometry/filtered`, and bringup publishes static identity `map→odom`. This is
  expected until V2 replaces both with LiDAR localization.
- Next:         Start V2 by assessing whether Gazebo Harmonic / `ros_gz` / `gpu_lidar` are
  available in the Nix+Docker ROS environment; if unavailable or headless GPU rendering blocks
  `/scan_cloud`, document honestly and add only safe, tested scaffold.

## 2026-06-21 02:16 KST — V2: LiDAR Localization — WIP/BLOCKED
- Built:        Added a buildable `aris_localization` package with ROS-free
  `localization_core.py` transform/error helpers and tests; added `v2_gazebo_lidar.launch.py`,
  a local `aris_lidar_smoke.sdf` world, `just v2-lidar-smoke`, and a guarded `use_sim` gpu_lidar
  block in the single shared ARIS URDF that targets `/scan_cloud`.
- Verified:     `gz`, `ros_gz`, `robot_localization`, `slam_toolbox`, and PCL packages are present
  in the ROS container. Headless server-only Gazebo can stay alive with an empty/world file, but
  `nix develop -c just v2-lidar-smoke` fails honestly: no `/scan_cloud` PointCloud2 sample; launch
  log shows `ros_gz_sim create` waiting for `/world/aris_lidar_smoke/create`, then the smoke times
  out and reports `/scan_cloud` has no type/publisher.
- Build/tests:  `nix develop -c just ros2-build` green (8 packages); `python3 -m pytest src -q`
  inside the ROS container green (`29 passed`); `nix develop -c just auto-sim` green, so V0/V1
  stack behavior still launches after the URDF sensor guard. `nix develop -c just v2-lidar-smoke`
  fails with exit code 1 by design because the completion-critical `/scan_cloud` sample is absent.
- Commit:       `ff118bc` — `V2: scaffold lidar localization probe (blocked: no scan cloud)`.
- Stubbed/blocked: V2 is not complete. No Gazebo-spawned URDF, no `/scan_cloud`, no SLAM `.pcd`,
  no NDT scan matching, no EKF-owned `/odometry/filtered`, and no real `map→odom`. The concrete
  blocker is Gazebo/ros_gz headless service/sensor activation: the world create service is not
  discoverable by `ros_gz_sim create`, and therefore the gpu_lidar cannot be verified.
- Next:         Fix the Gazebo headless transport/rendering path first: make
  `/world/aris_lidar_smoke/create` discoverable, spawn the shared URDF, and get one real
  PointCloud2 sample on `/scan_cloud`. Only after that should V2 proceed to SLAM map generation,
  NDT/EKF localization ownership of `/odometry/filtered` and `map→odom`, and the ≤5 cm drift gate.

## 2026-06-21 02:16 KST — SUMMARY
- Truly done: V1 teach-and-repeat. Criteria passed with an automated recorded teleop route
  (36 waypoints, 7.499 m) replayed at `max_lateral_error=0.000 m < 0.3 m`; commit `c4d2897`.
- WIP/blocked: V2 LiDAR localization. Scaffold and tests exist; completion criteria are not met
  because Gazebo/ros_gz does not yet spawn the URDF or publish `/scan_cloud` in this headless run;
  commit `ff118bc`.
- Not attempted: V3-V6. They depend on V2’s real localization and sensor streams, so forward
  progress stopped per the honesty gate instead of skipping dependencies.
- Current state: `nix develop -c just ros2-build` green (8 packages), ROS-free/unit suite green
  (`29 passed`), `nix develop -c just auto-sim` green, `nix develop -c just v2-lidar-smoke`
  correctly fails with the documented V2 blocker.
- Exact next step: debug Gazebo/ros_gz service discovery and headless gpu_lidar rendering until
  `just v2-lidar-smoke` produces one `/scan_cloud` PointCloud2 sample, then implement the real
  V2 localization chain and rerun V1 repeat on the new `/odometry/filtered`.
