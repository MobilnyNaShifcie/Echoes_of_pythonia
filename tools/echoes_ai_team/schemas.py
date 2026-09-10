from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class RepoEvidence(BaseModel):
    path: str = Field(
        description="Repository-relative file/path or git-info source inspected through read-only tools."
    )
    finding: str = Field(
        description="Concrete fact learned from that source, not a guess."
    )


class DeveloperPlan(BaseModel):
    status: Literal[
        "READY_FOR_REVIEW",
        "BLOCKED",
        "HUMAN_DECISION_REQUIRED",
    ]

    summary: str = Field(description="Krótko: co Developer proponuje zrobić.")

    files_to_inspect: list[str] = Field(
        default_factory=list,
        description="Planning-only areas/files worth inspecting.",
    )

    repo_evidence: list[RepoEvidence] = Field(
        default_factory=list,
        description="Actual repository evidence inspected in repository-aware mode.",
    )

    files_to_change: list[str] = Field(
        default_factory=list,
        description="Likely concrete files to modify after actual repository inspection.",
    )

    plan_steps: list[str] = Field(
        default_factory=list,
        description="Kolejne kroki implementacji.",
    )

    tests_to_run: list[str] = Field(
        default_factory=list,
        description="Targeted/full tests expected for the task.",
    )

    risks: list[str] = Field(
        default_factory=list,
        description="Ryzyka techniczne/projektowe.",
    )

    human_question: str = Field(
        default="",
        description="Pytanie do właściciela tylko gdy decyzja człowieka jest naprawdę wymagana.",
    )


class ReviewResult(BaseModel):
    verdict: Literal[
        "APPROVED",
        "CHANGES_REQUESTED",
        "HUMAN_DECISION_REQUIRED",
    ]

    scope_check: Literal["PASS", "FAIL"]

    evidence_checked: list[RepoEvidence] = Field(
        default_factory=list,
        description="Independent repository evidence checked by Reviewer in repository-aware mode.",
    )

    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)
    test_confidence: str
    save_data_risk: str
    visual_review_requirement: str
    summary: str
    human_question: str = ""
