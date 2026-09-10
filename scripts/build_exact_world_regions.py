"""Build technical region data, never modify the approved map illustrations.

Shared border paths are traced at source resolution along the painted gold ridge.
Each edge is stored once and reused in both neighbouring polygons. The resulting
atlas is authoritative for CPU picking and both art-layer shaders. R = region ID,
G = protected painted border, B = the new valley/plains border to draw on top.
No erosion, dilation, or half-resolution segmentation of the region IDs.
"""

from __future__ import annotations

import heapq
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "godot/assets/world_map"
CANVAS = (2560, 1440)
OFFSET = (444, 249)
VALLEY_RECT = (100, 350, 850, 850)
CODES = {"twilight_plains": 51, "black_forest": 102,
         "silentwater_marshes": 153, "ashen_borderlands": 204,
         "ice_coast": 255, "varenhold_valley": 26}

# Coordinates are in the ORIGINAL 1672 x 941 illustration, not the viewport.
# Junctions are shared, not independently guessed by each neighbouring region.
J = {"A": (697, 473), "B": (978, 483), "C": (1044, 523),
     "D": (963, 143), "E": (408, 213), "F": (1556, 397),
     "G": (1022, 819), "H": (487, 780)}
EDGES = {
    "EA": [(408,213),(443,226),(469,249),(496,264),(526,282),
           (522,304),(519,326),(547,339),(553,356),(568,386),
           (604,391),(628,387),(650,400),(680,408),(701,429),
           (691,448),(697,473)],
    "AB": [(697,473),(735,480),(775,480),(809,486),(840,478),
           (869,465),(901,450),(927,465),(953,477),(978,483)],
    "DB": [(963,143),(974,158),(1005,190),(1010,204),(974,222),
           (951,239),(973,261),(974,280),(983,305),(981,325),
           (957,341),(970,359),(1005,384),(1015,398),(1005,418),
           (1000,436),(986,456),(995,465),(978,483)],
    "BC": [(978,483),(985,492),(1009,495),(1018,511),(1037,515),(1044,523)],
    "CF": [(1044,523),(1050,510),(1080,499),(1111,477),
           (1142,473),(1171,478),(1200,473),(1218,467),(1240,479),
           (1265,473),(1289,443),(1316,435),(1348,415),(1380,396),
           (1407,394),(1434,381),(1464,387),(1484,398),(1518,394),
           (1541,401),(1556,397)],
    "AH": [(697,473),(689,499),(671,519),(654,541),(637,556),
           (627,579),(604,591),(600,615),(575,634),(550,642),
           (531,651),(516,661),(530,675),(513,690),(533,710),
           (508,724),(497,743),(492,765),(487,780)],
    "CG": [(1044,523),(1058,536),(1084,552),(1095,568),(1121,585),
           (1122,598),(1099,609),(1123,631),(1106,648),(1095,667),
           (1078,689),(1086,702),(1070,710),(1065,725),(1050,740),
           (1048,752),(1037,772),(1018,786),(1024,796),(1017,807),(1022,819)],
    "ED": [(408,213),(384,192),(355,170),(352,150),(369,130),
           (402,120),(431,126),(459,112),(475,97),(510,104),
           (539,92),(562,76),(591,85),(616,84),(645,70),
           (665,77),(692,57),(708,56),(732,67),(761,64),
           (790,87),(819,94),(848,93),(877,106),(880,120),
           (906,132),(931,132),(950,144),(963,143)],
    "DF": [(963,143),(959,121),(965,109),(983,102),(1011,103),
           (1036,86),(1060,94),(1089,83),(1112,95),(1138,116),
           (1172,120),(1207,113),(1237,124),(1270,136),(1300,146),
           (1330,159),(1352,180),(1382,186),(1397,200),(1383,212),
           (1395,224),(1424,225),(1455,238),(1465,252),(1501,261),
           (1533,280),(1552,300),(1555,318),(1580,329),(1602,336),
           (1610,350),(1592,367),(1570,379),(1556,397)],
    "EH": [(408,213),(386,226),(360,230),(342,233),(316,221),
           (300,219),(277,225),(248,233),(215,246),(189,244),
           (177,260),(171,276),(180,282),(173,299),(149,318),
           (138,340),(153,351),(134,373),(111,390),(93,396),
           (94,411),(67,429),(45,455),(49,471),(68,480),
           (67,497),(48,515),(38,535),(18,558),(21,581),
           (39,595),(42,617),(68,631),(98,652),(132,659),
           (154,675),(143,694),(158,715),(184,720),(210,735),
           (246,739),(276,748),(304,742),(326,767),(355,773),
           (377,790),(409,799),(430,781),(451,777),(470,764),(487,780)],
    "HG": [(487,780),(507,799),(522,805),(532,819),(559,819),
           (592,815),(611,834),(626,845),(638,866),(665,867),
           (686,870),(707,862),(730,849),(757,846),(787,852),
           (816,853),(842,867),(869,876),(892,877),(911,874),
           (930,856),(956,850),(979,838),(1007,828),(1022,819)],
}

