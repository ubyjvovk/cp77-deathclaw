
public native class AIScriptsTargetTrackingListener extends AIITargetTrackingListener {

  public final native func SetAccuracyBound(bound: Float) -> Void;

  public final native func SetSharedAccuracyBound(bound: Float) -> Void;

  public func OnAccuracyBoundReached(above: Bool) -> Void;

  public func OnSharedAccuracyBoundReached(above: Bool) -> Void;
}

public class SecuritySupportListener extends AIScriptsTargetTrackingListener {

  public let npc: wref<ScriptedPuppet>;

  public final static func Construct(npc: ref<ScriptedPuppet>) -> ref<SecuritySupportListener> {
    let player: ref<PlayerPuppet>;
    let listener: ref<SecuritySupportListener> = new SecuritySupportListener();
    listener.npc = npc;
    listener.SetAccuracyBound(0.00);
    player = GetPlayer(npc.GetGame());
    if IsDefined(player) {
      npc.GetTargetTrackerComponent().RegisterListener(player, listener);
    };
    return listener;
  }

  public func OnAccuracyBoundReached(above: Bool) -> Void {
    this.npc.OnSecuritySupportThreshold(above);
  }
}

public class TargetTrackingExtension extends TargetTrackerComponent {

  private let m_trackedCombatSquads: [ref<CombatSquadScriptInterface>];

  private let m_trackedCombatSquadsCounters: [Int32];

  private let m_threatPersistanceMemory: ThreatPersistanceMemory;

  private let m_hasBeenSeenByPlayer: Bool;

  private let m_canBeAddedToBossHealthbar: Bool;

  private let m_playerPuppet: wref<GameObject>;

  private final func RegisterTrackedSquadMember(cssi: ref<CombatSquadScriptInterface>) -> Void {
    let index: Int32 = ArrayFindFirst(this.m_trackedCombatSquads, cssi);
    if index < 0 {
      ArrayPush(this.m_trackedCombatSquads, cssi);
      ArrayPush(this.m_trackedCombatSquadsCounters, 1);
    } else {
      this.m_trackedCombatSquadsCounters[index] += 1;
    };
  }

  private final func RevaluateTrackedSquads() -> Void {
    let i: Int32;
    let trackedLocations: array<TrackedLocation>;
    ArrayClear(this.m_trackedCombatSquadsCounters);
    ArrayClear(this.m_trackedCombatSquads);
    trackedLocations = this.GetHostileThreats(false);
    i = 0;
    while i < ArraySize(trackedLocations) {
      this.TryToRegisterTrackedSquad(trackedLocations[i].entity as ScriptedPuppet);
      i += 1;
    };
  }

  public final func RemoveHostileCamerasFromThreats() -> Void {
    let trackedLocations: array<TrackedLocation> = this.GetHostileThreats(false);
    let i: Int32 = 0;
    while i < ArraySize(trackedLocations) {
      if IsDefined(trackedLocations[i].entity as SurveillanceCamera) {
        this.RemoveThreat(this.MapThreat(trackedLocations[i].entity));
      };
      i += 1;
    };
  }

  public final func SquadTrackedMembersAmount(cssi: ref<CombatSquadScriptInterface>) -> Int32 {
    let index: Int32 = ArrayFindFirst(this.m_trackedCombatSquads, cssi);
    if index < 0 {
      return 0;
    };
    return this.m_trackedCombatSquadsCounters[index];
  }

  public final func IsSquadTracked(cssi: ref<CombatSquadScriptInterface>) -> Bool {
    return ArrayContains(this.m_trackedCombatSquads, cssi);
  }

  protected cb func OnSeenByPlayerEvent(evt: ref<gameProperlySeenByPlayerEvent>) -> Bool {
    this.m_hasBeenSeenByPlayer = true;
    if this.m_canBeAddedToBossHealthbar && IsDefined(this.m_playerPuppet) {
      BossHealthBarGameController.ReevaluateBossHealthBar(this.GetEntity() as NPCPuppet, this.m_playerPuppet);
    };
  }

  private final func AddPotentialBossTarget(target: wref<GameObject>) -> Void {
    let ownerPuppet: wref<NPCPuppet> = this.GetEntity() as NPCPuppet;
    if !IsDefined(ownerPuppet) || !ownerPuppet.IsBoss() {
      return;
    };
    if !IsDefined(target) || !target.IsPlayer() {
      return;
    };
    this.m_playerPuppet = target;
    this.m_canBeAddedToBossHealthbar = true;
    if this.m_hasBeenSeenByPlayer && IsDefined(this.m_playerPuppet) {
      BossHealthBarGameController.ReevaluateBossHealthBar(ownerPuppet, this.m_playerPuppet);
    };
  }

