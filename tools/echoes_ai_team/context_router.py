from __future__ import annotations

import re
from dataclasses import dataclass

WORD_RE = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿĄĆĘŁŃÓŚŹŻąćęłńóśźż0-9_+-]+", re.UNICODE)
HEADING_RE = re.compile(r"^(#{1,4})\s+(.+?)\s*$")

STOPWORDS = {
    "a","albo","ale","and","are","as","at","be","bez","by","czy","dla","do",
    "for","from","i","in","is","jak","jest","na","nie","o","of","or","po","się",
    "the","to","u","w","with","z","za","że","this","that","it","its","oraz","ma",
    "mają","być","żeby",
}

# Polish inflections + project vocabulary.
ALIASES = {
    # map / UI
    "mapa":{"map","world","worldmap","region","hover","selection"},
    "mapy":{"map","world","worldmap","region","hover","selection"},
    "mapie":{"map","world","worldmap","region","hover","selection"},
    "mapę":{"map","world","worldmap","region","hover","selection"},
    "świat":{"world","map","worldmap"},
    "świata":{"world","map","worldmap"},
    "świecie":{"world","map","worldmap"},
    "hover":{"hover","highlight","selection","focus","map"},
    "hoveru":{"hover","highlight","selection","focus","map"},
    "najechanie":{"hover","highlight","selection","focus"},
    "najechaniu":{"hover","highlight","selection","focus"},
    "podświetlenie":{"hover","highlight","selection"},
    "podświetlanie":{"hover","highlight","selection"},
    "ekran":{"screen","ui","layout","interface","visual"},
    "ekranu":{"screen","ui","layout","interface","visual"},
    "ui":{"ui","screen","layout","interface","visual","focus"},
    "layout":{"layout","ui","screen","container","spacing"},
    "wizualny":{"visual","ui","art","presentation"},
    "wizualna":{"visual","ui","art","presentation"},
    "wizualne":{"visual","ui","art","presentation"},
    "region":{"region","world","map","encounter"},
    "regionu":{"region","world","map","encounter"},
    "regionów":{"region","world","map","encounter"},
    "regionami":{"region","world","map","encounter"},
    # mechanics / technical
    "mechanika":{"mechanic","gameplay","domain"},
    "mechaniki":{"mechanic","gameplay","domain"},
    "mechanik":{"mechanic","gameplay","domain"},
    "mechanikę":{"mechanic","gameplay","domain"},
    "bug":{"bug","test","regression","error","technical"},
    "błąd":{"bug","test","regression","error","technical"},
    "test":{"test","validation","gut","pytest","check"},
    "git":{"git","branch","commit","diff","snapshot"},
    "kod":{"code","gdscript","technical","architecture"},
    "kodu":{"code","gdscript","technical","architecture"},
    # other domains
    "miasto":{"city","varenhold","hub","hotspot","navigation"},
    "varenhold":{"city","hub","hotspot","navigation","varenhold"},
    "ekwipunek":{"equipment","inventory","paperdoll","slot","item","grid"},
    "plecak":{"inventory","backpack","grid","item","carry"},
    "przedmiot":{"item","equipment","inventory","asset"},
    "przedmioty":{"item","equipment","inventory","asset"},
    "walka":{"combat","damage","turn","enemy","skill"},
    "combat":{"combat","damage","turn","enemy","skill"},
    "umiejętność":{"skill","combat","card","ability"},
    "skill":{"skill","combat","card","ability"},
    "klasa":{"class","warrior","hunter","mage","pierrot","progression"},
    "pierrot":{"pierrot","fate","dice","luck","szczęście"},
    "wojownik":{"warrior","shield","provoke","heavy","knight"},
    "łowca":{"hunter","volley","bow","sequence","combination"},
    "mag":{"mage","arcana","weave","mana","elemental"},
    "save":{"save","migration","schema","persistence","codec"},
    "zapis":{"save","migration","schema","persistence","codec"},
    "quest":{"quest","guild","contract","objective","reward"},
    "zadanie":{"task","objective","acceptance"},
    "gildia":{"guild","reputation","contract","companion"},
    "kompan":{"companion","party","injury","tactic","recruitment"},
    "kompani":{"companion","party","injury","tactic","recruitment"},
    "szczelina":{"rift","party","segment","anomaly","boss"},
    "rift":{"rift","party","segment","anomaly","boss"},
    "dungeon":{"dungeon","crypt","wreck","boss","entry"},
    "loch":{"dungeon","crypt","wreck","boss","entry"},
    "czarny":{"black","market","bargain","rotation","informant"},
    "rynek":{"black","market","bargain","rotation","informant"},
    "sklep":{"shop","merchant","market","economy","buy","sell"},
    "grafika":{"art","asset","visual","character","background"},
    "grafiki":{"art","asset","visual","character","background"},
    "asset":{"art","asset","manifest","alpha","production"},
    "animacja":{"animation","motion","rig","vfx","presentation"},
}

