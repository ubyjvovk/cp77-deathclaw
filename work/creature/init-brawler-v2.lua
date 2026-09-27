-- Local experimental NPC. Uses its own record and entity, leaving the statue intact.
local M = {record='Character.LocalDeathclawBrawlerV2', version='brawler-v2', elapsed=0, overlay=false,
  mode='idle', status='Prototype ready. Spawn it from this panel.', pending=0,
  home={x=3832,y=-1555,z=130.2}, patrolIndex=0, patrolClock=0, scanClock=0}
local patrol={{0,0},{12,6},{15,-10},{-9,-13},{-12,5}}
local function distance(a,b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function entity() return M.id and Game.FindEntityByID(M.id) end
local function player() return Game.GetPlayer() end
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
  local r={version=M.version,status=M.status,mode=M.mode,entityFound=e~=nil,meshVerified=false,combatDamageVerified=false}
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
  M.id=nil;M.target=nil;M.command=nil;M.pending=0;M.mode='idle';M.spawnPosition=nil;M.maxTravel=0
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
local function attack(e,target)
  stopCommand(e)
  e:GetAttitudeAgent():SetAttitudeTowards(target:GetAttitudeAgent(),EAIAttitude.AIA_Hostile)
  local reaction=e.reactionComponent
  if not reaction then error('NPC reaction component unavailable') end
  reaction:SetReactionPreset(TweakDBInterface.GetReactionPresetRecord(TweakDBID.new('ReactionPresets.Ganger_Aggressive')))
  reaction:TriggerCombat(target)
  M.target=target;report('Combat requested against a nearby target')
end
function M.AttackPlayer()
  local e=entity();if e and player() then M.mode='combat';attack(e,player()) end
end
function M.AttackLookAt()
  local e=entity();if not e or not player() then return end
  local t=Game.GetTargetingSystem():GetLookAtObject(player(),false,false)
  if t and t:IsNPC() and t:GetEntityID().hash~=e:GetEntityID().hash and not t:IsDead() then
    M.mode='combat';attack(e,t)
  else report('Look at a living NPC first') end
end
function M.Patrol()
  local e=entity();if not e then return end
  stopCommand(e);M.target=nil;M.mode='patrol';M.patrolClock=30
  report('Patrolling the Wind Farm; nearby NPCs are prey')
end
local function moveTo(e,p)
  stopCommand(e)
  local world=NewObject('WorldPosition');world:SetVector4(world,Vector4.new(p.x,p.y,p.z,1))
  local pos=NewObject('AIPositionSpec');pos:SetWorldPosition(pos,world)
  local cmd=NewObject('handle:AIMoveToCommand')
  cmd.movementTarget=pos;cmd.rotateEntityTowardsFacingTarget=false
  cmd.ignoreNavigation=false;cmd.desiredDistanceFromTarget=2
  cmd.movementType='Walk';cmd.finishWhenDestinationReached=true
  cmd.alwaysUseStealth=false;e:GetAIControllerComponent():SendCommand(cmd);M.command=cmd
end
local function findPrey(e)
  local query=Game['TSQ_NPC;']();query.maxDistance=100
  local ok,parts=Game.GetTargetingSystem():GetTargetParts(player(),query)
  if not ok then return nil end
  local nearest,best=nil,22;local seen={};local here=e:GetWorldPosition()
  for _,part in ipairs(parts) do
    local t=part:GetComponent(part):GetEntity()
    if t and t:IsNPC() then
      local id=tostring(t:GetEntityID().hash)
      if not seen[id] and t:GetEntityID().hash~=e:GetEntityID().hash and not t:IsDead() then
        seen[id]=true;local d=distance(here,t:GetWorldPosition())
        if d<best then nearest=t;best=d end
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
    TweakDB:Update(M.record)
    report('Prototype ready. Spawn it from this panel.')
  end)
end)
registerForEvent('onOverlayOpen',function() M.overlay=true end)
registerForEvent('onOverlayClose',function() M.overlay=false end)
registerForEvent('onShutdown',function() pcall(M.Despawn) end)
registerForEvent('onUpdate',function(dt)
  M.elapsed=M.elapsed+dt;if M.elapsed<1 then return end
  local step=M.elapsed;M.elapsed=0
  if not player() then M.id=nil;M.target=nil;M.command=nil;M.pending=0;M.mode='idle';return end
  if not M.id then return end
  protected(function()
    local e=entity()
    if not e then
      M.pending=M.pending-step
      if M.pending<=0 then M.Despawn();report('NPC did not appear or world reloaded; spawn again') end
      return
    end
    if M.pending>0 then
      M.pending=0;M.patrolClock=30
      local pos=e:GetWorldPosition();M.spawnPosition={x=pos.x,y=pos.y,z=pos.z};M.maxTravel=0
      -- Affect only this NPC, never global faction attitudes.
      e:GetAttitudeAgent():SetAttitudeTowards(player():GetAttitudeAgent(),EAIAttitude.AIA_Neutral)
      report('Animated NPC found; patrol enabled');M.Inspect()
    end
    if distance(e:GetWorldPosition(),player():GetWorldPosition())>250 then M.Despawn();return end
    if e:IsDead() then M.mode='dead';return end
    if M.mode=='patrol' then
      if M.target then
        if not M.target:IsDead() then return end
        M.target=nil;M.patrolClock=30
      end
      M.scanClock=M.scanClock+step;M.patrolClock=M.patrolClock+step
      if M.scanClock>=3 then M.scanClock=0;local prey=findPrey(e);if prey then attack(e,prey);return end end
      if M.patrolClock>=15 then
        M.patrolClock=0;M.patrolIndex=M.patrolIndex%#patrol+1
        local point=patrol[M.patrolIndex]
        moveTo(e,{x=M.home.x+point[1],y=M.home.y+point[2],z=e:GetWorldPosition().z})
      end
    end
    M.Inspect()
  end)
end)
registerForEvent('onDraw',function()
  if not M.overlay then return end
  ImGui.SetNextWindowSize(460,240,ImGuiCond.FirstUseEver)
  if ImGui.Begin('Deathclaw Creature - experimental') then
    ImGui.TextWrapped(M.status)
    ImGui.Text('Mode: '..M.mode..' | Large melee brawler v2')
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