  public final static func HasHostileThreat(puppet: wref<ScriptedPuppet>, opt onlyVisible: Bool, opt onlyEntities: Bool) -> Bool {
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) {
      return false;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return false;
    };
    return tt.HasHostileThreat(onlyVisible, onlyEntities);
  }

  public final static func InjectThreat(puppet: wref<ScriptedPuppet>, const threat: script_ref<TrackedLocation>) -> Void {
    let pos: Vector4;
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) || !IsDefined(Deref(threat).entity) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return;
    };
    if TargetTrackingExtension.IsThreatInThreatList(puppet, Deref(threat).entity, false, true) {
      return;
    };
    if SenseComponent.ShouldIgnoreIfPlayerCompanion(puppet, Deref(threat).entity) {
      return;
    };
    pos = Deref(threat).sharedLocation.position;
    if Vector4.IsZero(pos) {
      pos = Deref(threat).entity.GetWorldPosition();
    };
    if IsDefined(Deref(threat).entity as ScriptedPuppet) {
      tt.AddThreat(Deref(threat).entity, true, pos, 1.00, -1.00, false);
    } else {
      tt.AddThreatOnPosition(pos, 0.50);
    };
  }

  public final static func InjectThreat(puppet: wref<ScriptedPuppet>, pos: Vector4, timeToLive: Float) -> Void {
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if IsDefined(tt) {
      tt.AddThreatOnPosition(pos, timeToLive);
    };
  }

  public final static func InjectThreat(puppet: wref<ScriptedPuppet>, threat: wref<Entity>) -> Void {
    TargetTrackingExtension.InjectThreat(puppet, threat, 1.00);
  }

  public final static func InjectThreat(puppet: wref<ScriptedPuppet>, threat: wref<Entity>, accuracy: Float, opt cooldown: Float) -> Void {
    let pos: Vector4;
    let threatLocation: TrackedLocation;
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) || !IsDefined(threat) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return;
    };
    if SenseComponent.ShouldIgnoreIfPlayerCompanion(puppet, threat) {
      return;
    };
    if TargetTrackingExtension.IsThreatInThreatList(puppet, threat, false, true) {
      return;
    };
    if AISquadHelper.GetThreatLocationFromSquad(puppet, threat, threatLocation) {
      pos = threatLocation.sharedLocation.position;
      if Vector4.IsZero(pos) {
        pos = threatLocation.entity.GetWorldPosition();
      };
    } else {
      pos = threat.GetWorldPosition();
    };
    if IsDefined(threat as ScriptedPuppet) {
      if cooldown > 0.00 {
        tt.AddThreat(threat, true, pos, accuracy, cooldown, false);
      } else {
        tt.AddThreat(threat, true, pos, accuracy, -1.00, false);
      };
    } else {
      if IsDefined(threat as SecurityTurret) {
        threat.QueueEvent(new TurnOnVisibilitySenseComponent());
        if cooldown > 0.00 {
          tt.AddThreat(threat, true, pos, accuracy, cooldown, false);
        } else {
          tt.AddThreat(threat, true, pos, accuracy, -1.00, false);
        };
      } else {
        tt.AddThreatOnPosition(pos, 0.50);
      };
    };
  }

  public final static func RemoveThreat(puppet: wref<ScriptedPuppet>, threat: wref<Entity>) -> Void {
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) || !IsDefined(threat) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return;
    };
    if TargetTrackingExtension.IsThreatInThreatList(puppet, threat, false, true) {
      return;
    };
    tt.RemoveThreat(tt.MapThreat(threat));
  }

  public final static func SetThreatPersistence(puppet: wref<ScriptedPuppet>, target: wref<Entity>, isPersistent: Bool, persistenceSource: Uint32) -> Void {
    let evt: ref<SetThreatsPersistenceRequest>;
    let previousPersistenceStatus: AIThreatPersistenceStatus;
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) || !IsDefined(target) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return;
    };
    previousPersistenceStatus = tt.GetThreatPersistence(puppet);
    if NotEquals(previousPersistenceStatus, AIThreatPersistenceStatus.ThreatNotFound) {
      evt = new SetThreatsPersistenceRequest();
      evt.et = puppet;
      if Equals(previousPersistenceStatus, AIThreatPersistenceStatus.Persistent) {
        evt.isPersistent = true;
      };
      puppet.QueueEvent(evt);
    };
    tt.SetThreatPersistence(target, isPersistent, persistenceSource);
  }

  public final static func SetCurrentThreatsPersistence(puppet: wref<ScriptedPuppet>, isPersistent: Bool, persistenceSource: Uint32) -> Void {
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(puppet) {
      return;
    };
    tt = puppet.GetTargetTrackerComponent();
    if !IsDefined(tt) {
      return;
    };
    tt.SetCurrentThreatsPersistence(isPersistent, persistenceSource);
  }

  protected cb func OnSetThreatsPersistenceRequest(evt: ref<SetThreatsPersistenceRequest>) -> Bool {
    let index: Int32;
    if !IsDefined(evt.et) {
      return true;
    };
    if !ArrayContains(this.m_threatPersistanceMemory.threats, evt.et) {
      if evt.isPersistent {
        ArrayPush(this.m_threatPersistanceMemory.threats, evt.et);
        ArrayPush(this.m_threatPersistanceMemory.isPersistent, evt.isPersistent);
      };
    } else {
      if !evt.isPersistent {
        index = ArrayFindFirst(this.m_threatPersistanceMemory.threats, evt.et);
        ArrayErase(this.m_threatPersistanceMemory.threats, index);
        ArrayErase(this.m_threatPersistanceMemory.isPersistent, index);
      };
    };
    return true;
  }

  public final func WasThreatPersistent(threat: wref<Entity>) -> Bool {
    let currentPersistenceStatus: AIThreatPersistenceStatus;
    let index: Int32;
    let tt: ref<TargetTrackerComponent>;
    if !IsDefined(threat) {
      return false;
    };
    tt = (threat as ScriptedPuppet).GetTargetTrackerComponent();
    if IsDefined(tt) {
      currentPersistenceStatus = tt.GetThreatPersistence(threat);
    };
    if ArrayContains(this.m_threatPersistanceMemory.threats, threat) {
      index = ArrayFindFirst(this.m_threatPersistanceMemory.threats, threat);
      if NotEquals(currentPersistenceStatus, AIThreatPersistenceStatus.Persistent) {
        ArrayErase(this.m_threatPersistanceMemory.threats, index);
        ArrayErase(this.m_threatPersistanceMemory.isPersistent, index);
        return false;
      };
      return this.m_threatPersistanceMemory.isPersistent[index];
    };
    return false;
  }

  public final static func OnHit(ownerPuppet: wref<ScriptedPuppet>, evt: ref<gameHitEvent>) -> Void {
    let id: TweakDBID;
    let instigator: wref<GameObject>;
    let targetTracker: wref<TargetTrackingExtension>;
    if !IsDefined(ownerPuppet) || !IsDefined(evt) || !IsDefined(evt.attackData) {
      return;
    };
    instigator = evt.attackData.GetInstigator();
    if !IsDefined(instigator) {
      return;
    };
    if ownerPuppet.GetEntityID() == instigator.GetEntityID() {
      return;
    };
    if ScriptedPuppet.IsPlayerCompanion(instigator) {
      return;
    };
    if !ownerPuppet.IsActive() {
      return;
    };
    if Equals(GameObject.GetAttitudeTowards(ownerPuppet, instigator), EAIAttitude.AIA_Friendly) {
      return;
    };
    if !ownerPuppet.IsAggressive() {
      return;
    };
    if evt.attackData.HasFlag(hitFlag.WasKillingBlow) {
      return;
    };
    if evt.attackData.HasFlag(hitFlag.QuickHack) {
      return;
    };
    if evt.attackData.HasFlag(hitFlag.DealNoDamage) {
      return;
    };
    NPCStatesComponent.AlertPuppet(ownerPuppet);
    if IsDefined(evt.attackData.GetSource() as Device) && !IsDefined(evt.attackData.GetWeapon()) {
      return;
    };
    if !TargetTrackingExtension.Get(ownerPuppet, targetTracker) {
      return;
    };
    if SenseComponent.ShouldIgnoreIfPlayerCompanion(ownerPuppet, instigator) {
      return;
    };
    if AIActionHelper.TryChangingAttitudeToHostile(ownerPuppet, instigator) {
      id = targetTracker.GetCurrentPreset();
      TDBID.Append(id, t".droppingCooldownPerHit");
      if instigator.IsPlayer() && instigator.GetTakeOverControlSystem().IsDeviceControlled() {
        instigator = instigator.GetTakeOverControlSystem().GetControlledObject();
        GameObject.ChangeAttitudeToHostile(ownerPuppet, instigator);
      };
      targetTracker.AddDroppingCooldown(instigator, TweakDBInterface.GetFloat(id, 0.00));
      targetTracker.AddThreat(instigator, true, instigator.GetWorldPosition(), 1.00, -1.00, false);
      if instigator.IsSensor() {
        instigator.QueueEvent(new TurnOnVisibilitySenseComponent());
      };
    };
  }

  public final static func Get(const puppet: wref<ScriptedPuppet>, out targetTracker: wref<TargetTrackingExtension>) -> Bool {
    if IsDefined(puppet) {
      targetTracker = puppet.GetTargetTrackerComponent() as TargetTrackingExtension;
      if IsDefined(targetTracker) {
        return true;
      };
    };
    return false;
  }

  public final static func Get(const puppet: wref<ScriptedPuppet>, out targetTracker: wref<TargetTrackerComponent>) -> Bool {
    if IsDefined(puppet) {
      targetTracker = puppet.GetTargetTrackerComponent();
      if IsDefined(targetTracker) {
        return true;
      };
    };
    return false;
  }

  public final static func Get(const context: ScriptExecutionContext, out targetTracker: wref<TargetTrackerComponent>) -> Bool {
    let puppet: wref<ScriptedPuppet> = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    if IsDefined(puppet) {
      targetTracker = puppet.GetTargetTrackerComponent();
      if IsDefined(targetTracker) {
        return true;
      };
    };
    return false;
  }

  public final static func GetStrong(const context: ScriptExecutionContext, out targetTracker: ref<TargetTrackerComponent>) -> Bool {
    let puppet: wref<ScriptedPuppet> = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    if IsDefined(puppet) {
      targetTracker = puppet.GetTargetTrackerComponent();
      if IsDefined(targetTracker) {
        return true;
      };
    };
    return false;
  }

  public final static func GetTrackedLocation(puppet: wref<ScriptedPuppet>, target: wref<Entity>, out trackedLocation: TrackedLocation) -> Bool {
    let targetTracker: wref<TargetTrackerComponent>;
    if IsDefined(target) && TargetTrackingExtension.Get(puppet, targetTracker) {
      return targetTracker.ThreatFromEntity(target, trackedLocation);
    };
    return false;
  }

  public final static func GetTrackedLocation(const context: ScriptExecutionContext, target: wref<Entity>, out trackedLocation: TrackedLocation) -> Bool {
    let targetTracker: wref<TargetTrackerComponent>;
    if IsDefined(target) && TargetTrackingExtension.Get(context, targetTracker) {
      return targetTracker.ThreatFromEntity(target, trackedLocation);
    };
    return false;
  }

  public final static func GetTopThreat(const context: ScriptExecutionContext, visible: Bool, out trackedLocation: TrackedLocation) -> Bool {
    let targetTracker: wref<TargetTrackerComponent>;
    if TargetTrackingExtension.Get(context, targetTracker) {
      return targetTracker.GetTopHostileThreat(visible, trackedLocation);
    };
    return false;
  }

  public final static func GetHostileThreats(const context: ScriptExecutionContext, visible: Bool, trackedLocations: script_ref<[TrackedLocation]>) -> Bool {
    let targetTracker: wref<TargetTrackerComponent>;
    if TargetTrackingExtension.Get(context, targetTracker) {
      trackedLocations = targetTracker.GetHostileThreats(visible);
      return ArraySize(Deref(trackedLocations)) > 0;
    };
    return false;
  }

  public final static func GetHostileThreats(puppet: wref<ScriptedPuppet>, visible: Bool, trackedLocations: script_ref<[TrackedLocation]>) -> Bool {
    let targetTracker: wref<TargetTrackerComponent>;
    if TargetTrackingExtension.Get(puppet, targetTracker) {
      trackedLocations = targetTracker.GetHostileThreats(visible);
      return ArraySize(Deref(trackedLocations)) > 0;
    };
    return false;
  }

  public final static func GetPlayerFromThreats(const hostileThreats: script_ref<[TrackedLocation]>, out player: wref<GameObject>) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(Deref(hostileThreats)) {
      player = Deref(hostileThreats)[i].entity as GameObject;
      if player.IsPlayer() {
        return true;
      };
      i += 1;
    };
    return false;
  }

  protected cb func OnEnemyPushedToSquad(evt: ref<EnemyPushedToSquad>) -> Bool {
    if Equals((this.GetEntity() as ScriptedPuppet).GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) {
      if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this.GetEntity() as GameObject, n"ResetSquadSync") {
        if (this.GetEntity() as ScriptedPuppet).IsActive() {
          this.PullSquadSync(AISquadType.Combat);
        };
      };
    };
  }

  protected cb func OnHostJoinedSquad(th: ref<HostJoinedSquad>) -> Bool {
    let vehicle: wref<GameObject>;
    let isPolice: Bool = NPCManager.HasTag((this.GetEntity() as ScriptedPuppet).GetRecordID(), n"InActivePoliceChase");
    if VehicleComponent.GetVehicle((this.GetEntity() as GameObject).GetGame(), this.GetEntity() as GameObject, vehicle) {
      if Equals((vehicle as VehicleObject).GetPoliceStrategy(), vehiclePoliceStrategy.GetToPlayerFromAnywhere) {
        isPolice = false;
      };
    };
    if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this.GetEntity() as GameObject, n"ResetSquadSync") && !isPolice {
      this.PullSquadSync(AISquadType.Combat);
    };
  }

  protected cb func OnHostLeftSquad(th: ref<HostLeftSquad>) -> Bool {
    let cssi: ref<CombatSquadScriptInterface>;
    let evt: ref<OnSquadmateDied>;
    let i: Int32;
    let squadMembers: array<wref<Entity>>;
    if !ScriptedPuppet.IsAlive(this.GetEntity() as GameObject) {
      cssi = th.squadInterface as CombatSquadScriptInterface;
      if IsDefined(cssi) && cssi.ValidCombatSquad() {
        squadMembers = cssi.ListMembersWeak();
        evt = new OnSquadmateDied();
        evt.killer = (this.GetEntity() as ScriptedPuppet).GetKiller();
        evt.squad = cssi.GetName();
        evt.squadmate = this.GetEntity();
        i = 0;
        while i < ArraySize(squadMembers) {
          squadMembers[i].QueueEvent(evt);
          i += 1;
        };
      };
    };
  }

  private final func RemoveWholeSquadFromThreats(cssi: ref<CombatSquadScriptInterface>) -> Void {
    let squadMembers: array<wref<Entity>> = cssi.ListMembersWeak();
    let i: Int32 = 0;
    while i < ArraySize(squadMembers) {
      this.RemoveThreat(this.MapThreat(squadMembers[i]));
      (squadMembers[i] as ScriptedPuppet).GetAIControllerComponent().SetBehaviorArgument(n"CombatTarget", ToVariant(null));
      (this.GetEntity() as ScriptedPuppet).GetSenses().ReevaluateDetectionOverwrite(squadMembers[i] as GameObject);
      i += 1;
    };
  }

  protected cb func OnThreatRemoved(th: ref<ThreatRemoved>) -> Bool {
    let evt: ref<RemoveLinkedStatusEffectsEvent>;
    let i: Int32;
    let membersCount: Uint32;
    let playerSquad: ref<CombatSquadScriptInterface>;
    let shouldPlayVO: Bool;
    let squadMembers: array<wref<Entity>>;
    let threat: ref<GameObject>;
    let owner: ref<GameObject> = th.owner as GameObject;
    if !IsDefined(owner) {
      return false;
    };
    threat = th.threat as GameObject;
    if !IsDefined(threat) {
      return false;
    };
    if th.distanceBasedInstantDrop && owner.IsPrevention() {
      StatusEffectHelper.ApplyStatusEffect(owner, t"PreventionStatusEffect.InstantThreatDropGracePeriod");
      VehicleComponent.OnThreatInstantDrop(owner);
    };
    if !ScriptedPuppet.IsActive(th.threat as GameObject) {
      if ScriptedPuppet.IsPlayerCompanion(owner) {
        shouldPlayVO = true;
        i = 0;
        while i < ArraySize(this.m_trackedCombatSquads) {
          membersCount = this.m_trackedCombatSquads[i].GetMembersCount();
          if membersCount > 1u {
            shouldPlayVO = false;
            break;
          };
          if membersCount == 1u {
            squadMembers = this.m_trackedCombatSquads[i].ListMembersWeak();
            if squadMembers[0] != th.threat {
              shouldPlayVO = false;
              break;
            };
          };
          i += 1;
        };
        if shouldPlayVO && Equals((owner as ScriptedPuppet).GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Stealth) {
          GameObject.PlayVoiceOver(owner, n"stealth_ended", n"Scripts:OnThreatRemoved");
        };
      };
    };
    this.RevaluateTrackedSquads();
    if threat.IsPlayer() {
      if owner.IsPuppet() && (owner as NPCPuppet).IsBoss() {
        BossHealthBarGameController.ReevaluateBossHealthBar(owner as NPCPuppet, threat, true);
        this.m_canBeAddedToBossHealthbar = false;
      };
      if ScriptedPuppet.IsActive(owner) {
        if th.isHostile {
          this.SetRecentlyDroppedThreat(th.threat, th.threat.GetWorldPosition());
        } else {
          if threat.IsPlayer() && StatusEffectSystem.ObjectHasStatusEffect(threat, t"StatusEffect.HackReveal") {
            StatusEffectHelper.ApplyStatusEffect(owner, t"AIQuickHackStatusEffect.HackRevealInterrupted", th.owner.GetEntityID());
          } else {
            StatusEffectHelper.ApplyStatusEffect(owner, t"AIQuickHackStatusEffect.HackingInterrupted", th.owner.GetEntityID());
          };
          evt = new RemoveLinkedStatusEffectsEvent();
          th.owner.QueueEvent(evt);
        };
        AISquadHelper.GetCombatSquadInterface(threat, playerSquad);
        this.RemoveWholeSquadFromThreats(playerSquad);
      };
    };
  }

  protected cb func OnStoppedBeingTrackedAsHostile(evt: ref<StoppedBeingTrackedAsHostile>) -> Bool {
    if this.m_canBeAddedToBossHealthbar && IsDefined(this.m_playerPuppet) {
      BossHealthBarGameController.ReevaluateBossHealthBar(this.GetEntity() as NPCPuppet, this.m_playerPuppet, true);
    };
  }

  private final func TryToRegisterTrackedSquad(threat: ref<ScriptedPuppet>) -> Void {
    let cssi: ref<CombatSquadScriptInterface>;
    let i: Int32;
    let senseComponent: ref<SenseComponent>;
    let squadMembers: array<wref<Entity>>;
    let wasSquadTracked: Bool;
    if !IsDefined(threat) {
      return;
    };
    AISquadHelper.GetCombatSquadInterface(threat, cssi);
    wasSquadTracked = this.IsSquadTracked(cssi);
    this.RegisterTrackedSquadMember(cssi);
    if !wasSquadTracked {
      if !AISquadHelper.GetSquadmates(threat, squadMembers, true) {
        return;
      };
      senseComponent = (this.GetEntity() as ScriptedPuppet).GetSenses();
      if IsDefined(senseComponent) {
        i = 0;
        while i < ArraySize(squadMembers) {
          senseComponent.RefreshCombatDetectionMultiplier(squadMembers[i] as ScriptedPuppet);
          i += 1;
        };
      };
    };
  }

  protected final func OnHostileThreatAdded(owner: wref<Entity>, threat: wref<Entity>) -> Void {
    let evt: ref<PlayerHostileThreatDetected>;
    let i: Int32;
    let squadMembers: array<wref<Entity>>;
    if SenseComponent.ShouldIgnoreIfPlayerCompanion(owner, threat) {
      this.RemoveThreat(this.MapThreat(threat));
    };
    if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this.GetEntity() as GameObject, n"ResetSquadSync") {
      this.PushSquadSync(AISquadType.Combat);
    };
    if ScriptedPuppet.IsPlayerCompanion(owner as ScriptedPuppet) {
      this.TryToPlayVOOnCompanion(owner as ScriptedPuppet, threat as GameObject, true);
    };
    this.TryToRegisterTrackedSquad(threat as ScriptedPuppet);
    if (owner as ScriptedPuppet).IsPlayer() {
      if !AISquadHelper.GetSquadmates(owner as ScriptedPuppet, squadMembers) {
        return;
      };
      evt = new PlayerHostileThreatDetected();
      evt.owner = owner;
      evt.threat = threat;
      evt.status = true;
      i = 0;
      while i < ArraySize(squadMembers) {
        squadMembers[i].QueueEvent(evt);
        i += 1;
      };
    } else {
      this.AddPotentialBossTarget(threat as GameObject);
    };
  }

  protected cb func OnSquadmateDeath(evt: ref<OnSquadmateDied>) -> Bool {
    if TargetTrackingExtension.IsThreatInThreatList(this.GetEntity() as ScriptedPuppet, evt.killer, false, true) {
      this.SetThreatAccuracy(evt.killer, 1.00);
      this.SetThreatBeliefAccuracy(evt.killer, 1.00);
    };
  }

  protected cb func OnNewThreat(th: ref<NewThreat>) -> Bool {
    if th.isHostile && !th.isEnemy {
      this.OnHostileThreatAdded(th.owner, th.threat);
    };
  }

  protected cb func OnHostileThreatDetected(th: ref<HostileThreatDetected>) -> Bool {
    if !th.status {
      return false;
    };
    this.OnHostileThreatAdded(th.owner, th.threat);
  }

  protected cb func OnPlayerHostileThreatDetected(evt: ref<PlayerHostileThreatDetected>) -> Bool {
    if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this.GetEntity() as GameObject, n"ResetSquadSync") {
      this.PullSquadSync(AISquadType.Combat);
    };
  }

  protected cb func OnEnemyThreatDetected(th: ref<EnemyThreatDetected>) -> Bool {
    let broadcaster: ref<StimBroadcasterComponent>;
    let threat: wref<GameObject>;
    let owner: ref<ScriptedPuppet> = th.owner as ScriptedPuppet;
    if owner.IsPlayer() {
      return false;
    };
    threat = th.threat as GameObject;
    if th.status {
      if ScriptedPuppet.IsPlayerCompanion(owner) {
        this.TryToPlayVOOnCompanion(owner, threat, false);
        TargetTrackingExtension.InjectThreat(owner, th.threat);
        return false;
      };
      if owner.IsCharacterCivilian() {
        broadcaster = threat.GetStimBroadcasterComponent();
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this.GetEntity() as GameObject, gamedataStimType.Combat, owner);
        };
      } else {
        if AIActionHelper.TryChangingAttitudeToHostile(owner, threat) {
          if IsSingleplayer() {
            TargetTrackingExtension.InjectThreat(owner, th.threat);
          };
        };
      };
    };
  }

  public final static func IsThreatInThreatList(owner: wref<ScriptedPuppet>, threat: wref<Entity>, visible: Bool, hostile: Bool) -> Bool {
    let allThreats: array<TrackedLocation>;
    let i: Int32;
    let targetTracker: wref<TargetTrackerComponent> = owner.GetTargetTrackerComponent();
    if IsDefined(targetTracker) {
      if hostile {
        allThreats = targetTracker.GetHostileThreats(visible);
      } else {
        allThreats = targetTracker.GetThreats(visible);
      };
      i = 0;
      while i < ArraySize(allThreats) {
        if allThreats[i].entity == threat {
          return true;
        };
        i += 1;
      };
    };
    return false;
  }

  private final func TryToPlayVOOnCompanion(owner: wref<ScriptedPuppet>, threat: wref<GameObject>, detectedBySelf: Bool) -> Void {
    let cssi: ref<CombatSquadScriptInterface>;
    let friendlyTarget: wref<PlayerPuppet>;
    let hls: gamedataNPCHighLevelState;
    let npcThreat: ref<NPCPuppet>;
    let npcThreatRarity: gamedataNPCRarity;
    if !IsDefined(owner) || !IsDefined(threat) || !owner.GetAIControllerComponent().GetFriendlyTargetAsPlayer(friendlyTarget) {
      return;
    };
    if AISquadHelper.GetCombatSquadInterface(threat as ScriptedPuppet, cssi) {
      if this.IsSquadTracked(cssi) || (friendlyTarget.GetTargetTrackerComponent() as TargetTrackingExtension).SquadTrackedMembersAmount(cssi) > detectedBySelf ? 0 : 1 {
        return;
      };
    };
    hls = owner.GetHighLevelStateFromBlackboard();
    if Equals(hls, gamedataNPCHighLevelState.Combat) {
      if threat.IsTurret() {
        GameObject.PlayVoiceOver(owner, n"turret_warning", n"Scripts:OnEnemyThreatDetected");
      } else {
        if threat.IsNPC() {
          npcThreat = threat as NPCPuppet;
          npcThreatRarity = npcThreat.GetNPCRarity();
          switch npcThreat.GetNPCType() {
            case gamedataNPCType.Drone:
              if Equals(npcThreatRarity, gamedataNPCRarity.Elite) || Equals(npcThreatRarity, gamedataNPCRarity.Officer) || Equals(npcThreatRarity, gamedataNPCRarity.Boss) {
                GameObject.PlayVoiceOver(owner, n"octant_warning", n"Scripts:OnEnemyThreatDetected");
              } else {
                GameObject.PlayVoiceOver(owner, n"drones_warning", n"Scripts:OnEnemyThreatDetected");
              };
              break;
            case gamedataNPCType.Mech:
              GameObject.PlayVoiceOver(owner, n"mech_warning", n"Scripts:OnEnemyThreatDetected");
              break;
            default:
              if Equals(npcThreatRarity, gamedataNPCRarity.Elite) {
                GameObject.PlayVoiceOver(owner, n"elite_warning", n"Scripts:OnEnemyThreatDetected");
              };
          };
        };
      };
    } else {
      if (Equals(hls, gamedataNPCHighLevelState.Stealth) || Equals(hls, gamedataNPCHighLevelState.Relaxed)) && EngineTime.ToFloat(GameInstance.GetTimeSystem(friendlyTarget.GetGame()).GetSimTime()) - friendlyTarget.GetCombatExitTimestamp() > 45.00 {
        if IsDefined(threat as SurveillanceCamera) {
          GameObject.PlayVoiceOver(owner, n"camera_warning", n"Scripts:OnEnemyThreatDetected");
        } else {
          GameObject.PlayVoiceOver(owner, n"enemy_warning", n"Scripts:OnEnemyThreatDetected");
        };
      };
    };
  }

  protected cb func OnPullSquadSyncRequest(evt: ref<PullSquadSyncRequest>) -> Bool {
    let ownerPuppet: ref<ScriptedPuppet> = this.GetEntity() as ScriptedPuppet;
    if IsDefined(ownerPuppet) && !StatusEffectSystem.ObjectHasStatusEffectWithTag(ownerPuppet, n"ResetSquadSync") {
      AISquadHelper.PullSquadSync(ownerPuppet, evt.squadType);
    };
  }
}

