"""Authorized deterministic alpha pass; never overwrites production or raw files.

Explicit neutral profiles and reviewed hole seeds; magenta uses exterior-only
connectivity so internal purple magic is not globally keyed away. This module
shares the pilot's verified local unmatting/padding approach and project gate.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
sys.path.insert(0,str(ROOT/'tools'))
sys.path.insert(0,str(HERE.parent/'enemy_style_pilot_20260912'))
from prepare_regional_item_icon import dilate, extend_colors
from prepare_alpha import padded, connected_background, extract
from echoes_autopilot_desktop.art_policy import inspect_enemy_png


def chroma_cut(image, holes=(), reviewed_all_matte=False, despill_boundary=False, strict_matte_despill=False):
    rgb=np.asarray(image.convert('RGB')).astype(np.float32)
    r,g,b=rgb.transpose(2,0,1)
    candidate=(r>218)&(b>218)&(g<65)
    # Require uniform magenta corners before interpreting any color as a key.
    if not all(candidate[y,x] for x,y in [(0,0),(-1,0),(0,-1),(-1,-1)]):
        raise ValueError('Not a uniform magenta source; inspect and provide a profile')
    mask=Image.fromarray(np.pad(candidate,1,constant_values=True).astype(np.uint8)*255).copy()
    ImageDraw.floodfill(mask,(0,0),128,thresh=0)
    for x,y in holes:
        if not (0<=x<image.width and 0<=y<image.height) or mask.getpixel((x+1,y+1)) not in (128,255):
            raise ValueError('Reviewed hole is not magenta background')
        ImageDraw.floodfill(mask,(x+1,y+1),128,thresh=0)
    # Explicit per-art palette review permits removing the same matte from
    # enclosed gaps. Never enable for genuine magenta eyes/corruption by default.
    bgmask=candidate if reviewed_all_matte else np.asarray(mask)[1:-1,1:-1]==128
    edge=dilate(bgmask,6)&~bgmask
    core=~(bgmask|edge)
    fg=extend_colors(rgb,core,12)
    bg=extend_colors(rgb,bgmask,6)
    delta=fg-bg
    est=np.sum((rgb-bg)*delta,axis=2)/np.maximum(np.sum(delta*delta,axis=2),1)
    residual=np.max(np.abs(bg+est[:,:,None]*delta-rgb),axis=2)
    blend=edge&(est>.01)&(est<1)&(residual<12)
    alpha=np.ones(bgmask.shape,np.float32)
    alpha[bgmask]=0
    alpha[blend]=est[blend]
    clean=rgb.copy()
    clean[blend]=(rgb[blend]-bg[blend]*(1-alpha[blend,None]))/alpha[blend,None]
    interior_spill=np.zeros(bgmask.shape,dtype=bool)
    if reviewed_all_matte or despill_boundary:
        # Residual chroma spill only in the six-pixel boundary band; opaque
        # interior colors are untouched. Recover the black/painted contour,
        # never blur or erode it. Pure matte has already been made transparent.
        excess=np.maximum(np.minimum(clean[:,:,0],clean[:,:,2])-clean[:,:,1],0)
        if strict_matte_despill:
            # Explicit per-image palette review only. Dark pink matte flecks
            # also occur in grey ribbons/hair; a brightness-only threshold
            # misses those. Never enable for genuine violet corruption.
            interior_spill=(~bgmask)&(r>60)&(b>60)&(np.minimum(r,b)-g>50)
        spill=(edge|interior_spill)&(excess>16)
        coverage=np.clip(1-excess/255,.01,1)
        clean[spill]=(clean[spill]-(1-coverage[spill,None])*np.array([255,0,255]))/coverage[spill,None]
        alpha[spill]*=coverage[spill]
    rgba=np.dstack((np.clip(clean,0,255),np.rint(alpha*255))).astype(np.uint8)
    rgba[rgba[:,:,3]<=3]=0
    preserved=core&~interior_spill
    assert np.array_equal(rgba[preserved,:3],rgb[preserved].astype(np.uint8))
    return Image.fromarray(rgba),dict(background_fraction=float(bgmask.mean()),unchanged_core_rgb_pixels=int(preserved.sum()),reviewed_interior_spill_pixels=int((interior_spill&core).sum()))


def preview(name, image, qa):
    thumb=image.copy()
    thumb.thumbnail((690,730),Image.Resampling.LANCZOS)
    out=Image.new('RGB',(1440,800),'#142333')
    out.paste(Image.new('RGB',(720,800),'#efe9df'),(720,0))
    draw=ImageDraw.Draw(out)
    font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
    for x,color in [(0,'#e1e7ef'),(720,'#1b2937')]:
        out.paste(thumb,(x+(720-thumb.width)//2,45+(740-thumb.height)//2),thumb)
        draw.text((x+20,10),name,font=font,fill=color)
    out.save(qa/(name+'_alpha_review.png'))


def process(name,profiles):
    profile=profiles.get(name,{'mode':'magenta','holes':[]})
    source=HERE/'raw'/(name+'_'+profile.get('variant','v1')+'.png')
    with Image.open(source) as original:
        if original.mode=='RGBA' and original.getchannel('A').getextrema()[0]==0:
            art=original.copy()
            details={'preserved_existing_alpha':True}
        elif profile['mode']=='neutral':
            art,details=extract(original,profile['minimum'],profile['spread'],profile.get('holes',[]))
        else:
            art,details=chroma_cut(original,profile.get('holes',[]),profile.get('reviewed_all_matte',False),profile.get('despill_boundary',False),profile.get('strict_matte_despill',False))
    bbox=art.getchannel('A').getbbox()
    touched=bool(bbox and (bbox[0]==0 or bbox[1]==0 or bbox[2]==art.width or bbox[3]==art.height))
    result,framing=padded(art)
    out=HERE/'processed'
    qa=out/'qa'
    qa.mkdir(parents=True,exist_ok=True)
    art.save(qa/(name+'_unframed.png'))
    result.save(out/(name+'.png'))
    preview(name,result,qa)
    # Visible diagnostic: these may be legitimate white details/purple spells.
    px=np.asarray(art)
    rgb=px[:,:,:3].astype(np.int16)
    if profile['mode']=='neutral':
        suspect=(rgb.min(axis=2)>=profile['minimum'])&(np.ptp(rgb,axis=2)<=profile['spread'])
    else:
        suspect=(rgb[:,:,0]>218)&(rgb[:,:,2]>218)&(rgb[:,:,1]<65)
    suspect&=px[:,:,3]>3
    board=Image.new('RGB',art.size,'#142333');board.paste(art,(0,0),art)
    marked=np.asarray(board).copy();marked[dilate(suspect,3)]=[0,255,0]
    Image.fromarray(marked).save(qa/(name+'_key_diagnostic.png'))
    gate=inspect_enemy_png(out/(name+'.png'))
    report=dict(enemy=name,variant=profile.get('variant','v1'),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),profile=profile,
                extraction=details,framing=framing,pixel_gate=gate,source_silhouette_touched_canvas=touched,
                remaining_key_candidate_pixels=int(suspect.sum()),
                production_changed=False,owner_art_approval=False,visual_review='PENDING',
                note='Pixel PASS is not evidence of no clipping, no matte remnants, style or correct anatomy.')
    (qa/(name+'_alpha_report.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(name,gate['status'],'touched_source_canvas=',touched,'residual_key_candidates=',int(suspect.sum()))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('enemies',nargs='*');args=parser.parse_args()
    profiles=json.loads((HERE/'processing.json').read_text(encoding='utf-8'))
    names=args.enemies or [p.stem.removesuffix('_v1') for p in (HERE/'raw').glob('*_v1.png')]
    for name in names:
        if '/' in name or '\\' in name or name.startswith('.'):
            raise ValueError('Invalid enemy id')
        process(name,profiles)


if __name__=='__main__':
    main()
