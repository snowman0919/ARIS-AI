# aris_mapping

V3 semantic HD map scaffold.

This package is intentionally ROS-free for now because V3 completion needs camera streams and a
segmentation model that are not available in this environment. The implemented core covers the
five planned layers:

- metric cells
- occupancy probability
- semantic labels with confidence
- traversability cost
- route graph nodes/edges

The current update policy supports repeat-pass confidence and change detection. It is WIP
scaffolding, not a completed V3 map pipeline.