public abstract class AIActionTarget extends IScriptable {

  public final static func Set(const context: ScriptExecutionContext, record: ref<AIActionTarget_Record>, opt entity: wref<Entity>, pos: Vector4, opt coverID: Uint32) -> Bool {
    let tmpID: Uint64;
    if !IsDefined(record) {
      return false;
    };
    if record.IsObject() {
      ScriptExecutionContext.SetArgumentObject(context, record.BehaviorArgumentName(), entity as GameObject);
      ScriptExecutionContext.GetTweakActionSystem(context).ForceDirty(context, record.GetID());
      return true;
    };
    if record.IsPosition() {
      if IsDefined(entity) {
        ScriptExecutionContext.SetArgumentVector(context, record.BehaviorArgumentName(), entity.GetWorldPosition());
        ScriptExecutionContext.GetTweakActionSystem(context).ForceDirty(context, record.GetID());
        return true;
      };
      ScriptExecutionContext.SetArgumentVector(context, record.BehaviorArgumentName(), pos);
      ScriptExecutionContext.GetTweakActionSystem(context).ForceDirty(context, record.GetID());
      return true;
    };
    if record.IsCoverID() {
      tmpID = Cast<Uint64>(ScriptExecutionContext.GetArgumentInt(context, record.BehaviorArgumentName()));
      if tmpID != Cast<Uint64>(coverID) {
        ScriptExecutionContext.SetArgumentInt(context, record.BehaviorArgumentName(), Cast<Int32>(coverID));
        ScriptExecutionContext.GetTweakActionSystem(context).ForceDirty(context, record.GetID());
      };
      return true;
    };
    return false;
  }

