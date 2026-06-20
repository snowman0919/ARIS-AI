import math

import pytest

from aris_localization.localization_core import (
    Pose2D,
    Transform2D,
    map_to_odom_from_base_poses,
    normalize_angle,
    point_to_polyline_distance,
    transform_pose,
)


def assert_pose_close(actual: Pose2D, expected: Pose2D) -> None:
    assert actual.x == pytest.approx(expected.x, abs=1e-9)
    assert actual.y == pytest.approx(expected.y, abs=1e-9)
    assert normalize_angle(actual.yaw - expected.yaw) == pytest.approx(0.0, abs=1e-9)


def test_map_to_odom_transform_aligns_base_poses():
    odom_base = Pose2D(x=4.0, y=1.0, yaw=0.3)
    map_base = Pose2D(x=10.0, y=-2.0, yaw=1.0)

    map_to_odom = map_to_odom_from_base_poses(map_base, odom_base)

    assert_pose_close(transform_pose(map_to_odom, odom_base), map_base)


def test_transform_pose_rotates_and_translates():
    transformed = transform_pose(
        Transform2D(x=1.0, y=2.0, yaw=math.pi / 2.0),
        Pose2D(x=2.0, y=0.0, yaw=math.pi / 2.0),
    )

    assert_pose_close(transformed, Pose2D(x=1.0, y=4.0, yaw=math.pi))


def test_point_to_polyline_distance_uses_nearest_segment():
    polyline = [(0.0, 0.0), (2.0, 0.0), (2.0, 2.0)]

    assert point_to_polyline_distance((1.0, 0.3), polyline) == pytest.approx(0.3)
    assert point_to_polyline_distance((2.4, 1.0), polyline) == pytest.approx(0.4)


def test_point_to_polyline_distance_rejects_degenerate_route():
    with pytest.raises(ValueError, match="at least two"):
        point_to_polyline_distance((0.0, 0.0), [(0.0, 0.0)])
