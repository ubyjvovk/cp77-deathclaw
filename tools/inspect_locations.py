import sqlite3
from pathlib import Path
p=Path(r'E:\Modding\Cyberpunk2077\mods\Appearance Menu Mod\bin\x64\plugins\cyber_engine_tweaks\mods\AppearanceMenuMod\db.sqlite3')
c=sqlite3.connect(p.as_uri()+'?mode=ro', uri=True)
tables=[r[0] for r in c.execute("select name from sqlite_master where type='table'")]
print('Location tables:', [t for t in tables if 'loc' in t])
for table in tables:
    if 'loc' not in table:
        continue
    print(table, c.execute(f'pragma table_info({table})').fetchall())
    for row in c.execute(f'select * from {table}'):
        if any(word in str(row).lower() for word in ['sunset','badland','rocky','nomad']):
            print(row)
