from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


class VisualReview(BaseModel):
    verdict: Literal["APPROVED", "CHANGES_REQUESTED", "HUMAN_DECISION_REQUIRED"]

    screenshot_set_check: Literal["PASS", "FAIL"]
    resolution_1920x1080: Literal["PASS", "FAIL"]
    resolution_1280x720: Literal["PASS", "FAIL"]

    hover_readability: Literal["PASS", "FAIL"]
    bright_region_preservation: Literal["PASS", "FAIL"]
    dark_region_preservation: Literal["PASS", "FAIL"]
    artifact_check: Literal["PASS", "FAIL"]
    layout_stability: Literal["PASS", "FAIL"]

    evidence: list[str] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)

    release_gate_status: Literal[
        "BLOCKED_BY_BASELINE_DEBT",
        "BLOCKED_BY_CURRENT_CHANGE",
    ]

    summary: str
    human_question: str = ""
