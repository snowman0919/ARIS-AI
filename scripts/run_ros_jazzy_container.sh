#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_WS="$ROOT_DIR/workspaces/ros2_ws"
IMAGE="${ROS_IMAGE:-ros:jazzy-ros-base-noble}"

mkdir -p "$ROS_WS/src"

exec docker run --rm -it \
  --network=host \
  -e ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-42}" \
  -e RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}" \
  -v "$ROS_WS:/ros2_ws:rw" \
  -w /ros2_ws \
  "$IMAGE" \
  bash