# No painted yellow line along the icy south/east coastline. Follow the top
# surface silhouette explicitly there; do not snap white ice to unrelated gold.
ICE_COAST = [(1556,397),(1571,409),(1584,426),(1588,438),(1569,451),
             (1587,465),(1574,479),(1591,493),(1605,510),(1628,528),
             (1637,548),(1621,568),(1600,574),(1571,580),(1556,602),
             (1550,624),(1517,639),(1494,655),(1467,664),(1468,681),
             (1444,691),(1420,685),(1405,700),(1380,716),(1346,721),
             (1331,751),(1306,758),(1280,775),(1260,783),(1234,798),
             (1200,808),(1166,820),(1137,834),(1111,847),(1088,843),
             (1064,831),(1044,829),(1022,819)]

# Political seam through dry foothills east of the cultivated valley. The same
# polyline creates region ownership AND the visible gold overlay, in world px.
VALLEY_SEAM = [(818,446),(813,469),(821,491),(808,505),(811,532),
              (822,548),(815,563),(821,577),(815,596),(823,611),(809,630),(814,649),
              (797,663),(800,682),(780,698),(786,718),(770,737),
              (777,759),(760,777),(765,795),(751,814),(759,835),
              (742,855),(749,877),(733,896),(737,915),(723,935),
              (731,954),(714,974),(718,995),(704,1012),(711,1032),
              (695,1055),(701,1076),(685,1096),(691,1117),(677,1140)]