  public final static func Get(const context: ScriptExecutionContext, record: ref<AIActionTarget_Record>, getSlotPosition: Bool, out obj: wref<GameObject>, out pos: Vector4, out coverID: Uint64, const opt predictionTime: Float) -> Bool {
    let strongObj: ref<GameObject>;
    if !IsDefined(record) {
      return false;
    };
    if Equals(record.Type(), gamedataAIActionTarget.NetrunnerProxy) {
      obj = AIActionTarget.GetNetrunnerProxy(context);
      if IsDefined(obj) {
        return true;
      };
      return false;
    };
    if Equals(record.Type(), gamedataAIActionTarget.CurrentNetrunnerProxy) {
      obj = ScriptExecutionContext.GetArgumentObject(context, n"NetrunnerProxy");
      if IsDefined(obj) {
        return true;
      };
      return false;
    };
    if !ScriptExecutionContext.GetTweakActionSystem(context).EvaluateActionTargetAll(context, record.GetID(), predictionTime, strongObj, pos, coverID) {
      return false;
    };
    obj = strongObj;
    return true;
  }

  public final static func Get(const context: ScriptExecutionContext, record: ref<AIActionTarget_Record>, out obj: wref<GameObject>, out pos: Vector4, out coverID: Uint64, const opt predictionTime: Float) -> Bool {
    return AIActionTarget.Get(context, record, false, obj, pos, coverID, predictionTime);
  }

