"""Exercise prototype lifecycle and targeting under mocks; not an engine test."""
from pathlib import Path
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
events={};function registerForEvent(n,f) events[n]=f end
hooks={};function ObserveAfter(c,n,f) hooks[c..'.'..n]=f;if c=='DamageSystem' then damageHook=f end end
json={encode=function() return '{}' end};io.open=function() return {write=function()end,close=function()end} end
function print(...) end
Vector3={new=function(x,y,z)return {x=x,y=y,z=z}end}
Vector4={new=function(x,y,z,w)return {x=x,y=y,z=z,w=w}end}
EulerAngles={new=function()return {}end,ToQuat=function()return {}end}
CName={new=function(x)return x end};TweakDBID={new=function(x,suffix)return tostring(x)..(suffix or '')end}
ResRef={FromString=function(x)return x end};DynamicEntitySpec={new=function()return {}end}
EAIAttitude={AIA_Hostile=1,AIA_Neutral=0}
flats={};TweakDB={GetRecord=function()return {}end,CloneRecord=function()end,CreateRecord=function()end,GetFlat=function(_,k)
if tostring(k):find('equipmentItems') then return {'fistEntry','gunEntry'} end
if k=='fistEntry.item' then return 'fists' end
if k=='gunEntry.item' then return 'gun' end
if tostring(k):find('Equipment') then return 'donorEquipment' end
return flats[k] or {'donorStat'} end,SetFlat=function(_,k,v)flats[k]=v end,Update=function()end}
gamedataItemType={Wea_Fists=78};TweakDBInterface={GetItemRecord=function(id)return {ItemType=function()return {Type=function()return id=='fists' and 78 or 81 end}end}end,GetReactionPresetRecord=function()return {}end,GetAIThreatPersistenceSourceRecord=function()return {EnumValue=function()return 7 end}end}
function NewObject(n)return {SetVector4=function()end,SetWorldPosition=function()end}end
created=0;deleted=0;commands=0;attacks=0;available=false;hasPlayer=true;dead=false
playerPosition={x=3827,y=-1561,z=130};npcPosition={x=3832,y=-1555,z=130}
ai={GetAIRole=function()return nil end,SendCommand=function()commands=commands+1 end,StopExecutingCommand=function()end}
attitude={SetAttitudeTowards=function()end}
p={GetWorldForward=function()return {x=0,y=1,z=0}end,GetEntityID=function()return {hash=1}end,IsNPC=function()return false end,IsDead=function()return false end,GetWorldPosition=function()return playerPosition end,GetAttitudeAgent=function()return attitude end}
threats=0;removedThreats=0;persistent=false;tracker={GetHostileThreats=function()return {}end,GetThreatPersistence=function()return persistent end,SetThreatPersistence=function(_,t,v,source)assert(source==7);persistent=v end,AddThreat=function()threats=threats+1 end,MapThreat=function(_,t)return t end,RemoveThreat=function()removedThreats=removedThreats+1 end}
e={GetTargetTrackerComponent=function()return tracker end,GetWorldPosition=function()return npcPosition end,GetEntityID=function()return {hash=44}end,
IsNPC=function()return true end,IsDead=function()return dead end,GetAIControllerComponent=function()return ai end,
GetAttitudeAgent=function()return attitude end,FindComponentByName=function()return {Toggle=function()end}end,
reactionComponent={SetReactionPreset=function()end,TriggerCombat=function()attacks=attacks+1 end}}
preyDead=false;preyPosition={x=3835,y=-1555,z=130}
opponentAttacks=0;opponentThreats=0;prey={GetAIControllerComponent=function()return ai end,GetTargetTrackerComponent=function()return {AddThreat=function()opponentThreats=opponentThreats+1 end}end,reactionComponent={SetReactionPreset=function()end,TriggerCombat=function(_,target)assert(target==e);opponentAttacks=opponentAttacks+1 end},GetWorldPosition=function()return preyPosition end,GetEntityID=function()return {hash=55}end,
IsNPC=function()return true end,IsDead=function()return preyDead end,GetAttitudeAgent=function()return attitude end}
preyEnabled=false
dynamic={CreateEntity=function(_,spec)created=created+1;lastSpec=spec;return 44 end,
DeleteEntity=function()deleted=deleted+1;available=false end}
lookAt=prey
targeting={GetTargetParts=function(_,origin,query)assert(origin==p,'must use player targeting component');assert(query.maxDistance>=120);if not preyEnabled then return true,{} end
local part={GetComponent=function()return {GetEntity=function()return prey end}end};return true,{part,part}end,
GetLookAtObject=function()return lookAt end}
Game={GetPlayer=function()if hasPlayer then return p end end,FindEntityByID=function()if available then return e end end,
GetDynamicEntitySystem=function()return dynamic end,GetTargetingSystem=function()return targeting end,
GetSpatialQueriesSystem=function()return {SyncRaycastByCollisionGroup=function()return true,{position={z=130}}end}end}
Game['TSQ_NPC;']=function()return {}end
gunEquipped=false;gunsRemoved=0
Game.GetTransactionSystem=function()return {GetItemInSlot=function(_,e,slot)if gunEquipped then return {IsRanged=function()return true end,GetItemID=function()return 'gun' end}end end,RemoveItemFromSlot=function()gunEquipped=false end,RemoveItem=function()gunsRemoved=gunsRemoved+1 end}end
ScannerName={new=function()return {Set=function(self,s)self.name=s end,SetArchetype=function(self,v)self.archetype=v end}end}
function GetAllBlackboardDefs()return {UI_ScannerModules={ScannerName=1}}end
function ToVariant(x)return x end
Game.GetBlackboardSystem=function()return {Get=function()return {SetVariant=function(_,key,v)scanner=v end}end}end

