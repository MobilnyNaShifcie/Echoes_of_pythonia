from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


class RepoEvidence(BaseModel):
    path: str
    finding: str


class DeveloperPlan(BaseModel):
    status: Literal["READY_FOR_REVIEW", "BLOCKED", "HUMAN_DECISION_REQUIRED"]
    summary: str
    repo_evidence: list[RepoEvidence] = Field(default_factory=list)
    files_to_change: list[str] = Field(default_factory=list)
    plan_steps: list[str] = Field(default_factory=list)
    tests_to_run: list[str] = Field(default_factory=list)
    risks: list[str] = Field(default_factory=list)
    human_question: str = ""


class ReviewResult(BaseModel):
    verdict: Literal["APPROVED", "CHANGES_REQUESTED", "HUMAN_DECISION_REQUIRED"]
    scope_check: Literal["PASS", "FAIL"]
    evidence_checked: list[RepoEvidence] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)
    test_confidence: str
    save_data_risk: str
    visual_review_requirement: str
    summary: str
    human_question: str = ""
