"""ROS-free five-layer semantic HD map scaffold.

The V3 production milestone needs camera segmentation and real sensor streams.
This module intentionally owns only deterministic map state/update policy so it
can be tested before those external assets exist.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Iterable


Cell = tuple[int, int]


@dataclass(frozen=True)
class SemanticObservation:
    x: float
    y: float
    label: str
    confidence: float
    source: str = "simulation"


@dataclass(frozen=True)
class MapUpdateDecision:
    cell: Cell
    label: str
    applied: bool
    change_detected: bool
    review_required: bool
    reason: str


@dataclass(frozen=True)
class RouteNode:
    node_id: str
    x: float
    y: float


@dataclass(frozen=True)
class RouteEdge:
    from_node: str
    to_node: str
    cost: float
    blocked: bool = False


@dataclass
class SemanticCellState:
    occupancy: float = 0.5
    labels: dict[str, float] = field(default_factory=dict)
    traversability: float = 0.5
    observations: int = 0

    @property
    def top_label(self) -> str | None:
        if not self.labels:
            return None
        return max(self.labels.items(), key=lambda item: item[1])[0]

    @property
    def top_confidence(self) -> float:
        if not self.labels:
            return 0.0
        return max(self.labels.values())


class SemanticHDMap:
    """Five V3 layers: metric, occupancy, semantic, traversability, route graph."""

    def __init__(
        self,
        resolution_m: float = 0.5,
        change_threshold: float = 0.65,
        confirmation_threshold: float = 0.75,
    ) -> None:
        if resolution_m <= 0.0:
            raise ValueError("resolution_m must be positive")
        self.resolution_m = resolution_m
        self.change_threshold = change_threshold
        self.confirmation_threshold = confirmation_threshold
        self.metric_cells: set[Cell] = set()
        self.cells: dict[Cell, SemanticCellState] = {}
        self.route_nodes: dict[str, RouteNode] = {}
        self.route_edges: list[RouteEdge] = []

    def cell_for_point(self, x: float, y: float) -> Cell:
        return (math.floor(x / self.resolution_m), math.floor(y / self.resolution_m))

    def mark_occupied(self, x: float, y: float, probability: float) -> None:
        cell = self.cell_for_point(x, y)
        state = self._state(cell)
        state.occupancy = _clamp01(probability)
        self.metric_cells.add(cell)

    def apply_semantic_observation(self, observation: SemanticObservation) -> MapUpdateDecision:
        if not 0.0 <= observation.confidence <= 1.0:
            raise ValueError("observation confidence must be in [0, 1]")
        cell = self.cell_for_point(observation.x, observation.y)
        state = self._state(cell)
        prior_label = state.top_label
        prior_confidence = state.top_confidence
        confidence = observation.confidence

        if confidence < self.change_threshold:
            return MapUpdateDecision(
                cell=cell,
                label=observation.label,
                applied=False,
                change_detected=False,
                review_required=True,
                reason="low_confidence",
            )

        change_detected = (
            prior_label is not None
            and prior_label != observation.label
            and prior_confidence >= self.confirmation_threshold
        )
        state.labels[observation.label] = max(state.labels.get(observation.label, 0.0), confidence)
        state.traversability = traversability_for_label(observation.label, confidence)
        state.observations += 1
        self.metric_cells.add(cell)

        return MapUpdateDecision(
            cell=cell,
            label=observation.label,
            applied=True,
            change_detected=change_detected,
            review_required=change_detected or confidence < self.confirmation_threshold,
            reason="change_detected" if change_detected else "applied",
        )

    def add_route_node(self, node: RouteNode) -> None:
        self.route_nodes[node.node_id] = node

    def add_route_edge(self, edge: RouteEdge) -> None:
        if edge.from_node not in self.route_nodes or edge.to_node not in self.route_nodes:
            raise ValueError("route edge endpoints must exist before adding an edge")
        self.route_edges.append(edge)

    def traversable_edges(self, from_node: str) -> Iterable[RouteEdge]:
        return (
            edge
            for edge in self.route_edges
            if edge.from_node == from_node and not edge.blocked
        )

    def _state(self, cell: Cell) -> SemanticCellState:
        if cell not in self.cells:
            self.cells[cell] = SemanticCellState()
        return self.cells[cell]


def traversability_for_label(label: str, confidence: float) -> float:
    normalized = label.lower()
    if normalized in {"road", "lane", "free_space"}:
        base = 0.1
    elif normalized in {"curb", "shoulder"}:
        base = 0.4
    elif normalized in {"mud", "water", "soft_ground"}:
        base = 0.7
    elif normalized in {"obstacle", "debris", "blocked", "vehicle", "person"}:
        base = 1.0
    else:
        base = 0.5
    return _clamp01(0.5 * (1.0 - confidence) + base * confidence)


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, float(value)))
