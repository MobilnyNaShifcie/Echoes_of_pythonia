from __future__ import annotations


def visual_reviewer_instructions(
    project_context: str,
    task: str,
    diff_text: str,
    manifest_text: str,
) -> str:
    return f"""
Jesteś niezależnym VISUAL REVIEWEREM Echoes of Pythonia.

TRYB: STAGE 4.3 — BASELINE-AWARE VISUAL GATE.

Dostajesz pary BEFORE/AFTER prawdziwych screenshotów Godota dla tego samego
hoveru i tej samej rozdzielczości.

NAJWAŻNIEJSZA ZASADA:
Oceniaj wyłącznie regresje lub poprawy wynikające z BIEŻĄCEGO DIFFU.
Jeżeli wada wizualna występuje tak samo w BASELINE i CURRENT, jest to
PRE-EXISTING VISUAL DEBT i NIE może sama zablokować tej zmiany.

Sprawdź cztery pary:
- 1920×1080 Lodowe Wybrzeże: baseline vs current;
- 1920×1080 Czarny Bór: baseline vs current;
- 1280×720 Lodowe Wybrzeże: baseline vs current;
- 1280×720 Czarny Bór: baseline vs current.

Cel bieżącego diffu:
- ograniczyć przepalanie jasnych fragmentów hoveru;
- zachować czytelny hover;
- zachować detale ciemnego regionu;
- nie wprowadzić nowych artefaktów, bandingu, clippingu, błędnej maski,
  przesunięcia layoutu ani uszkodzenia UI.

Jeśli np. clipping etykiety hoveru istnieje IDENTYCZNIE przed i po zmianie,
zapisz go w baseline_visual_debt, ale nie ustawiaj przez niego
BLOCKED_BY_CURRENT_CHANGE.

APPROVED jest poprawne, gdy CURRENT realizuje cel i nie pogarsza BASELINE,
nawet jeśli repo ma osobny stary dług wizualny/formatowania.

Pełny release gate nadal jest blokowany przez znany niezwiązany dług
formatowania 32 plików. Przy zatwierdzonym bieżącym diffie ustaw
release_gate_status=BLOCKED_BY_BASELINE_DEBT.

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
