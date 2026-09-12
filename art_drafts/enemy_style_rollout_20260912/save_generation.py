"""Persist a completed built-in image generation and its exact prepared job."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--enemy',required=True)
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--jobs-sha',required=True)
    p.add_argument('--jobs-file',default='jobs.json')
    args=p.parse_args()
    jobsfile=(HERE/args.jobs_file).resolve(strict=True)
    assert jobsfile.parent==HERE and jobsfile.suffix=='.json'
    assert hashlib.sha256(jobsfile.read_bytes()).hexdigest()==args.jobs_sha, 'Prepared jobs changed during generation'
    job=next(j for j in json.loads(jobsfile.read_text(encoding='utf-8')) if j['enemy']==args.enemy)
    source=args.source.resolve(strict=True)
    allowed=Path('C:/Users/kamil/.codex/generated_images').resolve()
    assert source.is_relative_to(allowed) and source.suffix.lower()=='.png'
    folder=HERE/'raw'
    folder.mkdir(exist_ok=True)
    variant=job.get('variant','v1')
    assert variant.startswith('v') and variant[1:].isdigit()
    target=folder/(args.enemy+'_'+variant+'.png')
    receipt=target.with_suffix('.json')
    if target.exists() or receipt.exists():
        raise FileExistsError('Keep previous generation; use an explicit new variant')
    shutil.copy2(source,target)
    data={**job,'status':'GENERATED_RAW_PENDING_ALPHA_AND_REVIEW','generator':'built-in image_gen__imagegen',
          'generated_source':str(source),'raw':target.relative_to(ROOT).as_posix(),
          'raw_sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    receipt.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(args.enemy,'saved',target)


if __name__=='__main__':
    main()
