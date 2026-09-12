"""List enclosed matte islands for explicit human/visual review, never auto-key."""
from collections import deque
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent


def islands(mask):
    remaining=mask.copy(); h,w=remaining.shape
    parts=[]
    for yy,xx in zip(*np.where(remaining)):
        if not remaining[yy,xx]: continue
        queue=deque([(int(xx),int(yy))]); remaining[yy,xx]=False
        count=0; x0=x1=int(xx); y0=y1=int(yy)
        while queue:
            x,y=queue.popleft(); count+=1
            x0=min(x0,x); x1=max(x1,x); y0=min(y0,y); y1=max(y1,y)
            for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0<=nx<w and 0<=ny<h and remaining[ny,nx]:
                    remaining[ny,nx]=False; queue.append((nx,ny))
        if count>=8: parts.append(dict(seed=[int(xx),int(yy)],pixels=count,bbox=[x0,y0,x1+1,y1+1]))
    return sorted(parts,key=lambda p:-p['pixels'])


def inspect(name):
    art=Image.open(HERE/'processed/qa'/f'{name}_unframed.png').convert('RGBA')
    px=np.asarray(art); r,g,b=px[:,:,:3].transpose(2,0,1)
    parts=islands((r>218)&(b>218)&(g<65)&(px[:,:,3]>3))
    board=Image.new('RGB',art.size,'#142333');board.paste(art,(0,0),art)
    draw=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',19)
    for i,p in enumerate(parts):
        p['id']=i
        draw.rectangle(p['bbox'],outline='#00ff55',width=2)
        draw.text(tuple(p['bbox'][:2]),str(i),font=font,fill='white',stroke_width=2,stroke_fill='black')
    qa=HERE/'processed/qa'
    board.save(qa/f'{name}_matte_islands.png')
    (qa/f'{name}_matte_islands.json').write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
    print(name,json.dumps(parts))


if __name__=='__main__':
    for enemy in sys.argv[1:]: inspect(enemy)
