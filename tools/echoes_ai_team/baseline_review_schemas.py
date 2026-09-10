from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


class BaselineAwareReview(BaseModel):
    verdict: Literal[
        "APPROVED",
        "CHANGES_REQUESTED",
        "HUMAN_DECISION_REQUIRED",
    ]

    scope_check: Literal["PASS", "FAIL"]
    targeted_validation_check: Literal["PASS", "FAIL"]

    full_check_status: str
    baseline_debt_assessment: str

    diff_evidence: list[str] = Field(default_factory=list)
    validation_evidence: list[str] = Field(default_factory=list)

    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)

    save_data_risk: str
    visual_review_required: bool
    visual_review_reason: str = ""

    release_gate_status: Literal[
        "CLEAR",
        "BLOCKED_BY_BASELINE_DEBT",
        "BLOCKED_BY_CURRENT_CHANGE",
    ]

    summary: str
    human_question: str = ""
