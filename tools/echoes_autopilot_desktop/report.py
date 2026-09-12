from __future__ import annotations

import html
from pathlib import Path


def render_report(directory: Path, state: dict) -> Path:
    esc = lambda value: html.escape(str(value))
    labels = {"PASSED": "Zaliczone", "NEEDS_CHANGES": "Wymaga poprawek",
              "BLOCKED": "Przebieg zablokowany", "STOPPED": "Zatrzymane",
              "CAPTURED": "Obrazy gotowe", "TESTED": "Testy zaliczone",
              "TESTING": "Trwają testy", "CAPTURING": "Renderowanie scen",
              "REVIEWING": "Sol ocenia grę", "DEVELOPING": "Astra przygotowuje zmiany"}
    status_label = labels.get(state.get("status"), state.get("status", ""))
    developer_summary = state.get('developer_summary', '')
    if not developer_summary:
        answers = sorted(directory.glob('cycle-*/astra/answer.json'))
        if answers:
            try:
                import json
                developer_summary = json.loads(answers[-1].read_text(encoding='utf-8-sig')).get('summary', '')
            except (OSError, ValueError):
                pass
    reviews = state.get("reviews", [])
    findings = [f for review in reviews for f in review.get("findings", [])]
    cards = "".join(
        f'<article><span class="tag">{esc(f["priority"])} · {esc(f["category"])}</span>'
        f'<h3>{esc(f["title"])}</h3><p>{esc(f["recommendation"])}</p>'
        f'<small>{esc(" | ".join(f["evidence"]))}</small></article>' for f in findings)
    suggestions = "".join(f'<li>{esc(s)}</li>' for r in reviews for s in r.get("suggestions", []))
    stages = "".join(f'<li><b>{esc(s["name"])}</b> — {esc(s["status"])} '
                     f'<a href="{esc((directory / s["log"]).as_uri())}">log</a></li>'
                     for s in state.get("checks", []))
    gallery = ""
    for shot in state.get("screenshots", []):
        path = directory / shot
        before = directory / "before" / path.name
        prior = (f'<a href="{esc(before.as_uri())}">Przed zmianą</a> · ' if before.exists() else "")
        gallery += (f'<figure><a href="{esc(path.as_uri())}"><img loading="lazy" '
                    f'src="{esc(path.as_uri())}" alt="{esc(path.stem)}"></a>'
                    f'<figcaption>{prior}{esc(path.stem)}</figcaption></figure>')
    patches = "".join(f'<details><summary>{esc(p.relative_to(directory))}</summary>'
                      f'<pre>{esc(p.read_text(encoding="utf-8"))}</pre></details>'
                      for p in sorted(directory.glob("cycle-*/backup/applied.diff")))
    summaries = "".join(f'<p>{esc(r["summary"])}</p>' for r in reviews)
    issue_labels = {'open': 'Otwarty', 'fixed': 'Naprawiony', 'returned': 'Powrócił', 'unverified': 'Do weryfikacji'}
    issue_rows = ''.join(f'<tr><td>{esc(i["id"])}</td><td>{esc(issue_labels[i["status"]])}</td><td>{esc(i["title"])}</td></tr>' for i in state.get('issues', []))
    completed = ''.join(f'<li>{esc(stage)}</li>' for stage in state.get('completed_stages', []))
    journey_steps = ''.join(f'<li>{esc(step["id"])}: {"PASS" if step["ok"] else "FAIL"} — {esc(step["detail"])}</li>' for step in state.get('journeys', {}).get('steps', []))
    workspace = state.get('workspace', {})
    workspace_text = (f'<p>Kopia robocza: {esc(workspace.get("root", ""))}<br>Wybrany branch: {esc(workspace.get("ref", ""))}. Zmiany oczekują na przeniesienie do głównej gry.</p>' if workspace else '')
    document = f'''<!doctype html><html lang="pl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Echoes — raport</title>
<style>
:root{{color-scheme:dark;font:16px/1.6 system-ui;background:#10131a;color:#e6e8f0}}
body{{max-width:1250px;margin:48px auto;padding:0 28px}}h1{{font-size:38px;margin:8px 0}}
h2{{margin-top:36px}}a{{color:#9fbaff}}small,figcaption{{color:#a2abc0}}
.eyebrow{{letter-spacing:3px;color:#d5b879;font-size:12px}}.tag{{color:#d5b879}}
article,details,.intro{{background:#1a202c;border:1px solid #303949;border-radius:14px;padding:22px;margin:14px 0}}
.gallery{{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:20px}}
figure{{margin:0}}img{{width:100%;border-radius:10px}}pre{{white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px}}
.error{{color:#ffb0a9}}li{{margin:8px 0}}
</style><div class="eyebrow">ECHOES OF PYTHONIA / AUTOPILOT</div>
<h1>{esc(status_label)}</h1><div class="intro"><b>{esc(state.get("task", ""))}</b>
<p>Astra: {esc(state.get("developer_model", ""))} · Sol: {esc(state.get("reviewer_model", ""))}</p>
<p>Projekt: {esc(state.get("project_root", ""))}<br>Branch: {esc(state.get("git_before", {}).get("branch", ""))} · commit: {esc(state.get("git_before", {}).get("head", ""))}</p>
<p>Tryb: {esc(state.get("mode", ""))} · Cykl: {esc(state.get("cycle", 0))}</p>
<p class="error">{esc(state.get("error", ""))}</p>
<p>{esc(state.get("recovery_notes", ""))}</p></div>
<h2>Wynik pracy Astry</h2><p>{esc(developer_summary) if developer_summary else "Brak propozycji w tym trybie."}</p>
<h2>Postęp i odzyskiwanie</h2><p>Etap: {esc(state.get("phase", ""))}</p>{workspace_text}<details><summary>Ukończone etapy: {len(state.get("completed_stages", []))}</summary><ul>{completed}</ul></details>
<h2>Czynności gracza</h2><ul>{journey_steps or "<li>Nie wykonywano.</li>"}</ul>
<h2>Rejestr usterek</h2><table><tr><th>Numer</th><th>Stan</th><th>Problem</th></tr>{issue_rows}</table>
<h2>Kontrole techniczne</h2><ul>{stages or '<li>Nie wykonano.</li>'}</ul>
<h2>Ocena Sola</h2>{summaries or '<p>Nie uzyskano jeszcze oceny modelu.</p>'}
{cards}<h2>Proponowane usprawnienia</h2><ul>{suggestions or '<li>Brak zaleceń.</li>'}</ul>
<h2>Pokrycie wizualne</h2><p>Ocena dotyczy wyłącznie poniższych scen i rozdzielczości.
Zrzuty przedstawiają kontrolowane scenariusze, nie całą możliwą rozgrywkę.</p>
<div class="gallery">{gallery}</div><h2>Wprowadzone zmiany</h2>{patches or '<p>Brak zmian z tego przebiegu.</p>'}
<p>Pełna historia: <a href="{esc((directory / 'state.json').as_uri())}">state.json</a> ·
<a href="{esc((directory / 'events.jsonl').as_uri())}">dziennik</a></p></html>'''
    path = directory / "report.html"
    path.write_text(document, encoding="utf-8")
    return path
