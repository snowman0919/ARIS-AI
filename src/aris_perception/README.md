# aris_perception

Simulation-only V3 perception scaffold.

No camera streams or segmentation model are available yet, so this package does not claim V3
completion. It currently contains ROS-free helpers for turning a segmentation detection plus camera
calibration/pose into a semantic map observation that `aris_mapping` can consume.
