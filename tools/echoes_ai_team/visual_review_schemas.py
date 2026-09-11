from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


class VisualReview(BaseModel):
    verdict: Literal["APPROVED", "CHANGES_REQUESTED", "HUMAN_DECISION_REQUIRED"]

    pair_set_check: Literal["PASS", "FAIL"]
    resolution_1920x1080: Literal["PASS", "FAIL"]
    resolution_1280x720: Literal["PASS", "FAIL"]

    requested_brightness_improvement: Literal["PASS", "FAIL"]
    hover_readability_regression: Literal["PASS", "FAIL"]
    dark_region_regression: Literal["PASS", "FAIL"]
    new_artifact_regression: Literal["PASS", "FAIL"]
    layout_regression: Literal["PASS", "FAIL"]

    evidence: list[str] = Field(default_factory=list)
    baseline_visual_debt: list[str] = Field(default_factory=list)
    current_change_regressions: list[str] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)

    release_gate_status: Literal[
        "BLOCKED_BY_BASELINE_DEBT",
        "BLOCKED_BY_CURRENT_CHANGE",
    ]

    summary: str
    human_question: str = ""
