# aris_localization

Localization package scaffold.

Priority order:

1. LiDAR.
2. IMU/Odometry.
3. Camera.
4. GPS.

V2 adds:

- ROS-free transform/error helpers in `aris_localization/localization_core.py`.
- A bounded Gazebo gpu_lidar probe: `nix develop -c just v2-lidar-smoke`.
- A launch scaffold that keeps the shared ARIS URDF as the vehicle source of truth and bridges the
  simulated gpu_lidar point cloud toward `/scan_cloud`.

Current blocker: in the headless container, the Gazebo world create service is not discoverable by
`ros_gz_sim create`, so the scaffold cannot yet spawn the URDF or produce `/scan_cloud`.

Mitigation path now available: `aris_vehicle_sim` provides a spec-driven 3D LiDAR surrogate that
publishes `/scan_cloud` as `sensor_msgs/PointCloud2` from a YAML LiDAR profile and 3D box map:

```bash
nix develop -c just lidar-sim-smoke
```

This does not complete V2 localization by itself. It unblocks algorithm development by giving V2/V3
the same topic/type contract that the real LiDAR driver will later provide.

V2A now adds a conservative LiDAR-localization ownership path:

```bash
nix develop -c just v2a-localization-smoke
```

The V2A launch disables the simulator's V1 `/odometry/filtered` placeholder, runs the LiDAR
surrogate, and starts `lidar_localization_node`, which publishes `/odometry/filtered` and
`map->odom`. In the current no-drift lightweight sim, the launch uses conservative correction
windows while the ROS-free scan-matching core remains tested separately with an offset correction
case.

The drift-recovery gate exercises the same ownership path with intentionally corrupted wheel
odometry:

```bash
nix develop -c just v2a-drift-smoke
```

That launch publishes ground truth only on `/aris/sim/ground_truth` for measurement and sensor
simulation, injects lateral drift into `/wheel_odom` and `odom->base_link`, and requires
LiDAR-owned `/odometry/filtered` to stay within 5 cm of ground truth while the wheel odometry
drifts by at least 8 cm.