gamedataStatType={Health=0};Game.GetStatsSystem=function()return {GetStatValue=function()return 20000 end}end
gamedataStatPoolType={Health=0};health=100
Game.GetStatPoolsSystem=function()return {GetStatPoolValue=function()return health end}end
''')
mod=lua.execute((ROOT/'creature/source/resources/bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawCreature/init.lua').read_text())
lua.globals().M=mod
lua.execute('''
events.onInit();events.onInit()
assert(#flats[M.record..'.statModifiers']==2,'health modifier stacks on reload')
assert(flats[M.record..'Health.value']==20,'convoy health preset')
assert(#flats[M.record..'FistsOnly.equipmentItems']==1,'gun in equipment group')
M.Spawn();M.Spawn();assert(created==1,'duplicate spawn')
assert(lastSpec.persistSpawn==false and lastSpec.persistState==false,'save persistence')
available=true;events.onUpdate(0.2);assert(commands==1,'patrol never started')
npcPosition={x=3837,y=-1555,z=130};health=72
local reading=M.Inspect();assert(reading.maxDistanceFromSpawn==5 and reading.healthPercent==72 and reading.maxHealth==20000,'diagnostics')
preyEnabled=true;events.onUpdate(0.4);assert(attacks==1 and threats==1,'prey not explicitly injected')
events.onUpdate(3);assert(attacks==1,'repeated combat command interrupts melee')
assert(M.target==prey and persistent and opponentAttacks==1 and opponentThreats==1,'mutual combat and persistence')
-- Dead victims must not freeze the director.
preyDead=true;preyEnabled=false;events.onUpdate(0.4);assert(M.target==nil and M.mode=='patrol')
preyDead=false
-- Opening the overlay may change targeting: retain the last actual aimed NPC.
events.onUpdate(0.2);events.onOverlayOpen();lookAt=nil;M.AttackLookAt();assert(M.target==prey,'cached aim lost')
M.AttackPlayer();assert(M.target==p,'player attack control')
M.Patrol();assert(M.target==nil)
-- Only damage actually caused by this creature is scaled; projection is untouched.
local computed={value=10,GetTotalAttackValue=function(self)return self.value end,MultAttackValue=function(self,m)self.value=self.value*m end}
damageHook(nil,{target=prey,attackData={GetInstigator=function()return e end},attackComputed=computed,projectionPipeline=true})
assert(computed.value==10 and M.outgoingHits==0,'preview damage mutated')
damageHook(nil,{target=prey,attackData={GetInstigator=function()return e end},attackComputed=computed})
assert(computed.value==40 and M.outgoingHits==1,'creature damage boost')
computed.value=10
damageHook(nil,{target=p,attackData={GetInstigator=function()return prey end},attackComputed=computed})
assert(computed.value==10,'unrelated damage changed')
damageHook(nil,{target=e,attackData={GetInstigator=function()return p end},attackComputed=computed})
assert(M.retaliation==p,'incoming attack did not queue retaliation')
events.onUpdate(0.2);assert(M.target==p and M.retaliation==nil,'retaliation not handled at next 200ms tick')
-- Do not switch every time a different shooter lands a hit.
damageHook(nil,{target=e,attackData={GetInstigator=function()return prey end},attackComputed=computed})
assert(M.retaliation==nil,'target oscillation')
-- An inaccessible target times out instead of blocking patrol forever.
M.Patrol();preyEnabled=true;preyPosition={x=3860,y=-1555,z=130};events.onUpdate(0.4)
assert(M.target==prey)
for i=1,32 do events.onUpdate(1) end
assert(M.target==nil and M.ignored['55']>M.time,'stalled target retained forever')
preyPosition={x=3835,y=-1555,z=130};M.ignored={};events.onUpdate(0.4);assert(M.target==prey)
preyPosition={x=4300,y=-1555,z=130};events.onUpdate(0.4);assert(M.target==nil,'territory leash failed')
-- Regression: a live opponent in melee range must never be restarted or timed out.
preyPosition={x=3839,y=-1555,z=130};M.ignored={};events.onUpdate(0.4)
local previousAttacks=attacks;local previousThreats=threats
for i=1,65 do events.onUpdate(1) end
assert(M.target==prey and attacks==previousAttacks and threats==previousThreats,'wind-up interrupted or close target abandoned')
-- Even a distant manually chosen target stays assigned until the user cancels.
M.lookTarget=prey;M.lookTime=M.time;M.AttackLookAt();preyPosition={x=3900,y=-1555,z=130}
for i=1,40 do events.onUpdate(1) end
assert(M.target==prey and M.targetReason=='manual','manual target abandoned by watchdog')
M.Patrol();assert(not persistent,'persistent threat leaked after cancelling')
-- Candidate outside creature radius must be rejected even if V can see it.
preyPosition={x=3980,y=-1555,z=130};events.onUpdate(0.4);assert(M.target==nil,'radius filter lost')
gunEquipped=true;events.onUpdate(0.2);assert(gunsRemoved==1,'ranged fallback not stripped')
hooks['NPCPuppet.CompileScannerChunks'](e);assert(scanner.name=='Deathclaw' and scanner.archetype==false,'scanner identity')
scanner=nil;hooks['NPCPuppet.CompileScannerChunks'](prey);assert(scanner==nil,'unrelated NPC renamed')
playerPosition={x=5000,y=0,z=130};events.onUpdate(1);assert(deleted==0 and M.id~=nil,'distance caused deletion')
available=false;events.onUpdate(1);assert(M.id~=nil and deleted==0,'temporary streaming miss caused deletion')
available=true;events.onUpdate(0.2);assert(M.missingTime==0,'streaming recovery failed')
M.Despawn();assert(deleted==1 and M.id==nil)
playerPosition={x=3827,y=-1561,z=130};M.Spawn();events.onUpdate(21);assert(M.id==nil,'spawn timeout cleanup')
M.Spawn(true,true);assert(lastSpec.position.x==playerPosition.x and lastSpec.position.y==playerPosition.y+8,'spawn beside V position')
available=true;events.onUpdate(0.2);assert(M.visualScale==2 and M.mother,'Mother scale not applied')
assert(lastSpec.recordID==M.record..'Mother','Mother uses normal template')
hooks['NPCPuppet.CompileScannerChunks'](e);assert(scanner.name=='Mother Deathclaw','Mother scanner identity')
-- AMM registry provides candidates even when native query misses spawned actors.
preyPosition={x=3835,y=-1555,z=130};preyEnabled=false
function GetMod()return {Spawn={spawnedNPCs={test={handle=prey}}}}end
M.Patrol();events.onUpdate(0.4);assert(M.target==prey and M.ammCandidates==1,'AMM spawn overlooked')
local cleared=false;local reset=false
local follower={IsA=function(_,name)return name=='AIFollowerRole' end,OnRoleCleared=function()cleared=true end}
ai.GetAIRole=function()return follower end
AINoRole={new=function()return {}end};AIHumanComponent={SetCurrentRole=function(t)assert(t==prey);reset=true end}
M.lookTarget=prey;M.lookTime=M.time;M.AttackLookAt()
assert(cleared and reset and prey.isPlayerCompanionCached==false,'manual opponent retains follower role')
M.Despawn();M.Spawn();hasPlayer=false;events.onUpdate(1);assert(M.id==nil,'world unload')
''')
print('PASS: nearby spawn and separate Mother record; fists-only equipment and ranged removal; scoped scanner names; no distance/streaming deletion; AMM registry acquisition;  health modifier deduplication; player query with creature radius filter; persistent threats and mutual combat; uninterrupted close/manual combat; cached aiming; dead/stalled/leashed target recovery; scoped damage; 200ms retaliation; target hysteresis; nonpersistent lifecycle cleanup. Mock tests only, not an engine test.')
