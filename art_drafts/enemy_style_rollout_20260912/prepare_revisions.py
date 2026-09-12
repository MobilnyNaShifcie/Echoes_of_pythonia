"""Explicit reviewed framing corrections; retain the rejected first variants."""
import argparse
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--extra',action='store_true');args=parser.parse_args()
    jobs=json.loads((HERE/'jobs.json').read_text(encoding='utf-8'))
    corrections={
        'nature_guardian':'The highest antler branch is cut at the top edge. Complete the pointed branch tip and keep both root feet, entire shield and the open hand in frame.',
        'venom_spider':'The nearest front walking-leg claw is cut off at the bottom. Complete that claw tip. Show exactly eight legs, all complete with clear joints and full claws. Do not shorten or hide a leg to fit.',
        'blackwood_executioner':'The uppermost branches of the wooden shoulder are cut at the top. Complete those branch tips, preserving the full axe, both hands and both heavy boots.',
        'bone_crocodile':'Only three walking legs are visible. Reveal its fourth (far hind) leg with a complete knee, ankle and clawed foot visible below the rear belly, separately from the nearest rear leg. A crocodile has exactly FOUR walking legs: two front and two rear. Preserve the existing bone plates, snout, curled tail and three already visible legs; no extra fifth leg.',
    }
    if args.extra:
        corrections={
            'drowned_mother':'The uppermost tip of the reed staff and a trailing edge of the long robe reach the canvas edge. Restore complete staff tip and entire trailing robe edge; keep crown, hands and both feet complete and unchanged.',
            'venom_spider':'Adjust stance so all EIGHT walking legs can be counted individually, in four pairs, four on each side of the cephalothorax. Show eight separated foot tips and traceable joint chains. The two venom fangs are NOT legs. Use a slightly elevated left-facing three-quarter view, head leading left, abdomen on right. Fan far-side legs apart so none vanish behind near-side legs. Keep bark/olive chitin and green venom; no wings or scorpion tail. Prioritize readable anatomy over copying the old pose.'}
    result=[]
    for job in jobs:
        if job['enemy'] not in corrections: continue
        extra_spider=args.extra and job['enemy']=='venom_spider'
        source=HERE/'raw'/f"{job['enemy']}_{'v2' if extra_spider else 'v1'}.png"
        new={**job,'variant':'v3' if extra_spider else 'v2','revision_of':source.as_posix()}
        new['references']=[str(source)]+job['references'][1:]
        new['prompt']=(
            'EDIT THE FIRST IMAGE. This is a narrowly scoped framing repair of the new stylized enemy, '
            'not another redesign. Preserve its illustrated contours, grouped material shading, palette, '
            'face, species, pose, accessories and all complete body parts. '+corrections[job['enemy']]+' '
            'ZOOM OUT strongly: the entire creature including every tip must occupy ONLY the central 65% '
            'of the canvas width and height. Keep a very wide continuous perfectly solid #FF00FF magenta '
            'margin on ALL FOUR edges. No part of the creature can touch any canvas edge. No frame. '
            'Do not crop the delivered bitmap tightly. No magenta reflected light or rim lighting; '
            'magenta is solely the removable matte, also filling every empty gap. '
            'Class references define the existing illustration quality, region map defines palette, '
            'never copy their scenery.\n\nOriginal canonical creative brief (identity unchanged):\n'+job['prompt'])
        if extra_spider:
            new['prompt']='ESSENTIAL ANATOMY CORRECTION: change the stance for eight clearly separate legs. This overrides preserve-pose wording in the earlier brief. '+new['prompt']
        result.append(new)
    path=HERE/('extra_revision_jobs.json' if args.extra else 'revision_jobs.json')
    if path.exists() and any((HERE/'raw'/f"{j['enemy']}_{j['variant']}.png").exists() for j in result):
        raise FileExistsError('Never change requests after a revision has been generated')
    path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Prepared',len(result),'framing revisions')


if __name__=='__main__': main()