DOC_AFFINITY = {
    "PROJECT_BIBLE.md":{"project","canon","identity","class","region","companion","rules"},
    "GAME_DESIGN.md":{"combat","class","quest","guild","item","economy","region","companion","rift","dungeon","progression","balance","mechanic","gameplay"},
    "TECHNICAL_RULES.md":{"bug","test","save","migration","git","code","gdscript","branch","commit","technical","architecture","resource"},
    "UI_RULES.md":{"ui","screen","layout","hover","highlight","focus","map","worldmap","city","inventory","equipment","shop","visual","resolution","carousel","selection"},
    "ART_DIRECTION.md":{"art","asset","character","enemy","background","animation","rig","alpha","vfx","visual","portrait","item"},
    "AI_WORKFLOW.md":{"task","review","developer","workflow","branch","test","commit","scope","risk","approval"},
}

PINNED_CORE = """\
<PINNED_CORE_RULES>
- Echoes of Pythonia is a Godot 4 RPG migrated from terminal v0.24.7.
- Latest explicit owner decision wins; do not silently create or replace canon.
- Work only on approved AI/task branches; never modify snapshot/*, main, or release/* directly.
- snapshot/pre-ai-team-2026-09-10 is read-only.
- UI is presentation; domain services own combat, economy, quests, saves, RNG and persistent state.
- Persistent IDs and save fields are compatibility contracts.
- Do not use destructive Git commands, force-push, erase user changes, or delete unknown files.
- If unexplained dirty/untracked work exists, STOP rather than cleaning or stashing it.
- Gameplay/code changes require relevant tests and final validation before approval.
- Canonical full validation is .\\scripts\\check.ps1 when available.
- Meaningful UI changes require 1920x1080 review and functional 1280x720 review.
- New creative art requires owner approval before production integration.
- Enemy/boss generation and regeneration must read AI_CONTEXT/ART_DIRECTION.md section 35
  and prepare its current class/map/region references with scripts/build_art_reference_board.py --region.
  Prior enemy artwork is identity-only, not a rendering-style reference. Missing references block art review.
- Reviewer verdicts: APPROVED, CHANGES_REQUESTED, HUMAN_DECISION_REQUIRED.
- Reviewer is read-only during review; Developer performs fixes.
- Maximum default review cycles: 4.
- Permanent companion death must never be a hidden random proc.
- Pierrot player-facing terminology uses "Szczęście", not "LCK".
- Do not regress graphical systems into terminal-style list-first UI without approval.
- If an exact number is missing, inspect authoritative code/tests in repository-aware stages instead of inventing it.
</PINNED_CORE_RULES>
"""

@dataclass(frozen=True)
class Section:
    document: str
    heading: str
    level: int
    body: str
    order: int

    @property
    def text(self) -> str:
        return f"{'#' * self.level} {self.heading}\n{self.body}".strip()

@dataclass(frozen=True)
class SelectedSection:
    section: Section
    score: float

def _norm(token: str) -> str:
    return token.casefold()

def tokenize(text: str) -> set[str]:
    tokens = {_norm(m.group(0)) for m in WORD_RE.finditer(text)}
    tokens = {t for t in tokens if len(t) >= 2 and t not in STOPWORDS}
    expanded = set(tokens)
    for token in list(tokens):
        expanded.update(ALIASES.get(token, set()))
    return expanded

def parse_markdown(document: str, text: str) -> list[Section]:
    sections = []
    heading = "Document preamble"
    level = 2
    body = []
    order = 0

    def flush():
        nonlocal order, body
        rendered = "\n".join(body).strip()
        if rendered:
            sections.append(Section(document, heading, level, rendered, order))
            order += 1
        body = []

    for line in text.splitlines():
        match = HEADING_RE.match(line)
        if match:
            flush()
            level = min(4, max(1, len(match.group(1))))
            heading = match.group(2).strip()
        else:
            body.append(line)
    flush()
    return sections

def detect_domains(task: str, tokens: set[str]) -> set[str]:
    text = task.casefold()
    domains = set()

    if tokens & {"ui","screen","layout","hover","highlight","focus","map","worldmap","selection","visual","carousel"}:
        domains.add("ui")
    if tokens & {"art","asset","character","background","animation","rig","alpha","vfx","portrait"}:
        domains.add("art")
    if tokens & {"save","migration","schema","persistence","codec"}:
        domains.add("save")
    if tokens & {"combat","damage","turn","skill","warrior","hunter","mage","pierrot"}:
        domains.add("combat")
    if tokens & {"git","branch","commit","diff","technical","architecture","code","gdscript","test","bug"}:
        domains.add("technical")
    if tokens & {"quest","guild","economy","companion","rift","dungeon","progression","balance"}:
        domains.add("gameplay")

    # "bez zmiany mechanik" means mechanics are a boundary, not the main topic.
    if re.search(r"\bbez\s+zmian[ay]?\s+mechanik|\bbez\s+zmiany\s+mechanik", text):
        domains.discard("gameplay")
        domains.add("mechanics_boundary")

    return domains