  public final static func GetLegacy(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, getSlotPosition: Bool, out obj: wref<GameObject>, out pos: Vector4, out coverID: Uint64, const opt predictionTime: Float) -> Bool {
    let objVelocity: Vector4;
    let slotName: CName;
    let targetTracker: ref<TargetTrackerComponent>;
    let tmpProvider: ref<IPositionProvider>;
    let trackedLocation: TrackedLocation;
    if !IsDefined(record) {
      return false;
    };
    if AIActionTarget.GetObjectLegacy(context, record, obj) {
      if obj != ScriptExecutionContext.GetOwner(context) && TargetTrackingExtension.GetTrackedLocation(context, obj, trackedLocation) && NotEquals(record.Type(), gamedataAIActionTarget.StimTarget) {
        if IsDefined(record.TrackingMode()) && NotEquals(record.TrackingMode().Type(), gamedataTrackingMode.RealPosition) && TargetTrackingExtension.GetStrong(context, targetTracker) {
          if getSlotPosition {
            slotName = record.TargetSlot();
          };
          switch record.TrackingMode().Type() {
            case gamedataTrackingMode.LastKnownPosition:
              tmpProvider = targetTracker.GetThreatLastKnownPositionProvider(obj, false, slotName, IPositionProvider.CreateEntityPositionProvider(ScriptExecutionContext.GetOwner(context)));
              break;
            case gamedataTrackingMode.BeliefPosition:
              tmpProvider = targetTracker.GetThreatBeliefPositionProvider(obj, false, slotName, IPositionProvider.CreateEntityPositionProvider(ScriptExecutionContext.GetOwner(context)));
              break;
            case gamedataTrackingMode.SharedLastKnownPosition:
              tmpProvider = targetTracker.GetThreatSharedLastKnownPositionProvider(obj, false, slotName, IPositionProvider.CreateEntityPositionProvider(ScriptExecutionContext.GetOwner(context)));
              break;
            case gamedataTrackingMode.SharedBeliefPosition:
              tmpProvider = targetTracker.GetThreatSharedBeliefPositionProvider(obj, false, slotName, IPositionProvider.CreateEntityPositionProvider(ScriptExecutionContext.GetOwner(context)));
              break;
            default:
          };
        };
        if !IsDefined(tmpProvider) || !tmpProvider.CalculatePosition(pos) {
          if Vector4.IsZero(trackedLocation.location.position) || !obj.GetTargetTrackerComponent().IsPositionValid(trackedLocation.location.position) {
            pos = obj.GetWorldPosition();
          } else {
            pos = trackedLocation.location.position;
          };
        };
        if predictionTime > 0.00 {
          pos += trackedLocation.speed * predictionTime;
        };
      } else {
        pos = obj.GetWorldPosition();
        if predictionTime > 0.00 && IsDefined(obj as gamePuppet) {
          objVelocity = (obj as gamePuppet).GetVelocity();
          objVelocity.Z = 0.00;
          pos += objVelocity * predictionTime;
        };
      };
      return true;
    };
    if record.IsPosition() {
      return AIActionTarget.GetPosition(context, record, pos, getSlotPosition);
    };
    if record.IsCoverID() {
      if !AIActionTarget.GetCoverID(context, record, coverID) {
        return false;
      };
      return AIActionTarget.GetCoverPosition(context, coverID, pos);
    };
    return false;
  }

  public final static func Get(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, getSlotPosition: Bool, out obj: wref<GameObject>, out position: Vector4, const opt predictionTime: Float) -> Bool {
    let coverId: Uint64;
    return AIActionTarget.Get(context, record, getSlotPosition, obj, position, coverId, predictionTime);
  }

  public final static func GetObject(const context: ScriptExecutionContext, record: ref<AIActionTarget_Record>, out object: wref<GameObject>) -> Bool {
    let strongObject: ref<GameObject>;
    if !IsDefined(record) {
      return false;
    };
    if Equals(record.Type(), gamedataAIActionTarget.NetrunnerProxy) {
      object = AIActionTarget.GetNetrunnerProxy(context);
      if IsDefined(object) {
        return true;
      };
      return false;
    };
    if Equals(record.Type(), gamedataAIActionTarget.CurrentNetrunnerProxy) {
      object = ScriptExecutionContext.GetArgumentObject(context, n"NetrunnerProxy");
      if IsDefined(object) {
        return true;
      };
      return false;
    };
    if !ScriptExecutionContext.GetTweakActionSystem(context).EvaluateActionTargetObject(context, record.GetID(), strongObject) {
      return false;
    };
    object = strongObject;
    return true;
  }

  public final static func GetNetrunnerProxy(const context: ScriptExecutionContext) -> wref<GameObject> {
    let candidate: wref<Entity>;
    let compareDistance: Float;
    let distance: Float;
    let i: Int32;
    let j: Int32;
    let securitySystem: ref<SecuritySystemControllerPS>;
    let sensorDevice: wref<SensorDevice>;
    let sensorDevices: array<ref<SensorDeviceControllerPS>>;
    let squadInterface: wref<SquadScriptInterface>;
    let squadMembers: array<wref<Entity>>;
    let trackedLocations: array<TrackedLocation>;
    let target: wref<GameObject> = ScriptExecutionContext.GetArgumentObject(context, n"CombatTarget");
    if !IsDefined(target) {
      return null;
    };
    if (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).IsConnectedToSecuritySystem() {
      securitySystem = (ScriptExecutionContext.GetOwner(context) as ScriptedPuppet).GetSecuritySystem();
      if IsDefined(securitySystem) {
        sensorDevices = securitySystem.GetSensors();
        i = 0;
        while i < ArraySize(sensorDevices) {
          sensorDevice = sensorDevices[i].GetOwnerEntityWeak() as SensorDevice;
          if IsDefined(sensorDevice) && sensorDevice.GetCurrentlyFollowedTarget() == target {
            candidate = sensorDevice;
          };
          i += 1;
        };
      };
    };
    squadInterface = ScriptExecutionContext.GetOwner(context).GetSquadMemberComponent().MySquad(AISquadType.Combat);
    if !IsDefined(squadInterface) {
      return null;
    };
    squadMembers = squadInterface.ListMembersWeak();
    ArrayRemove(squadMembers, ScriptExecutionContext.GetOwner(context));
    i = 0;
    while i < ArraySize(squadMembers) {
      if TargetTrackingExtension.GetHostileThreats(squadMembers[i] as ScriptedPuppet, true, trackedLocations) {
        j = 0;
        while j < ArraySize(trackedLocations) {
          distance = Vector4.Distance(squadMembers[i].GetWorldPosition(), target.GetWorldPosition());
          if trackedLocations[j].entity == target && (compareDistance == 0.00 || compareDistance > distance) {
            compareDistance = distance;
            candidate = squadMembers[i];
          };
          j += 1;
        };
      };
      i += 1;
    };
    return candidate as GameObject;
  }

