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
