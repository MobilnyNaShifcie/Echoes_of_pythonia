"""Regression checks for this authorized matte-cleanup pass, not art approval."""
import numpy as np
from PIL import Image, ImageDraw
import pytest

from extract_assets import chroma_cut


def fixture():
    im=Image.new('RGB',(80,80),(255,0,255))
    ImageDraw.Draw(im).rectangle((15,15,65,65),fill=(80,90,60))
    return im


def test_exterior_removed_and_opaque_core_preserved():
    im=fixture();out,_=chroma_cut(im)
    assert out.mode=='RGBA'
    assert out.getpixel((0,0))==(0,0,0,0)
    assert out.getpixel((40,40))==(80,90,60,255)


def test_internal_magenta_is_not_automatically_erased():
    im=fixture();ImageDraw.Draw(im).rectangle((30,30,45,45),fill=(255,0,255))
    out,_=chroma_cut(im)
    assert out.getpixel((35,35))==(255,0,255,255)


def test_reviewed_hole_removed_but_distinct_spell_is_preserved():
    im=fixture();draw=ImageDraw.Draw(im)
    draw.rectangle((28,28,36,36),fill=(255,0,255))
    draw.rectangle((48,48,55,55),fill=(255,0,255))
    out,_=chroma_cut(im,holes=[(30,30)])
    assert out.getpixel((30,30))==(0,0,0,0)
    assert out.getpixel((50,50))==(255,0,255,255)


def test_palette_review_can_remove_enclosed_matte():
    im=fixture();ImageDraw.Draw(im).rectangle((30,30,45,45),fill=(255,0,255))
    out,_=chroma_cut(im,reviewed_all_matte=True)
    assert out.getpixel((35,35))==(0,0,0,0)
    assert out.getpixel((58,30))==(80,90,60,255)


def test_rejects_unreviewed_background():
    with pytest.raises(ValueError,match='uniform magenta'):
        chroma_cut(Image.new('RGB',(80,80),'white'))


def test_rejects_foreground_as_hole_seed():
    with pytest.raises(ValueError,match='not magenta'):
        chroma_cut(fixture(),holes=[(40,40)])


def test_black_ink_contour_is_not_erased_and_hidden_rgb_zero():
    im=fixture();ImageDraw.Draw(im).rectangle((15,15,65,65),outline='black',width=2)
    out,_=chroma_cut(im,reviewed_all_matte=True)
    assert out.getpixel((15,40))==(0,0,0,255)
    px=np.asarray(out)
    assert not px[px[:,:,3]==0,:3].any()


def test_dark_pink_is_preserved_unless_strict_palette_review_enabled():
    im=fixture();im.putpixel((40,40),(100,15,95))
    ordinary,_=chroma_cut(im,reviewed_all_matte=True)
    cleaned,report=chroma_cut(im,reviewed_all_matte=True,strict_matte_despill=True)
    assert ordinary.getpixel((40,40))==(100,15,95,255)
    assert cleaned.getpixel((40,40))[3]<255
    assert report['reviewed_interior_spill_pixels']==1
    assert cleaned.getpixel((45,40))==(80,90,60,255)


def test_strict_review_preserves_opaque_blue_and_warm_paint():
    im=fixture();im.putpixel((35,35),(35,100,180));im.putpixel((45,45),(150,90,55))
    cleaned,_=chroma_cut(im,reviewed_all_matte=True,strict_matte_despill=True)
    assert cleaned.getpixel((35,35))==(35,100,180,255)
    assert cleaned.getpixel((45,45))==(150,90,55,255)
