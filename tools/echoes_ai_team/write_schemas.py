from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class RepoEvidence(BaseModel):
    path: str = Field(description="Repository-relative source visible in REPO_BRIEF.")
    finding: str = Field(description="Concrete fact supported by that source.")


class TextReplacement(BaseModel):
    old_text: str = Field(
        description=(
            "Exact existing UTF-8 text to replace. Keep the snippet as small as "
            "possible while still making it unique in the file."
        )
    )
    new_text: str = Field(
        description="Replacement text. No markdown fences."
    )


class FileEdit(BaseModel):
    path: str = Field(
        description="Repository-relative path. Must already exist and be in REPO_BRIEF."
    )
    rationale: str
    replacements: list[TextReplacement] = Field(default_factory=list)


class ChangeProposal(BaseModel):
    status: Literal[
        "READY_TO_APPLY",
        "BLOCKED",
        "HUMAN_DECISION_REQUIRED",
    ]
    summary: str
    repo_evidence: list[RepoEvidence] = Field(default_factory=list)
    edits: list[FileEdit] = Field(default_factory=list)
    tests_to_run: list[str] = Field(default_factory=list)
    visual_review: str = ""
    risks: list[str] = Field(default_factory=list)
    human_question: str = ""


class DiffReview(BaseModel):
    verdict: Literal[
        "APPROVED",
        "CHANGES_REQUESTED",
        "HUMAN_DECISION_REQUIRED",
    ]
    scope_check: Literal["PASS", "FAIL"]
    diff_evidence: list[str] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    important: list[str] = Field(default_factory=list)
    optional: list[str] = Field(default_factory=list)
    test_plan_check: str
    save_data_risk: str
    visual_review_requirement: str
    summary: str
    human_question: str = ""
