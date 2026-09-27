-- Local experimental NPC. Uses its own record and entity, leaving the statue intact.
local M = {record='Character.LocalDeathclawTerritorialV3', version='territorial-v3', elapsed=0, overlay=false,
  mode='idle', status='Prototype ready. Spawn it from this panel.', pending=0,
  home={x=3832,y=-1555,z=130.2}, patrolIndex=0, patrolClock=0, scanClock=0}
M.radius=50;M.leash=85;M.healthMultiplier=20;M.damageMultiplier=4
M.time=0;M.lastEngage=-100;M.lastSwitch=-100;M.outgoingHits=0;M.incomingHits=0
local patrol={{0,0},{12,6},{15,-10},{-9,-13},{-12,5}}
local function distance(a,b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function entity() return M.id and Game.FindEntityByID(M.id) end
local function player() return Game.GetPlayer() end
local function same(a,b)
  return a and b and a:GetEntityID().hash==b:GetEntityID().hash
end
local function living(t)
  if not t then return false end
  local ok,result=pcall(function() return (t:IsNPC() or same(t,player())) and not t:IsDead() end)
  return ok and result
end
local function report(s)
  M.status=s; print('[DeathclawCreature] '..s)
  local f=io.open('status.json','w')
  if f then f:write(json.encode({status=s,mode=M.mode,entityFound=entity()~=nil})); f:close() end
end
local function protected(fn)
  local ok,err=pcall(fn)
  if not ok then M.mode='idle'; report('Error: '..tostring(err)) end
end
function M.Inspect()
  local e=entity(); local p=player()
  local r={version=M.version,status=M.status,mode=M.mode,entityFound=e~=nil,meshVerified=false,combatDamageVerified=false,healthMultiplier=M.healthMultiplier,damageMultiplier=M.damageMultiplier,
    radius=M.radius,outgoingHits=M.outgoingHits,incomingHits=M.incomingHits,lastDamage=M.lastDamage,
    candidates=M.candidates,threatInjections=M.threatInjections,warning=M.warning}
  if e then
    local v=e:GetWorldPosition();r.position={x=v.x,y=v.y,z=v.z};r.isNPC=e:IsNPC();r.dead=e:IsDead()
    local ai=e:GetAIControllerComponent();r.hasAI=ai~=nil
    r.bodyPresent=e:FindComponentByName('protectors')~=nil
    if M.spawnPosition then
      M.maxTravel=math.max(M.maxTravel or 0,distance(v,M.spawnPosition))
      r.maxDistanceFromSpawn=M.maxTravel
    end
    local ok,health=pcall(function()
      return Game.GetStatPoolsSystem():GetStatPoolValue(e:GetEntityID(),gamedataStatPoolType.Health)
    end)
    if ok then r.healthPercent=health end
    local statOK,maxHealth=pcall(function() return Game.GetStatsSystem():GetStatValue(e:GetEntityID(),gamedataStatType.Health) end)
    if statOK then r.maxHealth=maxHealth end
    if M.target then
      local targetOK,targetData=pcall(function()
        return {id=tostring(M.target:GetEntityID().hash),dead=M.target:IsDead(),
          healthPercent=Game.GetStatPoolsSystem():GetStatPoolValue(M.target:GetEntityID(),gamedataStatPoolType.Health)}
      end)
      if targetOK then r.target=targetData end
    end
  end
  if p then local v=p:GetWorldPosition();r.player={x=v.x,y=v.y,z=v.z} end
  local f=io.open('inspection.json','w');if f then f:write(json.encode(r));f:close() end
  return r
end
function M.Despawn()
  if M.id then Game.GetDynamicEntitySystem():DeleteEntity(M.id) end
  M.id=nil;M.target=nil;M.command=nil;M.pending=0;M.mode='idle';M.spawnPosition=nil;M.maxTravel=0;M.retaliation=nil;M.lookTarget=nil;M.ignored={};M.lastEngage=-100
  report('Creature removed')
end
function M.Spawn()
  if not player() then report('Load a save first');return end
  if M.id then report('A creature already exists; remove it before spawning another');return end
  local spec=DynamicEntitySpec.new()
  spec.recordID=TweakDBID.new(M.record);spec.appearanceName='default'
  local z=M.home.z
  local hit,result=Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(
    Vector4.new(M.home.x,M.home.y,z+20,1),Vector4.new(M.home.x,M.home.y,z-30,1),'Static',false,false)
  if hit and result then z=result.position.z+.02 end
  spec.position=Vector4.new(M.home.x,M.home.y,z,1)
  spec.orientation=EulerAngles.ToQuat(EulerAngles.new(0,0,35))
  spec.persistSpawn=false;spec.persistState=false;spec.alwaysSpawned=true
  spec.spawnInView=true;spec.active=true;spec.tags={'LocalDeathclawCreature'}
  M.id=Game.GetDynamicEntitySystem():CreateEntity(spec);M.pending=20;M.mode='patrol'
  report('Requested large brawler Deathclaw; waiting for NPC')
end
function M.Visit()
  if player() then Game.GetTeleportationFacility():Teleport(player(),Vector4.new(3827,-1561,130.4,1),EulerAngles.new(0,0,-40)) end
end
local function stopCommand(e)
  if M.command then e:GetAIControllerComponent():StopExecutingCommand(M.command,true);M.command=nil end
end
local function forgetTarget(e)
  if M.target then
    pcall(function()
      local tracker=e:GetTargetTrackerComponent()
      tracker:RemoveThreat(tracker:MapThreat(M.target))
      e:GetAttitudeAgent():SetAttitudeTowards(M.target:GetAttitudeAgent(),EAIAttitude.AIA_Neutral)
    end)
  end
  M.target=nil;M.targetReason=nil;M.progressAt=nil
end
local function injectThreat(e,target)
  local tracker=e:GetTargetTrackerComponent()
  if not tracker then error('Target tracker unavailable') end
  tracker:AddThreat(target,true,target:GetWorldPosition(),1.0,-1.0,false)
  M.threatInjections=(M.threatInjections or 0)+1
end
local function attack(e,target,reason)
  if not living(target) or same(e,target) then return end
  local changed=not same(M.target,target)
  stopCommand(e)
  if changed then forgetTarget(e) end
  e:GetAttitudeAgent():SetAttitudeTowards(target:GetAttitudeAgent(),EAIAttitude.AIA_Hostile)
  -- Only these individual actors become enemies. No faction-wide edits.
  target:GetAttitudeAgent():SetAttitudeTowards(e:GetAttitudeAgent(),EAIAttitude.AIA_Hostile)
  injectThreat(e,target)
  local reaction=e.reactionComponent
  if not reaction then error('NPC reaction component unavailable') end
  reaction:SetReactionPreset(TweakDBInterface.GetReactionPresetRecord(TweakDBID.new('ReactionPresets.Ganger_Aggressive')))
  reaction:TriggerCombat(target)
  M.target=target;M.targetReason=reason or M.targetReason;M.mode='combat';M.lastEngage=M.time
  if changed then
    M.lastSwitch=M.time;M.progressAt=M.time;M.lastRange=distance(e:GetWorldPosition(),target:GetWorldPosition());M.progressPosition=e:GetWorldPosition()
    report('Hunting target '..tostring(target:GetEntityID().hash)..' ('..tostring(reason)..')')
  end
end
function M.AttackPlayer()
  local e=entity();if e and player() then attack(e,player(),'manual') end
end
function M.AttackLookAt()
  local e=entity();if not e or not player() then return end
  local t=M.lookTarget
  if not living(t) or M.time-(M.lookTime or -100)>15 then
    t=Game.GetTargetingSystem():GetLookAtObject(player(),false,false)
  end
  if living(t) and not same(t,e) and not same(t,player()) then
    attack(e,t,'manual')
  else report('Aim at a living NPC with CET closed, then open CET and press Attack NPC') end
end
function M.Patrol()
  local e=entity();if not e then return end
  stopCommand(e);forgetTarget(e);M.retaliation=nil;M.mode='patrol';M.patrolClock=30;M.scanClock=1
  report('Territorial patrol: hunts NPCs within 50m; V is ignored unless attacked')
end
local function moveTo(e,p)
  stopCommand(e)
  local world=NewObject('WorldPosition');world:SetVector4(world,Vector4.new(p.x,p.y,p.z,1))
  local pos=NewObject('AIPositionSpec');pos:SetWorldPosition(pos,world)
  local cmd=NewObject('handle:AIMoveToCommand')
  cmd.movementTarget=pos;cmd.rotateEntityTowardsFacingTarget=false
  cmd.ignoreNavigation=false;cmd.desiredDistanceFromTarget=2
  cmd.movementType='Run';cmd.finishWhenDestinationReached=true
  cmd.alwaysUseStealth=false;e:GetAIControllerComponent():SendCommand(cmd);M.command=cmd
end
local function findPrey(e)
  local query=Game['TSQ_NPC;']();query.maxDistance=M.radius
  local ok,parts=Game.GetTargetingSystem():GetTargetParts(e,query)
  if not ok then return nil end
  local nearest,best=nil,M.radius;local seen={};local here=e:GetWorldPosition();M.candidates=0
  for _,part in ipairs(parts) do
    local t=part:GetComponent(part):GetEntity()
    if t and t:IsNPC() then
      local id=tostring(t:GetEntityID().hash)
      if not seen[id] and t:GetEntityID().hash~=e:GetEntityID().hash and not t:IsDead() then
        seen[id]=true;local d=distance(here,t:GetWorldPosition())
        M.candidates=M.candidates+1
        local ignored=M.ignored and M.ignored[id] and M.ignored[id]>M.time
        if d<best and not ignored and distance(t:GetWorldPosition(),M.spawnPosition or M.home)<=M.leash then nearest=t;best=d end
      end
    end
  end
  return nearest
end
registerForEvent('onInit',function()
  protected(function()
    if not TweakDB:GetRecord(M.record) then
      if not TweakDB:GetRecord('Character.dtn_animals_bouncer2_melee2_fists_mb') then error('Animals brawler record is missing') end
      TweakDB:CloneRecord(M.record,'Character.dtn_animals_bouncer2_melee2_fists_mb')
    end
    TweakDB:SetFlat(M.record..'.entityTemplatePath',ResRef.FromString('local\\deathclaw_creature\\deathclaw_android.ent'))
    TweakDB:SetFlat(M.record..'.appearanceName',CName.new('default'))
    local hpRecord=M.record..'Health'
    if not TweakDB:GetRecord(hpRecord) then TweakDB:CreateRecord(hpRecord,'gamedataConstantStatModifier_Record') end
    TweakDB:SetFlat(hpRecord..'.statType',TweakDBID.new('BaseStats.Health'))
    TweakDB:SetFlat(hpRecord..'.modifierType',CName.new('Multiplier'))
    TweakDB:SetFlat(hpRecord..'.value',M.healthMultiplier)
    TweakDB:Update(hpRecord)
    -- Rebuild from the donor list on every init; never stack our modifier on reload.
    local mods={}
    for _,v in ipairs(TweakDB:GetFlat('Character.dtn_animals_bouncer2_melee2_fists_mb.statModifiers') or {}) do mods[#mods+1]=v end
    mods[#mods+1]=TweakDBID.new(hpRecord)
    TweakDB:SetFlat(M.record..'.statModifiers',mods)
    TweakDB:Update(M.record)
    report('Prototype ready. Spawn it from this panel.')
  end)
end)
-- This stage runs before DealDamages in the native pipeline (also used by AMM).
-- ObserveAfter preserves the game's calculation and modifies only our creature's hit.
ObserveAfter('DamageSystem','ProcessRagdollHit',function(_,hit)
  if not M.id or hit.projectionPipeline then return end
  local ok,err=pcall(function()
    local e=entity();if not e then return end
    local instigator=hit.attackData:GetInstigator()
    if same(instigator,e) then
      local before=hit.attackComputed:GetTotalAttackValue(gamedataStatPoolType.Health)
      hit.attackComputed:MultAttackValue(M.damageMultiplier)
      M.lastDamage={before=before,after=hit.attackComputed:GetTotalAttackValue(gamedataStatPoolType.Health)}
      M.outgoingHits=M.outgoingHits+1;M.progressAt=M.time
    elseif same(hit.target,e) and living(instigator) then
      M.incomingHits=M.incomingHits+1
      if not living(M.target) or (not same(M.target,instigator) and M.time-M.lastSwitch>=2) then M.retaliation=instigator end
    end
  end)
  if not ok then M.warning='Damage hook: '..tostring(err) end
end)
registerForEvent('onOverlayOpen',function() M.overlay=true end)
registerForEvent('onOverlayClose',function() M.overlay=false end)
registerForEvent('onShutdown',function() pcall(M.Despawn) end)
registerForEvent('onUpdate',function(dt)
  M.time=M.time+dt;M.elapsed=M.elapsed+dt;if M.elapsed<0.2 then return end
  local step=M.elapsed;M.elapsed=0
  if not player() then M.id=nil;M.target=nil;M.command=nil;M.pending=0;M.lookTarget=nil;M.retaliation=nil;M.mode='idle';return end
  protected(function()
    if not M.overlay then
      local t=Game.GetTargetingSystem():GetLookAtObject(player(),false,false)
      if living(t) and not same(t,entity()) then M.lookTarget=t;M.lookTime=M.time
      else M.lookTarget=nil end
    end
    if not M.id then return end
    local e=entity()
    if not e then
      M.pending=M.pending-step
      if M.pending<=0 then M.Despawn();report('NPC did not appear or world reloaded; spawn again') end
      return
    end
    if M.pending>0 then
      M.pending=0;M.patrolClock=30;M.scanClock=1;M.ignored={}
      local pos=e:GetWorldPosition();M.spawnPosition={x=pos.x,y=pos.y,z=pos.z};M.maxTravel=0
      e:GetAttitudeAgent():SetAttitudeTowards(player():GetAttitudeAgent(),EAIAttitude.AIA_Neutral)
      report('Territorial brawler ready: 20x health, 4x damage')
    end
    if distance(e:GetWorldPosition(),player():GetWorldPosition())>250 then M.Despawn();return end
    if e:IsDead() then M.mode='dead';M.retaliation=nil
    else
      if living(M.retaliation) then attack(e,M.retaliation,'retaliation') end
      M.retaliation=nil
      if M.target then
        local valid=living(M.target)
        local range=valid and distance(e:GetWorldPosition(),M.target:GetWorldPosition()) or 0
        local outside=valid and distance(M.target:GetWorldPosition(),M.spawnPosition)>M.leash
        if not valid or (outside and M.targetReason~='manual') then
          forgetTarget(e);M.mode='patrol';M.patrolClock=30
        else
          if range<(M.lastRange or range)-1 or (M.progressPosition and distance(e:GetWorldPosition(),M.progressPosition)>1.5) then
            M.progressAt=M.time;M.lastRange=range;M.progressPosition=e:GetWorldPosition()
          end
          -- Give melee animations room to finish. Refresh only a distant chase that stalls.
          local stalled=M.time-(M.progressAt or M.time)
          if stalled>(range>5 and 4 or 8) and M.time-M.lastEngage>4 then
            attack(e,M.target,M.targetReason)
          end
          if stalled>(range>5 and 18 or 30) then
            M.ignored[tostring(M.target:GetEntityID().hash)]=M.time+15
            forgetTarget(e);M.mode='patrol';M.patrolClock=30
            report('Target unreachable; resuming territory scan')
          end
        end
      end
      if not M.target then
        M.mode='patrol';M.scanClock=M.scanClock+step;M.patrolClock=M.patrolClock+step
        if M.scanClock>=0.4 then
          M.scanClock=0;local prey=findPrey(e);if prey then attack(e,prey,'territory') end
        end
        if not M.target and M.patrolClock>=8 then
          M.patrolClock=0;M.patrolIndex=M.patrolIndex%#patrol+1
          local point=patrol[M.patrolIndex]
          moveTo(e,{x=M.spawnPosition.x+point[1],y=M.spawnPosition.y+point[2],z=M.spawnPosition.z})
        end
      end
    end
    M.inspectClock=(M.inspectClock or 0)+step
    if M.inspectClock>=1 then M.inspectClock=0;M.Inspect() end
  end)
end)
registerForEvent('onDraw',function()
  if not M.overlay then return end
  ImGui.SetNextWindowSize(510,320,ImGuiCond.FirstUseEver)
  if ImGui.Begin('Deathclaw Creature - experimental') then
    ImGui.TextWrapped(M.status)
    ImGui.Text('Mode: '..M.mode..' | Territorial brawler v3')
    ImGui.Text('Convoy preset: 20x health | 4x damage | 50m detection')
    ImGui.TextWrapped('V is ignored unless attacked. Aim at an NPC before opening CET.')
    if M.lookTarget then ImGui.Text('Aimed target: '..tostring(M.lookTarget:GetEntityID().hash)) end
    if M.warning then ImGui.TextWrapped(M.warning) end
    if ImGui.Button('Visit creature area') then protected(M.Visit) end
    ImGui.SameLine();if ImGui.Button('Spawn creature') then protected(M.Spawn) end
    if ImGui.Button('Patrol and hunt NPCs') then protected(M.Patrol) end
    if ImGui.Button('Attack NPC I am looking at') then protected(M.AttackLookAt) end
    if ImGui.Button('Attack V') then protected(M.AttackPlayer) end
    ImGui.SameLine();if ImGui.Button('Remove creature') then protected(M.Despawn) end
    if ImGui.Button('Inspect creature') then protected(M.Inspect) end
  end
  ImGui.End()
end)
return M
