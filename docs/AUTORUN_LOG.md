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
