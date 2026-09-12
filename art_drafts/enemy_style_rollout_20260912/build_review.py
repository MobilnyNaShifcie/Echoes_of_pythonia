"""Local before/after gallery using existing reference-board and alpha gates.

This is batch evidence, not a new policy or a production installation command.
It never labels an unreviewed generated candidate as approved.
"""
import hashlib
import html
import json
import os
import re
from pathlib import Path
import subprocess
import sys
from urllib.parse import quote

from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from echoes_autopilot_desktop.art_policy import inspect_enemy_png,load_art_policy,policy_fingerprint

REGIONS={
    'twilight_plains':'Zmierzchowe Równiny',
    'black_forest':'Czarny Las',
    'silentwater_marshes':'Bagna Cichej Wody',
    'ashen_borderlands':'Popielne Pogranicze',
    'ice_coast':'Lodowe Wybrzeże',
}


def read(path):return json.loads(path.read_text(encoding='utf-8'))
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def href(path,out):return quote(os.path.relpath(path,out).replace('\\','/'),safe='/')


def main():
    # Display labels come from the game, not a parallel region-name catalogue.
    labels=re.findall(r'"([a-z_]+)",\s*"([^"\n]+)"',(ROOT/'godot/core/world/region_catalog.gd').read_text(encoding='utf-8'))
    REGIONS.update({key:value for key,value in labels if key in REGIONS})
    inventory=read(HERE/'audit/inventory.json')
    decisions=read(HERE/'decisions.json')
    profiles=read(HERE/'processing.json')
    qualitative=read(HERE/'qualitative_review.json')
    out=HERE/'review';out.mkdir(exist_ok=True)
    policy=load_art_policy(ROOT)
    fingerprint=policy_fingerprint(ROOT,policy)
    if fingerprint!=inventory['policy_fingerprint']:
        raise ValueError('Canonical references or policy changed since this batch audit; re-review required')
    records=[];groups={region:[] for region in REGIONS}
    for original in inventory['assets']:
        name=original['enemy'];source=ROOT/original['source']
        if digest(source)!=original['source_sha256']:
            raise ValueError(f'Production source changed since audit: {name}; preserve that edit and re-audit')
        record={**original}
        if name in decisions['keep']:
            record.update(decision='KEEP_EXISTING',reason=decisions['keep'][name])
        else:
            pilot=name in decisions['reuse_pilot']
            candidate=(HERE/decisions['reuse_pilot'][name]).resolve() if pilot else HERE/'processed'/f'{name}.png'
            record.update(decision='PENDING_GENERATION_OR_ALPHA',owner_art_approval=False,production_changed=False)
            if candidate.exists():
                variant=profiles.get(name,{}).get('variant','v1')
                receipt=HERE/'raw'/f'{name}_{variant}.json'
                qa=HERE/'processed/qa'/f'{name}_alpha_report.json'
                record.update(decision='CANDIDATE_PENDING_OWNER_AND_ENGINE_REVIEW',candidate=candidate.relative_to(ROOT).as_posix(),
                              pixel_gate=inspect_enemy_png(candidate),variant='pilot' if pilot else variant,
                              generation_receipt=None if pilot else receipt.relative_to(ROOT).as_posix(),
                              alpha_report=None if pilot else qa.relative_to(ROOT).as_posix())
                if qa.exists() and not pilot:
                    alpha=read(qa)
                    raw=HERE/'raw'/f'{name}_{variant}.png'
                    # Early v1 reports predate explicit variant metadata;
                    # their recorded raw checksum still binds the artwork.
                    if alpha.get('variant','v1')!=variant or alpha['source_sha256']!=digest(raw):
                        raise ValueError(f'Stale alpha evidence: {name}')
                    if alpha['pixel_gate']['sha256']!=digest(candidate):
                        raise ValueError(f'Candidate changed after alpha review: {name}')
                    record['source_silhouette_touched_canvas']=alpha['source_silhouette_touched_canvas']
                    record['remaining_key_candidate_pixels']=alpha['remaining_key_candidate_pixels']
                record['source_art_observation']=qualitative['observations'][name]
                record['compared_style_references']=read(HERE/'audit'/f'{original["region"]}_references.references.json')['references']
                record['source_art_review']='NEEDS_REVISION' if name in qualitative['needs_revision'] else 'CANDIDATE_FOR_OWNER_REVIEW'
                if name in qualitative['needs_revision']:
                    record['revision_required']=qualitative['needs_revision'][name]
                groups[original['region']].append((source,candidate,record))
        records.append(record)
    generated=sum(r['decision']=='CANDIDATE_PENDING_OWNER_AND_ENGINE_REVIEW' for r in records)
    manifest=dict(canonical_policy='AI_CONTEXT/ART_DIRECTION.md',policy_fingerprint=fingerprint,
                  active_sources=len(records),target_candidates=26,prepared_candidates=generated,
                  kept_existing=len(decisions['keep']),production_source_hashes_unchanged=True,
                  owner_art_approval=False,engine_capture_review='NOT_RUN',
                  formal_enemy_review='NOT_RUN',source_art_review_notes='qualitative_review.json',
                  unresolved_revisions=qualitative['needs_revision'],
                  generator='built-in image_gen__imagegen, followed by owner-authorized local alpha extraction',
                  assets=records)
    (out/'batch_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    font=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',23)
    sections=[]
    for region,entries in groups.items():
        if not entries:continue
        boardpath=out/f'{region}_before_after.png'
        subprocess.run([sys.executable,str(ROOT/'scripts/build_art_reference_board.py'),'--output',str(boardpath),
                        *[str(p) for source,candidate,_ in entries for p in [source,candidate]]],check=True,capture_output=True)
        with Image.open(boardpath) as board:
            labelled=Image.new('RGB',(board.width,board.height+54),'#162330');labelled.paste(board,(0,54))
        draw=ImageDraw.Draw(labelled)
        for col in range(4):draw.text((col*420+16,12),'OBECNIE' if col%2==0 else 'PROPOZYCJA',font=font,fill='#9aa9ba' if col%2==0 else '#efc96c')
        labelled.save(boardpath)
        cards=[]
        for source,candidate,record in entries:
            name=html.escape(record['enemy'])
            caution=record.get('revision_required') or ('Wymaga dalszej korekty kadru.' if record.get('source_silhouette_touched_canvas') else 'Podgląd do zatwierdzenia.')
            qa=HERE/'processed/qa'/f'{record["enemy"]}_alpha_review.png'
            links=f'<a href="{href(qa,out)}">Jasne / ciemne tło</a>' if qa.exists() else ''
            if record.get('generation_receipt'):
                links+=f' · <a href="{href(ROOT/record["generation_receipt"],out)}">Prompt i referencje</a>'
            cards.append(f'<article><h3>{name}</h3><div class="pair"><figure><figcaption>Obecnie</figcaption><a href="{href(source,out)}"><img loading="lazy" src="{href(source,out)}" alt="Obecnie: {name}"></a></figure><figure><figcaption>Propozycja</figcaption><a href="{href(candidate,out)}"><img loading="lazy" src="{href(candidate,out)}" alt="Propozycja: {name}"></a></figure></div><p>{caution} {links}</p></article>')
        ref=HERE/'audit'/f'{region}_references.png'
        sections.append(f'<section id="{region}"><h2>{REGIONS[region]}</h2><p><a href="{boardpath.name}">Cały region — porównanie PNG</a> · <a href="{href(ref,out)}">Kanoniczne wzorce klas i regionu</a></p>{"".join(cards)}</section>')
    navigation=''.join(f'<a href="#{r}">{title}</a>' for r,title in REGIONS.items())
    page='''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Echoes of Pythonia — przegląd przeciwników</title>
<style>body{margin:0;background:#0d1720;color:#e3e8ee;font:16px/1.5 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:32px}h1{font-size:clamp(26px,4vw,42px);margin:0}h2{margin-top:60px;color:#efc96c}h3{font-size:19px;margin:0 0 12px}p{color:#a9b7c7}a{color:#dfc382}nav{display:flex;flex-wrap:wrap;gap:16px;margin:24px 0}article{background:#142332;padding:20px;margin:20px 0;border-radius:12px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0;min-width:0}figcaption{color:#a9b7c7;margin-bottom:8px}figure:nth-child(2) figcaption{color:#efc96c}img{display:block;width:100%;height:490px;object-fit:contain}article p{font-size:14px}strong{color:#efc96c}@media(max-width:650px){main{padding:16px}article{padding:12px}.pair{gap:8px}img{height:300px}}</style>
<main>'''+f'<h1>Spójność przeciwników</h1><p><strong>{generated}/26</strong> przygotowanych kandydatów · 17 istniejących grafik pozostaje bez zmian.</p><p>Przegląd źródłowych ilustracji, nie zrzuty z silnika. Nowe grafiki nie zostały podłączone do gry; wymagają Twojej akceptacji oraz późniejszego sprawdzenia skali i styku z podłożem w Godot. Obraz po lewej: obecny. Po prawej: propozycja.</p><nav>{navigation}</nav>'+''.join(sections)+'<p><a href="batch_manifest.json">Manifest, ścieżki, kontrole PNG i statusy</a></p></main></html>'
    (out/'index.html').write_text(page,encoding='utf-8')
    (out/'qualitative_review.json').write_text(json.dumps(qualitative,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'{generated}/26 candidates, 17 kept; production source hashes unchanged; '+str(out/'index.html'))


if __name__=='__main__':main()
