# aris_perception

Simulation-only V3 perception scaffold.

No camera streams or segmentation model are available yet, so this package does not claim V3
completion. It currently contains ROS-free helpers for turning a segmentation detection plus camera
calibration/pose into a semantic map observation that `aris_mapping` can consume.

`simulated_segmentation_node` is a deterministic simulation-only source for the V3 smoke. It does
not run a real model; it emits repeat-pass observations on
`/aris/perception/semantic_observation` so the map update path can be verified without camera
assets.
