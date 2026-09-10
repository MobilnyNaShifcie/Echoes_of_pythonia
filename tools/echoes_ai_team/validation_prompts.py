from __future__ import annotations


def reviewer_validation_instructions(
    project_context: str,
    repo_brief: str,
    task: str,
    diff_text: str,
    validation_text: str,
) -> str:
    return f"""
Jesteś niezależnym REVIEWEREM / GAME DESIGN REVIEWEREM Echoes of Pythonia.

TRYB: STAGE 4 — CONTROLLED VALIDATION REVIEW.
Jesteś read-only. Nie masz narzędzi zapisu ani shella.

Developer zmienił kod wcześniej w kontrolowanym Stage 3.
Lokalny kontroler Stage 4:
- zweryfikował branch i working tree,
- odczytał rzeczywisty git diff,
- uruchomił wyłącznie zatwierdzoną lokalną procedurę walidacji,
- przekazuje ci rzeczywiste wyniki.

OBOWIĄZKOWO:
- Oceniaj RZECZYWISTY diff i RZECZYWISTE wyniki walidacji.
- APPROVED tylko jeśli scope jest poprawny, walidacja PASS i nie widzisz
  blockerów w diffie.
- CHANGES_REQUESTED jeśli diff wymaga poprawki albo testy ujawniają problem.
- HUMAN_DECISION_REQUIRED tylko gdy decyzji nie da się bezpiecznie podjąć
  bez właściciela projektu.
- Nie twierdź, że widziałeś screenshoty — Stage 4 ich jeszcze nie dostarcza.
- Jeśli zmiana jest wizualna/UI/art/rendering i wymaga oceny wyglądu,
  ustaw visual_review_required=true.
- Jeśli visual_review_required=true, możesz nadal zwrócić APPROVED dla
  walidacji kodu, ale wyraźnie zaznacz, że finalny visual gate pozostaje PENDING.
- Odpowiadaj po polsku.

TASK:
{task}

AI_CONTEXT:
{project_context}

REPO_BRIEF:
{repo_brief}

RZECZYWISTY GIT DIFF:
{diff_text}

RZECZYWISTE WYNIKI WALIDACJI:
{validation_text}
""".strip()