  public final static func GetObjectLegacy(const context: ScriptExecutionContext, record: ref<AIActionTarget_Record>, out object: wref<GameObject>) -> Bool {
    let compareDistance: Float;
    let distance: Float;
    let i: Int32;
    let j: Int32;
    let squadInterface: wref<SquadScriptInterface>;
    let squadMembers: array<wref<Entity>>;
    let trackedLocation: TrackedLocation;
    let trackedLocations: array<TrackedLocation>;
    if !IsDefined(record) {
      return false;
    };
    if !record.IsObject() {
      return false;
    };
    switch record.Type() {
      case gamedataAIActionTarget.Owner:
        object = ScriptExecutionContext.GetOwner(context);
        break;
      case gamedataAIActionTarget.CombatTarget:
        object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        break;
      case gamedataAIActionTarget.TopThreat:
      case gamedataAIActionTarget.VisibleTopThreat:
        if TargetTrackingExtension.GetTopThreat(context, Equals(record.Type(), gamedataAIActionTarget.VisibleTopThreat), trackedLocation) {
          object = trackedLocation.entity as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.NearestThreat:
        if TargetTrackingExtension.GetHostileThreats(context, true, trackedLocations) {
          i = 0;
          while i < ArraySize(trackedLocations) {
            distance = Vector4.Distance(ScriptExecutionContext.GetOwner(context).GetWorldPosition(), trackedLocations[i].location.position);
            if compareDistance == 0.00 || compareDistance > distance {
              compareDistance = distance;
              j = i;
            };
            i += 1;
          };
          object = trackedLocations[j].entity as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.FurthestThreat:
        if TargetTrackingExtension.GetHostileThreats(context, true, trackedLocations) {
          i = 0;
          while i < ArraySize(trackedLocations) {
            distance = Vector4.Distance(ScriptExecutionContext.GetOwner(context).GetWorldPosition(), trackedLocations[i].location.position);
            if compareDistance == 0.00 || compareDistance < distance {
              compareDistance = distance;
              j = i;
            };
            i += 1;
          };
          object = trackedLocations[j].entity as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.NearestSquadmate:
        squadInterface = ScriptExecutionContext.GetOwner(context).GetSquadMemberComponent().MySquad(AISquadType.Combat);
        if IsDefined(squadInterface) {
          squadMembers = squadInterface.ListMembersWeak();
        };
        if ArraySize(squadMembers) > 0 {
          i = 0;
          while i < ArraySize(squadMembers) {
            distance = Vector4.Distance(ScriptExecutionContext.GetOwner(context).GetWorldPosition(), squadMembers[i].GetWorldPosition());
            if ScriptExecutionContext.GetOwner(context) != squadMembers[i] && (compareDistance == 0.00 || compareDistance > distance) {
              compareDistance = distance;
              j = i;
            };
            i += 1;
          };
          object = squadMembers[j] as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.FurthestSquadmate:
        squadInterface = ScriptExecutionContext.GetOwner(context).GetSquadMemberComponent().MySquad(AISquadType.Combat);
        if IsDefined(squadInterface) {
          squadMembers = squadInterface.ListMembersWeak();
        };
        if ArraySize(squadMembers) > 0 {
          i = 0;
          while i < ArraySize(squadMembers) {
            distance = Vector4.Distance(ScriptExecutionContext.GetOwner(context).GetWorldPosition(), squadMembers[i].GetWorldPosition());
            if compareDistance == 0.00 || compareDistance < distance {
              compareDistance = distance;
              j = i;
            };
            i += 1;
          };
          object = squadMembers[j] as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.HostileOfficer:
        if TargetTrackingExtension.GetHostileThreats(context, true, trackedLocations) {
          i = 0;
          while i < ArraySize(trackedLocations) {
            if (trackedLocations[i].entity as ScriptedPuppet).IsOfficer() {
              break;
            };
            i += 1;
          };
          object = trackedLocations[i].entity as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
      case gamedataAIActionTarget.SquadOfficer:
        squadInterface = ScriptExecutionContext.GetOwner(context).GetSquadMemberComponent().MySquad(AISquadType.Community);
        if IsDefined(squadInterface) {
          squadMembers = squadInterface.ListMembersWeak();
        };
        if ArraySize(squadMembers) > 0 {
          i = 0;
          while i < ArraySize(squadMembers) {
            if (squadMembers[i] as ScriptedPuppet).IsOfficer() {
              break;
            };
            i += 1;
          };
          object = squadMembers[i] as GameObject;
        } else {
          object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
        };
        break;
      case gamedataAIActionTarget.AssignedVehicle:
        AIHumanComponent.GetAssignedVehicle(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, object);
        break;
      case gamedataAIActionTarget.MountedVehicle:
        VehicleComponent.GetVehicle(ScriptExecutionContext.GetOwner(context).GetGame(), ScriptExecutionContext.GetOwner(context), object);
        break;
      case gamedataAIActionTarget.NearestDefeatedSquadmate:
        squadInterface = ScriptExecutionContext.GetOwner(context).GetSquadMemberComponent().MySquad(AISquadType.Combat);
        j = -1;
        if IsDefined(squadInterface) {
          squadMembers = squadInterface.ListMembersWeak();
        };
        i = 0;
        while i < ArraySize(squadMembers) {
          if !ScriptedPuppet.IsDefeated(squadMembers[i] as GameObject) {
          } else {
            distance = Vector4.Distance(ScriptExecutionContext.GetOwner(context).GetWorldPosition(), squadMembers[i].GetWorldPosition());
            if compareDistance == 0.00 || compareDistance > distance {
              compareDistance = distance;
              j = i;
            };
          };
          i += 1;
        };
        if j > -1 {
          object = squadMembers[j] as GameObject;
        } else {
          object = null;
        };
        break;
      case gamedataAIActionTarget.Player:
        object = GameInstance.GetPlayerSystem(ScriptExecutionContext.GetOwner(context).GetGame()).GetLocalPlayerMainGameObject();
        break;
      default:
        object = ScriptExecutionContext.GetArgumentObject(context, record.BehaviorArgumentName());
    };
    return object != null;
  }

  public final static func GetPosition(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, out position: Vector4, getSlotPosition: Bool, const opt predictionTime: Float) -> Bool {
    let target: wref<GameObject>;
    if !IsDefined(record) {
      return false;
    };
    if record.IsPosition() {
      position = ScriptExecutionContext.GetArgumentVector(context, record.BehaviorArgumentName());
    } else {
      if record.IsCoverID() {
        AIActionTarget.GetCoverPosition(context, ScriptExecutionContext.GetArgumentUint64(context, record.BehaviorArgumentName()), position);
      } else {
        if record.IsObject() {
          AIActionTarget.Get(context, record, getSlotPosition, target, position, predictionTime);
        };
      };
    };
    return !Vector4.IsZero(position);
  }

  public final static func GetCurrentCoverID(const context: ScriptExecutionContext, out coverID: Uint64, out position: Vector4) -> Bool {
    if !AIActionTarget.GetCurrentCoverID(context, coverID) {
      return false;
    };
    return AIActionTarget.GetCoverPosition(context, coverID, position);
  }

  public final static func GetCurrentCoverID(const context: ScriptExecutionContext, out coverID: Uint64) -> Bool {
    let cm: ref<CoverManager>;
    let puppet: ref<ScriptedPuppet> = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
    if !IsDefined(puppet) {
      return false;
    };
    cm = GameInstance.GetCoverManager(puppet.GetGame());
    if !IsDefined(cm) {
      return false;
    };
    coverID = cm.GetCurrentCover(puppet);
    return coverID > 0u;
  }

  public final static func GetCoverID(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, out coverID: Uint64, out position: Vector4) -> Bool {
    if !AIActionTarget.GetCoverID(context, record, coverID) {
      return false;
    };
    return AIActionTarget.GetCoverPosition(context, coverID, position);
  }

  public final static func GetCoverID(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, out coverID: Uint64) -> Bool {
    let cm: ref<CoverManager>;
    let puppet: ref<ScriptedPuppet>;
    if !IsDefined(record) {
      return false;
    };
    if !record.IsCoverID() {
      return false;
    };
    switch record.Type() {
      case gamedataAIActionTarget.CurrentCover:
        puppet = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
        if !IsDefined(puppet) {
          return false;
        };
        cm = GameInstance.GetCoverManager(puppet.GetGame());
        if !IsDefined(cm) {
          return false;
        };
        coverID = cm.GetCurrentCover(puppet);
        break;
      case gamedataAIActionTarget.DesiredCover:
        coverID = ScriptExecutionContext.GetArgumentUint64(context, n"DesiredCoverID");
        break;
      case gamedataAIActionTarget.SelectedCover:
        coverID = ScriptExecutionContext.GetArgumentUint64(context, n"CoverID");
        break;
      case gamedataAIActionTarget.CommandCover:
        coverID = ScriptExecutionContext.GetArgumentUint64(context, n"CommandCoverID");
    };
    return coverID > 0u;
  }

  public final static func GetCoverPosition(const context: ScriptExecutionContext, coverID: Uint64, out position: Vector4) -> Bool {
    if coverID > 0u {
      if IsDefined(GameInstance.GetCoverManager(ScriptExecutionContext.GetOwner(context).GetGame())) {
        position = GameInstance.GetCoverManager(ScriptExecutionContext.GetOwner(context).GetGame()).GetCoverPosition(coverID);
      };
    };
    return !Vector4.IsZero(position);
  }

  public final static func GetVehicleObject(const context: ScriptExecutionContext, record: wref<AIActionTarget_Record>, out vehicleObject: wref<VehicleObject>) -> Bool {
    let object: wref<GameObject>;
    if !AIActionTarget.GetObject(context, record, object) {
      return false;
    };
    vehicleObject = object as VehicleObject;
    if IsDefined(vehicleObject) || VehicleComponent.GetVehicle(object.GetGame(), object, vehicleObject) {
      return true;
    };
    return false;
  }

  public final static func UpdateThreatsValue(puppet: ref<NPCPuppet>, newTargetObject: ref<GameObject>, timeSinceTargetChange: Float) -> Void {
    let allThreats: array<TrackedLocation>;
    let currentTime: Float;
    let i: Int32;
    let isPlayersFollower: Bool;
    let isVisTargetingMode: Bool;
    let targetTrackerComponent: ref<TargetTrackerComponent>;
    let threat: ref<GameObject>;
    let threatBaseVal: Float;
    let visTargetingTolerance: Float = 0.80;
    let ownerPos: Vector4 = puppet.GetWorldPosition();
    if Vector4.IsZero(ownerPos) {
      return;
    };
    isPlayersFollower = ScriptedPuppet.IsPlayerCompanion(puppet) && Equals(puppet.GetAIControllerComponent().GetAIRole().GetRoleEnum(), EAIRole.Follower);
    targetTrackerComponent = puppet.GetTargetTrackerComponent();
    allThreats = targetTrackerComponent.GetHostileThreats(false);
    currentTime = EngineTime.ToFloat(GameInstance.GetSimTime(puppet.GetGame()));
    isVisTargetingMode = isPlayersFollower && StatusEffectSystem.ObjectHasStatusEffect(puppet, t"BaseStatusEffect.FollowerVisibilityTargeting");
    i = 0;
    while i < ArraySize(allThreats) {
      threat = allThreats[i].entity as GameObject;
      threatBaseVal = 0.00;
      if threat.IsPlayerControlled() {
        if StatusEffectSystem.ObjectHasStatusEffectOfType(threat, gamedataStatusEffectType.BlockTargetingPlayer) || StatusEffectSystem.ObjectHasStatusEffectOfType(puppet, gamedataStatusEffectType.BlockTargetingPlayer) {
          targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
        } else {
          if isVisTargetingMode && (!allThreats[i].visible || targetTrackerComponent.GetVisibleThreatBeliefAccuracy(threat) < visTargetingTolerance) {
            if !AIActionTarget.IsThreatCloseOrVisibleByPlayer(ownerPos, threat) {
              targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
            } else {
              if IsDefined(threat as SurveillanceCamera) {
                targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
              } else {
                switch puppet.GetThreatCalculationType() {
                  case EAIThreatCalculationType.Madness:
                    AIActionTarget.MadnessThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                    break;
                  case EAIThreatCalculationType.Boss:
                    AIActionTarget.BossThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                    break;
                  default:
                    AIActionTarget.RegularThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                };
                targetTrackerComponent.SetThreatBaseMul(threat, threatBaseVal);
              };
            };
          };
          if IsDefined(threat as SurveillanceCamera) {
            targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
          } else {
            switch puppet.GetThreatCalculationType() {
              case EAIThreatCalculationType.Madness:
                AIActionTarget.MadnessThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                break;
              case EAIThreatCalculationType.Boss:
                AIActionTarget.BossThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                break;
              default:
                AIActionTarget.RegularThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
            };
            targetTrackerComponent.SetThreatBaseMul(threat, threatBaseVal);
          };
        };
      };
      if isVisTargetingMode && (!allThreats[i].visible || targetTrackerComponent.GetVisibleThreatBeliefAccuracy(threat) < visTargetingTolerance) {
        if !AIActionTarget.IsThreatCloseOrVisibleByPlayer(ownerPos, threat) {
          targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
        } else {
          if IsDefined(threat as SurveillanceCamera) {
            targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
          } else {
            switch puppet.GetThreatCalculationType() {
              case EAIThreatCalculationType.Madness:
                AIActionTarget.MadnessThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                break;
              case EAIThreatCalculationType.Boss:
                AIActionTarget.BossThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
                break;
              default:
                AIActionTarget.RegularThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
            };
            targetTrackerComponent.SetThreatBaseMul(threat, threatBaseVal);
          };
        };
      };
      if IsDefined(threat as SurveillanceCamera) {
        targetTrackerComponent.SetThreatBaseMul(threat, -1.00);
      } else {
        switch puppet.GetThreatCalculationType() {
          case EAIThreatCalculationType.Madness:
            AIActionTarget.MadnessThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
            break;
          case EAIThreatCalculationType.Boss:
            AIActionTarget.BossThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
            break;
          default:
            AIActionTarget.RegularThreatCalculation(puppet, ownerPos, targetTrackerComponent, newTargetObject, threat, timeSinceTargetChange, currentTime, threatBaseVal);
        };
        targetTrackerComponent.SetThreatBaseMul(threat, threatBaseVal);
      };
      i += 1;
    };
  }

  private final static func RegularThreatCalculation(owner: wref<ScriptedPuppet>, ownerPos: Vector4, targetTrackerComponent: ref<TargetTrackerComponent>, newTargetObject: wref<GameObject>, threat: wref<GameObject>, timeSinceTargetChange: Float, currentTime: Float, out threatValue: Float) -> Void {
    let distance: Float;
    let turret: ref<SecurityTurret>;
    let zDiff: Float;
    if !ScriptedPuppet.IsActive(threat) {
      return;
    };
    threatValue = 0.01;
    turret = threat as SecurityTurret;
    if !threat.IsPuppet() && !IsDefined(turret) {
      return;
    };
    if threat.IsPlayerControlled() || IsDefined(turret) {
      threatValue = 1.00;
    };
    distance = AIActionTarget.GetDistanceToThreat(ownerPos, threat, zDiff, true);
    threatValue += AIActionTarget.GetThreatZDiffModifier(zDiff);
    threatValue += AIActionTarget.GetThreatDistanceModifier(targetTrackerComponent, distance);
    threatValue += AIActionTarget.GetThreatHisteresisModifier(targetTrackerComponent, threat, newTargetObject, timeSinceTargetChange);
    threatValue += AIActionTarget.GetThreatDamageModifier(targetTrackerComponent, owner, threat, distance, currentTime);
    threatValue += AIActionTarget.GetThreatAttackersModifier(targetTrackerComponent, owner, threat);
    threatValue += AIActionTarget.GetThreatLastVisibilityModifier(owner, threat);
    threatValue += AIActionTarget.GetThreatAccessibilityFromCoverModifier(owner, threat);
    if ScriptedPuppet.IsBeingGrappled(threat) {
      threatValue *= 0.10;
    } else {
      if !IsDefined(turret) && !AIActionTarget.HasWeaponInInventory(threat) {
        threatValue *= 0.50;
      };
    };
  }

  private final static func BossThreatCalculation(owner: wref<ScriptedPuppet>, ownerPos: Vector4, targetTrackerComponent: ref<TargetTrackerComponent>, newTargetObject: wref<GameObject>, threat: wref<GameObject>, timeSinceTargetChange: Float, currentTime: Float, out threatValue: Float) -> Void {
    let distance: Float;
    let threatPuppet: wref<ScriptedPuppet>;
    let turret: wref<SecurityTurret>;
    let zDiff: Float;
    if ScriptedPuppet.IsActive(threat) {
      threatValue = 0.01;
      if threat.IsTurret() {
        turret = threat as SecurityTurret;
      } else {
        if threat.IsPuppet() {
          threatPuppet = threat as ScriptedPuppet;
        };
      };
      if IsDefined(threatPuppet) || IsDefined(turret) {
        if threat == newTargetObject && IsDefined(threatPuppet) && threatPuppet.IsPlayerCompanion() && timeSinceTargetChange >= 3.00 {
          threatValue = 0.01;
          return;
        };
        if threat.IsPlayerControlled() {
          threatValue = 2.00;
        } else {
          if IsDefined(turret) {
            if turret.GetDevicePS().IsControlledByPlayer() {
              threatValue = 100.00;
            } else {
              threatValue = 2.00;
            };
          };
        };
        distance = AIActionTarget.GetDistanceToThreat(ownerPos, threat, zDiff);
        threatValue += AIActionTarget.GetThreatDistanceModifier(targetTrackerComponent, distance);
        threatValue += AIActionTarget.GetThreatHisteresisModifier(targetTrackerComponent, threat, newTargetObject, timeSinceTargetChange);
        threatValue += AIActionTarget.GetThreatDamageModifier(targetTrackerComponent, owner, threat, distance, currentTime);
        threatValue += AIActionTarget.GetThreatAttackersModifier(targetTrackerComponent, owner, threat);
      };
    };
  }

  private final static func MadnessThreatCalculation(owner: wref<ScriptedPuppet>, ownerPos: Vector4, targetTrackerComponent: ref<TargetTrackerComponent>, newTargetObject: wref<GameObject>, threat: wref<GameObject>, timeSinceTargetChange: Float, currentTime: Float, out threatValue: Float) -> Void {
    let distance: Float;
    let zDiff: Float;
    if ScriptedPuppet.IsActive(threat) {
      threatValue = 0.01;
      if threat.IsPuppet() || threat.IsTurret() {
        distance = AIActionTarget.GetDistanceToThreat(ownerPos, threat, zDiff);
        threatValue += AIActionTarget.GetThreatDistanceModifier(targetTrackerComponent, distance);
      };
    };
  }

  private final static func HasWeaponInInventory(owner: wref<GameObject>) -> Bool {
    let puppet: ref<ScriptedPuppet> = owner as ScriptedPuppet;
    if IsDefined(puppet) {
      return puppet.HasPrimaryOrSecondaryEquipment();
    };
    return false;
  }

  public final static func GetDistanceToThreat(ownerPos: Vector4, threat: ref<GameObject>, out zDiff: Float, opt positionOfRoot: Bool) -> Float {
    let targetPos: Vector4;
    if positionOfRoot || !AIActionHelper.GetTargetSlotPosition(threat, n"Head", targetPos) {
      targetPos = threat.GetWorldPosition();
    };
    zDiff = ownerPos.Z - targetPos.Z;
    return Vector4.Distance(ownerPos, targetPos);
  }

  public final static func GetThreatDistanceModifier(targetTrackerComponent: ref<TargetTrackerComponent>, distance: Float) -> Float {
    let threatValue: Float = targetTrackerComponent.GetThreatPriorityModFromDistCurve(distance);
    return threatValue;
  }

  public final static func GetThreatZDiffModifier(zDiff: Float) -> Float {
    let floorDiff: Int32 = Cast<Int32>(AbsF(zDiff) / 3.70);
    let threatValue: Float = 1.50 * (1.00 - ClampF(Cast<Float>(floorDiff), 0.00, 5.00) / 5.00);
    return threatValue;
  }

  private final static func GetThreatHisteresisModifier(targetTrackerComponent: ref<TargetTrackerComponent>, threat: ref<GameObject>, currentTarget: ref<GameObject>, timeSinceTargetChange: Float) -> Float {
    let histeresisVal: Float = 0.00;
    if threat == currentTarget {
      histeresisVal = targetTrackerComponent.GetThreatPriorityModFromHisteresisCurve(timeSinceTargetChange);
    };
    return histeresisVal;
  }

  private final static func GetThreatDamageModifier(targetTrackerComponent: ref<TargetTrackerComponent>, puppet: ref<ScriptedPuppet>, threat: ref<GameObject>, distance: Float, currentTime: Float) -> Float {
    let isMelee: Bool = false;
    let meleeModifier: Float = 1.00;
    let curveModifier: Float = 1.00;
    let distanceModifier: Float = 1.00;
    let minDistance: Float = 2.00;
    let maxDistance: Float = 20.00;
    let timeSinceDamage: Float = puppet.GetLastDamageTimeFrom(threat, isMelee);
    if timeSinceDamage != -1.00 {
      if isMelee {
        meleeModifier = 2.00;
      };
      curveModifier = targetTrackerComponent.GetThreatPriorityModFromDmgCurve(currentTime - timeSinceDamage) * meleeModifier;
      if distance <= minDistance {
        distanceModifier = 1.00;
      } else {
        if distance >= maxDistance {
          distanceModifier = 0.00;
        } else {
          distanceModifier = (distance - minDistance) / (maxDistance - minDistance);
          distanceModifier *= distanceModifier;
          distanceModifier = 1.00 - distanceModifier;
        };
      };
      return distanceModifier * curveModifier;
    };
    return 0.00;
  }

  private final static func GetThreatAttackersModifier(targetTrackerComponent: ref<TargetTrackerComponent>, puppet: ref<ScriptedPuppet>, threat: ref<GameObject>) -> Float {
    let cssi: ref<CombatSquadScriptInterface>;
    let priorityAttackersMod: Float;
    let squadMembersCount: Uint32;
    let enemiesCount: Uint32 = 0u;
    let enemyAttackersCount: Uint32 = 0u;
    AISquadHelper.GetCombatSquadInterface(puppet, cssi);
    if !IsDefined(cssi) {
      return 0.00;
    };
    enemiesCount = cssi.GetEnemyAttackersCount(threat);
    if enemiesCount <= 1u || !cssi.IsEnemy(threat) {
      return 0.00;
    };
    squadMembersCount = cssi.GetMembersCount();
    if squadMembersCount >= enemiesCount {
      priorityAttackersMod = targetTrackerComponent.GetThreatPriorityModFromAttackersCurve(enemyAttackersCount);
      if priorityAttackersMod > 0.00 && AIActionTarget.GetClosestMemberId(cssi, threat.GetWorldPosition()) == puppet.GetEntityID() {
        return priorityAttackersMod;
      };
    };
    return 0.00;
  }

  private final static func GetThreatLastVisibilityModifier(puppet: ref<ScriptedPuppet>, threat: ref<GameObject>) -> Float {
    let sensorComponent: ref<SensorObjectComponent>;
    let threatId: EntityID;
    let minTime: Float = 3.00;
    let maxTime: Float = 7.00;
    let maxVal: Float = 1.00;
    let timeSinceLastVisible: Float = maxTime;
    let senseComponent: ref<SenseComponent> = puppet.GetSensesComponent();
    if IsDefined(senseComponent) {
      threatId = threat.GetEntityID();
      timeSinceLastVisible = senseComponent.GetTimeSinceLastEntityVisible(threatId);
    } else {
      sensorComponent = puppet.GetSensorObjectComponent();
      if IsDefined(sensorComponent) {
        threatId = threat.GetEntityID();
        timeSinceLastVisible = sensorComponent.GetTimeSinceLastEntityVisible(threatId);
      };
    };
    if timeSinceLastVisible > 100000000.00 {
      timeSinceLastVisible = 0.00;
    };
    if timeSinceLastVisible >= maxTime {
      return 0.00;
    };
    if timeSinceLastVisible <= minTime {
      return maxVal;
    };
    return maxVal * (1.00 - (timeSinceLastVisible - minTime) / (maxTime - minTime));
  }

  private final static func GetThreatAccessibilityFromCoverModifier(puppet: ref<ScriptedPuppet>, threat: ref<GameObject>) -> Float {
    let maxVal: Float = 3.00;
    let minUsableMethods: Uint32 = 1u;
    let coverManager: ref<CoverManager> = GameInstance.GetCoverManager(puppet.GetGame());
    let coverID: Uint64 = coverManager.GetCurrentCover(puppet);
    if coverID > 0u {
      if coverManager.GetUsableExposureSpotsNumForCoverTolerance(coverID, threat, 3.00, true) >= minUsableMethods {
        return maxVal;
      };
    };
    return 0.00;
  }

  private final static func IsThreatCloseOrVisibleByPlayer(ownerPos: Vector4, threat: ref<GameObject>) -> Bool {
    let continuousLineOfSight: Float;
    let playerFwd: Vector4;
    let playerPos: Vector4;
    let playerPuppet: ref<PlayerPuppet>;
    let threatFwd: Vector4;
    let threatPos: Vector4;
    let minDistSqr: Float = 324.00;
    let playerDistSqr: Float = 144.00;
    if !IsDefined(threat) {
      return false;
    };
    playerPuppet = GameInstance.GetPlayerSystem(threat.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    if IsDefined(playerPuppet) {
      playerPos = playerPuppet.GetWorldPosition();
      playerFwd = playerPuppet.GetWorldForward();
      threatPos = threat.GetWorldPosition();
      threatFwd = Vector4.Normalize(threatPos - playerPos);
      if Vector4.Dot(playerFwd, threatFwd) > 0.00 && threat.GetSourceShootComponent().GetContinuousLineOfSightToTarget(playerPuppet, continuousLineOfSight) {
        return true;
      };
      if Vector4.DistanceSquared(ownerPos, playerPos) > playerDistSqr {
        return false;
      };
    };
    return Vector4.DistanceSquared(ownerPos, threatPos) < minDistSqr;
  }

  private final static func GetClosestMemberId(smi: ref<SquadScriptInterface>, pos: Vector4) -> EntityID {
    let closestId: EntityID;
    let dist: Float;
    let i: Int32;
    let members: array<wref<Entity>> = smi.ListMembersWeak();
    let minDist: Float = 100000000.00;
    if IsDefined(smi) {
      i = 0;
      while i < ArraySize(members) {
        dist = Vector4.DistanceSquared(pos, members[i].GetWorldPosition());
        if dist < minDist {
          minDist = dist;
          closestId = members[i].GetEntityID();
        };
        i += 1;
      };
    };
    return closestId;
  }
}
