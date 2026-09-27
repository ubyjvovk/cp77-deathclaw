import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'project/source/archive/local/deathclaw_badlands'
for suffix in ['d01','n01']:
    data = json.loads((ROOT / f'work/inspect/deathclaw_{suffix}.xbm.json').read_text())
    setup = data['Data']['RootChunk']['setup']
    setup['compression'] = 'TCM_DXTNoAlpha' if suffix == 'd01' else 'TCM_Normalmap'
    setup['group'] = 'TEXG_Generic_Color' if suffix == 'd01' else 'TEXG_Generic_Normal'
    setup['isGamma'] = int(suffix == 'd01')
    (OUT/f'deathclaw_{suffix}.xbm.json').write_text(json.dumps(data))
    print(suffix, setup)