def smoothstep(lo: float, hi: float, value: np.ndarray) -> np.ndarray:
    t = np.clip((value - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def trace_edges(source: Image.Image) -> dict[str, list[tuple[int, int]]]:
    rgb = np.asarray(source.convert("RGB"), dtype=float)
    r, g, b = rgb.transpose(2, 0, 1)
    # Gold line colour AND its narrow bright ridge, not general terrain edges.
    ridge = r - np.asarray(source.convert("RGB").filter(ImageFilter.GaussianBlur(3)),
                           dtype=float)[:, :, 0]
    gold = (np.clip((r-b-30)/65, 0, 1) * np.clip((g-b-12)/32, 0, 1)
            * np.clip((r-90)/100, 0, 1) * np.clip((ridge+5)/30, 0, 1))
    cost = 1 + 75 * (1-gold)**2

    def snap(point: tuple[int, int], radius: int = 5) -> tuple[int, int]:
        x, y = point
        ys, xs = np.mgrid[y-radius:y+radius+1, x-radius:x+radius+1]
        merit = gold[ys, xs] - np.hypot(xs-x, ys-y)*0.026
        i = np.unravel_index(merit.argmax(), merit.shape)
        return int(xs[i]), int(ys[i])

    junctions = {k: snap(v) for k,v in J.items()}
    result = {}
    for name, anchors in EDGES.items():
        points = [junctions[name[0]]] + anchors[1:-1] + [junctions[name[1]]]
        # Anchors constrain a corridor, NOT mandatory intermediate pixels.
        # Forcing a rough anchor would briefly pull an otherwise exact path off
        # the gold ridge. Only the shared endpoint junctions are mandatory.
        corridor = Image.new("L", source.size)
        ImageDraw.Draw(corridor).line(points,fill=255,width=65,joint="curve")
        constrained = np.where(np.asarray(corridor)>0,cost,np.inf)
        bounds = (max(0,min(x for x,y in points)-34), max(0,min(y for x,y in points)-34),
                  min(source.width,max(x for x,y in points)+35),
                  min(source.height,max(y for x,y in points)+35))
        path = shortest_path(constrained, points[0], points[-1], bounds)
        result[name] = path
        values = np.array([gold[y,x] for x,y in path])
        print(f"{name}: {len(path)} px, gold ridge coverage {(values > .25).mean():.1%}", flush=True)
    result["FG"] = [junctions["F"]] + ICE_COAST[1:-1] + [junctions["G"]]
    return result


def shortest_path(cost: np.ndarray, start: tuple[int,int], end: tuple[int,int],
                  bounds: tuple[int,int,int,int]) -> list[tuple[int,int]]:
    x0,y0,x1,y1 = bounds
    local = cost[y0:y1,x0:x1]
    start = (start[0]-x0,start[1]-y0)
    end = (end[0]-x0,end[1]-y0)
    distances = np.full(local.shape, np.inf)
    distances[start[1],start[0]] = 0
    previous = {}
    queue = [(0, start)]
    while queue:
        distance, p = heapq.heappop(queue)
        if p == end:
            break
        if distance > distances[p[1],p[0]]:
            continue
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
            q = (p[0]+dx,p[1]+dy)
            if not (0 <= q[0] < local.shape[1] and 0 <= q[1] < local.shape[0]):
                continue
            step = 1.41421356237 if dx and dy else 1
            value = distance + (local[p[1],p[0]]+local[q[1],q[0]])*.5*step
            if value < distances[q[1],q[0]]:
                distances[q[1],q[0]] = value
                previous[q] = p
                heapq.heappush(queue, (value,q))
    path = [end]
    while path[-1] != start:
        path.append(previous[path[-1]])
    return [(p[0]+x0,p[1]+y0) for p in reversed(path)]


def build() -> None:
    paths = trace_edges(Image.open(ASSETS / "pythonia_world_map.png"))
    routes = {"twilight_plains": ["EA","AH","HE"],
              "black_forest": ["ED","DB","BA","AE"],
              "silentwater_marshes": ["DF","FC","CB","BD"],
              "ashen_borderlands": ["AB","BC","CG","GH","HA"],
              "ice_coast": ["CF","FG","GC"]}
    def edge(name):
        return paths[name] if name in paths else list(reversed(paths[name[::-1]]))
    atlas_ids = Image.new("L", CANVAS)
    painter = ImageDraw.Draw(atlas_ids)
    for region, route in routes.items():
        polygon = [(x+OFFSET[0],y+OFFSET[1]) for name in route for x,y in edge(name)]
        painter.polygon(polygon, fill=CODES[region])

    # Rasterize module coverage with the same key/fade as the existing shader.
    # Its art coverage is independent from the political border in VALLEY_SEAM.
    source = Image.open(ASSETS / "modules/varenhold_valley_two_cities_v2.png").convert("RGB")
    xx, yy = np.meshgrid((np.arange(850)+.5)/850, (np.arange(850)+.5)/850)
    raw = np.asarray(source, dtype=float)/255
    rgb = raw[np.minimum((yy*source.height).astype(int),source.height-1),
              np.minimum((xx*source.width).astype(int),source.width-1)]
    high, low = rgb.max(axis=2), rgb.min(axis=2)
    neutral = 1-smoothstep(.045,.14,high-low)
    luminance = rgb @ np.array([.299,.587,.114])
    alpha = (1-np.maximum(neutral*smoothstep(.62,.82,luminance),smoothstep(.74,.90,low)))
    alpha *= 1-smoothstep(.78,.94,xx)
    ids = np.array(atlas_ids)
    west = Image.new("L", CANVAS)
    ImageDraw.Draw(west).polygon([(0,0),(VALLEY_SEAM[0][0],0)] + VALLEY_SEAM +
                                [(VALLEY_SEAM[-1][0],1440),(0,1440)], fill=255)
    west = np.asarray(west) > 0
    module = np.zeros(ids.shape, dtype=bool)
    module[350:1200,100:950] = alpha >= .55
    # A single ID per pixel. Eastern part of the module is part of the Plains,
    # even where the art feathering still overlays the old illustration.
    ids[module & west] = CODES["varenhold_valley"]
    ids[module & ~west & ((ids == 0) | (ids == 51))] = 51
    protected = Image.new("L", CANVAS)
    draw = ImageDraw.Draw(protected)
    for name,path in paths.items():
        if name != "FG":
            draw.line([(x+444,y+249) for x,y in path], fill=255, width=3)
    protect = np.array(protected)
    # The painted base borders are hidden wherever opaque module art is on top.
    protect[module] = 0

    # Extract the actual shared interface, including its exact coastal ends.
    # Thus every visible seam segment really has Valley on one side, Plains on
    # the other, and no decorative line can run beyond the land into the sea.
    seam = Image.new("L", (CANVAS[0]*4,CANVAS[1]*4))
    draw = ImageDraw.Draw(seam)
    for dy,dx in ((0,1),(1,0)):
        a = ids[:1440-dy,:2560-dx]
        b = ids[dy:,dx:]
        shared = ((a==26)&(b==51)) | ((a==51)&(b==26))
        for y,x in zip(*np.nonzero(shared)):
            if dx:
                draw.line([((x+1)*4,y*4),((x+1)*4,(y+1)*4)],fill=255,width=5)
            else:
                draw.line([(x*4,(y+1)*4),((x+1)*4,(y+1)*4)],fill=255,width=5)
    seam = np.asarray(seam.resize(CANVAS,Image.Resampling.LANCZOS))
    atlas = np.stack([ids,protect,seam],axis=2)
    Image.fromarray(atlas).save(ASSETS / "pythonia_region_atlas_v2.png")
    output = ROOT / "build/world-map-validation"
    output.mkdir(parents=True,exist_ok=True)
    colors = {0:(9,20,30),26:(108,174,94),51:(221,177,88),102:(42,100,67),
              153:(78,134,154),204:(140,69,52),255:(167,206,232)}
    preview = np.zeros((*ids.shape,3),dtype=np.uint8)
    for code,color in colors.items():
        preview[ids==code] = color
    Image.fromarray(preview).save(output / "region-ownership-v2.png")
    data = {"canvas":CANVAS,"source_offset":OFFSET,"valley_seam":VALLEY_SEAM,
            "codes":CODES,"edges":paths}
    (output / "traced-region-borders.json").write_text(json.dumps(data),encoding="utf-8")
    print('Atlas:',{code:int((ids==code).sum()) for code in colors},flush=True)


if __name__ == "__main__":
    build()
