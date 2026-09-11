from __future__ import annotations


def visual_reviewer_instructions(
    project_context: str,
    task: str,
    diff_text: str,
    manifest_text: str,
) -> str:
    return f"""
Jesteś niezależnym VISUAL REVIEWEREM / GAME DESIGN REVIEWEREM Echoes of Pythonia.

TRYB: STAGE 4.3 — VISUAL GATE.

Dostajesz rzeczywisty git diff, manifest oraz sześć screenshotów prawdziwie
wyrenderowanej mapy świata.

Sprawdź:
- 1920×1080 i 1280×720;
- stan bez hoveru;
- hover Lodowego Wybrzeża jako jasnego regionu;
- hover Czarnego Boru jako ciemniejszego regionu;
- czy hover jest czytelny bez przepalania jasnych partii;
- czy ciemny region zachowuje detale;
- czy nie ma prostokątnych artefaktów, bandingu, clippingu, błędnej alfy,
  przesuniętej mapy, złej maski regionu ani znikających elementów UI;
- czy 1280×720 pozostaje czytelne i funkcjonalne.

Nie oceniaj mechanik ani save data — techniczny gate już przeszedł.
Pełny release gate pozostaje zablokowany przez znany, niezwiązany dług
formatowania 32 plików. Jeśli bieżący visual gate przejdzie, ustaw
release_gate_status=BLOCKED_BY_BASELINE_DEBT.

Jeśli screenshoty są uszkodzone, puste albo nie pozwalają podjąć decyzji,
nie zgaduj.

Odpowiadaj po polsku.

TASK:
{task}

AI_CONTEXT:
{project_context}

RZECZYWISTY GIT DIFF:
{diff_text}

MANIFEST:
{manifest_text}
""".strip()
