"""Read-only production/capture checks and derived review contact sheets."""
import hashlib
import json
from pathlib import Path
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import (
    load_art_policy, policy_fingerprint, require_enemy_coverage, enemy_review_targets,
)


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    output = HERE / 'integration'
    approval = read(output / 'approval.json')
    capture_dir = output / 'in_game_final'
    captured = read(capture_dir / 'manifest.json')
    policy = load_art_policy(ROOT)
    assert policy_fingerprint(ROOT, policy) == captured['policy_fingerprint']
    shots = [capture_dir / name for name in captured['images']]
    require_enemy_coverage(ROOT, policy, shots, [a['source'] for a in approval['assets']])
    checks = []
    for layout in captured['layouts']:
        enemy_id = layout['scenario'].removeprefix('combat_')
        record = next(a for a in approval['assets'] if a['enemy'] == enemy_id)
        assert layout['background'] == f'res://assets/combat/backgrounds/{record["region"]}_day.png'
        for role in ['hero','enemy']:
            actor = layout[role]
            x,y,w,h = actor['painted_rect']
            sx,sy,sw,sh = actor['slot_rect']
            assert x >= sx - 0.1 and x+w <= sx+sw+0.1
            assert y >= sy - 0.1 and y+h <= sy+sh+0.1
            assert abs(y+h - (sy+sh*0.965)) < 0.1
            source = ROOT / 'godot' / actor['source'].removeprefix('res://')
            with Image.open(source) as art:
                left,top,right,bottom = art.convert('RGBA').getchannel('A').getbbox()
            assert actor['crop'] == [left,top,right-left,bottom-top], (enemy_id, role, actor['crop'])
            assert abs(w/h - (right-left)/(bottom-top)) < 0.001
        assert layout['enemy']['source'] == record['source'].replace('godot/','res://',1)
        assert not layout['enemy']['flip_h']
        ex,ey,ew,eh = layout['enemy']['painted_rect']
        hx,hy,hw,hh = layout['hero']['painted_rect']
        assert hx+hw <= ex
        assert abs(ey+eh-hy-hh) < 0.1
        checks.append({'scenario': layout['scenario'], 'resolution': layout['resolution'],
                       'full_source_crop': True, 'slot_containment': True,
                       'shared_ground_line': True, 'correct_region': True})
    assert len(checks) == 50
    boards = output / 'boards'
    boards.mkdir(exist_ok=True)
    font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
    assets = approval['assets']
    board_names = []
    for batch in range(0,len(assets),2):
        group = assets[batch:batch+2]
        sheet = Image.new('RGB',(1536,464*len(group)),'#162330')
        draw = ImageDraw.Draw(sheet)
        for row,record in enumerate(group):
            for col,(w,h) in enumerate([(1280,720),(1920,1080)]):
                name = f'combat_{record["enemy"]}_{w}x{h}.png'
                with Image.open(capture_dir / name) as image:
                    assert image.size == (w,h)
                    image.thumbnail((768,432), Image.Resampling.LANCZOS)
                    sheet.paste(image,(col*768,row*464+32))
                draw.text((col*768+12,row*464+3),f'{record["enemy"]} — {w} × {h}',font=font,fill='#efc96c')
        filename = f'combat_review_{batch//2+1:02}.png'
        sheet.save(boards / filename)
        board_names.append(filename)
    logs = {}
    for name in ['import','capture']:
        log_path = capture_dir / (name+'.log')
        if not log_path.exists():
            log_path = output / 'in_game' / (name+'.log')
        content = log_path.read_text(encoding='utf-8')
        logs[name] = [line.strip() for line in content.splitlines()
                      if 'ERROR:' in line or 'WARNING:' in line or 'Leaked instance:' in line]
    manifest = dict(owner_art_approval=True, installed=25, deferred=['venom_spider'],
                    policy_fingerprint=captured['policy_fingerprint'],
                    geometry_checks=checks, review_targets=enemy_review_targets(ROOT,policy,shots),
                    engine_log_diagnostics=logs, visual_review='PENDING_MANUAL_INSPECTION',
                    source_review='../qualitative_review.json', boards=board_names)
    (output / 'capture_checks.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # Preserve the approved before/after gallery: the production paths now point
    # to new bytes, so its old column must link to the hash-verified backup.
    gallery = HERE / 'review/index.html'
    text = gallery.read_text(encoding='utf-8')
    for record in assets:
        original = '../../../' + record['source']
        backup = '../integration/before/enemies/' + Path(record['source']).name
        text = text.replace(original, backup)
    text = text.replace('Nowe grafiki nie zostały podłączone do gry; wymagają Twojej akceptacji oraz późniejszego sprawdzenia skali i styku z podłożem w Godot.',
                        'Właściciel zatwierdził zestaw: 25 grafik podłączono do gry. Pająk pozostaje do korekty. Ta galeria zachowuje porównanie z kopiami oryginałów; aktualne rendery są w raporcie integracji.')
    gallery.write_text(text,encoding='utf-8')
    print('50/50 capture geometry/source/region checks passed; 13 boards prepared.')
    print(json.dumps(logs,ensure_ascii=False))


if __name__ == '__main__':
    main()
