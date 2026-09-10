from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class ValidationReview(BaseModel):
    verdict: Literal[
        "APPROVED",
        "CHANGES_REQUESTED",
        "HUMAN_DECISION_REQUIRED",
    ]

    scope_check: Literal["PASS", "FAIL"]
    validation_check: Literal["PASS", "FAIL"]

    diff_evidence: list[str] = Field(default_factory=list)
    validation_evidence: list[str] = Field(default_factory=list)

    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)

    save_data_risk: str

    visual_review_required: bool
    visual_review_reason: str = ""

    summary: str
    human_question: str = ""
