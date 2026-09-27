local M = {
  location = {x=3816.0, y=-1555.0, z=130.1, yaw=35.0},
  template = [[local\deathclaw_badlands\deathclaw.ent]],
  entityID = nil, overlay = false, elapsed = 0, status = 'Waiting for a loaded game',
  verified = false, attempts = 0, pendingTime = 0
}

local function report(message)
  M.status = message
  print('[Deathclaw Badlands] '..message)
  local f = io.open('status.json', 'w')
  if f then
    f:write(json.encode({status=message, location=M.location, verified=M.verified, attempts=M.attempts}))
    f:close()
  end
end

local function ground(x,y,z)
  local hit, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(
    Vector4.new(x,y,z+25,1), Vector4.new(x,y,z-65,1), 'Static', false, false)
  if hit then return result.position.z end
  return nil
end

function M.Despawn()
  if M.entityID then
    Game.GetDynamicEntitySystem():DeleteEntity(M.entityID)
    M.entityID = nil
  end
  M.verified = false
  M.pendingTime = 0
end

function M.Spawn()
  if M.entityID then return end
  local z = ground(M.location.x, M.location.y, M.location.z)
  if not z then report('Waiting for terrain at the Wind Farm'); return end
  M.location.z = z + 0.015
  local spec = DynamicEntitySpec.new()
  spec.templatePath = M.template
  spec.appearanceName = 'default'
  spec.position = Vector4.new(M.location.x,M.location.y,M.location.z,1)
  spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0,0,M.location.yaw))
  spec.persistState = false
  spec.persistSpawn = false
  spec.alwaysSpawned = true
  spec.spawnInView = true
  spec.active = true
  spec.tags = {'DeathclawBadlands'}
  M.entityID = Game.GetDynamicEntitySystem():CreateEntity(spec)
  M.pendingTime = 0
  M.attempts = M.attempts + 1
  report('Requested Deathclaw at the Wind Farm')
end

function M.Visit()
  local player = Game.GetPlayer()
  if not player then return end
  Game.GetTeleportationFacility():Teleport(player,
    Vector4.new(3810.4736,-1560.9727,130.45,1), EulerAngles.new(0,0,-40))
  report('Travelled to the Wind Farm viewing spot')
end

function M.Inspect()
  local player = Game.GetPlayer()
  local entity = M.entityID and Game.FindEntityByID(M.entityID)
  local result = {status=M.status, location=M.location, entityFound=entity ~= nil}
  if player then
    local p=player:GetWorldPosition()
    result.player={x=p.x,y=p.y,z=p.z}
  end
  if entity then
    local p=entity:GetWorldPosition()
    result.entity={x=p.x,y=p.y,z=p.z}
  end
  print(json.encode(result))
  local f=io.open('inspection.json','w')
  if f then f:write(json.encode(result)); f:close() end
  return result
end

registerForEvent('onInit', function() report('Ready: statue will appear near the Wind Farm') end)
registerForEvent('onOverlayOpen', function() M.overlay=true end)
registerForEvent('onOverlayClose', function() M.overlay=false end)
registerForEvent('onShutdown', function() pcall(M.Despawn) end)
registerForEvent('onUpdate', function(dt)
  M.elapsed=M.elapsed+dt
  if M.elapsed < 2 then return end
  M.elapsed=0
  local player=Game.GetPlayer()
  if not player then M.entityID=nil; M.verified=false; M.attempts=0; return end
  local p=player:GetWorldPosition()
  local distance=math.sqrt((p.x-M.location.x)^2+(p.y-M.location.y)^2)
  local ok,err=pcall(function()
    if distance > 250 then
      if M.entityID then M.Despawn(); report('Statue unloaded while outside the Wind Farm') end
      return
    end
    if not M.entityID and distance < 180 and M.attempts < 3 then M.Spawn(); return end
    if M.entityID and not M.verified then
      if Game.FindEntityByID(M.entityID) then
        M.verified=true
        M.attempts=0
        report('Deathclaw entity is present at the Wind Farm')
        M.Inspect()
      else
        M.pendingTime = M.pendingTime + 2
        if M.pendingTime >= 20 then
          M.Despawn()
          report('Entity did not appear; check that the archive is installed')
        end
      end
    elseif M.entityID and M.verified and not Game.FindEntityByID(M.entityID) then
      M.Despawn()
      M.attempts = 0
      report('Waiting to restore the statue after a world reload')
    end
  end)
  if not ok then report(tostring(err)) end
end)
registerForEvent('onDraw', function()
  if not M.overlay then return end
  ImGui.SetNextWindowSize(410,170,ImGuiCond.FirstUseEver)
  if ImGui.Begin('Deathclaw Badlands') then
    ImGui.TextWrapped(M.status)
    ImGui.Text('Location: Badlands Wind Farm')
    if ImGui.Button('Visit the statue') then M.Visit() end
    ImGui.SameLine()
    if ImGui.Button('Inspect') then M.Inspect() end
    if ImGui.Button('Respawn statue') then M.Despawn(); M.attempts=0; M.elapsed=-2 end
  end
  ImGui.End()
end)
return M