def _doc_domain_bonus(document: str, domains: set[str]) -> float:
    bonus = 0.0

    if "ui" in domains:
        bonus += {
            "UI_RULES.md": 24.0,
            "TECHNICAL_RULES.md": 5.0,
            "AI_WORKFLOW.md": 3.0,
            "PROJECT_BIBLE.md": 2.0,
            "GAME_DESIGN.md": 0.5,
            "ART_DIRECTION.md": 1.0,
        }.get(document, 0.0)

    if "art" in domains:
        bonus += {"ART_DIRECTION.md":24.0,"UI_RULES.md":5.0,"TECHNICAL_RULES.md":4.0,"AI_WORKFLOW.md":3.0}.get(document,0.0)

    if "save" in domains:
        bonus += {"TECHNICAL_RULES.md":20.0,"GAME_DESIGN.md":10.0,"AI_WORKFLOW.md":6.0}.get(document,0.0)

    if "combat" in domains:
        bonus += {"GAME_DESIGN.md":18.0,"TECHNICAL_RULES.md":7.0,"UI_RULES.md":5.0,"AI_WORKFLOW.md":3.0}.get(document,0.0)

    if "technical" in domains:
        bonus += {"TECHNICAL_RULES.md":20.0,"AI_WORKFLOW.md":8.0}.get(document,0.0)

    if "gameplay" in domains:
        bonus += {"GAME_DESIGN.md":18.0,"PROJECT_BIBLE.md":7.0,"TECHNICAL_RULES.md":5.0}.get(document,0.0)

    if "mechanics_boundary" in domains:
        # Strongly prefer UI/technical boundary rules; avoid generic gameplay sections
        # that only happen to mention "region".
        bonus += {"UI_RULES.md":8.0,"TECHNICAL_RULES.md":8.0,"AI_WORKFLOW.md":3.0}.get(document,0.0)
        if document == "GAME_DESIGN.md":
            bonus -= 5.0

    return bonus

def _score(section: Section, task_tokens: set[str], domains: set[str]) -> float:
    ht = tokenize(section.heading)
    bt = tokenize(section.body[:8000])
    affinity = DOC_AFFINITY.get(section.document, set())

    score = len(task_tokens & ht) * 10.0
    score += len(task_tokens & bt) * 1.0
    score += len(task_tokens & affinity) * 1.5
    score += _doc_domain_bonus(section.document, domains)

    # Very strong boost for direct world-map/hover headings on UI tasks.
    heading_l = section.heading.casefold()
    if "ui" in domains:
        if "world map" in heading_l or "world-map" in heading_l:
            score += 25.0
        if "region hover" in heading_l or "hover" in heading_l:
            score += 28.0
        if "screenshot" in heading_l or "visual smoke" in heading_l:
            score += 8.0

    # Penalize unrelated region-lore sections for pure UI map tasks.
    if "ui" in domains and "map" in task_tokens:
        if section.document in {"PROJECT_BIBLE.md","GAME_DESIGN.md"}:
            if any(x in heading_l for x in ("region 5","region 6","dungeon","level bands","region count")):
                score -= 30.0

    if len(section.body) <= 1800:
        score += 0.35
    return score

def _pinned_bonus(section: Section) -> float:
    heading = section.heading.casefold()
    always = {
        "PROJECT_BIBLE.md":("non-negotiable ai rules","source-of-truth priority"),
        "TECHNICAL_RULES.md":("source-of-truth priority","git safety","stop conditions"),
        "AI_WORKFLOW.md":("core operating principle","protected branches","preflight","reviewer verdicts","maximum review cycles"),
    }
    return 35.0 if any(x in heading for x in always.get(section.document, ())) else 0.0

def select_sections(task: str, documents: dict[str, str], max_chars: int, max_sections: int):
    task_tokens = tokenize(task)
    domains = detect_domains(task, task_tokens)

    all_sections = []
    for doc, text in documents.items():
        all_sections.extend(parse_markdown(doc, text))

    scored = []
    for section in all_sections:
        score = _score(section, task_tokens, domains) + _pinned_bonus(section)
        if score > 0:
            scored.append(SelectedSection(section, score))

    scored.sort(key=lambda x: (-x.score, x.section.document, x.section.order))

    chosen = []
    used = len(PINNED_CORE)
    for item in scored:
        if len(chosen) >= max_sections:
            break
        block = f'\n<PROJECT_EXCERPT document="{item.section.document}" heading="{item.section.heading}">\n{item.section.text}\n</PROJECT_EXCERPT>\n'
        if used + len(block) > max_chars:
            continue
        chosen.append(item)
        used += len(block)

    ordered = sorted(
        chosen,
        key=lambda x: (list(documents.keys()).index(x.section.document), x.section.order),
    )

    parts = [PINNED_CORE]
    for item in ordered:
        parts.append(
            f'\n<PROJECT_EXCERPT document="{item.section.document}" heading="{item.section.heading}">\n'
            f'{item.section.text}\n</PROJECT_EXCERPT>\n'
        )

    return "\n".join(parts), ordered, sum(len(x) for x in documents.values())
