"""Exercise streaming/reload/retry logic in Lua; does not emulate REDengine."""
from pathlib import Path
from lupa import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
callbacks={}; entities={}; serial=0; created=0; deleted=0; failSpawn=false; loaded=false
playerPos={x=0,y=0,z=130,w=1}
function registerForEvent(name,fn) callbacks[name]=fn end
json={encode=function(v) return '{}' end}
io={open=function() return {write=function() end,close=function() end} end}
print=function() end
Vector4={new=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end}
EulerAngles={new=function(x,y,z) return {x=x,y=y,z=z} end,ToQuat=function(v) return v end}
DynamicEntitySpec={new=function() return {} end}
player={GetWorldPosition=function() return playerPos end}
system={
 CreateEntity=function(self,spec)
   serial=serial+1; created=created+1
   if not failSpawn then entities[serial]={GetWorldPosition=function() return spec.position end} end
   return serial
 end,
 DeleteEntity=function(self,id) entities[id]=nil; deleted=deleted+1 end
}
Game={
 GetPlayer=function() if loaded then return player end end,
 GetDynamicEntitySystem=function() return system end,
 FindEntityByID=function(id) return entities[id] end,
 GetSpatialQueriesSystem=function() return {SyncRaycastByCollisionGroup=function() return true,{position={z=130}} end} end
}
function tick(n) for i=1,n do callbacks.onUpdate(2) end end
''')
lua.globals().mod=lua.execute((ROOT/'project/source/resources/bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawBadlands/init.lua').read_text())
lua.execute('''
callbacks.onInit(); tick(5); assert(created==0,'must not spawn without a player')
loaded=true; tick(5); assert(created==0,'must not spawn far from statue')
playerPos={x=3816,y=-1555,z=130}; tick(2)
assert(created==1 and mod.verified,'must spawn and resolve near the site')
tick(10); assert(created==1,'must not duplicate while nearby')
for i=1,5 do
 playerPos={x=0,y=0,z=130}; tick(1)
 playerPos={x=3816,y=-1555,z=130}; tick(2)
 assert(mod.verified,'must respawn after repeated visits')
end
assert(created==6 and deleted==5)
entities={}; tick(3); assert(created==7 and mod.verified,'must recover after world entity disappears')
loaded=false; entities={}; tick(1); loaded=true; tick(2)
assert(created==8 and mod.verified,'must respawn after loading a save')
mod.Despawn(); failSpawn=true; mod.attempts=0
local previous=created; tick(100)
assert(created==previous+3 and not mod.verified,'failed spawns must stop after three attempts')
''')
print('PASS: no-player/far-distance guards, duplicate prevention, five return visits, world reload, save reload, bounded failed-spawn retries')
