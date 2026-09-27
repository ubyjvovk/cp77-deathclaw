
public class PlayerStatsListener extends ScriptStatsListener {

  public let m_owner: wref<GameObject>;

  public func OnStatChanged(ownerID: StatsObjectID, statType: gamedataStatType, diff: Float, total: Float) -> Void {
    this.m_owner.SetScannerDirty(true);
  }
}

public class NPCGodModeListener extends ScriptStatsListener {

  public let m_owner: wref<NPCPuppet>;

  public func OnGodModeChanged(ownerID: EntityID, newType: gameGodModeType) -> Void {
    this.m_owner.OnGodModeChanged();
  }
}

public class NPCDeathListener extends ScriptStatPoolsListener {

  public let npc: wref<NPCPuppet>;

  protected cb func OnStatPoolAdded() -> Bool {
    if this.npc.IsDefeatMechanicActive() {
      GameInstance.GetStatPoolsSystem(this.npc.GetGame()).RequestSettingStatPoolValueCustomLimit(Cast<StatsObjectID>(this.npc.GetEntityID()), gamedataStatPoolType.Health, 0.10, null);
    } else {
      GameInstance.GetStatPoolsSystem(this.npc.GetGame()).RequestSettingStatPoolValueCustomLimit(Cast<StatsObjectID>(this.npc.GetEntityID()), gamedataStatPoolType.Health, 0.00, null);
    };
  }

  protected cb func OnStatPoolCustomLimitReached(value: Float) -> Bool {
    if StatusEffectSystem.ObjectHasStatusEffect(this.npc, t"BaseStatusEffect.ForceKill") || StatusEffectSystem.ObjectHasStatusEffect(this.npc, t"WorkspotStatus.Death") {
      this.npc.MarkForDeath();
    } else {
      this.npc.MarkForDefeat();
    };
    this.SendPotentialDeathEvent();
    this.npc.m_wasJustKilledOrDefeated = true;
  }

  protected cb func OnStatPoolMinValueReached(value: Float) -> Bool {
    this.npc.m_wasJustKilledOrDefeated = true;
    if Equals(this.npc.GetNPCType(), gamedataNPCType.Drone) {
      this.npc.MarkForDeath();
      this.SendPotentialDeathEvent();
    };
  }

  protected final func SendPotentialDeathEvent() -> Void {
    let potentialDeathEvt: ref<gamePotentialDeathEvent> = new gamePotentialDeathEvent();
    potentialDeathEvt.instigator = this.npc.GetLastHitInstigator();
    this.npc.QueueEvent(potentialDeathEvt);
  }
}

public class NPCPoiseListener extends ScriptStatPoolsListener {

  public let npc: wref<NPCPuppet>;

  protected cb func OnStatPoolMinValueReached(value: Float) -> Bool {
    let playerPuppet: ref<ScriptedPuppet> = GameInstance.GetPlayerSystem(this.npc.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
    if IsDefined(playerPuppet) {
      if playerPuppet.HasFinisherAvailable() {
        StatusEffectHelper.ApplyStatusEffect(this.npc, t"BaseStatusEffect.FinisherActiveStatusEffect");
        if !this.npc.IsFinisherSoundPlayed() {
          GameObject.PlaySound(playerPuppet, n"w_melee_perk_finisher_ready");
          this.npc.SetFinisherSoundPlayed(true);
        };
      };
    };
  }
}

public class NPCPuppet extends ScriptedPuppet {

  private let m_lastHitEvent: ref<gameHitEvent>;

  private let m_totalFrameReactionDamageReceived: Float;

  private let m_totalFrameWoundsDamageReceived: Float;

  private let m_totalFrameDismembermentDamageReceived: Float;

  private let m_hitEventLock: RWLock;

  private let m_NPCManager: ref<NPCManager>;

  private let m_customDeathDirection: Int32;

  private let m_deathOverrideState: Bool;

  private let m_agonyState: Bool;

  private let m_defensiveState: Bool;

  private let m_lastSetupWorkspotActionEvent: ref<SetupWorkspotActionEvent>;

  public let m_wasJustKilledOrDefeated: Bool;

  private let m_shouldDie: Bool;

  private let m_shouldBeDefeated: Bool;

  private let m_sentDownedEvent: Bool;

  private let m_isRagdolling: Bool;

  private let m_hasAnimatedRagdoll: Bool;

  private let m_disableCollisionRequested: Bool;

  private let m_ragdollInstigator: wref<GameObject>;

  private let m_ragdollSplattersSpawned: Int32;

  private let m_ragdollFloorSplashSpawned: Bool;

  private let m_ragdollDamageData: RagdollDamagePollData;

  private let m_ragdollInitialPosition: Vector4;

  private let m_ragdollActivationTimestamp: Float;

  private let m_ragdollImpactedNPCs: [wref<NPCPuppet>];

  private let m_disableRagdollAfterRecovery: Bool;

  private let m_thrownNPCNearbyCrowdNPCs: [wref<Entity>];

  private let m_isNotVisible: Bool;

  private let m_deathListener: ref<NPCDeathListener>;

  private let m_poiseListener: ref<NPCPoiseListener>;

  private let m_godModeStatListener: ref<NPCGodModeListener>;

  private let m_VehicleHitImmunityCallbackID: Uint32;

  private let m_npcCollisionComponent: ref<SimpleColliderComponent>;

  private let m_npcRagdollComponent: ref<IComponent>;

  private let m_npcTraceObstacleComponent: ref<SimpleColliderComponent>;

  private let m_npcMountedToPlayerComponents: [ref<IComponent>];

  private let m_scavengeComponent: ref<ScavengeComponent>;

  private let m_influenceComponent: ref<InfluenceComponent>;

  private let m_comfortZoneComponent: ref<IComponent>;

  public let m_isTargetingPlayer: Bool;

  public let m_shouldBeImmuneToVehicleHit: Bool;

  private let m_playerStatsListener: ref<ScriptStatsListener>;

  private let m_upperBodyStateCallbackID: ref<CallbackHandle>;

  private let m_leftCyberwareStateCallbackID: ref<CallbackHandle>;

  private let m_meleeStateCallbackID: ref<CallbackHandle>;

  private let m_combatGadgetStateCallbackID: ref<CallbackHandle>;

  private let m_wasAimedAtLast: Bool;

  private let m_wasCWChargedAtLast: Bool;

  private let m_wasMeleeChargedAtLast: Bool;

  private let m_wasChargingGadgetAtLast: Bool;

  private let m_isLookedAt: Bool;

  private let m_cachedPlayerID: EntityID;

  private let m_wasAggressiveCrowd: Bool;

  private let m_canGoThroughDoors: Bool;

  private let m_lastStatusEffectSignalSent: wref<StatusEffect_Record>;

  private let m_cachedStatusEffectAnim: wref<StatusEffect_Record>;

  private let m_resendStatusEffectSignalDelayID: DelayID;

  private let m_lastSEAppliedByPlayer: ref<StatusEffect>;

  private let m_pendingSEEvent: ref<ApplyStatusEffectEvent>;

  private let m_pendingDueToCachedSEAnim: Bool;

  private let m_bounty: Bounty;

  private let m_cachedVFXList: [wref<StatusEffectFX_Record>];

  private let m_cachedSFXList: [wref<StatusEffectFX_Record>];

  private let m_isThrowingGrenadeToPlayer: Bool;

  private let m_throwingGrenadeDelayEventID: DelayID;

  private let m_myKiller: wref<GameObject>;

  private let m_primaryThreatCalculationType: EAIThreatCalculationType;

  private let m_temporaryThreatCalculationType: EAIThreatCalculationType;

  private let m_isPlayerCompanionCached: Bool;

  private let m_isPlayerCompanionCachedTimeStamp: Float;

  private let m_quickHackEffectsApplied: Uint32;

  private let m_hackingResistanceMod: ref<gameConstantStatModifierData>;

  private let m_delayNonStealthQuickHackVictimEventID: DelayID;

  private let m_cachedIsPaperdoll: Int32;

  private let smartDespawnDelayID: DelayID;

  private let despawnTicks: Uint32;

  public const func IsNPC() -> Bool {
    return true;
  }

  public final const func IsReplicable() -> Bool {
    return true;
  }

  public final const func GetReplicatedStateClass() -> CName {
    return n"gameNpcPuppetReplicatedState";
  }

  protected final func PrepareVendor() -> Void {
    GameInstance.GetDelaySystem(this.GetGame()).QueueTask(this, null, n"PrepareVendorTask", gameScriptTaskExecutionStage.Any);
  }

  protected final func PrepareVendorTask(data: ref<ScriptTaskData>) -> Void {
    let request: ref<AttachVendorRequest>;
    let vendorID: TweakDBID;
    let record: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(this.GetRecordID());
    if IsDefined(record) && IsDefined(record.VendorID()) {
      vendorID = record.VendorID().GetID();
    };
    if TDBID.IsValid(vendorID) {
      request = new AttachVendorRequest();
      request.owner = this;
      request.vendorID = vendorID;
      MarketSystem.GetInstance(this.GetGame()).QueueRequest(request);
    };
  }

  protected final func RemoveVendor() -> Void {
    GameInstance.GetDelaySystem(this.GetGame()).QueueTask(this, null, n"RemoveVendorTask", gameScriptTaskExecutionStage.Any);
  }

  protected final func RemoveVendorTask() -> Void {
    let request: ref<DeattachVendorRequest>;
    let vendorID: TweakDBID;
    let record: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(this.GetRecordID());
    if IsDefined(record) && IsDefined(record.VendorID()) {
      vendorID = record.VendorID().GetID();
    };
    if TDBID.IsValid(vendorID) {
      request = new DeattachVendorRequest();
      request.owner = this;
      request.vendorID = vendorID;
      MarketSystem.GetInstance(this.GetGame()).QueueRequest(request);
    };
  }

  protected final func InitializeNPCManager() -> Void {
    this.m_NPCManager = new NPCManager();
    this.m_NPCManager.Init(this);
  }

  public const func IsPaperdoll() -> Bool {
    return this.m_cachedIsPaperdoll > 0;
  }

  public const func IsPuppetInCombat() -> Bool {
    return NPCPuppet.IsInCombat(this);
  }

  public final func ResetCompanionRoleCacheTimeStamp() -> Void {
    this.m_isPlayerCompanionCachedTimeStamp = 0.00;
  }

  protected cb func OnPlayerCompanionCacheData(evt: ref<PlayerCompanionCacheDataEvent>) -> Bool {
    this.m_isPlayerCompanionCached = evt.m_isPlayerCompanionCached;
    this.m_isPlayerCompanionCachedTimeStamp = evt.m_isPlayerCompanionCachedTimeStamp;
  }

  private final const func GetPlayerID() -> EntityID {
    if EntityID.IsDefined(this.m_cachedPlayerID) {
      return this.m_cachedPlayerID;
    };
    return GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject().GetEntityID();
  }

  public const func IsPlayerCompanion() -> Bool {
    let evt: ref<PlayerCompanionCacheDataEvent>;
    let isPlayerCompanionCached: Bool;
    let currTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
    if this.m_isPlayerCompanionCachedTimeStamp == 0.00 || currTime - this.m_isPlayerCompanionCachedTimeStamp > 10.00 {
      evt = new PlayerCompanionCacheDataEvent();
      isPlayerCompanionCached = super.IsPlayerCompanion();
      evt.m_isPlayerCompanionCached = isPlayerCompanionCached;
      evt.m_isPlayerCompanionCachedTimeStamp = currTime;
      GameInstance.GetPersistencySystem(this.GetGame()).QueueEntityEvent(this.GetEntityID(), evt);
    } else {
      isPlayerCompanionCached = this.m_isPlayerCompanionCached;
    };
    return isPlayerCompanionCached;
  }

  protected cb func OnRequestComponents(ri: EntityRequestComponentsInterface) -> Bool {
    super.OnRequestComponents(ri);
    EntityRequestComponentsInterface.RequestComponent(ri, n"scanning", n"gameScanningComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"npcCollision", n"SimpleColliderComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"npcTraceObstacle", n"SimpleColliderComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"ethnicity", n"EthnicityComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"VisibleObject", n"VisibleObjectComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"ScavengeComponent", n"ScavengeComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"HitPhysicalQueryMesh", n"entColliderComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"HitRepresentation", n"gameHitRepresentationComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"VisualOffset", n"visualOffsetTransformComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"RagdollComponent", n"entRagdollComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"InfluenceComponent", n"gameinfluenceComponent", false);
    EntityRequestComponentsInterface.RequestComponent(ri, n"ComfortZone", n"entTriggerComponent", false);
  }

  protected cb func OnTakeControl(ri: EntityResolveComponentsInterface) -> Bool {
    super.OnTakeControl(ri);
    this.m_npcCollisionComponent = EntityResolveComponentsInterface.GetComponent(ri, n"npcCollision") as SimpleColliderComponent;
    this.m_npcTraceObstacleComponent = EntityResolveComponentsInterface.GetComponent(ri, n"npcTraceObstacle") as SimpleColliderComponent;
    this.m_visibleObjectComponent = EntityResolveComponentsInterface.GetComponent(ri, n"VisibleObject") as VisibleObjectComponent;
    this.m_scavengeComponent = EntityResolveComponentsInterface.GetComponent(ri, n"ScavengeComponent") as ScavengeComponent;
    ArrayPush(this.m_npcMountedToPlayerComponents, EntityResolveComponentsInterface.GetComponent(ri, n"HitPhysicalQueryMesh"));
    ArrayPush(this.m_npcMountedToPlayerComponents, EntityResolveComponentsInterface.GetComponent(ri, n"HitRepresentation"));
    ArrayPush(this.m_npcMountedToPlayerComponents, EntityResolveComponentsInterface.GetComponent(ri, n"VisualOffset"));
    this.m_npcRagdollComponent = EntityResolveComponentsInterface.GetComponent(ri, n"RagdollComponent");
    this.m_influenceComponent = EntityResolveComponentsInterface.GetComponent(ri, n"InfluenceComponent") as InfluenceComponent;
    this.m_comfortZoneComponent = EntityResolveComponentsInterface.GetComponent(ri, n"ComfortZone");
  }

  protected cb func OnPostInitialize(evt: ref<entPostInitializeEvent>) -> Bool {
    super.OnPostInitialize(evt);
    if IsDefined(this.m_comfortZoneComponent) {
      this.m_comfortZoneComponent.Toggle(false);
    };
    if IsDefined(this.m_visibleObjectComponent) {
      this.m_visibleObjectComponent.Toggle(false);
    };
    this.InitializeNPCManager();
  }

  protected cb func OnPreUninitialize(evt: ref<entPreUninitializeEvent>) -> Bool {
    super.OnPreUninitialize(evt);
    if IsDefined(this.m_NPCManager) {
      this.m_NPCManager.UnInit(this);
    };
  }

  protected cb func OnGameAttached() -> Bool {
    let hasCrowdLOD: Bool;
    let isCrowd: Bool;
    let setScannerTime: ref<SetScanningTimeEvent>;
    super.OnGameAttached();
    this.m_NPCManager.ApplySpawnAnimWrappers();
    isCrowd = this.IsCrowd();
    hasCrowdLOD = this.HasCrowdStaticLOD();
    if hasCrowdLOD {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"crowd", 1.00);
    };
    this.SetAnimWrapperWeightBasedOnFaction();
    this.SetRandomAnimWrappersForLocomotion();
    AnimationControllerComponent.ApplyFeature(this, n"ProceduralLean", new AnimFeature_ProceduralLean());
    this.InitThreatsCurves();
    if !isCrowd {
      setScannerTime = new SetScanningTimeEvent();
      setScannerTime.time = 0.50;
      this.QueueEvent(setScannerTime);
      this.PrepareVendor();
    } else {
      this.m_VehicleHitImmunityCallbackID = GameInstance.GetQuestsSystem(this.GetGame()).RegisterEntity(n"q301_WayToCrashsite_CarHitImmunity", this.GetEntityID());
    };
    if !IsDefined(this.m_deathListener) {
      this.m_deathListener = new NPCDeathListener();
      this.m_deathListener.npc = this;
      GameInstance.GetStatPoolsSystem(this.GetGame()).RequestRegisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, this.m_deathListener);
    };
    if !IsDefined(this.m_poiseListener) {
      this.m_poiseListener = new NPCPoiseListener();
      this.m_poiseListener.npc = this;
      GameInstance.GetStatPoolsSystem(this.GetGame()).RequestRegisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Poise, this.m_poiseListener);
    };
    this.SetSenseObjectType(gamedataSenseObjectType.Npc);
    if this.GetPS().GetWasIncapacitated() {
      if !isCrowd {
        this.GenerateLoot();
        this.EvaluateLootQualityByTask();
        this.SetBountyAwarded(true);
      };
      this.SetIsDefeatMechanicActive(false, true);
    } else {
      this.SetIsDefeatMechanicActive(Equals(this.GetNPCType(), gamedataNPCType.Human), true);
    };
    if this.m_cachedIsPaperdoll == 0 {
      if NPCManager.HasTag(this.GetRecordID(), n"TPP_Player") {
        this.m_cachedIsPaperdoll = 1;
      } else {
        this.m_cachedIsPaperdoll = -1;
      };
    };
  }

  protected cb func OnDetach() -> Bool {
    let playerPuppet: wref<ScriptedPuppet>;
    super.OnDetach();
    if !this.IsCrowd() {
      StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.Grappled");
      if this.IsBoss() || Equals(this.GetNPCRarity(), gamedataNPCRarity.MaxTac) {
        playerPuppet = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
        if IsDefined(playerPuppet) {
          BossHealthBarGameController.ReevaluateBossHealthBar(this, playerPuppet, true);
        };
      };
    } else {
      GameInstance.GetQuestsSystem(this.GetGame()).UnregisterEntity(n"q301_WayToCrashsite_CarHitImmunity", this.m_VehicleHitImmunityCallbackID);
    };
    if IsDefined(this.m_deathListener) {
      GameInstance.GetStatPoolsSystem(this.GetGame()).RequestUnregisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, this.m_deathListener);
      this.m_deathListener = null;
    };
    if IsDefined(this.m_poiseListener) {
      GameInstance.GetStatPoolsSystem(this.GetGame()).RequestUnregisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Poise, this.m_poiseListener);
      this.m_poiseListener = null;
    };
    if EntityID.IsDefined(this.m_cachedPlayerID) {
      this.UnregisterCallbacksForReactions();
      this.m_cachedPlayerID = new EntityID();
    };
    this.RemoveVendorTask();
  }

  protected cb func OnPreloadAnimationsEvent(evt: ref<PreloadAnimationsEvent>) -> Bool {
    AIActionHelper.PreloadAnimations(this, evt.m_streamingContextName, evt.m_highPriority);
  }

  protected cb func OnDeviceLinkRequest(evt: ref<DeviceLinkRequest>) -> Bool {
    let link: ref<PuppetDeviceLinkPS>;
    if this.IsCrowd() && !this.IsCharacterPolice() || this.IsCharacterCivilian() {
      return false;
    };
    link = PuppetDeviceLinkPS.CreateAndAcquirePuppetDeviceLinkPS(this.GetGame(), this.GetEntityID());
    if IsDefined(link) {
      GameInstance.GetPersistencySystem(this.GetGame()).QueuePSEvent(link.GetID(), link.GetClassName(), evt);
    };
  }

  protected func CreateListeners() -> Void {
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(GetGameInstance());
    let puppetID: EntityID = this.GetEntityID();
    if !IsDefined(this.m_godModeStatListener) {
      this.m_godModeStatListener = new NPCGodModeListener();
      this.m_godModeStatListener.m_owner = this;
      statSys.RegisterListener(Cast<StatsObjectID>(puppetID), this.m_godModeStatListener);
    };
    super.CreateListeners();
  }

  protected func RemoveListeners() -> Void {
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(GetGameInstance());
    let puppetID: EntityID = this.GetEntityID();
    if IsDefined(this.m_godModeStatListener) {
      statSys.UnregisterListener(Cast<StatsObjectID>(puppetID), this.m_godModeStatListener);
      this.m_godModeStatListener = null;
    };
    super.RemoveListeners();
  }

  protected cb func OnDeviceLinkEstablished(evt: ref<DeviceLinkEstablished>) -> Bool {
    GameInstance.GetPersistencySystem(this.GetGame()).QueuePSEvent(this.GetPS().GetID(), this.GetPS().GetClassName(), evt);
  }

  protected const func GetPS() -> ref<ScriptedPuppetPS> {
    return this.GetBasePS() as ScriptedPuppetPS;
  }

  protected cb func OnFactChangedEvent(evt: ref<FactChangedEvent>) -> Bool {
    if Equals(evt.GetFactName(), n"q301_WayToCrashsite_CarHitImmunity") {
      this.UpdateVehicleHitImmunity();
    };
  }

  private final func UpdateVehicleHitImmunity() -> Void {
    this.m_shouldBeImmuneToVehicleHit = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"q301_WayToCrashsite_CarHitImmunity") == 1 ? true : false;
  }

  public final const func GetBounty() -> Bounty {
    return this.m_bounty;
  }

  public final func SetBountyAwarded(awarded: Bool) -> Void {
    let evt: ref<SetBountyAwardedEvent> = new SetBountyAwardedEvent();
    evt.awarded = awarded;
    this.QueueEvent(evt);
  }

  protected cb func OnSetBountyAwardedEvent(evt: ref<SetBountyAwardedEvent>) -> Bool {
    this.m_bounty.m_awarded = evt.awarded;
  }

  public final static func SetBountyObject(target: ref<GameObject>, const bounty: script_ref<Bounty>) -> Void {
    let evt: ref<SetBountyObjectEvent>;
    if IsDefined(target) {
      evt = new SetBountyObjectEvent();
      evt.bounty = Deref(bounty);
      target.QueueEvent(evt);
    };
  }

  protected cb func OnSetBountyObjectEvent(evt: ref<SetBountyObjectEvent>) -> Bool {
    this.SetBounty(evt.bounty);
  }

  protected final func SetBounty(const bounty: script_ref<Bounty>) -> Void {
    this.m_bounty = Deref(bounty);
    this.GetPS().StoreBountyData(this.m_bounty.m_bountID, this.m_bounty.m_transgressions);
  }

  protected cb func OnSetBounty(evt: ref<SetBountyEvent>) -> Bool {
    BountyManager.SetBountyFromID(evt.bountyID, this);
  }

  public final static func SetNPCDisposedFact(npcBody: wref<NPCPuppet>) -> Void {
    let factName: CName;
    if !IsDefined(npcBody) {
      return;
    };
    factName = TweakDBInterface.GetCName(npcBody.GetRecordID() + t".BodyDisposalFact", n"someNpcDisposed");
    SetFactValue(npcBody.GetGame(), factName, 1);
  }

  protected cb func OnSecuritySystemAgentTrackingPlayer(evt: ref<SecuritySystemSupport>) -> Bool {
    let ttc: ref<TargetTrackerComponent>;
    let playerPuppet: wref<ScriptedPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
    if !IsDefined(playerPuppet) {
      return false;
    };
    ttc = this.GetTargetTrackerComponent();
    if !IsDefined(ttc) {
      return false;
    };
    if evt.supportGranted {
      if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"Blind") && !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"CommsNoiseJam") {
        this.SwitchTargetPlayerTrackedAccuracy(true);
      };
    } else {
      this.SwitchTargetPlayerTrackedAccuracy(false);
    };
  }

  protected final func SwitchTargetPlayerTrackedAccuracy(freeze: Bool) -> Bool {
    let threatPersistenceSource: ref<AIThreatPersistenceSource_Record>;
    let ttc: ref<TargetTrackerComponent>;
    let playerPuppet: wref<ScriptedPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
    if !IsDefined(playerPuppet) {
      return false;
    };
    ttc = this.GetTargetTrackerComponent();
    if !IsDefined(ttc) {
      return false;
    };
    threatPersistenceSource = TweakDBInterface.GetAIThreatPersistenceSourceRecord(t"AIThreatPersistenceSource.TrackedBySecuritySystemAgent");
    if freeze {
      ttc.SetThreatBeliefAccuracy(playerPuppet, 1.00);
      ttc.RequestThreatBeliefAccuracyMinValue(playerPuppet, n"TrackedBySecuritySystemAgent", 1.00);
      TargetTrackingExtension.SetThreatPersistence(playerPuppet, this, true, Cast<Uint32>(threatPersistenceSource.EnumValue()));
    } else {
      ttc.RemoveThreatBeliefAccuracyMinValue(playerPuppet, n"TrackedBySecuritySystemAgent");
      TargetTrackingExtension.SetThreatPersistence(playerPuppet, this, false, Cast<Uint32>(threatPersistenceSource.EnumValue()));
    };
    return true;
  }

  protected final func SwitchTargetPlayerTrackedAccuracy(ttc: ref<TargetTrackerComponent>, freeze: Bool) -> Bool {
    let playerPuppet: wref<ScriptedPuppet>;
    let threatPersistenceSource: ref<AIThreatPersistenceSource_Record>;
    if !IsDefined(ttc) {
      return false;
    };
    playerPuppet = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
    if !IsDefined(playerPuppet) {
      return false;
    };
    threatPersistenceSource = TweakDBInterface.GetAIThreatPersistenceSourceRecord(t"AIThreatPersistenceSource.TrackedBySecuritySystemAgent");
    if freeze {
      ttc.SetThreatBeliefAccuracy(playerPuppet, 1.00);
      ttc.RequestThreatBeliefAccuracyMinValue(playerPuppet, n"TrackedBySecuritySystemAgent", 1.00);
      TargetTrackingExtension.SetThreatPersistence(playerPuppet, this, true, Cast<Uint32>(threatPersistenceSource.EnumValue()));
    } else {
      ttc.RemoveThreatBeliefAccuracyMinValue(playerPuppet, n"TrackedBySecuritySystemAgent");
      TargetTrackingExtension.SetThreatPersistence(playerPuppet, this, false, Cast<Uint32>(threatPersistenceSource.EnumValue()));
    };
    return true;
  }

  protected cb func OnPlayerDetectionChangedEvent(evt: ref<PlayerDetectionChangedEvent>) -> Bool {
    this.SetDetectionPercentage(evt.newDetectionValue);
  }

  public final func SetDetectionPercentage(percent: Float) -> Void {
    let bb: ref<IBlackboard> = this.GetPuppetStateBlackboard();
    bb.SetFloat(GetAllBlackboardDefs().PuppetState.DetectionPercentage, percent);
  }

  public final func GetDetectionPercentage() -> Float {
    let bb: ref<IBlackboard> = this.GetPuppetStateBlackboard();
    return bb.GetFloat(GetAllBlackboardDefs().PuppetState.DetectionPercentage);
  }

  private final func InitThreatsCurves() -> Void {
    let targetTrackerComponent: ref<TargetTrackerComponent> = this.GetTargetTrackerComponent();
    if IsDefined(targetTrackerComponent) {
      targetTrackerComponent.SetThreatPriorityDistCurve(n"ThreatValueDistModifier");
      targetTrackerComponent.SetThreatPriorityDmgCurve(n"ThreatValueDmgModifier");
      targetTrackerComponent.SetThreatPriorityHisteresisCurve(n"ThreatValueHisteresisModifier");
      targetTrackerComponent.SetThreatPriorityAttackersCurve(n"ThreatValueAttackersModifier");
    };
  }

  public func Kill(opt instigator: wref<GameObject>, opt skipNPCDeathAnim: Bool, opt disableNPCRagdoll: Bool) -> Void {
    if GameInstance.GetStatsSystem(this.GetOwner().GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetOwner().GetEntityID()), gamedataStatType.IsInvulnerable) > 0.00 {
      return;
    };
    this.MarkForDeath();
    this.SetIsDefeatMechanicActive(false);
    if skipNPCDeathAnim {
      this.SetSkipDeathAnimation(true);
    };
    if disableNPCRagdoll {
      this.SetDisableRagdoll(true);
    };
    super.Kill(instigator, skipNPCDeathAnim, disableNPCRagdoll);
  }

  public const func IsDead() -> Bool {
    return GameInstance.GetStatPoolsSystem(this.GetGame()).HasStatPoolValueReachedMin(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health);
  }

  public final func MarkForDeath() -> Void {
    this.m_shouldDie = true;
  }

  public final const func IsAboutToDie() -> Bool {
    return this.m_shouldDie;
  }

  public final func MarkForDefeat() -> Void {
    this.m_shouldBeDefeated = true;
  }

  public final const func IsAboutToBeDefeated() -> Bool {
    return this.m_shouldBeDefeated;
  }

  public final const func IsAboutToDieOrDefeated() -> Bool {
    return this.m_shouldBeDefeated || this.m_shouldDie;
  }

  public final const func IsDefeatMechanicActive() -> Bool {
    if TweakDBInterface.GetCharacterRecord(this.GetRecordID()).DisableDefeatedState() {
      return false;
    };
    return this.GetPS().IsDefeatMechanicActive();
  }

  public final func SetIsDefeatMechanicActive(isDefeatMechanicActive: Bool, opt isInitialisation: Bool) -> Void {
    this.GetPS().SetIsDefeatMechanicActive(isDefeatMechanicActive);
    if !isInitialisation {
      if isDefeatMechanicActive {
        GameInstance.GetStatPoolsSystem(this.GetGame()).RequestSettingStatPoolValueCustomLimit(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, 0.10, null);
      } else {
        GameInstance.GetStatPoolsSystem(this.GetGame()).RequestSettingStatPoolValueCustomLimit(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, 0.00, null);
      };
    };
  }

  public final func GetAffiliation() -> String {
    let affiliation: wref<Affiliation_Record> = TweakDBInterface.GetCharacterRecord(this.GetRecordID()).Affiliation();
    if !IsDefined(affiliation) {
      return "Unknown";
    };
    return ToString(affiliation.EnumName());
  }

  public final func OnGodModeChanged() -> Void {
    if this.CanEnableRagdollComponent() {
      if IsDefined(this.m_npcRagdollComponent) {
        this.m_npcRagdollComponent.Toggle(true);
      };
    } else {
      if IsDefined(this.m_npcRagdollComponent) {
        this.m_npcRagdollComponent.Toggle(false);
      };
    };
  }

  public final const func CanEnableRagdollComponent(opt fromSetDeathParams: Bool) -> Bool {
    if GameInstance.GetGodModeSystem(this.GetGame()).HasGodMode(this.GetEntityID(), gameGodModeType.Invulnerable) {
      return false;
    };
    if GameInstance.GetGodModeSystem(this.GetGame()).HasGodMode(this.GetEntityID(), gameGodModeType.Immortal) {
      return false;
    };
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"DisableRagdoll") {
      return false;
    };
    if (this.IsBoss() || Equals(this.GetNPCRarity(), gamedataNPCRarity.MaxTac)) && !this.GetPS().GetWasIncapacitated() {
      return false;
    };
    return true;
  }

  protected cb func OnDisableRagdollComponentEvent(evt: ref<DisableRagdollComponentEvent>) -> Bool {
    if IsDefined(this.m_npcRagdollComponent) {
      this.m_npcRagdollComponent.Toggle(false);
    };
  }

  public final func SetDisableRagdoll(disableRagdoll: Bool, opt force: Bool, opt leaveRagdollEnabled: Bool) -> Void {
    if IsDefined(this.m_npcRagdollComponent) {
      if disableRagdoll {
        this.m_npcRagdollComponent.Toggle(false);
      } else {
        if force {
          if !leaveRagdollEnabled && !this.m_npcRagdollComponent.IsEnabled() {
            this.m_disableRagdollAfterRecovery = true;
          };
          this.m_npcRagdollComponent.Toggle(true);
        } else {
          if this.CanEnableRagdollComponent(true) {
            this.m_npcRagdollComponent.Toggle(true);
          };
        };
      };
    };
  }

  public final static func SendNPCHitDataTrackingRequest(owner: ref<NPCPuppet>, telemetryData: ENPCTelemetryData, modifyValue: Int32) -> Void {
    let request: ref<ModifyNPCTelemetryVariable> = new ModifyNPCTelemetryVariable();
    request.dataTrackingFact = telemetryData;
    request.value = modifyValue;
    GameInstance.GetScriptableSystemsContainer(owner.GetGame()).Get(n"DataTrackingSystem").QueueRequest(request);
  }

  public final const func CheckStubData(data: NPCstubData) -> Bool {
    let entityStubPSID: PersistentID = CreatePersistentID(this.GetEntityID(), gameEntityStubComponentPS.GetPSComponentName());
    let entityStubPS: ref<gameEntityStubComponentPS> = GameInstance.GetPersistencySystem(this.GetGame()).GetConstAccessToPSObject(entityStubPSID, n"gameEntityStubComponentPS") as gameEntityStubComponentPS;
    let spawnerID: EntityID = entityStubPS.GetSpawnerID();
    let entryID: CName = entityStubPS.GetOwnerCommunityEntryName();
    if spawnerID == data.spawnerID && Equals(entryID, data.entryID) {
      return true;
    };
    return false;
  }

  protected cb func OnItemAddedToSlot(evt: ref<ItemAddedToSlot>) -> Bool {
    let equippedItemType: gamedataItemType;
    let itemRecord: ref<Item_Record>;
    let weaponRecord: ref<WeaponItem_Record>;
    let hasTechWeapon: Bool = false;
    super.OnItemAddedToSlot(evt);
    NPCPuppet.SetAnimWrapperBasedOnEquippedItem(this, evt.GetSlotID(), evt.GetItemID(), 1.00);
    this.SetAnimWrappersOnItem(GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlotByItemID(this, evt.GetItemID()));
    this.SetWeaponFx();
    AIActionHelper.QueuePreloadCoreAnimationsEvent(this);
    AIActionHelper.QueuePreloadBaseAnimationsEvent(this);
    itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(evt.GetItemID()));
    equippedItemType = itemRecord.ItemType().Type();
    if Equals(equippedItemType, gamedataItemType.Cyb_StrongArms) {
      this.SpawnStrongArmsFX();
    };
    if !IsFinal() {
    };
    if WeaponObject.IsRanged(evt.GetItemID()) {
      weaponRecord = itemRecord as WeaponItem_Record;
      if IsDefined(weaponRecord) && IsDefined(weaponRecord.Evolution()) && Equals(weaponRecord.Evolution().Type(), gamedataWeaponEvolution.Tech) {
        hasTechWeapon = true;
      };
    };
    if IsDefined(this.GetSensorObjectComponent()) {
      this.GetSensorObjectComponent().SetHasPierceableWapon(hasTechWeapon);
    };
    if IsDefined(this.GetSensesComponent()) {
      this.GetSensesComponent().SetHasPierceableWapon(hasTechWeapon);
    };
    AIComponent.InvokeBehaviorCallback(this, n"OnItemAddedToSlotConditionEvaluation");
  }

  protected cb func OnItemVisualsAddedToSlot(evt: ref<ItemVisualsAddedToSlot>) -> Bool {
    let itemRecord: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(evt.GetItemID()));
    let equippedItemType: gamedataItemType = itemRecord.ItemType().Type();
    if Equals(equippedItemType, gamedataItemType.Gad_Grenade) {
      BaseGrenade.SendGrenadeAnimFeatureChangeEvent(this, evt.GetItemID());
    };
  }

  private final func SetWeaponFx() -> Void {
    let evt: ref<UpdateMeleeTrailEffectEvent> = new UpdateMeleeTrailEffectEvent();
    evt.instigator = this;
    let item: ref<ItemObject> = GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponRight");
    if IsDefined(item) {
      item.QueueEvent(evt);
    };
    item = GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponLeft");
    if IsDefined(item) {
      item.QueueEvent(evt);
    };
  }

  private final func SpawnStrongArmsFX() -> Void {
    let cachedThreshold: Float;
    let damageType: gamedataDamageType;
    let statSystem: ref<StatsSystem>;
    let weaponID: StatsObjectID;
    let weapon: wref<WeaponObject> = ScriptedPuppet.GetWeaponRight(this);
    if !IsDefined(weapon) {
      return;
    };
    statSystem = GameInstance.GetStatsSystem(weapon.GetGame());
    weaponID = Cast<StatsObjectID>(weapon.GetEntityID());
    cachedThreshold = statSystem.GetStatValue(weaponID, gamedataStatType.PhysicalDamage);
    damageType = gamedataDamageType.Physical;
    if statSystem.GetStatValue(weaponID, gamedataStatType.ThermalDamage) > cachedThreshold {
      cachedThreshold = statSystem.GetStatValue(weaponID, gamedataStatType.ThermalDamage);
      damageType = gamedataDamageType.Thermal;
    };
    if statSystem.GetStatValue(weaponID, gamedataStatType.ElectricDamage) > cachedThreshold {
      cachedThreshold = statSystem.GetStatValue(weaponID, gamedataStatType.ElectricDamage);
      damageType = gamedataDamageType.Electric;
    };
    if statSystem.GetStatValue(weaponID, gamedataStatType.ChemicalDamage) > cachedThreshold {
      cachedThreshold = statSystem.GetStatValue(weaponID, gamedataStatType.ChemicalDamage);
      damageType = gamedataDamageType.Chemical;
    };
    if Equals(damageType, gamedataDamageType.Thermal) {
      StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.StrongArmsThermalActive", this.GetEntityID());
    } else {
      if Equals(damageType, gamedataDamageType.Chemical) {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.StrongArmsChemicalActive", this.GetEntityID());
      } else {
        if Equals(damageType, gamedataDamageType.Electric) {
          StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.StrongArmsElecricActive", this.GetEntityID());
        };
      };
    };
  }

  private final func RemoveStrongArmsFX() -> Void {
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.StrongArmsThermalActive");
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.StrongArmsChemicalActive");
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.StrongArmsElecricActive");
  }

  protected cb func OnItemRemovedFromSlot(evt: ref<ItemRemovedFromSlot>) -> Bool {
    let weaponTag: CName;
    let wrapperNameBasedOnID: CName = AIActionHelper.GetAnimWrapperNameBasedOnItemID(evt.GetItemID());
    if Equals(wrapperNameBasedOnID, n"Cyb_StrongArms") {
      this.RemoveStrongArmsFX();
    };
    super.OnItemRemovedFromSlot(evt);
    if this.IsPaperdoll() {
      NPCPuppet.SetAnimWrapperBasedOnEquippedItem(this, wrapperNameBasedOnID, evt.GetSlotID(), evt.GetItemID(), 0.00);
    } else {
      if ScriptedPuppet.IsActive(this) {
        weaponTag = AIActionHelper.GetAnimWrapperNameBasedOnItemTag(evt.GetItemID());
        if !AIScriptSquad.HasOrder(this, n"Equip") || !IsNameValid(weaponTag) || this.IsCrowd() && NotEquals(this.GetUpperBodyStateFromBlackboard(), gamedataNPCUpperBodyState.Equip) {
          NPCPuppet.SetAnimWrapperBasedOnEquippedItem(this, wrapperNameBasedOnID, evt.GetSlotID(), evt.GetItemID(), 0.00);
        };
      };
    };
  }

  private final func SetAnimWrapperWeightBasedOnFaction() -> Void {
    let animWrappers: array<CName>;
    let i: Int32;
    let affiliation: wref<Affiliation_Record> = TweakDBInterface.GetCharacterRecord(this.GetRecordID()).Affiliation();
    if !IsDefined(affiliation) {
      return;
    };
    animWrappers = affiliation.AnimWrappers();
    i = 0;
    while i < ArraySize(animWrappers) {
      if IsNameValid(animWrappers[i]) {
        AnimationControllerComponent.SetAnimWrapperWeight(this, animWrappers[i], 1.00);
      };
      i += 1;
    };
  }

  public final static func SetAnimWrapperBasedOnEquippedItem(npc: wref<NPCPuppet>, const slotID: TweakDBID, const itemID: ItemID, const value: Float) -> Void {
    let wrapperNameBaseOnID: CName = AIActionHelper.GetAnimWrapperNameBasedOnItemID(itemID);
    if slotID == t"AttachmentSlots.WeaponRight" {
      AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(npc, n"WeaponRight", value);
      AnimationControllerComponent.SetAnimWrapperWeight(npc, wrapperNameBaseOnID, value);
      AnimationControllerComponent.SetAnimWrapperWeight(npc, AIActionHelper.GetAnimWrapperNameBasedOnItemTag(itemID), value);
      AIActionHelper.SendItemHandling(npc, TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)), n"rightHandItemHandling", value > 0.00 ? true : false);
      if Equals(wrapperNameBaseOnID, n"Wea_Fists") {
        AnimationControllerComponent.SetAnimWrapperWeight(npc, n"Wea_Hammer", 0.00);
      };
    } else {
      if slotID == t"AttachmentSlots.WeaponLeft" {
        if NotEquals(wrapperNameBaseOnID, n"Gad_Grenade") {
          AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(npc, n"WeaponLeft", value);
        };
        AnimationControllerComponent.SetAnimWrapperWeight(npc, wrapperNameBaseOnID, value);
        AnimationControllerComponent.SetAnimWrapperWeight(npc, AIActionHelper.GetAnimWrapperNameBasedOnItemTag(itemID), value);
        AIActionHelper.SendItemHandling(npc, TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)), n"leftHandItemHandling", value > 0.00 ? true : false);
      };
    };
  }

  public final static func SetAnimWrapperBasedOnEquippedItem(npc: wref<NPCPuppet>, const wrapperNameBasedOnID: CName, const slotID: TweakDBID, const itemID: ItemID, const value: Float) -> Void {
    if slotID == t"AttachmentSlots.WeaponRight" {
      AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(npc, n"WeaponRight", value);
      AnimationControllerComponent.SetAnimWrapperWeight(npc, wrapperNameBasedOnID, value);
      AnimationControllerComponent.SetAnimWrapperWeight(npc, AIActionHelper.GetAnimWrapperNameBasedOnItemTag(itemID), value);
      AIActionHelper.SendItemHandling(npc, TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)), n"rightHandItemHandling", value > 0.00 ? true : false);
      if Equals(wrapperNameBasedOnID, n"Wea_Fists") {
        AnimationControllerComponent.SetAnimWrapperWeight(npc, n"Wea_Hammer", 0.00);
      };
    } else {
      if slotID == t"AttachmentSlots.WeaponLeft" {
        if NotEquals(wrapperNameBasedOnID, n"Gad_Grenade") {
          AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(npc, n"WeaponLeft", value);
        };
        AnimationControllerComponent.SetAnimWrapperWeight(npc, wrapperNameBasedOnID, value);
        AnimationControllerComponent.SetAnimWrapperWeight(npc, AIActionHelper.GetAnimWrapperNameBasedOnItemTag(itemID), value);
        AIActionHelper.SendItemHandling(npc, TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)), n"leftHandItemHandling", value > 0.00 ? true : false);
      };
    };
  }

  private final func SetRandomAnimWrappersForLocomotion() -> Void {
    switch RandRange(1, 15) {
      case 1:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle01", 1.00);
        break;
      case 2:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle02", 1.00);
        break;
      case 3:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle03", 1.00);
        break;
      case 4:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle04", 1.00);
        break;
      case 5:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle05", 1.00);
        break;
      case 6:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle06", 1.00);
        break;
      case 7:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle07", 1.00);
        break;
      case 8:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle08", 1.00);
        break;
      case 9:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle09", 1.00);
        break;
      case 10:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle10", 1.00);
        break;
      case 11:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle11", 1.00);
        break;
      case 12:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle12", 1.00);
        break;
      case 13:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle13", 1.00);
        break;
      case 14:
        AnimationControllerComponent.SetAnimWrapperWeight(this, n"LocomotionCycle14", 1.00);
        break;
      default:
    };
    if this.MatchVisualTag(n"anim_Lowlife") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"LowlifeLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_MidCorp") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"MidCorpLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Posh") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"PoshLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_DirtGirl") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"DirtGirlLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Homeless") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"HomelessLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Freak") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"FreakLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Junkie") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"JunkieLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Mallrat") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"MallratLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Worker") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"WorkerLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Borg") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"BorgLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Fam") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"FamLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Cowboy") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"CowboyLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Tomboy") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"TomboyLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Redneck") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"RedneckLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Tennant") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"TennantLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Youngster") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"YoungsterLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_LowCorp") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"LowCorpLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Elder") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"ElderLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Nightlife") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"NightlifeLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"Anim_Monk") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"MonkLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Drunk") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"DrunkLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"anim_Beaten") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"BeatenLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"Overload_Heavy") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"BackpackHeavyLocomotion", 1.00);
    };
    if this.MatchVisualTag(n"Overload_Mid") {
      AnimationControllerComponent.SetAnimWrapperWeight(this, n"BackpackMidLocomotion", 1.00);
    };
  }

  protected cb func OnDelaySetCoverNPCCurrentlyExposed(evt: ref<DelaySetCoverNPCCurrentlyExposed>) -> Bool {
    AICoverHelper.SetCoverNPCCurrentlyExposed(this, evt.exposed);
  }

  protected cb func OnSetPuppetTargetingPlayer(evt: ref<OnBeingTarget>) -> Bool {
    if IsDefined(evt.objectThatTargets as NPCPuppet) {
      this.SetPuppetTargetingPlayer(true);
    } else {
      if IsDefined(evt.objectThatTargets as NPCPuppet) && evt.noLongerTarget {
        this.SetPuppetTargetingPlayer(false);
      };
    };
  }

  private final func SetPuppetTargetingPlayer(isTargeting: Bool) -> Void {
    this.m_isTargetingPlayer = isTargeting;
    let i: Int32 = 0;
    while i < ArraySize(this.m_listeners) {
      this.m_listeners[i].OnIsTrackingPlayerChanged(isTargeting);
      i += 1;
    };
  }

  public final const func IsPuppetTargetingPlayer() -> Bool {
    return this.m_isTargetingPlayer;
  }

  public final const func PuppetIsNotVisible() -> Bool {
    return this.m_isNotVisible;
  }

  public final static func ChangeHighLevelState(obj: ref<GameObject>, newState: gamedataNPCHighLevelState) -> Void {
    let signal: ref<NPCStateChangeSignal>;
    let signalId: Uint16;
    let signalTable: ref<gameBoolSignalTable>;
    let owner: ref<NPCPuppet> = obj as NPCPuppet;
    if !IsDefined(owner) {
      return;
    };
    if Equals(owner.GetHighLevelStateFromBlackboard(), newState) {
      return;
    };
    signalTable = owner.GetSignalTable();
    signal = new NPCStateChangeSignal();
    signalId = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_highLevelState = newState;
    signal.m_highLevelStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeUpperBodyState(obj: ref<GameObject>, newState: gamedataNPCUpperBodyState) -> Void {
    let signal: ref<NPCStateChangeSignal>;
    let signalId: Uint16;
    let signalTable: ref<gameBoolSignalTable>;
    let owner: ref<NPCPuppet> = obj as NPCPuppet;
    if !IsDefined(owner) {
      return;
    };
    if Equals(owner.GetUpperBodyStateFromBlackboard(), newState) {
      return;
    };
    signalTable = owner.GetSignalTable();
    signal = new NPCStateChangeSignal();
    signalId = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_upperBodyState = newState;
    signal.m_upperBodyStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeStanceState(obj: ref<GameObject>, newState: gamedataNPCStanceState) -> Void {
    let signal: ref<NPCStateChangeSignal>;
    let signalId: Uint16;
    let signalTable: ref<gameBoolSignalTable>;
    let owner: ref<NPCPuppet> = obj as NPCPuppet;
    if !IsDefined(owner) {
      return;
    };
    if Equals(owner.GetStanceStateFromBlackboard(), newState) {
      return;
    };
    signalTable = owner.GetSignalTable();
    signal = new NPCStateChangeSignal();
    signalId = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_stanceState = newState;
    signal.m_stanceStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeHitReactionModeState(obj: ref<GameObject>, newState: EHitReactionMode) -> Void {
    let signal: ref<NPCStateChangeSignal>;
    let signalId: Uint16;
    let signalTable: ref<gameBoolSignalTable>;
    let owner: ref<NPCPuppet> = obj as NPCPuppet;
    if !IsDefined(owner) {
      return;
    };
    if Equals(owner.GetHitReactionModeFromBlackboard(), newState) {
      return;
    };
    signalTable = owner.GetSignalTable();
    signal = new NPCStateChangeSignal();
    signalId = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_hitReactionModeState = newState;
    signal.m_hitReactionModeStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeDefenseModeState(obj: ref<GameObject>, newState: gamedataDefenseMode) -> Void {
    let signal: ref<NPCStateChangeSignal>;
    let signalId: Uint16;
    let signalTable: ref<gameBoolSignalTable>;
    let owner: ref<NPCPuppet> = obj as NPCPuppet;
    if !IsDefined(owner) {
      return;
    };
    if Equals(owner.GetDefenseModeStateFromBlackboard(), newState) {
      return;
    };
    signalTable = owner.GetSignalTable();
    signal = new NPCStateChangeSignal();
    signalId = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_defenseMode = newState;
    signal.m_defenseModeValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeLocomotionMode(obj: ref<GameObject>, newState: gamedataLocomotionMode) -> Void {
    let signalTable: ref<gameBoolSignalTable> = (obj as NPCPuppet).GetSignalTable();
    let signal: ref<NPCStateChangeSignal> = new NPCStateChangeSignal();
    let signalId: Uint16 = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_locomotionMode = newState;
    signal.m_locomotionModeValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeBehaviorState(obj: ref<GameObject>, newState: gamedataNPCBehaviorState) -> Void {
    let signalTable: ref<gameBoolSignalTable> = (obj as NPCPuppet).GetSignalTable();
    let signal: ref<NPCStateChangeSignal> = new NPCStateChangeSignal();
    let signalId: Uint16 = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_behaviorState = newState;
    signal.m_behaviorStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangePhaseState(obj: ref<GameObject>, newState: ENPCPhaseState) -> Void {
    let signalTable: ref<gameBoolSignalTable> = (obj as NPCPuppet).GetSignalTable();
    let signal: ref<NPCStateChangeSignal> = new NPCStateChangeSignal();
    let signalId: Uint16 = signalTable.GetOrCreateSignal(n"NPCStateChangeSignal");
    signal.m_phaseState = newState;
    signal.m_phaseStateValid = true;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  public final static func ChangeForceRagdollOnDeath(obj: ref<GameObject>, value: Bool) -> Void {
    let signalTable: ref<gameBoolSignalTable> = (obj as NPCPuppet).GetSignalTable();
    let signal: ref<ForcedRagdollDeathSignal> = new ForcedRagdollDeathSignal();
    let signalId: Uint16 = signalTable.GetOrCreateSignal(n"ForcedRagdollDeathSignal");
    signal.m_value = value;
    signalTable.Set(signalId, false);
    signalTable.SetWithData(signalId, signal);
    signalTable.Set(signalId, true);
  }

  protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
    let i: Int32;
    let setSlowMoEvt: ref<SetSlowMoForOnePunchAttackEvent>;
    let si: ref<SquadScriptInterface>;
    let squadMate: ref<ScriptedPuppet>;
    let squadMates: array<wref<Entity>>;
    let ttc: ref<TargetTrackerComponent>;
    let slowMoDelay: Float = TDB.GetFloat(t"Items.StrongArms.slowMoDelay");
    let gmplTags: array<CName> = evt.staticData.GameplayTags();
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    if this.IsDead() || ScriptedPuppet.IsDefeated(this) || this.IsAboutToDieOrDefeated() {
      if ArrayContains(gmplTags, n"OnePunchedMark") {
        setSlowMoEvt = new SetSlowMoForOnePunchAttackEvent();
        GameInstance.GetDelaySystem(player.GetGame()).DelayEvent(player, setSlowMoEvt, slowMoDelay, true);
        this.GetHitReactionComponent().ProcessOnePunchAttackHitImpact(this, player);
      } else {
        if ArrayContains(gmplTags, n"GrandFinaleMark") {
          this.GetHitReactionComponent().ProcessGrandFinaleHitImpact(this, player);
        };
      };
    };
    if ArrayContains(gmplTags, n"Quickhack") {
      this.OnQuickHackEffectApplied(evt);
    };
    if ArrayContains(gmplTags, n"Blind") {
      SenseComponent.RequestSecondaryPresetChange(this, t"Senses.Blind");
      ttc = this.GetTargetTrackerComponent();
      if IsDefined(ttc) {
        this.SwitchTargetPlayerTrackedAccuracy(ttc, false);
        ttc.SetThreatBeliefAccuracy(this, 0.00);
      };
    };
    if ArrayContains(gmplTags, n"Cloak") && !ArrayContains(gmplTags, n"Cloak_Exit") {
      this.GetSensesComponent().RemoveSenseMappin();
    };
    if ArrayContains(gmplTags, n"ClearThreats") {
      ttc = this.GetTargetTrackerComponent();
      if IsDefined(ttc) {
        ttc.ClearThreats();
      };
    };
    if ArrayContains(gmplTags, n"ExitCombatWithPerk") {
      AISquadHelper.GetSquadmates(this, squadMates);
      i = 0;
      while i < ArraySize(squadMates) {
        squadMate = squadMates[i] as ScriptedPuppet;
        if !IsDefined(squadMate) {
        } else {
          this.GetSecuritySystem().TryReleaseFromReprimand(this.GetEntityID());
          StatusEffectHelper.ApplyStatusEffect(squadMate, t"BaseStatusEffect.MemoryWipeExitCombat", evt.instigatorEntityID);
        };
        i += 1;
      };
    };
    if ArrayContains(gmplTags, n"ResetSquadSync") {
      if AISquadHelper.GetSquadMemberInterface(this, si) {
        si.Leave(this);
        si.Join(this);
      };
    };
    if ArrayContains(gmplTags, n"DisableRagdoll") {
      this.SetDisableRagdoll(true);
    };
    if ArrayContains(gmplTags, n"Defeated") {
      this.SetIsDefeatMechanicActive(false);
      StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.InvulnerableAfterDefeated");
    };
    switch evt.staticData.StatusEffectType().Type() {
      case gamedataStatusEffectType.DefeatedWithRecover:
        this.OnDefeatedWithRecoverStatusEffectApplied();
        break;
      default:
    };
    if this.ShouldDelayStatusEffectApplication(evt) {
      this.DelayStatusEffectApplication(evt);
    } else {
      this.ProcessStatusEffectApplication(evt);
    };
  }

  private final func ShouldDelayStatusEffectApplication(evt: ref<ApplyStatusEffectEvent>) -> Bool {
    if TDBID.IsValid(evt.staticData.AIData().GetID()) {
      if evt.staticData.AIData().ShouldDelayStatusEffectApplication() {
        return true;
      };
    };
    return false;
  }

  private final func ProcessStatusEffectApplication(evt: ref<ApplyStatusEffectEvent>) -> Void {
    let newStatusEffectPrio: Float;
    let topPrioStatusEffectPrio: Float;
    let topProEffect: ref<StatusEffect>;
    this.OnStatusEffectApplied(evt);
    if (StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"Braindance") || StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.Drunk")) && NotEquals(evt.staticData.StatusEffectType().Type(), gamedataStatusEffectType.Defeated) {
      return;
    };
    if evt.staticData.AIData().ShouldProcessAIDataOnReapplication() && evt.staticData.GetID() == this.m_cachedStatusEffectAnim.GetID() {
      return;
    };
    if !evt.isNewApplication && !evt.staticData.AIData().ShouldProcessAIDataOnReapplication() {
      return;
    };
    if IsDefined(evt.staticData) && IsDefined(evt.staticData.AIData()) {
      newStatusEffectPrio = evt.staticData.AIData().Priority();
      topProEffect = StatusEffectHelper.GetTopPriorityEffect(this, evt.staticData.StatusEffectType().Type(), true);
      if IsDefined(topProEffect) {
        topPrioStatusEffectPrio = topProEffect.GetRecord().AIData().Priority();
      };
    };
    if Equals(evt.staticData.StatusEffectType().Type(), gamedataStatusEffectType.Defeated) {
      if ScriptedPuppet.CanRagdoll(this) {
        this.QueueEvent(new UncontrolledMovementStartEvent());
      };
      this.TriggerDefeatedBehavior(evt);
    } else {
      if Equals(evt.staticData.StatusEffectType().Type(), gamedataStatusEffectType.DefeatedWithRecover) {
        this.TriggerStatusEffectBehavior(evt, true);
      } else {
        if Equals(evt.staticData.StatusEffectType().Type(), gamedataStatusEffectType.UncontrolledMovement) {
          this.OnUncontrolledMovementStatusEffectAdded(evt);
        } else {
          if newStatusEffectPrio >= topPrioStatusEffectPrio && StatusEffectHelper.CheckStatusEffectBehaviorPrereqs(this, evt.staticData) {
            if this.IsCrowd() && Equals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Fear) {
              return;
            };
            if newStatusEffectPrio > topPrioStatusEffectPrio || !IsDefined(this.m_cachedStatusEffectAnim) {
              this.TriggerStatusEffectBehavior(evt);
            } else {
              if evt.staticData.AIData().AllowDelayStatusEffectSignalIfSamePriorityExecuting() {
                this.m_pendingSEEvent = evt;
                this.m_pendingDueToCachedSEAnim = true;
              };
            };
          };
        };
      };
    };
    this.CacheStatusEffectAppliedByPlayer(evt);
  }

  private final func OnQuickHackEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Void {
    let durationStatModifiers: array<wref<StatModifier_Record>>;
    let i: Int32;
    let squadMate: ref<ScriptedPuppet>;
    let squadMates: array<wref<Entity>>;
    let statusEffectDuration: Float;
    let statusEffectDurationModifier: Float;
    let statusEffects: array<ref<StatusEffect>>;
    let value: Float;
    let vehicleMounted: wref<VehicleObject>;
    let remainingDuration: Float = -1.00;
    let gmplTags: array<CName> = evt.staticData.GameplayTags();
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    this.m_quickHackEffectsApplied += 1u;
    evt.staticData.Duration().StatModifiers(durationStatModifiers);
    statusEffectDuration = RPGManager.CalculateStatModifiers(durationStatModifiers, this.GetGame(), player, Cast<StatsObjectID>(player.GetEntityID()));
    GameInstance.GetStatusEffectSystem(this.GetGame()).GetAppliedEffectsWithID(this.GetEntityID(), evt.staticData.GetRecordID(), statusEffects);
    if ArraySize(statusEffects) > 0 {
      remainingDuration = statusEffects[0].GetRemainingDuration();
    };
    if Cast<Bool>(PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Central_Perk_1_3)) && evt.staticData.GameplayTagsContains(n"ControlQuickhacked") && GameInstance.GetStatPoolsSystem(this.GetGame()).HasStatPoolValueReachedMax(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health) {
      statusEffectDurationModifier += TweakDBInterface.GetFloat(t"NewPerks.Intelligence_Central_Perk_1_3.durationMultiplier", 0.00);
    };
    if Cast<Bool>(PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Left_Milestone_1)) && EntityID.IsDefined(evt.proxyEntityID) {
      statusEffectDurationModifier += TweakDBInterface.GetFloat(t"NewPerks.Intelligence_Left_Milestone_1.durationIncease", 0.00);
    };
    remainingDuration = statusEffectDuration * statusEffectDurationModifier + remainingDuration;
    GameInstance.GetStatusEffectSystem(this.GetGame()).SetStatusEffectRemainingDuration(this.GetEntityID(), evt.staticData.GetID(), remainingDuration);
    if this.m_quickHackEffectsApplied == 1u {
      value = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(evt.instigatorEntityID), gamedataStatType.LowerHackingResistanceOnHack);
      if value > 0.00 {
        this.m_hackingResistanceMod = new gameConstantStatModifierData();
        this.m_hackingResistanceMod.statType = gamedataStatType.HackingResistance;
        this.m_hackingResistanceMod.modifierType = gameStatModifierType.Additive;
        this.m_hackingResistanceMod.value = value * -1.00;
        GameInstance.GetStatsSystem(this.GetGame()).AddModifier(Cast<StatsObjectID>(this.GetEntityID()), this.m_hackingResistanceMod);
      };
      if GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(evt.instigatorEntityID), gamedataStatType.HasMadnessLvl4Passive) == 1.00 {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.DoNotBlockShootingOnFriendlyFire", evt.instigatorEntityID);
      };
      if GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(evt.instigatorEntityID), gamedataStatType.RemoveSprintOnQuickhack) == 1.00 {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.LocomotionMalfunctionLevel4Passive", evt.instigatorEntityID);
      };
    };
    if ArrayContains(gmplTags, n"CommsNoiseJam") {
      this.SwitchTargetPlayerTrackedAccuracy(false);
      if ArrayContains(gmplTags, n"CommsNoiseUncontious") && StatusEffectHelper.HasStatusEffectWithTagConst(this, n"MemoryWipe") && StatusEffectHelper.HasStatusEffectWithTagConst(this, n"QuickHackBlind") {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.SystemCollapse", evt.instigatorEntityID);
        StatusEffectHelper.RemoveStatusEffectsWithTag(this, n"MemoryWipe");
        StatusEffectHelper.RemoveStatusEffectsWithTag(this, n"CommsNoiseUncontious");
        StatusEffectHelper.RemoveStatusEffectsWithTag(this, n"QuickHackBlind");
      };
    };
    if !evt.isAppliedOnSpawn && evt.instigatorEntityID == this.GetPlayerID() && !ArrayContains(gmplTags, n"Stealth") {
      if QuickHackableQueueHelper.IsAwarenessBumpingAllowed(this) {
        GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.m_delayNonStealthQuickHackVictimEventID);
        this.m_delayNonStealthQuickHackVictimEventID = GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, NonStealthQuickHackVictimEvent.Create(evt.instigatorEntityID), 0.10);
      };
      if VehicleComponent.IsMountedToVehicle(this.GetGame(), this) {
        VehicleComponent.GetVehicle(this.GetGame(), this, vehicleMounted);
        if VehicleComponent.GetDriver(this.GetGame(), vehicleMounted, vehicleMounted.GetEntityID()) == this {
          vehicleMounted.ActivateTemporaryLossOfControl();
        };
      };
    };
    if ArrayContains(gmplTags, n"JamWeapon") && !ArrayContains(gmplTags, n"WeaponMalfunctionOnSmartLock") {
      if this.IsTargetedWithSmartWeapon() {
        this.ProlongWeaponGlitchNPCDebuff(player);
      };
      if ArrayContains(gmplTags, n"JamWeaponLvl4PlusPlus") {
        StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.WeaponGlitchLvl4PlusPlusBuff");
      } else {
        if ArrayContains(gmplTags, n"JamWeaponLvl4") {
          StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.WeaponGlitchLvl4Buff");
        };
      };
    };
    if ArrayContains(gmplTags, n"MemoryWipe") {
      if player.IsBeingRevealed() {
        if GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.HasSystemCollapse) == 1.00 {
          StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.SystemCollapseMemoryCostReduction");
        };
        if GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.HasSystemCollapse) == 1.00 {
          StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.SystemCollapseMemoryCostReduction");
        };
      };
      if ArrayContains(gmplTags, n"MemoryWipeLvl4") {
        AISquadHelper.GetSquadmates(this, squadMates);
        i = 0;
        while i < ArraySize(squadMates) {
          squadMate = squadMates[i] as ScriptedPuppet;
          if !IsDefined(squadMate) {
          } else {
            this.GetSecuritySystem().TryReleaseFromReprimand(this.GetEntityID());
            StatusEffectHelper.ApplyStatusEffect(squadMate, t"BaseStatusEffect.MemoryWipeLevel2", evt.instigatorEntityID);
          };
          i += 1;
        };
      };
    };
    if ArrayContains(gmplTags, n"QuickHackBlind") {
      this.GetSensesComponent().ResetDetection(player.GetEntityID());
    };
    if Cast<Bool>(PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Master_Perk_4)) && StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff") {
      StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.Intelligence_Master_Perk_4_Overclock_Target_Weakspot", player.GetEntityID());
    };
  }

  protected cb func OnNonStealthQuickHackVictimEvent(evt: ref<NonStealthQuickHackVictimEvent>) -> Bool {
    if !NPCPuppet.RevealPlayerPositionIfNeeded(this, evt.instigatorID) {
      NPCStatesComponent.AlertPuppet(this);
    };
    AIActionHelper.TryChangingAttitudeToHostile(this, GameInstance.FindEntityByID(this.GetGame(), evt.instigatorID) as PlayerPuppet);
  }

  public final static func RevealPlayerPositionIfNeeded(ownerPuppet: wref<ScriptedPuppet>, playerID: EntityID, opt isPrevention: Bool) -> Bool {
    let evt: ref<HackTargetEvent>;
    let hackingMinigameBB: ref<IBlackboard>;
    let ownerHighLevelState: gamedataNPCHighLevelState;
    let player: wref<PlayerPuppet>;
    if !IsDefined(ownerPuppet) || !EntityID.IsDefined(playerID) {
      return false;
    };
    player = GameInstance.FindEntityByID(ownerPuppet.GetGame(), playerID) as PlayerPuppet;
    if !IsDefined(player) || player.IsInCombat() || player.IsReplacer() || player.IsBeingRevealed() {
      return false;
    };
    ownerHighLevelState = ownerPuppet.GetHighLevelStateFromBlackboard();
    if ScriptedPuppet.IsBoss(ownerPuppet) && NotEquals(ownerHighLevelState, gamedataNPCHighLevelState.Combat) {
      return false;
    };
    evt = new HackTargetEvent();
    evt.targetID = player.GetEntityID();
    evt.netrunnerID = ownerPuppet.GetEntityID();
    evt.objectRecord = TweakDBInterface.GetObjectActionRecord(isPrevention ? t"AIQuickHack.PreventionHackRevealPosition" : t"AIQuickHack.HackRevealPosition");
    evt.settings.showDirectionalIndicator = false;
    evt.settings.isRevealPositionAction = true;
    evt.settings.HUDData.bottomText = "LocKey#92249";
    evt.settings.HUDData.failedText = "LocKey#92985";
    evt.settings.HUDData.completedText = "LocKey#92985";
    evt.settings.HUDData.type = SimpleMessageType.Reveal;
    if IsDefined(evt.objectRecord) {
      player.QueueEvent(evt);
      hackingMinigameBB = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().HackingMinigame);
      hackingMinigameBB.SetVector4(GetAllBlackboardDefs().HackingMinigame.LastPlayerHackPosition, player.GetWorldPosition());
      return true;
    };
    return false;
  }

  protected final func TriggerDefeatedBehavior(evt: ref<ApplyStatusEffectEvent>) -> Void {
    let flags: array<EAIGateSignalFlags>;
    let repeatSignalDelay: Float;
    let repeatSignalStatModifiers: array<wref<StatModifier_Record>>;
    let tags: array<CName>;
    let priority: Float = evt.staticData.AIData().Priority();
    let statusEffectDuration: Float = StatusEffectHelper.GetStatusEffectByID(this, evt.staticData.GetID()).GetRemainingDuration();
    if statusEffectDuration < 0.00 {
      statusEffectDuration = RPGManager.GetStatRecord(gamedataStatType.MaxDuration).Max();
    };
    ArrayResize(tags, 3);
    tags[0] = n"downed";
    tags[1] = EnumValueToName(n"gamedataStatusEffectType", Cast<Int64>(EnumInt(evt.staticData.StatusEffectType().Type())));
    ArrayResize(flags, 1);
    flags[0] = IntEnum<EAIGateSignalFlags>(Cast<Int32>(EnumValueFromString("EAIGateSignalFlags", "AIGSF_" + EnumValueToString("gamedataStatusEffectAIBehaviorFlag", Cast<Int64>(EnumInt(evt.staticData.AIData().BehaviorEventFlag().Type()))))));
    evt.staticData.AIData().BehaviorSignalResendDelay(repeatSignalStatModifiers);
    repeatSignalDelay = RPGManager.CalculateStatModifiers(repeatSignalStatModifiers, this.GetGame(), this, Cast<StatsObjectID>(this.GetEntityID()));
    this.SendStatusEffectSignal(priority, tags, flags, evt.staticData.GetID(), repeatSignalDelay, statusEffectDuration);
  }

  protected final func DelayStatusEffectApplication(evt: ref<ApplyStatusEffectEvent>) -> Void {
    let delayStatusEffectTimes: Vector2 = TweakDBInterface.GetVector2(t"AIGeneralSettings.delayStatusEffectApplicationTime", new Vector2(0.10, 0.40));
    let finalDelayTime: Float = RandRangeF(delayStatusEffectTimes.X, delayStatusEffectTimes.Y);
    let delayedSEReactionEvent: ref<DelayedStatusEffectApplicationEvent> = new DelayedStatusEffectApplicationEvent();
    delayedSEReactionEvent.statusEffectEvent = evt;
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, delayedSEReactionEvent, finalDelayTime);
  }

  protected final func TriggerStatusEffectBehavior(evt: ref<ApplyStatusEffectEvent>, opt alwaysTrigger: Bool, opt checkCachedSEAnim: Bool) -> Void {
    let flags: array<EAIGateSignalFlags>;
    let priority: Float;
    let repeatSignalDelay: Float;
    let repeatSignalStatModifiers: array<wref<StatModifier_Record>>;
    let statusEffectDuration: Float;
    let tags: array<CName>;
    if !IsDefined(evt.staticData) || !IsDefined(evt.staticData.AIData()) {
      return;
    };
    priority = evt.staticData.AIData().Priority();
    statusEffectDuration = StatusEffectHelper.GetStatusEffectByID(this, evt.staticData.GetID()).GetRemainingDuration();
    if statusEffectDuration < 0.00 {
      statusEffectDuration = RPGManager.GetStatRecord(gamedataStatType.MaxDuration).Max();
    };
    ArrayResize(tags, 3);
    tags[0] = n"reactive";
    tags[1] = n"statusEffects";
    tags[2] = EnumValueToName(n"gamedataStatusEffectType", Cast<Int64>(EnumInt(evt.staticData.StatusEffectType().Type())));
    evt.staticData.AIData().BehaviorSignalResendDelay(repeatSignalStatModifiers);
    repeatSignalDelay = RPGManager.CalculateStatModifiers(repeatSignalStatModifiers, this.GetGame(), this, Cast<StatsObjectID>(this.GetEntityID()));
    if alwaysTrigger {
      this.SendStatusEffectSignal(priority, tags, flags, evt.staticData.GetID(), repeatSignalDelay, statusEffectDuration);
    } else {
      if checkCachedSEAnim && IsDefined(this.m_cachedStatusEffectAnim) {
        this.m_pendingSEEvent = evt;
        this.m_pendingDueToCachedSEAnim = true;
      } else {
        if !ScriptedPuppet.IsOnOffMeshLink(this) && !NPCPuppet.IsUnstoppable(this) {
          this.SendStatusEffectSignal(priority, tags, flags, evt.staticData.GetID(), repeatSignalDelay, statusEffectDuration);
          if IsDefined(this.m_pendingSEEvent) {
            this.m_pendingSEEvent = null;
          };
        } else {
          this.m_pendingSEEvent = evt;
          this.m_pendingDueToCachedSEAnim = false;
        };
      };
    };
  }

  protected final func SendStatusEffectSignal(priority: Float, const tags: script_ref<[CName]>, const flags: script_ref<[EAIGateSignalFlags]>, statusEffectID: TweakDBID, repeatSignalDelay: Float, remainingStatusEffectDuration: Float) -> Void {
    let i: Int32;
    let signal: AIGateSignal;
    signal.priority = priority;
    signal.lifeTime = remainingStatusEffectDuration;
    if StatusEffectHelper.HasStatusEffectWithTagConst(this, n"ExitCombatWithPerk") {
      return;
    };
    i = 0;
    while i < ArraySize(Deref(tags)) {
      AIGateSignal.AddTag(signal, Deref(tags)[i]);
      i += 1;
    };
    i = 0;
    while i < ArraySize(Deref(flags)) {
      AIGateSignal.AddFlag(signal, Cast<AISignalFlags>(Deref(flags)[i]));
      i += 1;
    };
    this.GetSignalHandlerComponent().AddSignal(signal, false);
    this.m_lastStatusEffectSignalSent = TweakDBInterface.GetStatusEffectRecord(statusEffectID);
    this.TryRepeatStatusEffectSignal(priority, tags, flags, statusEffectID, repeatSignalDelay, remainingStatusEffectDuration);
  }

  protected final func TryRepeatStatusEffectSignal(priority: Float, const tags: script_ref<[CName]>, const flags: script_ref<[EAIGateSignalFlags]>, statusEffectID: TweakDBID, repeatSignalDelay: Float, remainingStatusEffectDuration: Float) -> Void {
    let emptyDelayID: DelayID;
    let repeatSignalEvent: ref<StatusEffectSignalEvent>;
    if repeatSignalDelay <= 0.00 || remainingStatusEffectDuration < repeatSignalDelay {
      return;
    };
    repeatSignalEvent = new StatusEffectSignalEvent();
    repeatSignalEvent.priority = priority;
    repeatSignalEvent.tags = Deref(tags);
    repeatSignalEvent.flags = Deref(flags);
    repeatSignalEvent.statusEffectID = statusEffectID;
    repeatSignalEvent.repeatSignalDelay = repeatSignalDelay;
    if this.m_resendStatusEffectSignalDelayID != emptyDelayID {
      GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.m_resendStatusEffectSignalDelayID);
      this.m_resendStatusEffectSignalDelayID = emptyDelayID;
    };
    this.m_resendStatusEffectSignalDelayID = GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, repeatSignalEvent, repeatSignalDelay);
  }

  protected cb func OnStatusEffectSignal(evt: ref<StatusEffectSignalEvent>) -> Bool {
    let statusEffect: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(this, evt.statusEffectID);
    if IsDefined(statusEffect) {
      if !ArrayContains(evt.tags, n"reapplication") {
        ArrayPush(evt.tags, n"reapplication");
      };
      if !ScriptedPuppet.IsOnOffMeshLink(this) {
        this.SendStatusEffectSignal(evt.priority, evt.tags, evt.flags, evt.statusEffectID, evt.repeatSignalDelay, statusEffect.GetRemainingDuration());
      };
    };
  }

  protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool {
    let gmplTags: array<CName>;
    let playerBlackboard: ref<IBlackboard>;
    let playerPuppet: ref<PlayerPuppet>;
    let secSys: ref<SecuritySystemControllerPS>;
    let ttc: ref<TargetTrackerComponent>;
    super.OnStatusEffectRemoved(evt);
    gmplTags = evt.staticData.GameplayTags();
    if ArrayContains(gmplTags, n"Quickhack") {
      this.OnQuickHackEffectRemoved(evt);
    };
    if ArrayContains(gmplTags, n"Blind") && evt.isFinalRemoval {
      SenseComponent.ResetPreset(this);
      if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"CommsNoiseJam") {
        secSys = this.GetSecuritySystem();
        if IsDefined(secSys) && secSys.HasSupport(Cast<PersistentID>(this.GetEntityID())) {
          this.SwitchTargetPlayerTrackedAccuracy(true);
        };
      };
    };
    if ArrayContains(gmplTags, n"Cloak") && !ArrayContains(gmplTags, n"Cloak_Exit") && evt.isFinalRemoval {
      this.GetSensesComponent().TryCreateSenseMappin();
    };
    if ArrayContains(gmplTags, n"ResetSquadSync") {
      ttc = this.GetTargetTrackerComponent();
      if IsDefined(ttc) {
        ttc.PushSquadSync(AISquadType.Combat);
        AISquadHelper.PullSquadSync(this, AISquadType.Combat);
      };
      AIActionHelper.QueuePullSquadSync(this);
    };
    if ArrayContains(gmplTags, n"DisableRagdoll") {
      this.SetDisableRagdoll(false);
    };
    if ArrayContains(gmplTags, n"Defeated") && ScriptedPuppet.IsActive(this) {
      this.SetIsDefeatMechanicActive(Equals(this.GetNPCType(), gamedataNPCType.Human));
    };
    if ArrayContains(gmplTags, n"JamWeapon") && ScriptedPuppet.IsActive(this) {
      StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.WeaponMalfunctionReapply");
      StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.WeaponMalfunctionRepeat");
    };
    if evt.staticData == this.m_lastStatusEffectSignalSent {
      this.m_lastStatusEffectSignalSent = null;
    };
    switch evt.staticData.StatusEffectType().Type() {
      case gamedataStatusEffectType.UncontrolledMovement:
        this.OnUncontrolledMovementStatusEffectRemoved();
        break;
      case gamedataStatusEffectType.DefeatedWithRecover:
        this.OnDefeatedWithRecoverStatusEffectRemoved();
        break;
      default:
    };
    if ArrayContains(gmplTags, n"MonoWireQuickhackContagiousHittableTarget") {
      playerPuppet = GetPlayer(this.GetGame());
      playerBlackboard = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
      if playerBlackboard != null {
        playerBlackboard.SetVariant(GetAllBlackboardDefs().PlayerStateMachine.MeleeSpreadableQuickhackActionID, ToVariant(TDBID.None()));
      };
    };
  }

  private final func OnQuickHackEffectRemoved(evt: ref<RemoveStatusEffect>) -> Void {
    let incapacitatedEvent: ref<IncapacitatedEvent>;
    let secSys: ref<SecuritySystemControllerPS>;
    let gmplTags: array<CName> = evt.staticData.GameplayTags();
    this.m_quickHackEffectsApplied -= 1u;
    if this.m_quickHackEffectsApplied == 0u {
      StatusEffectHelper.RemoveStatusEffect(this, t"AIQuickHackStatusEffect.LocomotionMalfunctionLevel4Passive");
      StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.DoNotBlockShootingOnFriendlyFire");
      StatusEffectHelper.RemoveStatusEffect(this, t"AIQuickHackStatusEffect.CommsNoisePassiveEffect");
      if IsDefined(this.m_hackingResistanceMod) {
        GameInstance.GetStatsSystem(this.GetGame()).RemoveModifier(Cast<StatsObjectID>(this.GetEntityID()), this.m_hackingResistanceMod);
      };
    };
    if ArrayContains(gmplTags, n"CommsNoiseJam") && this.IsConnectedToSecuritySystem() {
      AIActionHelper.QueueSecuritySystemCombatNotification(this);
      if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"Blind") {
        secSys = this.GetSecuritySystem();
        if IsDefined(secSys) && secSys.HasSupport(Cast<PersistentID>(this.GetEntityID())) {
          this.SwitchTargetPlayerTrackedAccuracy(true);
        };
      };
    };
    if ArrayContains(gmplTags, n"CommsNoiseIgnore") && this.GetPS().GetWasIncapacitated() {
      incapacitatedEvent = new IncapacitatedEvent();
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, incapacitatedEvent, 0.50);
    };
  }

  protected cb func OnCacheStatusEffectAnim(evt: ref<CacheStatusEffectAnimEvent>) -> Bool {
    if !evt.removeCachedStatusEffect {
      this.m_cachedStatusEffectAnim = this.m_lastStatusEffectSignalSent;
    } else {
      if IsDefined(this.m_cachedStatusEffectAnim) && IsDefined(this.m_pendingSEEvent) && this.m_pendingDueToCachedSEAnim {
        this.m_cachedStatusEffectAnim = null;
        this.TriggerPendingSEEvent();
      } else {
        this.m_cachedStatusEffectAnim = null;
      };
    };
  }

  protected func StopStatusEffectVFX(evt: ref<RemoveStatusEffect>) -> Void {
    if ArraySize(this.m_cachedVFXList) == 0 {
      super.StopStatusEffectVFX(evt);
    };
  }

  protected func StopStatusEffectSFX(evt: ref<RemoveStatusEffect>) -> Void {
    if ArraySize(this.m_cachedSFXList) == 0 {
      super.StopStatusEffectSFX(evt);
    };
  }

  protected cb func OnCacheStatusEffectFX(evt: ref<CacheStatusEffectFXEvent>) -> Bool {
    this.m_cachedVFXList = evt.vfxToCache;
    this.m_cachedSFXList = evt.sfxToCache;
  }

  protected cb func OnRemoveCachedStatusEffectFX(evt: ref<RemoveCachedStatusEffectFXEvent>) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(this.m_cachedVFXList) {
      GameObjectEffectHelper.BreakEffectLoopEvent(this, this.m_cachedVFXList[i].Name());
      i += 1;
    };
    i = 0;
    while i < ArraySize(this.m_cachedSFXList) {
      GameObjectEffectHelper.BreakEffectLoopEvent(this, this.m_cachedSFXList[i].Name());
      i += 1;
    };
    ArrayClear(this.m_cachedVFXList);
    ArrayClear(this.m_cachedSFXList);
  }

  protected cb func OnExplorationLeftEvent(evt: ref<ExplorationLeftEvent>) -> Bool {
    this.TriggerPendingSEEvent();
  }

  public final func OnSignalOnUnstoppableStateSignal(signalId: Uint16, newValue: Bool, userData: ref<OnUnstoppableStateSignal>) -> Void {
    if !newValue {
      this.TriggerPendingSEEvent();
    };
  }

  protected cb func OnDelayedSEReactionEvent(evt: ref<DelayedStatusEffectApplicationEvent>) -> Bool {
    if StatusEffectSystem.ObjectHasStatusEffect(this, evt.statusEffectEvent.staticData.GetID()) {
      this.ProcessStatusEffectApplication(evt.statusEffectEvent);
    };
  }

  private final func TriggerPendingSEEvent() -> Void {
    let statusEffectDuration: Float;
    if IsDefined(this.m_pendingSEEvent) {
      statusEffectDuration = StatusEffectHelper.GetStatusEffectByID(this, this.m_pendingSEEvent.staticData.GetID()).GetRemainingDuration();
      if statusEffectDuration <= 0.00 {
        this.m_pendingSEEvent = null;
      } else {
        this.TriggerStatusEffectBehavior(this.m_pendingSEEvent, false, this.m_pendingDueToCachedSEAnim);
      };
    };
  }

  private final func CacheStatusEffectAppliedByPlayer(evt: ref<ApplyStatusEffectEvent>) -> Void {
    if evt.instigatorEntityID == this.GetPlayerID() {
      this.m_lastSEAppliedByPlayer = StatusEffectHelper.GetStatusEffectByID(this, evt.staticData.GetID());
    };
  }

  public final func GetLastSEAppliedByPlayer() -> ref<StatusEffect> {
    return this.m_lastSEAppliedByPlayer;
  }

  protected final func OnUncontrolledMovementStatusEffectAdded(evt: ref<ApplyStatusEffectEvent>) -> Void {
    let ragdollInstigator: wref<GameObject> = GameInstance.FindEntityByID(this.GetGame(), evt.instigatorEntityID) as GameObject;
    if IsDefined(ragdollInstigator) {
      this.m_ragdollInstigator = ragdollInstigator;
    };
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, new CheckUncontrolledMovementStatusEffectEvent(), 1.50, true);
  }

  protected final func OnUncontrolledMovementStatusEffectRemoved() -> Void {
    this.QueueEvent(new UncontrolledMovementEndEvent());
    if !this.m_isRagdolling {
      if this.IsOutsideOfNavmeshWithTolerance(this.GetWorldPosition(), new Vector4(0.50, 0.50, 0.75, 1.00)) {
        this.QueueEvent(CreateForceRagdollEvent(n"OffNavmesh_UncontrolledStatusEffectRemoved"));
      } else {
        this.m_ragdollInstigator = null;
      };
    };
  }

  protected cb func OnCheckUncontrolledMovementStatusEffectEvent(evt: ref<CheckUncontrolledMovementStatusEffectEvent>) -> Bool {
    let removeAllStatusEffectEvent: ref<RemoveAllStatusEffectOfTypeEvent>;
    let hasStatusEffect: Bool = StatusEffectSystem.ObjectHasStatusEffectOfType(this, gamedataStatusEffectType.UncontrolledMovement);
    if hasStatusEffect {
      if this.m_isRagdolling || Vector4.Length(this.GetVelocity()) < 0.01 {
        removeAllStatusEffectEvent = new RemoveAllStatusEffectOfTypeEvent();
        removeAllStatusEffectEvent.statusEffectType = gamedataStatusEffectType.UncontrolledMovement;
        this.QueueEvent(removeAllStatusEffectEvent);
        hasStatusEffect = false;
      };
    };
    if hasStatusEffect {
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, new CheckUncontrolledMovementStatusEffectEvent(), 0.20, true);
    };
  }

  protected cb func OnCheckRagdollStateEvent(evt: ref<CheckPuppetRagdollStateEvent>) -> Bool {
    let checkRagdollEvent: ref<CheckPuppetRagdollStateEvent>;
    let moveSpeed: Float;
    let navmeshPos: Vector4;
    let needToCheckStateAgain: Bool = false;
    if this.m_isRagdolling {
      navmeshPos = this.GetWorldPosition();
      moveSpeed = Vector4.Length(this.GetVelocity());
      if moveSpeed < TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollRecoveryVelocityThreshold", 0.10) && this.m_ragdollActivationTimestamp <= 0.00 {
        this.m_ragdollActivationTimestamp = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
      };
      if moveSpeed >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollRecoveryVelocityThreshold", 0.10) || !this.CanStandUpFromRagdoll(navmeshPos) || StatusEffectSystem.ObjectHasStatusEffect(this, t"WorkspotStatus.SyncAnimation") {
        needToCheckStateAgain = true;
      };
    };
    if needToCheckStateAgain {
      checkRagdollEvent = new CheckPuppetRagdollStateEvent();
      if StatusEffectSystem.ObjectHasStatusEffect(this, t"WorkspotStatus.SyncAnimation") {
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, checkRagdollEvent, 2.00, true);
      } else {
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, checkRagdollEvent, 0.20, true);
      };
    } else {
      this.TriggerRagdollBehaviorEnd();
    };
  }

  protected cb func OnAnimVisibilityChangedEvent(evt: ref<AnimVisibilityChangedEvent>) -> Bool {
    this.m_isNotVisible = !evt.isVisible;
  }

  protected final func CanStandUpFromRagdoll(currentPosition: Vector4) -> Bool {
    let influenceMapScorePercentage: Float;
    let player: wref<GameObject>;
    if Equals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Unconscious) || StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.Unconscious") {
      if this.m_isNotVisible {
        return true;
      };
      if !GameObject.IsCooldownActive(this, n"UnconsciousRagdollFrustumCheck") {
        if Vector4.Distance(this.GetWorldPosition(), GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject().GetWorldPosition()) < 5.00 && !GameInstance.GetCameraSystem(this.GetGame()).IsInCameraFrustum(this, 0.60, 1.50) {
          return true;
        };
        GameObject.StartCooldown(this, n"UnconsciousRagdollFrustumCheck", 0.30);
      };
      return false;
    };
    player = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject();
    this.GetInfluenceMapScoreInRange(currentPosition, TweakDBInterface.GetFloat(t"AIGeneralSettings.influenceMapCheckRange", 0.60), influenceMapScorePercentage);
    if influenceMapScorePercentage <= TweakDBInterface.GetFloat(t"AIGeneralSettings.allowedInfluenceMapPercentage", 0.30) {
      return true;
    };
    if (Equals(this.GetAttitudeTowards(player), EAIAttitude.AIA_Friendly) || Equals(this.GetRecord().Priority().Type(), gamedataSpawnableObjectPriority.Quest)) && !this.IsPrevention() {
      if influenceMapScorePercentage <= TweakDBInterface.GetFloat(t"AIGeneralSettings.allowedInfluenceMapPercentageFriendly", 0.50) || EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame())) - this.m_ragdollActivationTimestamp >= TweakDBInterface.GetFloat(t"AIGeneralSettings.recoveryDespiteInfluenceMapTimeout", 3.00) {
        return true;
      };
    };
    if !this.IsUnderneathVehicle() {
      return true;
    };
    return false;
  }

  protected final func IsUnderneathVehicle() -> Bool {
    let fitTestOvelap: TraceResult;
    let hipsWorldTransform: WorldTransform;
    let overlapSuccessVehicle: Bool;
    let queryOrientation: EulerAngles;
    let queryPosition: Vector4;
    let sqs: ref<SpatialQueriesSystem>;
    let queryDimensions: array<Float> = TDB.GetFloatArray(t"AIGeneralSettings.ragdollRecoveryVehicleCheckProbeDimensions");
    let queryExtents: Vector4 = new Vector4(queryDimensions[0] * 0.50, queryDimensions[1] * 0.50, queryDimensions[2] * 0.50, queryDimensions[3]);
    this.GetSlotComponent().GetSlotTransform(n"Hips", hipsWorldTransform);
    sqs = GameInstance.GetSpatialQueriesSystem(this.GetGame());
    queryPosition = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(hipsWorldTransform));
    queryOrientation = Quaternion.ToEulerAngles(this.GetWorldOrientation());
    queryPosition.Z += queryExtents.Z + 0.10;
    overlapSuccessVehicle = sqs.Overlap(queryExtents, queryPosition, queryOrientation, n"Vehicle", fitTestOvelap);
    return overlapSuccessVehicle;
  }

  protected final func GetInfluenceMapScoreInRange(currentPosition: Vector4, range: Float, out scorePercentage: Float) -> Int32 {
    let score: Int32;
    if this.IsAnOccupiedInfluenceMapNode(currentPosition) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(range, 0.00, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(-range, 0.00, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(0.00, range, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(0.00, -range, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(range / 1.50, range / 1.50, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(-range / 1.50, -range / 1.50, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(-range / 1.50, range / 1.50, 0.00, 0.00)) {
      score += 1;
    };
    if this.IsAnOccupiedInfluenceMapNode(currentPosition + new Vector4(range / 1.50, -range / 1.50, 0.00, 0.00)) {
      score += 1;
    };
    scorePercentage = Cast<Float>(score) / 9.00;
    return score;
  }

  protected cb func OnRagdollEnabledEvent(evt: ref<RagdollNotifyEnabledEvent>) -> Bool {
    let checkRagdollEvent: ref<CheckPuppetRagdollStateEvent>;
    let navmeshProbeResults: NavigationFindPointResult;
    let ragdollInstigator: ref<GameObject>;
    this.m_isRagdolling = true;
    this.UpdateCollisionState();
    this.UpdateAnimgraphRagdollState(this.m_isRagdolling);
    navmeshProbeResults = GameInstance.GetAINavigationSystem(this.GetGame()).FindPointInBoxForCharacter(this.GetWorldPosition(), new Vector4(0.20, 0.20, 0.75, 1.00), this);
    if Equals(navmeshProbeResults.status, worldNavigationRequestStatus.OK) {
      this.m_ragdollInitialPosition = navmeshProbeResults.point;
    } else {
      this.m_ragdollInitialPosition = this.GetWorldPosition();
    };
    if this.IsCrowd() {
      this.GetCrowdMemberComponent().TryStopTrafficMovement();
    };
    ragdollInstigator = GameInstance.FindEntityByID(this.GetGame(), evt.instigator) as GameObject;
    if IsDefined(ragdollInstigator) {
      this.m_ragdollInstigator = ragdollInstigator;
    };
    if ScriptedPuppet.IsAlive(this) {
      checkRagdollEvent = new CheckPuppetRagdollStateEvent();
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, checkRagdollEvent, 1.50, true);
      GameInstance.GetStatusEffectSystem(this.GetGame()).ApplyStatusEffect(this.GetEntityID(), t"BaseStatusEffect.NonInteractable");
      this.TriggerRagdollBehavior();
    } else {
      if this.IsUnderwater(0.50) {
        NPCPuppet.SetNPCDisposedFact(this);
      } else {
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, new CheckDeadPuppetDisposedEvent(), 1.50, true);
      };
    };
  }

  protected final func UpdateAnimgraphRagdollState(isActive: Bool) -> Void {
    let headTransform: WorldTransform;
    let hipsForward: Vector4;
    let hipsLeft: Vector4;
    let hipsPolePitch: Float;
    let hipsToHead: Vector4;
    let hipsTransform: WorldTransform;
    let ragdollStateFeature: ref<AnimFeature_RagdollState> = new AnimFeature_RagdollState();
    this.GetSlotComponent().GetSlotTransform(n"Hips", hipsTransform);
    this.GetSlotComponent().GetSlotTransform(n"Head", headTransform);
    hipsToHead = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(headTransform)) - WorldPosition.ToVector4(WorldTransform.GetWorldPosition(hipsTransform));
    hipsLeft = Vector4.Cross(Quaternion.GetForward(WorldTransform.GetOrientation(hipsTransform)), hipsToHead);
    hipsForward = Vector4.Cross(hipsLeft, hipsToHead);
    hipsPolePitch = Vector4.GetAngleDegAroundAxis(Vector4.Normalize(hipsForward), new Vector4(0.00, 0.00, 1.00, 0.00), Vector4.Normalize(hipsLeft)) + 90.00;
    ragdollStateFeature.isActive = isActive;
    ragdollStateFeature.hipsPolePitch = isActive ? hipsPolePitch : 0.00;
    ragdollStateFeature.speed = isActive ? Vector4.Length(this.GetVelocity()) : 0.00;
    AnimationControllerComponent.ApplyFeatureToReplicate(this, n"ragdollState", ragdollStateFeature);
  }

  protected cb func OnCheckDeadPuppetDisposedEvent(evt: ref<CheckDeadPuppetDisposedEvent>) -> Bool {
    if this.IsUnderwater(0.50) {
      NPCPuppet.SetNPCDisposedFact(this);
    } else {
      if this.m_isRagdolling && Vector4.Length(this.GetVelocity()) >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollRecoveryVelocityThreshold", 0.10) {
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, new CheckDeadPuppetDisposedEvent(), 1.50, true);
      };
    };
  }

  public final func OnNPCThrown(nearbyCrowdNPCs: [wref<Entity>]) -> Void {
    this.m_thrownNPCNearbyCrowdNPCs = nearbyCrowdNPCs;
    EntityGameInterface.TryEnableCrowdCollider(this.m_thrownNPCNearbyCrowdNPCs);
  }

  protected cb func OnRagdollImpactEvent(evt: ref<RagdollImpactEvent>) -> Bool {
    let attackInstigator: ref<GameObject>;
    let currentPosition: Vector4;
    let damageEvent: ref<StartRagdollDamageEvent>;
    let i: Int32;
    let impactData: RagdollImpactPointData;
    let isDead: Bool;
    let isDefeated: Bool;
    let isHighFall: Bool;
    let isHitByPlayerVehicle: Bool;
    let isImpactedThrownNPC: Bool;
    let isThrownNPC: Bool;
    let otherNPCPuppet: ref<NPCPuppet>;
    let otherVehicleObject: ref<VehicleObject>;
    let player: ref<PlayerPuppet>;
    let terminalVelocityReached: Bool;
    let vehicleHitEvent: ref<gameVehicleHitEvent>;
    if evt.triggeredSimulation {
      otherVehicleObject = evt.otherEntity as VehicleObject;
      if IsDefined(otherVehicleObject) {
        vehicleHitEvent = new gameVehicleHitEvent();
        vehicleHitEvent.vehicleVelocity = otherVehicleObject.GetLinearVelocity();
        vehicleHitEvent.preyVelocity = this.GetVelocity();
        vehicleHitEvent.target = this;
        vehicleHitEvent.hitPosition = WorldPosition.ToVector4(evt.impactPoints[0].worldPosition);
        vehicleHitEvent.hitDirection = evt.impactPoints[0].worldNormal;
        vehicleHitEvent.attackData = new AttackData();
        attackInstigator = VehicleComponent.GetDriver(this.GetGame(), otherVehicleObject, otherVehicleObject.GetEntityID());
        if otherVehicleObject.IsVehicleAccelerateQuickhackActive() {
          attackInstigator = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject();
        };
        vehicleHitEvent.attackData.SetInstigator(attackInstigator);
        vehicleHitEvent.attackData.SetSource(otherVehicleObject);
        this.QueueEvent(vehicleHitEvent);
        if IsDefined(attackInstigator) {
          this.m_ragdollInstigator = attackInstigator;
        };
      };
    };
    isDead = this.IsDead() || StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.ForceKill");
    isDefeated = ScriptedPuppet.IsDefeated(this);
    isHitByPlayerVehicle = VehicleComponent.IsMountedToVehicle(this.GetGame(), GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject());
    isThrownNPC = StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.ThrownNPC");
    isImpactedThrownNPC = StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.ImpactedThrownNPC");
    player = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    otherNPCPuppet = evt.otherEntity as NPCPuppet;
    currentPosition = this.GetWorldPosition();
    i = 0;
    while i < ArraySize(evt.impactPoints) {
      impactData = evt.impactPoints[i];
      if isThrownNPC {
        if IsDefined(otherNPCPuppet) && ScriptedPuppet.IsAlive(otherNPCPuppet) && !ArrayContains(this.m_ragdollImpactedNPCs, otherNPCPuppet) {
          ArrayPush(this.m_ragdollImpactedNPCs, otherNPCPuppet);
        } else {
          this.SpawnRagdollSplatter(impactData, true);
        };
        if impactData.forceMagnitude > this.m_ragdollDamageData.maxForceMagnitude {
          this.SetRagdollDamageData(impactData, currentPosition);
        };
      } else {
        terminalVelocityReached = impactData.velocityChange >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollImpactKillVelocityThreshold", 11.00);
        isHighFall = impactData.velocityChange >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollHighFallVelocityThreshold", 8.00) && AbsF(this.m_ragdollInitialPosition.Z - currentPosition.Z) >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollHighFallHeightThreshold", 6.00);
        if IsDefined(otherNPCPuppet) && !otherNPCPuppet.IsRagdolling() && !ArrayContains(this.m_ragdollImpactedNPCs, otherNPCPuppet) {
          if Vector4.Length(this.GetVelocity()) <= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripNPCInstigatorVelThreshold", 0.20) {
            if !GameObject.IsCooldownActive(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject(), n"RagdollTripGlobalCooldown") && ScriptedPuppet.CanTripOverRagdolls(otherNPCPuppet) && this.ShouldTripVictim(otherNPCPuppet) {
              otherNPCPuppet.QueueEvent(CreateForceRagdollEvent(n"Tripped over a ragdoll"));
              GameObject.StartCooldown(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject(), n"RagdollTripGlobalCooldown", TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripGlobalCooldownDuration", 0.00));
            };
          } else {
            if !(isImpactedThrownNPC && Equals(GameObject.GetAttitudeTowards(player, otherNPCPuppet), EAIAttitude.AIA_Friendly)) && impactData.velocityChange >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollAnotherNPCVelocityThreshold", 1.00) && Equals(otherNPCPuppet.GetNPCType(), gamedataNPCType.Human) && ScriptedPuppet.CanRagdoll(otherNPCPuppet) {
              otherNPCPuppet.QueueEvent(CreateForceRagdollEvent(n"Hit by a ragdolling NPC"));
            } else {
              this.SpawnRagdollBumpAttack(WorldPosition.ToVector4(impactData.worldPosition) + Vector4.Normalize(impactData.worldNormal) * 0.05);
            };
          };
          ArrayPush(this.m_ragdollImpactedNPCs, otherNPCPuppet);
        };
        if this.CanReceiveDamageFromRagdollImpacts(isDead, isDefeated, terminalVelocityReached, isHighFall) {
          if impactData.velocityChange >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollDamageMinimumVelocity", 2.00) {
            if this.m_ragdollDamageData.maxVelocityChange == 0.00 {
              if IsDefined(attackInstigator) {
                this.m_ragdollInstigator = attackInstigator;
              };
              damageEvent = new StartRagdollDamageEvent();
              GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, damageEvent, 0.30);
            };
            if impactData.velocityChange > this.m_ragdollDamageData.maxVelocityChange {
              this.SetRagdollDamageData(impactData, currentPosition);
            };
          };
        } else {
          if isHitByPlayerVehicle && (isDefeated || isDead) {
            this.SpawnRagdollSplatter(impactData, isDead);
          };
        };
        if !this.m_ragdollFloorSplashSpawned && (terminalVelocityReached || isHighFall) {
          this.SpawnRagdollFloorSplash(impactData);
        };
      };
      i += 1;
    };
    if isThrownNPC {
      this.OnThrownNPCRagdollImpact();
    };
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"OnePunchedMark") {
      GameObjectEffectHelper.StartEffectEvent(this, n"blood_nose_punch_strong");
      this.SpawnRagdollSplatter(impactData, isDead);
    };
  }

  protected final func ShouldTripVictim(victim: ref<NPCPuppet>) -> Bool {
    let angle: Float = Vector4.GetAngleDegAroundAxis(victim.GetWorldForward(), victim.GetVelocity(), this.GetWorldUp());
    if AbsF(angle) <= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripForwardAngle", 90.00) {
      if Vector4.Length(victim.GetVelocity()) >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripVictimForwardVelMin", 4.00) && RandRangeF(0.00, 100.00) <= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripVictimForwardChance", 0.00) {
        return true;
      };
    } else {
      if Vector4.Length(victim.GetVelocity()) >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripVictimBackwardVelMin", 0.10) && RandRangeF(0.00, 100.00) <= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollTripVictimBackwardChance", 100.00) {
        return true;
      };
    };
    return false;
  }

  protected final func CanReceiveDamageFromRagdollImpacts(isDead: Bool, isDefeated: Bool, terminalVelocityReached: Bool, isHighFall: Bool) -> Bool {
    if !isDead && !isDefeated && !this.IsCrowd() && !this.IsBoss() && NotEquals(this.GetNPCRarity(), gamedataNPCRarity.MaxTac) {
      return true;
    };
    if (this.IsCrowd() || Equals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Unconscious)) && (terminalVelocityReached || isHighFall) {
      return true;
    };
    return false;
  }

  protected final func SpawnRagdollBumpAttack(position: Vector4) -> Void {
    let attackContext: AttackInitContext;
    let effect: ref<EffectInstance>;
    let statMods: array<ref<gameStatModifierData>>;
    attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.RagdollBump");
    attackContext.instigator = this;
    attackContext.source = this;
    let attack: ref<Attack_GameEffect> = IAttack.Create(attackContext) as Attack_GameEffect;
    attack.GetStatModList(statMods);
    effect = attack.PrepareAttack(this);
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.range, attackContext.record.Range());
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, attackContext.record.Range());
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, position);
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    attack.StartAttack();
  }

  protected final func SpawnRagdollFloorSplash(const evt: script_ref<RagdollImpactPointData>) -> Void {
    let spawnedEffect: ref<FxInstance>;
    let splashTransform: WorldTransform;
    let transformMatrix: Matrix;
    let transformQuaternion: Quaternion;
    let splashResource: FxResource = this.GetFxResourceByKey(n"ragdollFloorSplash");
    let orientation: Quaternion = Quaternion.BuildFromDirectionVector(Deref(evt).worldNormal, this.GetWorldUp());
    Quaternion.SetAxisAngle(transformQuaternion, new Vector4(1.00, 0.00, 0.00, 0.00), Deg2Rad(-90.00));
    orientation *= transformQuaternion;
    transformMatrix = Quaternion.ToMatrix(orientation);
    transformMatrix *= Matrix.BuiltTranslation(WorldPosition.ToVector4(Deref(evt).worldPosition));
    WorldTransform.SetPosition(splashTransform, Matrix.GetTranslation(transformMatrix));
    WorldTransform.SetOrientation(splashTransform, Matrix.ToQuat(transformMatrix));
    spawnedEffect = GameInstance.GetFxSystem(this.GetGame()).SpawnEffectOnGround(splashResource, splashTransform, 0.50);
    if !IsDefined(spawnedEffect) {
      GameInstance.GetFxSystem(this.GetGame()).SpawnEffect(splashResource, splashTransform, true);
    };
    GameObject.PlaySoundEvent(this, n"gmp_ragdoll_floor_splash");
    this.m_ragdollFloorSplashSpawned = true;
  }

  protected final func SpawnRagdollSplatter(const impactData: script_ref<RagdollImpactPointData>, isDead: Bool) -> Void {
    let allowedActors: array<Int32>;
    let orientation: Quaternion;
    let splatterChance: Float;
    let splatterResource: FxResource;
    let splatterTransform: WorldTransform;
    let transformMatrix: Matrix;
    let transformQuaternion: Quaternion;
    let allowedAmountOfSplatters: Int32 = TweakDBInterface.GetInt(t"AIGeneralSettings.maximumRagdollSplattersPerNPC", -1);
    if allowedAmountOfSplatters >= 0 && this.m_ragdollSplattersSpawned >= allowedAmountOfSplatters {
      return;
    };
    if Deref(impactData).forceMagnitude < TweakDBInterface.GetFloat(t"AIGeneralSettings.vehicleHitBloodSplatterThreshold", 500.00) {
      return;
    };
    allowedActors = TDB.GetIntArray(t"AIGeneralSettings.vehicleHitBloodSplatterAllowedActors");
    if ArraySize(allowedActors) > 0 && !ArrayContains(allowedActors, Cast<Int32>(Deref(impactData).ragdollProxyActorIndex)) {
      return;
    };
    if !this.IsPointOnStaticMesh(WorldPosition.ToVector4(Deref(impactData).worldPosition), Deref(impactData).worldNormal) {
      return;
    };
    if isDead {
      splatterChance = GameInstance.GetStatsDataSystem(this.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", Cast<Float>(this.m_ragdollSplattersSpawned), n"dead_puppet_blood_splatter_chance");
    } else {
      splatterChance = GameInstance.GetStatsDataSystem(this.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", Cast<Float>(this.m_ragdollSplattersSpawned), n"defeated_puppet_blood_splatter_chance");
    };
    if RandF() >= splatterChance {
      return;
    };
    splatterResource = this.GetFxResourceByKey(n"ragdollWallSplatter");
    orientation = Quaternion.BuildFromDirectionVector(Deref(impactData).worldNormal, this.GetWorldUp());
    Quaternion.SetAxisAngle(transformQuaternion, new Vector4(1.00, 0.00, 0.00, 0.00), Deg2Rad(-90.00));
    orientation *= transformQuaternion;
    transformMatrix = Quaternion.ToMatrix(orientation);
    transformMatrix *= Matrix.BuiltTranslation(WorldPosition.ToVector4(Deref(impactData).worldPosition));
    WorldTransform.SetPosition(splatterTransform, Matrix.GetTranslation(transformMatrix));
    WorldTransform.SetOrientation(splatterTransform, Matrix.ToQuat(transformMatrix));
    GameInstance.GetFxSystem(this.GetGame()).SpawnEffect(splatterResource, splatterTransform, true);
    this.m_ragdollSplattersSpawned += 1;
    if !IsFinal() {
      this.Debug_Ragdoll();
    };
  }

  protected final func IsPointOnStaticMesh(position: Vector4, normal: Vector4) -> Bool {
    let geometryDescription: ref<GeometryDescriptionQuery>;
    let geometryDescriptionResult: ref<GeometryDescriptionResult>;
    let staticQueryFilter: QueryFilter;
    QueryFilter.AddGroup(staticQueryFilter, n"Static");
    geometryDescription = new GeometryDescriptionQuery();
    geometryDescription.refPosition = position + Vector4.Normalize(normal) * 0.10;
    geometryDescription.refDirection = -normal;
    geometryDescription.filter = staticQueryFilter;
    geometryDescription.primitiveDimension = new Vector4(0.10, 0.10, 0.10, 0.00);
    geometryDescription.maxDistance = 0.50;
    geometryDescription.maxExtent = 0.50;
    geometryDescription.probingPrecision = 0.05;
    geometryDescription.probingMaxDistanceDiff = 0.50;
    geometryDescriptionResult = GameInstance.GetSpatialQueriesSystem(this.GetGame()).GetGeometryDescriptionSystem().QueryExtents(geometryDescription);
    return Equals(geometryDescriptionResult.queryStatus, worldgeometryDescriptionQueryStatus.OK);
  }

  protected final func Debug_Ragdoll() -> Void {
    let sink: SDOSink = GameInstance.GetScriptsDebugOverlaySystem(this.GetGame()).CreateSink();
    SDOSink.SetRoot(sink, "NPCRagdolls/[NPC: " + ToString(this.GetEntityID()) + "]");
    SDOSink.PushInt32(sink, "Total splatters spawned", this.m_ragdollSplattersSpawned);
  }

  protected cb func OnStartRagdollDamageEvent(inEvent: ref<StartRagdollDamageEvent>) -> Bool {
    let attackContext: AttackInitContext;
    let ragdollInstigator: wref<GameObject>;
    attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.RagdollImpact");
    attackContext.instigator = this.GetRagdollInstigator(ragdollInstigator) ? ragdollInstigator : this;
    attackContext.source = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject();
    let attack: ref<IAttack> = IAttack.Create(attackContext);
    let evt: ref<gameRagdollHitEvent> = new gameRagdollHitEvent();
    evt.target = this;
    evt.hitPosition = WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition);
    evt.hitDirection = this.m_ragdollDamageData.worldNormal;
    evt.attackData = new AttackData();
    evt.attackData.AddFlag(hitFlag.RagdollImpact, n"Ragdoll impact");
    evt.attackData.AddFlag(hitFlag.CanDamageSelf, n"Ragdoll impact");
    evt.attackData.AddFlag(hitFlag.DeterministicDamage, n"Ragdoll impact");
    evt.attackData.AddFlag(hitFlag.CannotModifyDamage, n"Ragdoll impact");
    evt.attackData.SetInstigator(attackContext.instigator);
    evt.attackData.SetSource(this);
    evt.attackData.SetAttackDefinition(attack);
    evt.impactForce = this.m_ragdollDamageData.maxForceMagnitude;
    evt.speedDelta = this.m_ragdollDamageData.maxVelocityChange;
    evt.heightDelta = this.m_ragdollDamageData.maxZDiff;
    GameInstance.GetDamageSystem(this.GetGame()).QueueHitEvent(evt, this);
    this.ResetRagdollDamageData();
  }

  protected final func OnThrownNPCRagdollImpact() -> Void {
    let attack: ref<Attack_GameEffect>;
    let attackContext: AttackInitContext;
    let broadcaster: ref<StimBroadcasterComponent>;
    let cleanUpNearbyNPCsEvent: ref<CleanUpThrownNPCNearbyCrowdNPCs>;
    let critThrowMaxDamageThreshold: Float;
    let critThrowThreshold: Float;
    let effect: ref<EffectInstance>;
    let investigateData: stimInvestigateData;
    let randForcedDismemberment: Int32;
    let throwDamageMultiplier: Float;
    let throwDistance: Float;
    let throwHitFlag: SHitFlag;
    let throwHitFlags: array<SHitFlag>;
    let playerPuppet: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.ImpactedThrownNPC");
    throwDamageMultiplier = 0.80;
    throwDistance = Vector4.Length(playerPuppet.GetWorldPosition() - WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
    critThrowThreshold = 30.00;
    if throwDistance > critThrowThreshold {
      critThrowMaxDamageThreshold = 40.00;
      throwDamageMultiplier *= LerpF((throwDistance - critThrowThreshold) / (critThrowMaxDamageThreshold - critThrowThreshold), 1.50, 2.00, true);
      throwHitFlag.flag = hitFlag.CriticalHit;
      throwHitFlag.source = n"Far ThrownNPC";
      ArrayPush(throwHitFlags, throwHitFlag);
      throwHitFlag.flag = hitFlag.CriticalHitNoDamageModifier;
      throwHitFlag.source = n"Far ThrownNPC";
      ArrayPush(throwHitFlags, throwHitFlag);
      EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.flags, ToVariant(throwHitFlags));
    };
    attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.ThrownNPCImpact");
    attackContext.instigator = playerPuppet;
    attackContext.source = this;
    attack = IAttack.Create(attackContext) as Attack_GameEffect;
    attack.AddStatModifier(RPGManager.CreateCombinedStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Additive, gamedataStatType.Health, gameCombinedStatOperation.Multiplication, throwDamageMultiplier, gameStatObjectsRelation.Root));
    effect = attack.PrepareAttack(playerPuppet);
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.range, attackContext.record.Range());
    EffectData.SetFloat(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.radius, attackContext.record.Range());
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    if ArraySize(throwHitFlags) > 0 {
      EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.flags, ToVariant(throwHitFlags));
    };
    attack.StartAttack();
    GameObject.PlaySoundEvent(this, n"w_melee_finisher_savage_sling_throw_impact");
    if ArraySize(this.m_ragdollImpactedNPCs) > 0 {
      GameObject.PlaySoundEvent(this, n"w_melee_finisher_savage_sling_throw_impact_npc");
    };
    broadcaster = this.GetStimBroadcasterComponent();
    if IsDefined(broadcaster) {
      investigateData.attackInstigator = playerPuppet;
      investigateData.attackInstigatorPosition = playerPuppet.GetWorldPosition();
      investigateData.revealsInstigatorPosition = true;
      broadcaster.TriggerSingleBroadcast(this, gamedataStimType.Explosion, 30.00, investigateData);
    };
    if this.m_ragdollDamageData.maxForceMagnitude >= 10000.00 {
      randForcedDismemberment = RandRange(0, 4);
      if randForcedDismemberment == 0 || RandF() < 0.30 {
        DismembermentComponent.RequestDismemberment(this, gameDismBodyPart.LEFT_ARM, gameDismWoundType.COARSE, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
      };
      if randForcedDismemberment == 1 || RandF() < 0.30 {
        DismembermentComponent.RequestDismemberment(this, gameDismBodyPart.RIGHT_ARM, gameDismWoundType.COARSE, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
      };
      if randForcedDismemberment == 2 || RandF() < 0.30 {
        DismembermentComponent.RequestDismemberment(this, gameDismBodyPart.LEFT_LEG, gameDismWoundType.COARSE, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
      };
      if randForcedDismemberment == 3 || RandF() < 0.30 {
        DismembermentComponent.RequestDismemberment(this, gameDismBodyPart.RIGHT_LEG, gameDismWoundType.COARSE, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
      };
      if RandRangeF(0.00, 1.00) < 0.15 {
        DismembermentComponent.RequestDismemberment(this, gameDismBodyPart.HEAD, gameDismWoundType.COARSE, WorldPosition.ToVector4(this.m_ragdollDamageData.worldPosition));
      };
    };
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.ThrownNPC");
    this.ResetRagdollDamageData();
    cleanUpNearbyNPCsEvent = new CleanUpThrownNPCNearbyCrowdNPCs();
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, cleanUpNearbyNPCsEvent, 1.00);
  }

  protected final func SetRagdollDamageData(const ragdollImpactPointData: RagdollImpactPointData, const currentPosition: Vector4) -> Void {
    this.m_ragdollDamageData.worldPosition = ragdollImpactPointData.worldPosition;
    this.m_ragdollDamageData.worldNormal = ragdollImpactPointData.worldNormal;
    this.m_ragdollDamageData.maxVelocityChange = ragdollImpactPointData.velocityChange;
    this.m_ragdollDamageData.maxImpulseMagnitude = ragdollImpactPointData.maxImpulseMagnitude;
    this.m_ragdollDamageData.maxForceMagnitude = ragdollImpactPointData.maxForceMagnitude;
    this.m_ragdollDamageData.maxZDiff = AbsF(this.m_ragdollInitialPosition.Z - currentPosition.Z);
  }

  protected final func ResetRagdollDamageData() -> Void {
    this.m_ragdollDamageData.worldPosition = new WorldPosition();
    this.m_ragdollDamageData.worldNormal = new Vector4();
    this.m_ragdollDamageData.maxForceMagnitude = 0.00;
    this.m_ragdollDamageData.maxImpulseMagnitude = 0.00;
    this.m_ragdollDamageData.maxVelocityChange = 0.00;
    this.m_ragdollDamageData.maxZDiff = 0.00;
  }

  public final func GetRagdollInstigator(out ragdollInstigator: wref<GameObject>) -> Bool {
    let ragdollSE: ref<StatusEffect>;
    ragdollInstigator = this.m_ragdollInstigator;
    if IsDefined(ragdollInstigator) {
      return true;
    };
    ragdollSE = StatusEffectHelper.GetTopPriorityEffect(this, gamedataStatusEffectType.UncontrolledMovement);
    if IsDefined(ragdollSE) {
      ragdollInstigator = GameInstance.FindEntityByID(this.GetGame(), ragdollSE.GetInstigatorEntityID()) as GameObject;
      if IsDefined(ragdollInstigator) {
        return true;
      };
    };
    return false;
  }

  protected cb func OnRagdollDisabledEvent(evt: ref<RagdollNotifyDisabledEvent>) -> Bool {
    this.m_isRagdolling = false;
    this.m_ragdollActivationTimestamp = -1.00;
    ArrayClear(this.m_ragdollImpactedNPCs);
    this.UpdateCollisionState(true);
    this.UpdateAnimgraphRagdollState(this.m_isRagdolling);
    this.m_ragdollInstigator = null;
    if this.m_disableRagdollAfterRecovery {
      this.SetDisableRagdoll(true);
      this.m_disableRagdollAfterRecovery = false;
    };
  }

  protected cb func OnAnimatedRagdollEnabledEvent(evt: ref<AnimatedRagdollNotifyEnabledEvent>) -> Bool {
    let distanceVector: Vector4;
    let hitAngle: Float;
    let hitDirection: Int32;
    let invistigator: ref<ScriptedPuppet>;
    let invistigatorVehicle: wref<VehicleObject>;
    let npcOrientation: Vector4;
    let turnOnRagdollEvent: ref<RagdollToggleDelayEvent>;
    this.m_hasAnimatedRagdoll = true;
    this.UpdateCollisionState();
    if NotEquals(this.GetNPCType(), gamedataNPCType.Human) || this.IsRagdolling() || GameObject.IsCooldownActive(this, n"bumpStaggerCooldown") {
      return IsDefined(null);
    };
    invistigator = GameInstance.FindEntityByID(this.GetGame(), evt.instigator) as ScriptedPuppet;
    if IsDefined(invistigator) && VehicleComponent.IsMountedToVehicle(this.GetGame(), invistigator) {
      VehicleComponent.GetVehicle(this.GetGame(), evt.instigator, invistigatorVehicle);
      if invistigatorVehicle.GetBlackboard().GetFloat(GetAllBlackboardDefs().Vehicle.SpeedValue) < TDB.GetFloat(t"AIGeneralSettings.vehicleStaggerSpeedThreshold") && !this.IsRagdolling() && !GameObject.IsCooldownActive(this, n"bumpStaggerCooldown") {
        GameObject.StartCooldown(this, n"bumpStaggerCooldown", 1.00);
        npcOrientation = this.GetWorldForward();
        distanceVector = invistigatorVehicle.GetWorldPosition() - this.GetWorldPosition();
        hitAngle = Vector4.GetAngleDegAroundAxis(npcOrientation, distanceVector, this.GetWorldUp());
        if AbsF(hitAngle) <= 45.00 {
          hitDirection = 3;
          hitDirection = 4;
        } else {
          if AbsF(hitAngle) >= 135.00 {
            hitDirection = 1;
            hitDirection = 2;
          } else {
            if hitAngle > 45.00 && hitAngle < 135.00 {
              hitDirection = 0;
              hitDirection = 1;
            } else {
              hitDirection = 2;
              hitDirection = 3;
            };
          };
        };
        AISubActionForceHitReaction_Record_Implementation.SendForcedHitDataToAIBehavior(this, hitDirection, 1, 3, 5, 0, 0, 2);
        this.SpawnVehicleBumpAttack(invistigatorVehicle, invistigator);
        turnOnRagdollEvent = new RagdollToggleDelayEvent();
        turnOnRagdollEvent.target = this;
        turnOnRagdollEvent.enable = true;
        if this.m_npcRagdollComponent.IsEnabled() && !this.CanEnableRagdollComponent() {
          turnOnRagdollEvent.force = true;
          turnOnRagdollEvent.leaveRagdollEnabled = true;
        };
        this.SetDisableRagdoll(true);
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, turnOnRagdollEvent, TweakDBInterface.GetFloat(t"AIGeneralSettings.vehicleStaggerRagdollImmunity", 0.15), true);
      };
    };
  }

  protected final func IsCloseEnoughForGrandFinale(target: wref<GameObject>, maxDistance: Float) -> Bool {
    let playerPos: Vector4 = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject().GetWorldPosition();
    let targetPosition: Vector4 = target.GetWorldPosition();
    let distance: Float = Vector4.Length(targetPosition - playerPos);
    return distance <= maxDistance;
  }

  protected cb func OnApplyRelicMeleewareDamageOnNPCEvent(evt: ref<ApplyRelicMeleewareDamageOnNPCEvent>) -> Bool {
    if Equals(evt.weaponType, gamedataItemType.Cyb_StrongArms) && this.IsCloseEnoughForGrandFinale(evt.target, 1.25) {
      evt.newHitEvent.hitPosition = evt.target.GetHitReactionComponent().GetHitPosition();
      GameInstance.GetDamageSystem(evt.target.GetGame()).QueueHitEvent(evt.newHitEvent, evt.target);
      GameObjectEffectHelper.StartEffectEvent(evt.weapon, n"spy_strong_arms_one_punch_impact");
      GameObject.PlaySoundEvent(evt.weapon, n"w_cyb_strongarms_spy_perk_hit");
      GameObjectEffectHelper.StartEffectEvent(evt.target, n"spy_strong_arms_force");
      GameObjectEffectHelper.StartEffectEvent(evt.target, n"one_punch_impact");
      if NPCPuppet.TargetIsHumanTrashToElite(evt.target) {
        StatusEffectHelper.ApplyStatusEffect(evt.target, t"BaseStatusEffect.GorillaArmsOnePunchNPCMark");
      };
    };
    if Equals(evt.weaponType, gamedataItemType.Cyb_MantisBlades) && this.IsCloseEnoughForGrandFinale(evt.target, 3.50) {
      GameInstance.GetDamageSystem(evt.target.GetGame()).QueueHitEvent(evt.newHitEvent, evt.target);
      if NPCPuppet.TargetIsHumanTrashToElite(evt.target) {
        StatusEffectHelper.ApplyStatusEffect(evt.target, t"BaseStatusEffect.MantisBladesGrandFinaleNPCMark");
      };
    };
  }

  protected final static func TargetIsHumanTrashToElite(target: ref<ScriptedPuppet>) -> Bool {
    return Equals(target.GetNPCType(), gamedataNPCType.Human) && NotEquals(target.GetNPCRarity(), gamedataNPCRarity.Boss);
  }

  protected final static func GetGorillaArmsOnePunchNPCMarkStatusEffectID() -> TweakDBID {
    return t"BaseStatusEffect.GorillaArmsOnePunchNPCMark";
  }

  protected final static func GetMantisBladesNPCMarkStatusEffectID() -> TweakDBID {
    return t"BaseStatusEffect.MantisBladesGrandFinaleNPCMark";
  }

  public final func SpawnVehicleBumpAttack(vehicle: wref<VehicleObject>, instigator: wref<GameObject>) -> Void {
    let hipsTransform: WorldTransform;
    let vehicleHitEvent: ref<gameVehicleHitEvent> = new gameVehicleHitEvent();
    vehicleHitEvent.vehicleVelocity = vehicle.GetLinearVelocity();
    vehicleHitEvent.preyVelocity = this.GetVelocity();
    this.GetSlotComponent().GetSlotTransform(n"Hips", hipsTransform);
    vehicleHitEvent.target = this;
    vehicleHitEvent.hitPosition = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(hipsTransform));
    vehicleHitEvent.hitDirection = this.GetWorldPosition() - vehicle.GetWorldPosition();
    vehicleHitEvent.attackData = new AttackData();
    if vehicle.IsVehicleRemoteControlled() || vehicle.IsVehicleAccelerateQuickhackActive() {
      instigator = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject();
    };
    vehicleHitEvent.attackData.SetInstigator(instigator);
    vehicleHitEvent.attackData.SetSource(vehicle);
    this.QueueEvent(vehicleHitEvent);
  }

  protected cb func OnAnimatedRagdollDisabledEvent(evt: ref<AnimatedRagdollNotifyDisabledEvent>) -> Bool {
    this.m_hasAnimatedRagdoll = false;
    this.UpdateCollisionState(true);
  }

  protected final func IsOutsideOfNavmesh(currentPosition: Vector4) -> Bool {
    return !GameInstance.GetAINavigationSystem(this.GetGame()).IsPointOnNavmesh(this, currentPosition, new Vector4(0.20, 0.20, 0.75, 1.00));
  }

  protected final func IsOutsideOfNavmeshWithTolerance(currentPosition: Vector4, tolerance: Vector4) -> Bool {
    return !GameInstance.GetAINavigationSystem(this.GetGame()).IsPointOnNavmesh(this, currentPosition, tolerance);
  }

  protected final func IsOutsideOfNavmesh(currentPosition: Vector4, out navmeshPoint: Vector4) -> Bool {
    return !GameInstance.GetAINavigationSystem(this.GetGame()).IsPointOnNavmesh(this, currentPosition, new Vector4(0.20, 0.20, 0.75, 1.00), navmeshPoint);
  }

  protected final func IsAnOccupiedInfluenceMapNode(currentPosition: Vector4) -> Bool {
    return Equals(this.GetInfluenceComponent().IsPositionEmpty(currentPosition), gameinfluenceCollisionTestOutcome.Full);
  }

  protected final func TriggerRagdollBehavior() -> Void {
    let signal: AIGateSignal;
    signal.priority = 10.00;
    signal.lifeTime = 100.00;
    AIGateSignal.AddTag(signal, n"Ragdoll");
    this.GetSignalHandlerComponent().AddSignal(signal, false);
  }

  protected final func TriggerRagdollBehaviorEnd() -> Void {
    let signal: AIGateSignal;
    signal.priority = 100.00;
    signal.lifeTime = 100.00;
    AIGateSignal.AddTag(signal, n"RagdollEnd");
    AIGateSignal.AddFlag(signal, AISignalFlags.InterruptsSamePriorityTask);
    this.GetSignalHandlerComponent().AddSignal(signal, false);
  }

  public final const func IsRagdolling() -> Bool {
    return this.m_isRagdolling;
  }

  public final const func IsRagdollEnabled() -> Bool {
    return this.m_isRagdolling || this.m_hasAnimatedRagdoll;
  }

  public final const func GetInitialRagdollPosition() -> Vector4 {
    return this.m_ragdollInitialPosition;
  }

  public final const func KillIfUnderwater() -> Bool {
    if this.HasHeadUnderwater() {
      this.PuppetSubmergedRequestRemovingStatusEffects(this);
      if StatusEffectHelper.HasStatusEffectFromInstigator(this, t"BaseStatusEffect.Unconscious", this.GetPlayerID()) || StatusEffectHelper.HasStatusEffectFromInstigator(this, t"BaseStatusEffect.Defeated", this.GetPlayerID()) {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.ForceKill", this.GetPlayerID());
      } else {
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.ForceKill");
      };
      NPCPuppet.SetNPCDisposedFact(this);
    };
    return false;
  }

  public const func HasHeadUnderwater() -> Bool {
    let checkPosition: Vector4;
    let headTransform: WorldTransform;
    let waterLevel: Float;
    let slotComponent: ref<SlotComponent> = this.GetSlotComponent();
    if IsDefined(slotComponent) && slotComponent.GetSlotTransform(n"Head", headTransform) {
      checkPosition = WorldPosition.ToVector4(WorldTransform.GetWorldPosition(headTransform));
    } else {
      checkPosition = this.GetWorldPosition();
    };
    if AIScriptUtils.GetWaterLevel(this.GetGame(), Vector4.Vector4To3(checkPosition), waterLevel) {
      if checkPosition.Z - waterLevel <= TDB.GetFloat(t"AIGeneralSettings.underwaterDepthKillThreshold") {
        return true;
      };
    };
    return false;
  }

  protected cb func OnRagdollBodyPartWaterImpactEvent(evt: ref<RagdollBodyPartWaterImpactEvent>) -> Bool {
    let impulseRadius: Float;
    let impulseStrength: Float;
    let impulseStrengthMax: Float;
    let impulseStrengthMin: Float;
    let speedPercentage: Float;
    let waterSplashInstance: ref<FxInstance>;
    let waterSplashPosition: Vector4;
    let waterSplashResource: FxResource;
    let waterSplashTransform: WorldTransform;
    let currentSpeed: Float = Vector4.Length(evt.linearVelocity);
    let maxSpeed: Float = TDB.GetFloat(t"player.locomotion.maxAirXYSpeed");
    if currentSpeed >= 2.00 {
      GameObject.PlaySound(this, evt.isTorso ? n"w_melee_water_medium_splash" : n"w_bul_hit_water");
      waterSplashResource = this.GetFxResourceByKey(evt.isTorso ? n"ragdollTorsoWaterSplash" : n"ragdollExtremityWaterSplash");
      if FxResource.IsValid(waterSplashResource) {
        waterSplashPosition = evt.worldPosition;
        waterSplashPosition.Z -= evt.depthBelowSurface;
        WorldTransform.SetPosition(waterSplashTransform, waterSplashPosition);
        waterSplashInstance = GameInstance.GetFxSystem(this.GetGame()).SpawnEffect(waterSplashResource, waterSplashTransform);
        waterSplashInstance.SetBlackboardValue(n"ragdoll_body_part_speed", ProportionalClampF(0.00, maxSpeed, currentSpeed, 0.00, 1.00));
      };
    };
    if currentSpeed >= 0.10 {
      if evt.isTorso {
        impulseRadius = 0.50;
        impulseStrengthMin = 0.00;
        impulseStrengthMax = 0.01;
      } else {
        impulseRadius = 0.20;
        impulseStrengthMin = 0.00;
        impulseStrengthMax = 0.00;
      };
      speedPercentage = FloatIsEqual(maxSpeed, 0.00) ? 0.00 : ClampF(currentSpeed / maxSpeed, 0.00, 1.00);
      impulseStrength = LerpF(speedPercentage, impulseStrengthMin, impulseStrengthMax);
      RenderingSystem.AddWaterImpulse(evt.worldPosition, impulseRadius, impulseStrength);
    };
  }

  protected cb func OnAttitudeChanged(evt: ref<AttitudeChangedEvent>) -> Bool {
    let threat: wref<GameObject>;
    if this.IsPrevention() && NotEquals(evt.attitude, EAIAttitude.AIA_Hostile) {
      threat = evt.otherAgent.GetEntity() as GameObject;
      if IsDefined(threat) {
        this.TriggerSecuritySystemNotification(threat.GetWorldPosition(), threat, ESecurityNotificationType.DEESCALATE);
      };
    };
  }

  protected cb func OnHit(evt: ref<gameHitEvent>) -> Bool {
    super.OnHit(evt);
  }

  protected func DamagePipelineFinalized(evt: ref<gameHitEvent>) -> Void {
    let maxHealth: Float;
    let overallChance: Float;
    let percentageMaxHealth: Float;
    let totalAttackValue: Float;
    let vehicleMounted: wref<VehicleObject>;
    if VehicleComponent.IsMountedToVehicle(this.GetGame(), this) {
      VehicleComponent.GetVehicle(this.GetGame(), this, vehicleMounted);
      if VehicleComponent.GetDriver(this.GetGame(), vehicleMounted, vehicleMounted.GetEntityID()) == this {
        totalAttackValue = evt.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
        maxHealth = GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolMaxPointValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health);
        percentageMaxHealth = MinF(totalAttackValue / maxHealth, 1.00);
        overallChance = GameInstance.GetStatsDataSystem(this.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", percentageMaxHealth, n"ChanceCauseDriverLoseControl");
        if RandF() <= overallChance {
          vehicleMounted.ActivateTemporaryLossOfControl();
        };
      };
    };
    super.DamagePipelineFinalized(evt);
  }

  protected cb func OnScanningLookedAt(evt: ref<ScanningLookAtEvent>) -> Bool {
    super.OnScanningLookedAt(evt);
    if evt.state {
      this.m_playerStatsListener = new PlayerStatsListener();
      GameInstance.GetStatsSystem(this.GetGame()).RegisterListener(Cast<StatsObjectID>(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject().GetEntityID()), this.m_playerStatsListener);
    } else {
      GameInstance.GetStatsSystem(this.GetGame()).UnregisterListener(Cast<StatsObjectID>(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject().GetEntityID()), this.m_playerStatsListener);
      this.m_playerStatsListener = null;
    };
  }

  protected cb func OnRevealStateChanged(evt: ref<RevealStateChangedEvent>) -> Bool {
    super.OnRevealStateChanged(evt);
    this.SendRevealStateToAllWeakspots(evt.state);
  }

  protected final func SendRevealStateToAllWeakspots(revealState: ERevealState) -> Void {
    let evt: ref<RevealStateChangedEvent>;
    let i: Int32;
    let weakspots: array<wref<WeakspotObject>>;
    this.GetWeakspotComponent().GetWeakspots(weakspots);
    i = 0;
    while i < ArraySize(weakspots) {
      evt = new RevealStateChangedEvent();
      evt.state = revealState;
      weakspots[i].QueueEvent(evt);
      i += 1;
    };
  }

  protected cb func OnSetupWorkspotActionEvent(evt: ref<SetupWorkspotActionEvent>) -> Bool {
    this.m_lastSetupWorkspotActionEvent = evt;
  }

  private final func SetHitEventData(hitEvent: ref<gameHitEvent>, hitReactionFactor: Float, hitWoundsFactor: Float, hitDismembermentFactor: Float) -> Void {
    RWLock.Acquire(this.m_hitEventLock);
    this.m_lastHitEvent = hitEvent;
    if !hitEvent.attackData.HasFlag(hitFlag.DealNoDamage) || !ScriptedPuppet.IsAlive(this) || ScriptedPuppet.IsDefeated(this) {
      if ScriptedPuppet.IsAlive(this) {
        this.m_totalFrameReactionDamageReceived = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) * hitReactionFactor;
        this.m_totalFrameWoundsDamageReceived = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) * hitWoundsFactor;
      };
      this.m_totalFrameDismembermentDamageReceived = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) * hitDismembermentFactor;
    } else {
      this.m_totalFrameReactionDamageReceived = 0.00;
      this.m_totalFrameWoundsDamageReceived = 0.00;
      this.m_totalFrameDismembermentDamageReceived = 0.00;
    };
    RWLock.Release(this.m_hitEventLock);
  }

  private final func OnHitAnimation(hitEvent: ref<gameHitEvent>) -> Void {
    let attackWeaponID: StatsObjectID;
    let hitDismembermentFactor: Float;
    let hitReactionFactor: Float;
    let hitWoundsFactor: Float;
    let statsSystem: ref<StatsSystem>;
    let attackWeapon: wref<GameObject> = hitEvent.attackData.GetWeapon();
    if !this.ShouldRequestHitReaction(hitEvent) {
      return;
    };
    hitReactionFactor = 1.00;
    if IsDefined(attackWeapon) {
      statsSystem = GameInstance.GetStatsSystem(attackWeapon.GetGame());
      attackWeaponID = Cast<StatsObjectID>(attackWeapon.GetEntityID());
      hitReactionFactor = statsSystem.GetStatValue(attackWeaponID, gamedataStatType.HitReactionFactor);
      hitWoundsFactor = statsSystem.GetStatValue(attackWeaponID, gamedataStatType.HitWoundsFactor);
      hitDismembermentFactor = statsSystem.GetStatValue(attackWeaponID, gamedataStatType.HitDismembermentFactor);
    };
    if Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Explosion) {
      hitReactionFactor = 2.00;
    } else {
      if hitReactionFactor < 1.00 && this.GetPuppetStateBlackboard().GetBool(GetAllBlackboardDefs().PuppetState.InAirAnimation) {
        hitReactionFactor = 1.00;
      };
    };
    this.SetHitEventData(hitEvent, hitReactionFactor, hitWoundsFactor, hitDismembermentFactor);
    this.RequestHitReaction(hitEvent);
    super.OnHitAnimation(hitEvent);
  }

  protected cb func OnResetAttackBlockedBlackBoardValue(evt: ref<ResetAttackBlockedBlackBoardValue>) -> Bool {
    this.GetAIControllerComponent().GetActionBlackboard().SetBool(GetAllBlackboardDefs().AIAction.attackBlocked, false);
    this.GetAIControllerComponent().GetActionBlackboard().SetBool(GetAllBlackboardDefs().AIAction.attackParried, false);
  }

  private final const func ShouldRequestHitReaction(hitEvent: ref<gameHitEvent>) -> Bool {
    if AttackData.IsEffect(hitEvent.attackData.GetAttackType()) && !hitEvent.attackData.HasFlag(hitFlag.VehicleDamage) {
      return false;
    };
    if hitEvent.attackData.WasBlocked() || hitEvent.attackData.WasDeflectedAny() {
      return true;
    };
    if hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) >= 0.00 {
      return true;
    };
    if Equals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Dead) {
      return true;
    };
    return false;
  }

  private final func RequestHitReaction(hitEvent: ref<gameHitEvent>) -> Void {
    let evt: ref<HitReactionRequest> = new HitReactionRequest();
    evt.hitEvent = hitEvent;
    this.QueueEvent(evt);
  }

  private final func OnHitSounds(hitEvent: ref<gameHitEvent>) -> Void {
    let criticalDamageThreshold: Float;
    let highDamageThreshold: Float;
    let medDamageThreshold: Float;
    let metadataEvent: ref<AudioEvent>;
    let target: ref<GameObject>;
    let totalAttackValue: Float;
    let weakDamageThreshold: Float;
    super.OnHitSounds(hitEvent);
    if IsDefined(hitEvent.attackData.GetWeapon()) && IsDefined(hitEvent.attackData.GetWeapon().GetItemData()) && hitEvent.attackData.GetWeapon().GetItemData().HasTag(n"MeleeWeapon") {
      return;
    };
    metadataEvent = new AudioEvent();
    metadataEvent.eventFlags = audioAudioEventFlags.Metadata;
    target = hitEvent.target;
    criticalDamageThreshold = TweakDBInterface.GetFloat(t"GlobalStats.DefaultKnockdownDamageThreshold.value", 60.00);
    highDamageThreshold = TweakDBInterface.GetFloat(t"GlobalStats.DefaultStaggerDamageThreshold.value", 40.00);
    medDamageThreshold = TweakDBInterface.GetFloat(t"GlobalStats.DefaultImpactDamageThreshold.value", 20.00);
    weakDamageThreshold = TweakDBInterface.GetFloat(t"GlobalStats.DefaultTwitchDamageThreshold.value", 1.00);
    metadataEvent.floatData = Vector4.Distance(hitEvent.attackData.GetAttackPosition(), target.GetWorldPosition());
    totalAttackValue = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if totalAttackValue >= criticalDamageThreshold {
      metadataEvent.eventName = n"critImpact";
    } else {
      if totalAttackValue >= highDamageThreshold {
        metadataEvent.eventName = n"hiImpact";
      } else {
        if totalAttackValue >= medDamageThreshold {
          metadataEvent.eventName = n"medImpact";
        } else {
          if totalAttackValue >= weakDamageThreshold {
            metadataEvent.eventName = n"lowImpact";
          };
        };
      };
    };
    target.QueueEvent(metadataEvent);
  }

  public final const func GetTotalFrameDamage() -> Float {
    let totalFrameReactionDamageReceived: Float;
    RWLock.AcquireShared(this.m_hitEventLock);
    totalFrameReactionDamageReceived = this.m_totalFrameReactionDamageReceived;
    RWLock.ReleaseShared(this.m_hitEventLock);
    return totalFrameReactionDamageReceived;
  }

  public final const func GetTotalFrameWoundsDamage() -> Float {
    let totalFrameWoundsDamageReceived: Float;
    RWLock.AcquireShared(this.m_hitEventLock);
    totalFrameWoundsDamageReceived = this.m_totalFrameWoundsDamageReceived;
    RWLock.ReleaseShared(this.m_hitEventLock);
    return totalFrameWoundsDamageReceived;
  }

  public final const func GetTotalFrameDismembermentDamage() -> Float {
    let totalFrameDismembermentDamageReceived: Float;
    RWLock.AcquireShared(this.m_hitEventLock);
    totalFrameDismembermentDamageReceived = this.m_totalFrameDismembermentDamageReceived;
    RWLock.ReleaseShared(this.m_hitEventLock);
    return totalFrameDismembermentDamageReceived;
  }

  protected cb func OnResetTotalFrameDamage(evt: ref<ResetFrameDamage>) -> Bool {
    RWLock.Acquire(this.m_hitEventLock);
    this.m_totalFrameReactionDamageReceived = 0.00;
    this.m_totalFrameDismembermentDamageReceived = 0.00;
    RWLock.Release(this.m_hitEventLock);
  }

  private final const func GetLastHitAttackType() -> gamedataAttackType {
    let attackType: gamedataAttackType;
    RWLock.AcquireShared(this.m_hitEventLock);
    attackType = this.m_lastHitEvent.attackData.GetAttackType();
    RWLock.ReleaseShared(this.m_hitEventLock);
    return attackType;
  }

  public final const func GetLastHitInstigator() -> wref<GameObject> {
    let instigator: wref<GameObject>;
    RWLock.AcquireShared(this.m_hitEventLock);
    instigator = this.m_lastHitEvent.attackData.GetInstigator();
    RWLock.ReleaseShared(this.m_hitEventLock);
    return instigator;
  }

  private final const func GetLastHitAttackRecord() -> ref<Attack_GameEffect_Record> {
    let attackRecord: ref<Attack_GameEffect_Record>;
    RWLock.AcquireShared(this.m_hitEventLock);
    attackRecord = this.m_lastHitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    RWLock.ReleaseShared(this.m_hitEventLock);
    return attackRecord;
  }

  private final const func HasLastHitFlag(flag: hitFlag) -> Bool {
    let hasFlag: Bool;
    RWLock.AcquireShared(this.m_hitEventLock);
    hasFlag = this.m_lastHitEvent.attackData.HasFlag(flag);
    RWLock.ReleaseShared(this.m_hitEventLock);
    return hasFlag;
  }

  private final const func GetLastHitAttackValues() -> [Float] {
    let attackValues: array<Float>;
    RWLock.AcquireShared(this.m_hitEventLock);
    attackValues = this.m_lastHitEvent.attackComputed.GetAttackValues();
    RWLock.ReleaseShared(this.m_hitEventLock);
    return attackValues;
  }

  public final const func GetLastHitAttackDirection() -> Vector4 {
    let hitDirection: Vector4;
    RWLock.AcquireShared(this.m_hitEventLock);
    hitDirection = this.m_lastHitEvent.hitDirection;
    RWLock.ReleaseShared(this.m_hitEventLock);
    return hitDirection;
  }

  private final func OnHitUI(hitEvent: ref<gameHitEvent>) -> Void {
    if !ScriptedPuppet.IsAlive(this) {
      return;
    };
    super.OnHitUI(hitEvent);
  }

  public final func WasJustKilledOrDefeated() -> Bool {
    return this.m_wasJustKilledOrDefeated;
  }

  private final func SendAfterDeathOrDefeatEvent() -> Void {
    let afterDeathOrDefeatEvt: ref<NPCAfterDeathOrDefeatEvent> = new NPCAfterDeathOrDefeatEvent();
    this.QueueEvent(afterDeathOrDefeatEvt);
  }

  private final func SendDataTrackingEvent(defeated: Bool, nonLethal: Bool) -> Void {
    let damageHistory: DamageHistoryEntry;
    let dataTrackingEvent: ref<NPCKillDataTrackingRequest> = new NPCKillDataTrackingRequest();
    if this.IsCharacterCivilian() {
      return;
    };
    if this.IsCrowd() {
      return;
    };
    if !this.GetValidAttackFromDamageHistory(damageHistory) {
      return;
    };
    if !IsDefined(damageHistory.source) {
      return;
    };
    dataTrackingEvent.damageEntry = damageHistory;
    dataTrackingEvent.isDownedRecorded = this.m_sentDownedEvent;
    if defeated && nonLethal {
      dataTrackingEvent.eventType = EDownedType.Unconscious;
    } else {
      if defeated {
        dataTrackingEvent.eventType = EDownedType.Defeated;
      } else {
        if ScriptedPuppet.IsDefeated(this) {
          dataTrackingEvent.eventType = EDownedType.Finished;
        } else {
          dataTrackingEvent.eventType = EDownedType.Killed;
        };
      };
    };
    GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"DataTrackingSystem").QueueRequest(dataTrackingEvent);
    this.m_sentDownedEvent = true;
  }

  protected cb func OnAfterDeathOrDefeat(evt: ref<NPCAfterDeathOrDefeatEvent>) -> Bool {
    this.m_wasJustKilledOrDefeated = false;
    this.m_shouldDie = false;
    this.m_shouldBeDefeated = false;
  }

  public final func ClearDefeatAndImmortality() -> Void {
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.Defeated");
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.Unconscious");
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.CombatStim");
    StatusEffectHelper.RemoveStatusEffect(this, t"BaseStatusEffect.Invulnerable");
  }

  protected cb func OnResetTimeDilation(evt: ref<ResetTimeDilation>) -> Bool {
    let resetTimeDilationEvent: ref<ResetTimeDilation>;
    let blackboard: ref<IBlackboard> = this.GetAIControllerComponent().GetActionBlackboard();
    if !IsDefined(blackboard) {
      return false;
    };
    if blackboard.GetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation) != -1.00 && !this.HasIndividualTimeDilation() {
      resetTimeDilationEvent = new ResetTimeDilation();
      resetTimeDilationEvent.easeOut = evt.easeOut;
      resetTimeDilationEvent.global = evt.global;
      this.QueueEvent(resetTimeDilationEvent);
    } else {
      this.UnsetIndividualTimeDilation(evt.easeOut);
      blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerTimeDilation, -1.00);
      if evt.global {
        blackboard.SetFloat(GetAllBlackboardDefs().AIAction.ownerGlobalTimeDilation, -1.00);
      };
    };
  }

  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    super.OnDeath(evt);
    if IsDefined(this.m_npcRagdollComponent) {
      this.m_npcRagdollComponent.Toggle(true);
    };
    this.TrySetPreventionCodeRedReinforcement();
    this.TriggerEvent(n"RequestDeathAnimation");
    this.SendDataTrackingEvent(false, false);
    this.CheckNPCKilledThrowingGrenade(evt.instigator);
    this.ClearDefeatAndImmortality();
    GameInstance.GetStatPoolsSystem(this.GetGame()).RequestUnregisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, this.m_deathListener);
    GameInstance.GetStatPoolsSystem(this.GetGame()).RequestUnregisteringListener(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Poise, this.m_poiseListener);
    this.SendAfterDeathOrDefeatEvent();
    AISquadHelper.NotifySquadOnIncapacitated(this);
    AIComponent.InvokeBehaviorCallback(this, n"OnDeath");
    if IsDefined(evt.instigator) {
      this.m_myKiller = evt.instigator;
    };
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"OnePunchedMark") {
      GameObjectEffectHelper.StartEffectEvent(this, n"finisher_katana_02_decal");
    };
  }

  private final func TrySetPreventionCodeRedReinforcement() -> Void {
    let registry: ref<PoliceAgentRegistry> = PreventionSystem.GetAgentRegistry(this.GetGame());
    if this.IsPrevention() && PreventionSystem.IsChasingPlayer(this.GetGame()) && registry.HasNPCBeenAttackedByPlayer(this.GetEntityID()) && !registry.IsPoliceInCombatWithPalyer() {
      PreventionSystem.SetSpawnCodeRedReinforcement(this.GetGame(), true);
    };
  }

  private final func EvaluateQuickHackPassivesIncapacitated() -> Void {
    let attackRecord: ref<Attack_GameEffect_Record>;
    let hitFlags: array<String>;
    if Equals(this.GetNPCType(), gamedataNPCType.Human) {
      if Equals(this.GetLastHitAttackType(), gamedataAttackType.Hack) || this.HasLastHitFlag(hitFlag.QuickHack) {
        attackRecord = this.GetLastHitAttackRecord();
        hitFlags = attackRecord.HitFlags();
        if ArrayContains(hitFlags, "BrainMeltBurningHead") || GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetPlayerID()), gamedataStatType.FearOnQuickHackKill) == 1.00 {
          this.GetStimBroadcasterComponent().TriggerSingleBroadcast(this, gamedataStimType.Terror, 10.00);
          return;
        };
      };
    };
  }

  protected cb func OnPotentialDeath(evt: ref<gamePotentialDeathEvent>) -> Bool {
    let nonLethalFlag: Bool;
    let reactionPresetGroup: String = AIActionHelper.GetReactionPresetGroup(this);
    let isCivilian: Bool = Equals(reactionPresetGroup, "Civilian");
    this.SetMyKiller(evt.instigator);
    this.PlayVOOnSquadMembers(evt.instigator.IsPlayer());
    if !isCivilian = Equals(reactionPresetGroup, "Civilian") && (NotEquals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Dead) || NotEquals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Fear)) {
      this.PlayVOOnPlayerOrPlayerCompanion(evt.instigator);
    };
    if this.IsDefeatMechanicActive() {
      if this.IsAboutToDie() {
        this.Kill();
      } else {
        if !this.IsCrowd() && (StatusEffectSystem.ObjectHasStatusEffect(evt.instigator, t"GameplayRestriction.FistFight") || StatusEffectSystem.ObjectHasStatusEffect(this, t"GameplayRestriction.FistFight")) {
          StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.DefeatedWithRecover");
          nonLethalFlag = true;
        } else {
          nonLethalFlag = this.SearchForNonlethalFlag();
          if nonLethalFlag && GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.UnconsciousImmunity) == 0.00 {
            StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.Unconscious");
          } else {
            StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.Defeated");
          };
          if GameInstance.GetGameFeatureManager(this.GetGame()).AggressiveCrowdsEnabled() && this.IsCrowd() && this.IsAggressive() {
            this.CallUnregisterAggressiveNPC();
          };
          StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.InvulnerableAfterDefeated");
        };
        this.SendDataTrackingEvent(true, nonLethalFlag);
        this.CheckNPCKilledThrowingGrenade(evt.instigator);
        this.ProcessDoTAttackData();
        this.SendAfterDeathOrDefeatEvent();
        AISquadHelper.NotifySquadOnIncapacitated(this);
      };
    };
  }

  public final static func FinisherEffectorActionOn(npc: wref<NPCPuppet>, instigator: wref<GameObject>) -> Void {
    let evt: ref<FinisherEffectorActionOn>;
    if !IsDefined(npc) || !IsDefined(instigator) {
      return;
    };
    evt = new FinisherEffectorActionOn();
    evt.instigator = instigator;
    GameInstance.GetDelaySystem(npc.GetGame()).DelayEvent(npc, evt, 0.10, false);
  }

  protected cb func OnFinisherEffectorActionOn(evt: ref<FinisherEffectorActionOn>) -> Bool {
    if ScriptedPuppet.IsActive(this) && IsDefined(evt.instigator) {
      if AIActionHelper.TryChangingAttitudeToHostile(this, evt.instigator) {
        TargetTrackingExtension.InjectThreat(this, evt.instigator, 1.00, 10.00);
        NPCPuppet.ChangeHighLevelState(this, gamedataNPCHighLevelState.Combat);
      };
    };
  }

  private final func SearchForNonlethalFlag() -> Bool {
    let i: Int32;
    if ArraySize(this.m_receivedDamageHistory) > 0 {
      i = 0;
      while i < ArraySize(this.m_receivedDamageHistory) {
        if IsDefined(this.m_receivedDamageHistory[i].hitEvent) {
          if this.m_receivedDamageHistory[i].hitEvent.attackData.HasFlag(hitFlag.Nonlethal) {
            return true;
          };
        };
        i += 1;
      };
    };
    return false;
  }

  private final func GetValidAttackFromDamageHistory(entry: script_ref<DamageHistoryEntry>) -> Bool {
    let i: Int32 = 0;
    if ArraySize(this.m_receivedDamageHistory) > 0 {
      i;
      while i < ArraySize(this.m_receivedDamageHistory) {
        if IsDefined(this.m_receivedDamageHistory[i].hitEvent) {
          entry = this.m_receivedDamageHistory[i];
          return true;
        };
        i += 1;
      };
    };
    return false;
  }

  private final func ProcessDoTAttackData() -> Void {
    let gameEffectAttack: ref<Attack_GameEffect_Record>;
    let i: Int32;
    let statusEffectAttack: ref<Attack_Record>;
    if IsDefined(this.m_cachedStatusEffectAnim) {
      StatusEffectHelper.HasStatusEffectAttack(this.m_cachedStatusEffectAnim, statusEffectAttack);
      if IsDefined(statusEffectAttack) {
        gameEffectAttack = statusEffectAttack as Attack_GameEffect_Record;
        if IsDefined(gameEffectAttack) {
          ScriptedPuppet.SendActionSignal(this, gameEffectAttack.AttackTag(), 1.00);
        };
      };
      return;
    };
    if ArraySize(this.m_receivedDamageHistory) > 0 {
      i = 0;
      while i < ArraySize(this.m_receivedDamageHistory) {
        if IsDefined(this.m_receivedDamageHistory[i].hitEvent) {
          if AttackData.IsDoT(this.m_receivedDamageHistory[i].hitEvent.attackData) {
            gameEffectAttack = this.m_receivedDamageHistory[i].hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
            if IsDefined(gameEffectAttack) {
              ScriptedPuppet.SendActionSignal(this, gameEffectAttack.AttackTag(), 1.00);
            };
            return;
          };
        };
        i += 1;
      };
    };
  }

  public final func UpdateCollisionState(opt onRagdollDisabled: Bool) -> Void {
    if IsDefined(this.m_npcCollisionComponent) {
      if StatusEffectSystem.ObjectHasStatusEffectOfType(this, gamedataStatusEffectType.SystemCollapse) && Equals(this.GetNPCType(), gamedataNPCType.Android) && !this.IsRagdolling() {
        return;
      };
      if !onRagdollDisabled && (this.m_disableCollisionRequested || this.IsIncapacitated() || this.IsRagdolling() || this.m_hasAnimatedRagdoll || ScriptedPuppet.IsDefeated(this)) {
        this.GetAIControllerComponent().DisableCollider();
        if this.m_npcTraceObstacleComponent != null {
          this.m_npcTraceObstacleComponent.Toggle(false);
        };
      } else {
        this.GetAIControllerComponent().EnableCollider();
        if this.m_npcTraceObstacleComponent != null {
          this.m_npcTraceObstacleComponent.Toggle(true);
        };
      };
    };
  }

  public final func DisableCollision() -> Void {
    this.m_disableCollisionRequested = true;
    this.UpdateCollisionState();
  }

  public final func EnableCollision() -> Void {
    this.m_disableCollisionRequested = false;
    this.UpdateCollisionState();
  }

  protected final func OnDefeatedWithRecoverStatusEffectApplied() -> Void {
    this.UpdateCollisionState();
    NPCPuppet.ChangeHighLevelState(this, gamedataNPCHighLevelState.Unconscious);
  }

  protected final func OnDefeatedWithRecoverStatusEffectRemoved() -> Void {
    this.SetSenseObjectType(gamedataSenseObjectType.Npc);
    this.UpdateCollisionState();
    NPCPuppet.ChangeHighLevelState(this, gamedataNPCHighLevelState.Relaxed);
  }

  protected func OnResurrected() -> Void {
    super.OnResurrected();
    this.m_disableCollisionRequested = false;
    this.UpdateCollisionState();
    GameInstance.GetStatPoolsSystem(this.GetGame()).RequestSettingStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, 100.00, null, true);
    this.ClearDefeatAndImmortality();
    this.SetSenseObjectType(gamedataSenseObjectType.Npc);
  }

  protected func OnIncapacitated() -> Void {
    let playerPuppet: wref<ScriptedPuppet>;
    let fearSourceRadius: Float = 25.00;
    if !this.IsIncapacitated() && !GameInstance.GetReactionSystem(this.GetGame()).UsesLoreAnimationWorkspot(this.GetEntityID()) {
      if IsFinal() {
        GameInstance.GetReactionSystem(this.GetGame()).AddFearSource(Cast<Vector3>(this.GetWorldPosition()), fearSourceRadius);
      } else {
        GameInstance.GetReactionSystem(this.GetGame()).AddFearSource(Cast<Vector3>(this.GetWorldPosition()), fearSourceRadius, StringToName("[" + EntityID.ToDebugStringDecimal(this.GetEntityID()) + "] Death (R=" + fearSourceRadius + ")"));
      };
      GameInstance.GetReactionSystem(this.GetGame()).MarkDeadBody(this.GetEntityID(), this.IsAggressive(), GameInstance.GetSceneSystem(this.GetGame()).GetScriptInterface().IsEntityInScene(this.GetEntityID()));
    };
    if IsDefined(this.m_npcRagdollComponent) {
      this.m_npcRagdollComponent.Toggle(true);
    };
    if ScriptedPuppet.CanRagdoll(this) && !this.WasIncapacitatedOnAttach() {
      this.HandleRagdollOnDeath(true);
    };
    if this.IsBoss() {
      playerPuppet = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
      if IsDefined(playerPuppet) {
        BossHealthBarGameController.ReevaluateBossHealthBar(this, playerPuppet, true);
      };
    };
    if this.IsIncapacitated() {
      this.UpdateCollisionState();
      return;
    };
    this.QueueEvent(new TerminateReactionLookatEvent());
    this.ReevaluateQuickHackPerkRewardsForPlayer();
    this.EvaluateQuickHackPassivesIncapacitated();
    if Equals(this.GetNPCType(), gamedataNPCType.Android) {
      this.ProcessAndroidIncapacitated();
    };
    super.OnIncapacitated();
    this.ProcessLoot();
    AIActionHelper.CombatQueriesInit(this);
    this.SetPuppetTargetingPlayer(false);
    this.UpdateCollisionState();
    this.SetSenseObjectType(gamedataSenseObjectType.Deadbody);
    this.HandleRagdollOnDeath(false);
  }

  protected final func HandleRagdollOnDeathByEvent(handleUncontrolledMovement: Bool) -> Void {
    let evt: ref<HandleRagdollOnDeathEvent> = new HandleRagdollOnDeathEvent();
    evt.handleUncontrolledMovement = handleUncontrolledMovement;
    this.QueueEvent(evt);
  }

  protected cb func OnHandleRagdollOnDeath(evt: ref<HandleRagdollOnDeathEvent>) -> Bool {
    this.HandleRagdollOnDeath(evt.handleUncontrolledMovement);
  }

  protected final func HandleRagdollOnDeath(handleUncontrolledMovement: Bool) -> Void {
    let uncontrolledMovementEvent: ref<UncontrolledMovementStartEvent>;
    if handleUncontrolledMovement {
      uncontrolledMovementEvent = new UncontrolledMovementStartEvent();
      uncontrolledMovementEvent.DebugSetSourceName(n"NPCPuppet - OnIncapacitated()");
      if Equals(this.GetNPCType(), gamedataNPCType.Human) && VehicleComponent.IsMountedToVehicle(this.GetGame(), this) {
        uncontrolledMovementEvent.ragdollOnCollision = false;
      } else {
        uncontrolledMovementEvent.ragdollOnCollision = true;
      };
      if Equals(this.GetNPCType(), gamedataNPCType.Drone) && !GameInstance.GetNavigationSystem(this.GetGame()).IsOnGround(this) {
        uncontrolledMovementEvent.ragdollNoGroundThreshold = -1.00;
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, CreateForceRagdollEvent(n"Drone aerial death fallback event"), TweakDBInterface.GetFloat(this.GetRecordID() + t".airDeathRagdollDelay", 1.00), true);
      };
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, uncontrolledMovementEvent, 0.20, true);
    } else {
      if (Equals(this.GetNPCType(), gamedataNPCType.Human) || Equals(this.GetNPCType(), gamedataNPCType.Android)) && this.IsFloorSteepEnoughToRagdoll() {
        GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, CreateForceRagdollEvent(n"NPC died on sloped terrain"), TDB.GetFloat(t"AIGeneralSettings.ragdollFloorAngleActivationDelay"), true);
      };
    };
  }

  protected final func IsFloorSteepEnoughToRagdoll() -> Bool {
    let floorAngle: Float;
    if SpatialQueriesHelper.GetFloorAngle(this, floorAngle) && floorAngle >= TDB.GetFloat(t"AIGeneralSettings.maxAllowedIncapacitatedFloorAngle") {
      return true;
    };
    return false;
  }

  private final func ProcessAndroidIncapacitated() -> Void {
    let attackValues: array<Float> = this.GetLastHitAttackValues();
    if attackValues[1] > 0.00 {
      GameInstance.GetEffectorSystem(this.GetGame()).ApplyEffector(this.GetEntityID(), GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject(), t"Effectors.Android_ExplodeOnElectricDeathEffector");
      GameInstance.GetEffectorSystem(this.GetGame()).ApplyEffector(this.GetEntityID(), GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject(), t"Effectors.Android_ExplodeOnElectricDeathEffectorVFX");
    };
  }

  public const func IsIncapacitated() -> Bool {
    return this.GetPS().GetWasIncapacitated();
  }

  private final func ReevaluateQuickHackPerkRewardsForPlayer() -> Void {
    let appliedStatusEffects: array<ref<StatusEffect>>;
    let i: Int32;
    let remainingDuration: Float;
    let value: Float;
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    if IsDefined(player) && this.m_quickHackEffectsApplied > 0u {
      value = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.RestoreMemoryOnDefeat);
      if value > 0.00 {
        GameInstance.GetStatPoolsSystem(this.GetGame()).RequestChangingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Memory, value, player, true, false);
      };
      value = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.LowerActiveCooldownOnDefeat);
      if value > 0.00 {
        if StatusEffectHelper.GetAppliedEffectsWithTag(player, n"QuickHackCooldown", appliedStatusEffects) {
          i = 0;
          while i < ArraySize(appliedStatusEffects) {
            remainingDuration = appliedStatusEffects[i].GetRemainingDuration();
            GameInstance.GetStatusEffectSystem(this.GetGame()).SetStatusEffectRemainingDuration(player.GetEntityID(), appliedStatusEffects[i].GetRecord().GetID(), remainingDuration * (1.00 - value));
            i += 1;
          };
        };
      };
    };
  }

  protected cb func OnVehicleHijackEvent(evt: ref<VehicleHijackEvent>) -> Bool {
    let resetEvent: ref<ResetVehicleHijackEvent>;
    this.GetPuppetStateBlackboard().SetBool(GetAllBlackboardDefs().PuppetState.WorkspotAnimationInProgress, true);
    resetEvent = new ResetVehicleHijackEvent();
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, resetEvent, 5.00, true);
  }

  protected cb func OnResetVehicleHijackEvent(evt: ref<ResetVehicleHijackEvent>) -> Bool {
    let bb: ref<IBlackboard> = this.GetPuppetStateBlackboard();
    if IsDefined(bb) {
      bb.SetBool(GetAllBlackboardDefs().PuppetState.WorkspotAnimationInProgress, false);
      bb.SetBool(GetAllBlackboardDefs().PuppetState.InPendingBehavior, false);
    };
  }

  protected cb func OnVehicleHackedEvent(evt: ref<VehicleHackedEvent>) -> Bool {
    NPCStatesComponent.AlertPuppet(this);
  }

  protected cb func OnVehicleRammedEvent(evt: ref<VehicleRammedEvent>) -> Bool {
    NPCStatesComponent.AlertPuppet(this);
    AIActionHelper.TryChangingAttitudeToHostile(this, GetPlayer(this.GetGame()));
  }

  protected cb func OnCoverHit(evt: ref<gameCoverHitEvent>) -> Bool {
    this.TriggerEvent(n"RequestCoverHitReaction");
  }

  protected func OnHitVFX(hitEvent: ref<gameHitEvent>) -> Void {
    let isNPCMounted: Bool;
    let mountingInfo: MountingInfo;
    let mountingSlotName: CName;
    super.OnHitVFX(hitEvent);
    mountingInfo = GameInstance.GetMountingFacility(hitEvent.target.GetGame()).GetMountingInfoSingleWithObjects(hitEvent.target);
    isNPCMounted = EntityID.IsDefined(mountingInfo.childId);
    mountingSlotName = mountingInfo.slotId.id;
    if isNPCMounted && Equals(mountingSlotName, n"grapple") {
      GameObjectEffectHelper.StartEffectEvent(this, n"human_shield");
    };
  }

  private final func PlayImpactSound() -> Void {
    let voEvent: ref<SoundPlayVo> = new SoundPlayVo();
    voEvent.voContext = n"battlecry_01";
    voEvent.debugInitialContext = n"Scripts:PlayImpactSound()";
    this.QueueEvent(voEvent);
  }

  private final func SpawnHitVisualEffect(n: CName) -> Void {
    let spawnEffectEvent: ref<entSpawnEffectEvent> = new entSpawnEffectEvent();
    spawnEffectEvent.effectName = n;
    this.QueueEvent(spawnEffectEvent);
  }

  public const func CompileScannerChunks() -> Bool {
    let NPCName: String;
    let abilities: array<wref<GameplayAbility_Record>>;
    let abilityChunk: ref<ScannerAbilities>;
    let abilityGroups: array<wref<GameplayAbilityGroup_Record>>;
    let abilityItem: wref<GameplayAbility_Record>;
    let abilityUIValidationPrereqs: array<wref<IPrereq_Record>>;
    let ap: ref<AccessPointControllerPS>;
    let archetypeData: wref<ArchetypeData_Record>;
    let archetypeName: CName;
    let archtypeChunk: ref<ScannerArchetype>;
    let attitudeChunk: ref<ScannerAttitude>;
    let availablePlayerActions: array<TweakDBID>;
    let basicWeaponChunk: ref<ScannerWeaponBasic>;
    let bounty: Bounty;
    let bountyChunk: ref<ScannerBountySystem>;
    let bountyUI: BountyUI;
    let choices: array<InteractionChoice>;
    let context: GetActionsContext;
    let detailedWeaponChunk: ref<ScannerWeaponDetailed>;
    let enemyDifficulty: gameEPowerDifferential;
    let factionChunk: ref<ScannerFaction>;
    let hasLinkToDB: Bool;
    let healthChunk: ref<ScannerHealth>;
    let i: Int32;
    let items: array<wref<NPCEquipmentItem_Record>>;
    let k: Int32;
    let levelChunk: ref<ScannerLevel>;
    let nameChunk: ref<ScannerName>;
    let nameParams: ref<inkTextParams>;
    let networkStatusChunk: ref<ScannerNetworkStatus>;
    let puppetQuickHack: wref<ObjectAction_Record>;
    let quickHackActionRecords: array<wref<ObjectAction_Record>>;
    let rarityChunk: ref<ScannerRarity>;
    let resistancesChunk: ref<ScannerResistances>;
    let resists: array<ScannerStatDetails>;
    let scannerBlackboard: wref<IBlackboard>;
    let shouldShowInUIAccordingToAbilityPrereqs: Bool;
    let statPoolSystem: ref<StatPoolsSystem>;
    let vulnerabilitiesChunk: ref<ScannerVulnerabilities>;
    let vulnerability: Vulnerability;
    let z: Int32;
    let ps: ref<ScriptedPuppetPS> = this.GetPS();
    let characterRecord: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(this.GetRecordID());
    let scannerPreset: ref<ScannerModuleVisibilityPreset_Record> = characterRecord.ScannerModulePreset();
    let thisEntity: ref<GameObject> = EntityGameInterface.GetEntity(this.GetEntity()) as GameObject;
    if TDBID.IsValid(ps.GetForcedScannerPreset()) {
      scannerPreset = TweakDBInterface.GetScannerModuleVisibilityPresetRecord(ps.GetForcedScannerPreset());
    } else {
      scannerPreset = characterRecord.ScannerModulePreset();
    };
    scannerBlackboard = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_ScannerModules);
    if !IsDefined(characterRecord) || !IsDefined(scannerPreset) || !IsDefined(scannerBlackboard) {
      return false;
    };
    scannerBlackboard.SetInt(GetAllBlackboardDefs().UI_ScannerModules.ObjectType, 1, true);
    if scannerPreset.ShoulShowName() {
      nameChunk = new ScannerName();
      archetypeName = characterRecord.ArchetypeData().Type().LocalizedName();
      if NotEquals(archetypeName, n"None") && !characterRecord.SkipDisplayArchetype() {
        nameChunk.SetArchetype(true);
      };
      nameParams = new inkTextParams();
      if ps.HasAlternativeName() {
        if IsNameValid(characterRecord.AlternativeFullDisplayName()) {
          NPCName = LocKeyToString(characterRecord.AlternativeFullDisplayName());
        } else {
          NPCName = LocKeyToString(characterRecord.AlternativeDisplayName());
        };
      } else {
        if this.IsCharacterCivilian() || Equals(characterRecord.BaseAttitudeGroup(), n"child_ow") {
          if IsNameValid(characterRecord.DisplayName()) {
            NPCName = LocKeyToString(characterRecord.DisplayName());
          } else {
            NPCName = this.GetDisplayName();
          };
        } else {
          if IsNameValid(characterRecord.FullDisplayName()) {
            NPCName = LocKeyToString(characterRecord.FullDisplayName());
          } else {
            if IsNameValid(characterRecord.DisplayName()) {
              NPCName = LocKeyToString(characterRecord.DisplayName());
            } else {
              NPCName = this.GetDisplayName();
            };
          };
        };
      };
      if nameChunk.HasArchetype() {
        nameParams = new inkTextParams();
        if Equals(NPCName, ToString(archetypeName)) || !IsNameValid(characterRecord.FullDisplayName()) && !IsNameValid(characterRecord.DisplayName()) {
          NPCName = "";
        };
        nameParams.AddLocalizedString("TEXT_PRIMARY", NPCName);
        nameParams.AddLocalizedString("TEXT_SECONDARY", ToString(archetypeName));
        nameChunk.SetTextParams(nameParams);
        archtypeChunk = new ScannerArchetype();
        archtypeChunk.Set(characterRecord.ArchetypeData().Type().Type());
        scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerArchetype, ToVariant(archtypeChunk));
      } else {
        nameChunk.Set(NPCName);
      };
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerName, ToVariant(nameChunk));
    };
    if scannerPreset.ShouldShowLevel() {
      levelChunk = new ScannerLevel();
      levelChunk.Set(0);
      levelChunk.SetIndicator(NPCPuppet.ShouldShowIndicator(thisEntity));
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerLevel, ToVariant(levelChunk));
    };
    if scannerPreset.ShouldShowRarity() {
      rarityChunk = new ScannerRarity();
      hasLinkToDB = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(GetPlayer(this.GetGame()).GetEntityID()), gamedataStatType.HasLinkToBountySystem) > 0.00;
      rarityChunk.Set(this.GetNPCRarity(), this.IsCharacterCivilian() && hasLinkToDB);
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerRarity, ToVariant(rarityChunk));
    };
    if scannerPreset.ShouldShowFaction() {
      factionChunk = new ScannerFaction();
      factionChunk.Set(LocKeyToString(characterRecord.Affiliation().LocalizedName()));
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerFaction, ToVariant(factionChunk));
    };
    if !this.IsDead() && !ScriptedPuppet.IsDefeated(this) && scannerPreset.ShouldShowAttitude() {
      attitudeChunk = new ScannerAttitude();
      attitudeChunk.Set(this.GetAttitudeTowards(GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerControlledGameObject()));
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerAttitude, ToVariant(attitudeChunk));
    };
    if scannerPreset.ShouldShowHealth() {
      healthChunk = new ScannerHealth();
      statPoolSystem = GameInstance.GetStatPoolsSystem(this.GetGame());
      if IsDefined(statPoolSystem) {
        healthChunk.Set(Cast<Int32>(statPoolSystem.GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, false)), Cast<Int32>(GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolMaxPointValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health)));
        scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerHealth, ToVariant(healthChunk));
      };
    };
    if scannerPreset.ShouldShowBounty() && TDBID.IsValid(this.GetRecord().BountyDrawTable().GetID()) && !this.m_bounty.m_filteredOut {
      if ArraySize(this.m_bounty.m_transgressions) <= 0 {
        bounty = BountyManager.GenerateBounty(this);
      } else {
        bounty = this.m_bounty;
      };
      if !bounty.m_filteredOut {
        bountyChunk = new ScannerBountySystem();
        bountyUI.issuedBy = LocKeyToString(TweakDBInterface.GetAffiliationRecord(bounty.m_bountySetter).LocalizedName());
        bountyUI.moneyReward = bounty.m_moneyAmount;
        bountyUI.streetCredReward = bounty.m_streetCredAmount;
        enemyDifficulty = RPGManager.CalculatePowerDifferential(thisEntity);
        switch enemyDifficulty {
          case gameEPowerDifferential.TRASH:
            bountyUI.level = 1;
            break;
          case gameEPowerDifferential.EASY:
            bountyUI.level = 2;
            break;
          case gameEPowerDifferential.NORMAL:
            bountyUI.level = 3;
            break;
          case gameEPowerDifferential.HARD:
            bountyUI.level = 4;
            break;
          case gameEPowerDifferential.IMPOSSIBLE:
            bountyUI.level = 5;
            break;
          default:
        };
        bountyUI.hasAccess = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(GetPlayer(this.GetGame()).GetEntityID()), gamedataStatType.HasLinkToBountySystem) > 0.00;
        i = 0;
        while i < ArraySize(bounty.m_transgressions) {
          ArrayPush(bountyUI.transgressions, TweakDBInterface.GetTransgressionRecord(bounty.m_transgressions[i]).LocalizedDescription());
          i += 1;
        };
        bountyChunk.Set(bountyUI);
        scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerBountySystem, ToVariant(bountyChunk));
      };
    };
    if !this.IsDead() && !ScriptedPuppet.IsDefeated(this) && scannerPreset.ShouldShowWeaponData() {
      AIActionTransactionSystem.CalculateEquipmentItems(this, this.GetRecord().PrimaryEquipment(), items, -1);
      basicWeaponChunk = new ScannerWeaponBasic();
      basicWeaponChunk.Set(items[0].Item().DisplayName());
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerWeaponBasic, ToVariant(basicWeaponChunk));
    };
    if !this.IsDead() && !ScriptedPuppet.IsDefeated(this) && scannerPreset.ShouldShowVulnerabilities() {
      vulnerabilitiesChunk = new ScannerVulnerabilities();
      availablePlayerActions = RPGManager.GetPlayerQuickHackList(GetPlayer(this.GetGame()));
      context = ps.GenerateContext(gamedeviceRequestType.Remote, Device.GetInteractionClearance(), Device.GetPlayerMainObjectStatic(this.GetGame()), this.GetEntityID());
      ArrayResize(quickHackActionRecords, ArraySize(availablePlayerActions));
      i = 0;
      while i < ArraySize(availablePlayerActions) {
        quickHackActionRecords[i] = TweakDBInterface.GetObjectActionRecord(availablePlayerActions[i]);
        i += 1;
      };
      ps.GetValidChoices(quickHackActionRecords, context, null, false, choices);
      i = 0;
      while i < ArraySize(choices) {
        k = 0;
        while k < ArraySize(choices[i].data) {
          puppetQuickHack = FromVariant<ref<ScriptableDeviceAction>>(choices[i].data[k]).GetObjectActionRecord();
          if IsDefined(puppetQuickHack) {
            vulnerability.vulnerabilityName = puppetQuickHack.ObjectActionUI().Caption();
            vulnerability.icon = puppetQuickHack.ObjectActionUI().CaptionIcon().TexturePartID().GetID();
            z = 0;
            while z < ArraySize(quickHackActionRecords) {
              if quickHackActionRecords[z].GameplayCategory().GetID() == puppetQuickHack.GetID() {
                vulnerability.isActive = true;
              };
              z += 1;
            };
            vulnerabilitiesChunk.PushBack(vulnerability);
          };
          k += 1;
        };
        i += 1;
      };
      if vulnerabilitiesChunk.IsValid() {
        scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerVulnerabilities, ToVariant(vulnerabilitiesChunk));
      };
    };
    if scannerPreset.ShouldShowNetworkStatus() {
      networkStatusChunk = new ScannerNetworkStatus();
      ap = ps.GetAccessPoint();
      if IsDefined(ap) {
        if ap.IsBreached() {
          networkStatusChunk.Set(ScannerNetworkState.BREACHED);
        } else {
          networkStatusChunk.Set(ScannerNetworkState.NOT_BREACHED);
        };
      } else {
        networkStatusChunk.Set(ScannerNetworkState.NOT_CONNECTED);
      };
    };
    if !this.IsDead() && !ScriptedPuppet.IsDefeated(this) && scannerPreset.ShouldShowResistances() {
      resistancesChunk = new ScannerResistances();
      ArrayPush(resists, RPGManager.GetScannerResistanceDetails(thisEntity, gamedataStatType.PhysicalResistance));
      ArrayPush(resists, RPGManager.GetScannerResistanceDetails(thisEntity, gamedataStatType.ThermalResistance));
      ArrayPush(resists, RPGManager.GetScannerResistanceDetails(thisEntity, gamedataStatType.ElectricResistance));
      ArrayPush(resists, RPGManager.GetScannerResistanceDetails(thisEntity, gamedataStatType.ChemicalResistance));
      ArrayPush(resists, RPGManager.GetScannerResistanceDetails(thisEntity, gamedataStatType.HackingResistance, GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject()));
      resistancesChunk.Set(resists);
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerResistances, ToVariant(resistancesChunk));
    };
    if !this.IsDead() && !ScriptedPuppet.IsDefeated(this) {
      abilityChunk = new ScannerAbilities();
      archetypeData = characterRecord.ArchetypeData();
      if !IsDefined(archetypeData) {
        return false;
      };
      if archetypeData.GetAbilityGroupsCount() > 0 {
        archetypeData.AbilityGroups(abilityGroups);
        i = 0;
        while i < ArraySize(abilityGroups) {
          abilityGroups[i].Abilities(abilities);
          i += 1;
        };
      };
      i = 0;
      while i < characterRecord.GetAbilitiesCount() {
        abilityItem = characterRecord.GetAbilitiesItem(i);
        if !ArrayContains(abilities, abilityItem) {
          ArrayPush(abilities, abilityItem);
        };
        i += 1;
      };
      i = ArraySize(abilities) - 1;
      while i >= 0 {
        abilityItem = abilities[i];
        abilityItem.PrereqsForUIValidation(abilityUIValidationPrereqs);
        shouldShowInUIAccordingToAbilityPrereqs = false;
        k = 0;
        while k < ArraySize(abilityUIValidationPrereqs) {
          shouldShowInUIAccordingToAbilityPrereqs = IPrereq.CreatePrereq(abilityUIValidationPrereqs[k].GetID()).IsFulfilled(this.GetGame(), this);
          if !shouldShowInUIAccordingToAbilityPrereqs {
            ArrayRemove(abilities, abilityItem);
            break;
          };
          k += 1;
        };
        ArrayClear(abilityUIValidationPrereqs);
        i -= 1;
      };
      abilityChunk.Set(abilities);
      scannerBlackboard.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerAbilities, ToVariant(abilityChunk));
    };
    return true;
  }

  private final static func ShouldShowIndicator(npc: ref<GameObject>) -> Bool {
    let enemyDifficulty: gameEPowerDifferential = RPGManager.CalculatePowerDifferential(npc);
    if Equals(enemyDifficulty, gameEPowerDifferential.IMPOSSIBLE) {
      return true;
    };
    if NPCManager.HasVisualTag(npc as ScriptedPuppet, n"Sumo") || NPCManager.HasVisualTag(npc as ScriptedPuppet, n"Police") {
      return true;
    };
    return false;
  }

  protected cb func OnSetExposeQuickHacks(evt: ref<SetExposeQuickHacks>) -> Bool {
    super.OnSetExposeQuickHacks(evt);
    this.SetScannerDirty(true);
  }

  protected cb func OnSmartBulletDeflectedEvent(evt: ref<SmartBulletDeflectedEvent>) -> Bool {
    GameObject.StartReplicatedEffectEvent(this, n"glow_tattoo_promixity");
  }

  public func UpdateAdditionalScanningData() -> Void {
    let bb: ref<IBlackboard>;
    let stats: GameObjectScanStats;
    let weapon: ItemID;
    stats.scannerData.entityName = this.GetTweakDBFullDisplayName(true);
    AIActionTransactionSystem.GetFirstItemID(this, TweakDBInterface.GetItemCategoryRecord(t"ItemCategory.Weapon"), n"None", weapon);
    bb = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Scanner);
    if IsDefined(bb) {
      bb.SetVariant(GetAllBlackboardDefs().UI_Scanner.scannerObjectStats, ToVariant(stats));
      bb.Signal(GetAllBlackboardDefs().UI_Scanner.scannerObjectStats);
    };
  }

  private final const func GetHighestDamageStat(item: ref<gameItemData>) -> gamedataDamageType {
    let cachedThreshold: Float = item.GetStatValueByType(gamedataStatType.PhysicalDamage);
    let returnType: gamedataDamageType = gamedataDamageType.Physical;
    if item.GetStatValueByType(gamedataStatType.ThermalDamage) > cachedThreshold {
      cachedThreshold = item.GetStatValueByType(gamedataStatType.ThermalDamage);
      returnType = gamedataDamageType.Thermal;
    };
    if item.GetStatValueByType(gamedataStatType.ElectricDamage) > cachedThreshold {
      cachedThreshold = item.GetStatValueByType(gamedataStatType.ElectricDamage);
      returnType = gamedataDamageType.Electric;
    };
    if item.GetStatValueByType(gamedataStatType.ChemicalDamage) > cachedThreshold {
      cachedThreshold = item.GetStatValueByType(gamedataStatType.ChemicalDamage);
      returnType = gamedataDamageType.Chemical;
    };
    return returnType;
  }

  public final func MountingStartDisableComponents() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_npcMountedToPlayerComponents) {
      if IsDefined(this.m_npcMountedToPlayerComponents[i]) && this.IsIncapacitated() {
        this.m_npcMountedToPlayerComponents[i].Toggle(false);
      };
      i += 1;
    };
    this.DisableCollision();
    if !this.IsIncapacitated() {
      GameInstance.GetStatusEffectSystem(this.GetGame()).ApplyStatusEffect(this.GetEntityID(), t"BaseStatusEffect.Grappled");
    };
  }

  public final func MountingEndEnableComponents() -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_npcMountedToPlayerComponents) {
      if IsDefined(this.m_npcMountedToPlayerComponents[i]) {
        this.m_npcMountedToPlayerComponents[i].Toggle(true);
      };
      i += 1;
    };
    this.EnableCollision();
    if !this.IsIncapacitated() {
      GameInstance.GetStatusEffectSystem(this.GetGame()).RemoveStatusEffect(this.GetEntityID(), t"BaseStatusEffect.Grappled");
    };
  }

  public final func GrappleTargetDeadEnableRagdollComponent(b: Bool) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.m_npcMountedToPlayerComponents) {
      if IsDefined(this.m_npcMountedToPlayerComponents[i]) {
        this.m_npcMountedToPlayerComponents[i].Toggle(false);
      };
      i += 1;
    };
    this.SetDisableRagdoll(!b);
  }

  public final func SetMyKiller(killer: ref<GameObject>) -> Void {
    if IsDefined(killer) {
      this.m_myKiller = killer;
    };
  }

  protected cb func OnGrappleTargetDeadEnableRagdollWithDelay(evt: ref<RagdollToggleDelayEvent>) -> Bool {
    if IsDefined(evt.target) {
      this.SetDisableRagdoll(!evt.enable, evt.force, evt.leaveRagdollEnabled);
    };
  }

  protected cb func OnHidePuppetDelayEvent(evt: ref<HidePuppetDelayEvent>) -> Bool {
    if IsDefined(evt.m_target) {
      evt.m_target.HideIrreversibly();
    };
  }

  protected cb func On_TEMP_TestNPCOutsideNavmeshEvent(evt: ref<TestNPCOutsideNavmeshEvent>) -> Bool {
    let DelayedGameEffectEvt: ref<DelayedGameEffectEvent>;
    let currentPosition: Vector4 = evt.target.GetWorldPosition();
    let navigationPath: ref<NavigationPath> = GameInstance.GetAINavigationSystem(this.GetGame()).CalculatePathForCharacter(currentPosition, currentPosition, 0.20, this);
    if IsDefined(evt.target) && navigationPath == null {
      DelayedGameEffectEvt = new DelayedGameEffectEvent();
      DelayedGameEffectEvt.m_activator = evt.activator;
      DelayedGameEffectEvt.m_target = evt.target;
      DelayedGameEffectEvt.m_effectName = n"takedowns";
      DelayedGameEffectEvt.m_effectTag = n"kill";
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(evt.activator, DelayedGameEffectEvt, 0.10);
    };
  }

  public final const func GetScavengeComponent() -> ref<ScavengeComponent> {
    return this.m_scavengeComponent;
  }

  public final const func GetInfluenceComponent() -> ref<InfluenceComponent> {
    return this.m_influenceComponent;
  }

  public final const func GetComfortZoneComponent() -> ref<IComponent> {
    return this.m_comfortZoneComponent;
  }

  protected cb func OnSetDeathParams(evt: ref<gameDeathParamsEvent>) -> Bool {
    this.SetSkipDeathAnimation(evt.noAnimation);
    this.SetDisableRagdoll(evt.noRagdoll);
  }

  protected cb func OnSetDeathDirection(evt: ref<gameDeathDirectionEvent>) -> Bool {
    this.m_customDeathDirection = EnumInt(evt.direction);
  }

  public final const func IsRipperdoc() -> Bool {
    if this.IsVendor() {
      return Equals(TweakDBInterface.GetCharacterRecord(this.GetRecordID()).VendorID().VendorType().Type(), gamedataVendorType.RipperDoc);
    };
    return false;
  }

  protected final func RegisterCallbacks() -> Void {
    let playerPuppet: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    let blackBoard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    if !IsDefined(this.m_upperBodyStateCallbackID) {
      this.m_upperBodyStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody, this, n"OnAimedAt");
    };
    if !IsDefined(this.m_leftCyberwareStateCallbackID) {
      this.m_leftCyberwareStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.LeftHandCyberware, this, n"OnCyberware");
    };
    if !IsDefined(this.m_meleeStateCallbackID) {
      this.m_meleeStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon, this, n"OnMelee");
    };
  }

  protected final func RegisterCallbacksForReactions() -> Void {
    let blackBoard: ref<IBlackboard>;
    let newPlayerID: EntityID;
    let playerPuppet: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    if playerPuppet == null {
      if EntityID.IsDefined(this.m_cachedPlayerID) {
        this.UnregisterCallbacksForReactions();
      };
      this.m_cachedPlayerID = newPlayerID;
      return;
    };
    newPlayerID = playerPuppet.GetEntityID();
    if EntityID.IsDefined(this.m_cachedPlayerID) && newPlayerID != this.m_cachedPlayerID {
      this.UnregisterCallbacksForReactions();
    };
    this.m_cachedPlayerID = newPlayerID;
    blackBoard = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(this.m_cachedPlayerID, GetAllBlackboardDefs().PlayerStateMachine);
    if blackBoard == null {
      return;
    };
    if !IsDefined(this.m_upperBodyStateCallbackID) {
      this.m_upperBodyStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody, this, n"OnAimedAt");
      blackBoard.SignalInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
    };
    if !IsDefined(this.m_leftCyberwareStateCallbackID) {
      this.m_leftCyberwareStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.LeftHandCyberware, this, n"OnCyberware");
      blackBoard.SignalInt(GetAllBlackboardDefs().PlayerStateMachine.LeftHandCyberware);
    };
    if !IsDefined(this.m_meleeStateCallbackID) {
      this.m_meleeStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon, this, n"OnMelee");
      blackBoard.SignalInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon);
    };
    if !IsDefined(this.m_combatGadgetStateCallbackID) {
      this.m_combatGadgetStateCallbackID = blackBoard.RegisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.CombatGadget, this, n"OnCombatGadget");
      blackBoard.SignalInt(GetAllBlackboardDefs().PlayerStateMachine.CombatGadget);
    };
  }

  protected final func UnregisterCallbacksForReactions() -> Void {
    let blackBoard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(this.m_cachedPlayerID, GetAllBlackboardDefs().PlayerStateMachine);
    if IsDefined(blackBoard) {
      if IsDefined(this.m_upperBodyStateCallbackID) {
        blackBoard.UnregisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody, this.m_upperBodyStateCallbackID);
      };
      if IsDefined(this.m_leftCyberwareStateCallbackID) {
        blackBoard.UnregisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.LeftHandCyberware, this.m_leftCyberwareStateCallbackID);
      };
      if IsDefined(this.m_meleeStateCallbackID) {
        blackBoard.UnregisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon, this.m_meleeStateCallbackID);
      };
      if IsDefined(this.m_combatGadgetStateCallbackID) {
        blackBoard.UnregisterListenerInt(GetAllBlackboardDefs().PlayerStateMachine.CombatGadget, this.m_combatGadgetStateCallbackID);
      };
    };
    this.m_upperBodyStateCallbackID = null;
    this.m_leftCyberwareStateCallbackID = null;
    this.m_meleeStateCallbackID = null;
    this.m_combatGadgetStateCallbackID = null;
  }

  protected cb func OnLookedAtEvent(evt: ref<LookedAtEvent>) -> Bool {
    super.OnLookedAtEvent(evt);
    this.m_isLookedAt = evt.isLookedAt;
    this.ResolveReactiOnLookedAt(evt.isLookedAt);
  }

  private final func ResolveReactiOnLookedAt(isLookedAt: Bool) -> Void {
    let broadcaster: ref<StimBroadcasterComponent>;
    if isLookedAt {
      this.RegisterCallbacksForReactions();
    } else {
      this.UnregisterCallbacksForReactions();
      if this.m_wasAimedAtLast || this.m_wasCWChargedAtLast || this.m_wasMeleeChargedAtLast || this.m_wasChargingGadgetAtLast {
        broadcaster = GetPlayer(this.GetGame()).GetStimBroadcasterComponent();
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.StopedAiming, this);
        };
      };
      this.m_wasAimedAtLast = false;
      this.m_wasCWChargedAtLast = false;
      this.m_wasMeleeChargedAtLast = false;
      this.m_wasChargingGadgetAtLast = false;
    };
  }

  public final static func TutorialAddIllegalActionFact(targetPuppet: ref<NPCPuppet>) -> Void {
    let questSystem: ref<QuestsSystem> = GameInstance.GetQuestsSystem(targetPuppet.GetGame());
    if NPCPuppet.IsInCombat(targetPuppet) {
      return;
    };
    if questSystem.GetFact(n"illegal_action_tutorial") == 0 && questSystem.GetFact(n"disable_tutorials") == 0 {
      questSystem.SetFact(n"illegal_action_tutorial", 1);
    };
  }

  protected cb func OnQuestOverrideScannerPreset(evt: ref<OverrideScannerPreset>) -> Bool {
    this.GetPS().SetForcedScannerPreset(evt.scannerPreset);
  }

  protected cb func OnQuestResetScannerPreset(evt: ref<ResetScannerPreset>) -> Bool {
    this.GetPS().SetForcedScannerPreset(TDBID.None());
  }

  protected cb func OnAimedAt(value: Int32) -> Bool {
    let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(GetPlayer(this.GetGame()));
    let broadcaster: ref<StimBroadcasterComponent> = GetPlayer(this.GetGame()).GetStimBroadcasterComponent();
    if 6 == value && weapon.IsRanged() {
      if this.m_isLookedAt {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.AimingAt, this);
        };
        this.m_wasAimedAtLast = true;
        if this.IsCharacterCivilian() {
          NPCPuppet.TutorialAddIllegalActionFact(this);
        };
      };
    } else {
      if this.m_wasAimedAtLast && weapon.IsRanged() {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.StopedAiming, this);
        };
        this.m_wasAimedAtLast = false;
      };
    };
  }

  protected cb func OnCyberware(value: Int32) -> Bool {
    let broadcaster: ref<StimBroadcasterComponent> = GetPlayer(this.GetGame()).GetStimBroadcasterComponent();
    if 5 == value {
      if this.m_isLookedAt {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.AimingAt, this);
        };
        this.m_wasCWChargedAtLast = true;
      };
    } else {
      if this.m_wasCWChargedAtLast {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.StopedAiming, this);
        };
        this.m_wasCWChargedAtLast = false;
      };
    };
  }

  protected cb func OnMelee(value: Int32) -> Bool {
    let broadcaster: ref<StimBroadcasterComponent> = GetPlayer(this.GetGame()).GetStimBroadcasterComponent();
    if 7 == value || 9 == value {
      if this.m_isLookedAt {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.AimingAt, this);
        };
        this.m_wasMeleeChargedAtLast = true;
      };
    } else {
      if this.m_wasMeleeChargedAtLast {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.StopedAiming, this);
        };
        this.m_wasMeleeChargedAtLast = false;
      };
    };
  }

  protected cb func OnCombatGadget(value: Int32) -> Bool {
    let broadcaster: ref<StimBroadcasterComponent> = GetPlayer(this.GetGame()).GetStimBroadcasterComponent();
    if 3 == value {
      if this.m_isLookedAt {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.AimingAt, this);
        };
        this.m_wasChargingGadgetAtLast = true;
      };
    } else {
      if this.m_wasChargingGadgetAtLast {
        if IsDefined(broadcaster) {
          broadcaster.SendDrirectStimuliToTarget(this, gamedataStimType.StopedAiming, this);
        };
        this.m_wasChargingGadgetAtLast = false;
      };
    };
  }

  protected cb func OnNPCStartThrowingGrenadeEvent(evt: ref<NPCThrowingGrenadeEvent>) -> Bool {
    if IsDefined(evt.target) {
      if evt.target.IsPlayer() {
        this.m_isThrowingGrenadeToPlayer = true;
        ReactionManagerComponent.SendVOEventToSquad(evt.target, n"grenade_enemy");
        GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.m_throwingGrenadeDelayEventID);
        this.m_throwingGrenadeDelayEventID = GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, new NPCThrowingGrenadeEvent(), 5.00);
      };
    } else {
      this.m_isThrowingGrenadeToPlayer = false;
    };
  }

  protected final const func PlayVOOnSquadMembers(instigatorIsPlayer: Bool) -> Void {
    let smi: ref<SquadScriptInterface>;
    let squadMembersCount: Uint32;
    let shouldPlayBattlecrySingleEnemy: Bool = false;
    let onlyForMembersInCombat: Bool = false;
    if instigatorIsPlayer && Equals(this.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) {
      if AISquadHelper.GetSquadMemberInterface(this, smi) {
        squadMembersCount = smi.GetMembersCount();
        if squadMembersCount == 2u {
          shouldPlayBattlecrySingleEnemy = true;
        };
      };
      onlyForMembersInCombat = StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"ResetSquadSync");
      if !shouldPlayBattlecrySingleEnemy {
        ReactionManagerComponent.SendVOEventToSquad(this, n"squad_member_died", false, onlyForMembersInCombat);
      } else {
        ReactionManagerComponent.SendVOEventToSquad(this, n"battlecry_single_enemy", false, onlyForMembersInCombat);
      };
    };
  }

  protected final const func PlayVOOnPlayerOrPlayerCompanion(instigator: ref<GameObject>) -> Void {
    if !IsDefined(instigator) {
      return;
    };
    if ScriptedPuppet.IsPlayerCompanion(instigator) {
      GameObject.PlayVoiceOver(instigator, n"coop_reports_kill", n"Scripts:CheckIfKilledByPlayerCompanion");
    } else {
      if instigator.IsPlayer() && (instigator as PlayerPuppet).IsInCombat() {
        if AttackData.IsRangedOrDirect(this.GetLastHitAttackType()) {
          ReactionManagerComponent.SendVOEventToSquad(instigator, n"coop_praise");
        };
      };
    };
  }

  protected final const func CheckNPCKilledThrowingGrenade(instigator: ref<GameObject>) -> Void {
    let achievementRequest: ref<AddAchievementRequest>;
    let dataTrackingSystem: ref<DataTrackingSystem>;
    let achievement: gamedataAchievement = gamedataAchievement.Denied;
    if !IsDefined(instigator) || !this.m_isThrowingGrenadeToPlayer {
      return;
    };
    if !instigator.IsPlayer() && !instigator.IsPlayerControlled() {
      return;
    };
    achievementRequest = new AddAchievementRequest();
    achievementRequest.achievement = achievement;
    dataTrackingSystem = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"DataTrackingSystem") as DataTrackingSystem;
    dataTrackingSystem.QueueRequest(achievementRequest);
  }

  public final func CanGoThroughDoors() -> Bool {
    return this.m_canGoThroughDoors;
  }

  protected cb func OnEnteredPathWithDoors(evt: ref<EnteredPathWithDoors>) -> Bool {
    this.m_canGoThroughDoors = true;
  }

  protected cb func OnFinishedPathWithDoors(evt: ref<FinishedPathWithDoors>) -> Bool {
    this.m_canGoThroughDoors = false;
  }

  protected cb func OnEnteredSplineEvent(evt: ref<EnteredSplineEvent>) -> Bool {
    if evt.useDoors {
      this.m_canGoThroughDoors = true;
    };
  }

  protected cb func OnExitedSplineEvent(evt: ref<ExitedSplineEvent>) -> Bool {
    this.m_canGoThroughDoors = false;
  }

  public final func GetMyKiller() -> wref<GameObject> {
    return this.m_myKiller;
  }

  public final func GetThreatCalculationType() -> EAIThreatCalculationType {
    if NotEquals(this.m_temporaryThreatCalculationType, EAIThreatCalculationType.Regular) {
      return this.m_temporaryThreatCalculationType;
    };
    return this.m_primaryThreatCalculationType;
  }

  public final func ReevaluatEAIThreatCalculationType() -> Void {
    if this.IsBoss() {
      this.m_primaryThreatCalculationType = EAIThreatCalculationType.Boss;
    } else {
      this.m_primaryThreatCalculationType = EAIThreatCalculationType.Regular;
    };
  }

  public final static func SetTemporaryThreatCalculationType(npc: wref<GameObject>, newType: EAIThreatCalculationType) -> Void {
    let evt: ref<AIThreatCalculationEvent>;
    if !IsDefined(npc) {
      return;
    };
    evt = new AIThreatCalculationEvent();
    evt.set = true;
    evt.temporaryThreatCalculationType = newType;
    npc.QueueEvent(evt);
  }

  public final static func RemoveTemporaryThreatCalculationType(npc: wref<GameObject>) -> Void {
    let evt: ref<AIThreatCalculationEvent>;
    if !IsDefined(npc) {
      return;
    };
    evt = new AIThreatCalculationEvent();
    evt.set = false;
    npc.QueueEvent(evt);
  }

  public final static func IsInCombat(npc: wref<ScriptedPuppet>) -> Bool {
    let currentHighLevelState: gamedataNPCHighLevelState = IntEnum<gamedataNPCHighLevelState>(npc.GetPuppetStateBlackboard().GetInt(GetAllBlackboardDefs().PuppetState.HighLevel));
    if Equals(currentHighLevelState, gamedataNPCHighLevelState.Combat) {
      return true;
    };
    return false;
  }

  public final static func IsInCombatWithTarget(npc: wref<ScriptedPuppet>, target: ref<Entity>) -> Bool {
    let targetTrackerComponent: ref<TargetTrackerComponent>;
    let threat: TrackedLocation;
    if !NPCPuppet.IsInCombat(npc) {
      return false;
    };
    targetTrackerComponent = npc.GetTargetTrackerComponent();
    return IsDefined(targetTrackerComponent) && targetTrackerComponent.ThreatFromEntity(target, threat) && Equals(threat.status, AITrackedStatusType.Hostile);
  }

  public final static func IsInAlerted(npc: wref<ScriptedPuppet>) -> Bool {
    let currentHighLevelState: gamedataNPCHighLevelState = IntEnum<gamedataNPCHighLevelState>(npc.GetPuppetStateBlackboard().GetInt(GetAllBlackboardDefs().PuppetState.HighLevel));
    if Equals(currentHighLevelState, gamedataNPCHighLevelState.Alerted) {
      return true;
    };
    return false;
  }

  public final static func IsUnstoppable(npc: wref<ScriptedPuppet>) -> Bool {
    let currentHitReactionMode: EHitReactionMode = IntEnum<EHitReactionMode>(npc.GetPuppetStateBlackboard().GetInt(GetAllBlackboardDefs().PuppetState.HitReactionMode));
    if Equals(currentHitReactionMode, EHitReactionMode.Unstoppable) {
      return true;
    };
    return false;
  }

  public final static func IsSusceptibleOnlyToStaggerAndHigher(npc: wref<ScriptedPuppet>) -> Bool {
    let currentHitReactionMode: EHitReactionMode = IntEnum<EHitReactionMode>(npc.GetPuppetStateBlackboard().GetInt(GetAllBlackboardDefs().PuppetState.HitReactionMode));
    if Equals(currentHitReactionMode, EHitReactionMode.Unstoppable) {
      return true;
    };
    if Equals(currentHitReactionMode, EHitReactionMode.StaggerMin) {
      return true;
    };
    return false;
  }

  protected cb func OnAIThreatCalculationEvent(evt: ref<AIThreatCalculationEvent>) -> Bool {
    if evt.set {
      this.m_temporaryThreatCalculationType = evt.temporaryThreatCalculationType;
    } else {
      this.m_temporaryThreatCalculationType = EAIThreatCalculationType.Regular;
    };
  }

  public final func OnHittingPlayer(playerPuppet: wref<GameObject>, damageInflicted: Float) -> Void {
    let damageInflictedPercent: Float;
    let playerCurrentHealthPercent: Float;
    let playerPuppetID: EntityID;
    let squadmates: array<wref<Entity>>;
    let statPoolSys: ref<StatPoolsSystem>;
    if playerPuppet == null || playerPuppet != GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() || !AISquadHelper.GetSquadmates(this, squadmates) && !this.IsCrowd() {
      return;
    };
    playerPuppetID = playerPuppet.GetEntityID();
    statPoolSys = GameInstance.GetStatPoolsSystem(this.GetGame());
    damageInflictedPercent = 100.00 * damageInflicted / statPoolSys.GetStatPoolMaxPointValue(Cast<StatsObjectID>(playerPuppetID), gamedataStatPoolType.Health);
    playerCurrentHealthPercent = statPoolSys.GetStatPoolValue(Cast<StatsObjectID>(playerPuppetID), gamedataStatPoolType.Health);
    if this.IsCrowd() {
      GameObject.PlayVoiceOver(this, n"crowd_combat", n"Scripts:NPCPuppet:OnHittingPlayer");
    } else {
      if playerCurrentHealthPercent <= 50.00 {
        GameObject.PlayVoiceOver(this, n"attack_fragile_player_order", n"Scripts:NPCPuppet:OnHittingPlayer", 0.50);
      };
      if damageInflictedPercent >= 3.00 || GameInstance.GetGodModeSystem(this.GetGame()).HasGodMode(playerPuppetID, gameGodModeType.Invulnerable) {
        GameObject.PlayVoiceOver(this, n"combat_target_hit", n"Scripts:NPCPuppet:OnHittingPlayer");
      };
    };
  }

  protected cb func OnSmartDespawnRequest(evt: ref<SmartDespawnRequest>) -> Bool {
    GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.smartDespawnDelayID);
    if !GameInstance.GetCameraSystem(this.GetGame()).IsInCameraFrustum(this, 2.00, 0.75) {
      this.despawnTicks += 1u;
    } else {
      this.despawnTicks = 0u;
    };
    if this.despawnTicks >= 5u {
      GameInstance.GetCompanionSystem(this.GetGame()).DespawnSubcharacter(this.GetRecordID());
    } else {
      this.smartDespawnDelayID = GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, evt, 1.00);
    };
  }

  protected cb func OnCancelSmartDespawnRequest(evt: ref<CancelSmartDespawnRequest>) -> Bool {
    GameInstance.GetDelaySystem(this.GetGame()).CancelDelay(this.smartDespawnDelayID);
  }

  protected cb func OnUnregisterAggressiveCrowd(evt: ref<UnregisterAggressiveCrowd>) -> Bool {
    this.UnregisterAggressiveNPC();
  }

  protected cb func OnCleanUpThrownNPCNearbyCrowdNPCs(evt: ref<CleanUpThrownNPCNearbyCrowdNPCs>) -> Bool {
    EntityGameInterface.TryDisableCrowdCollider(this.m_thrownNPCNearbyCrowdNPCs);
    ArrayClear(this.m_thrownNPCNearbyCrowdNPCs);
  }

  public final func SetWasAggressiveCrowd(wasAggressive: Bool) -> Void {
    let evaluateRole: Bool = NotEquals(this.m_wasAggressiveCrowd, wasAggressive);
    this.m_wasAggressiveCrowd = wasAggressive;
    this.GetSensesComponent().SetCrowdsAggressiveState(this.m_wasAggressiveCrowd);
    if evaluateRole {
      this.ForceReEvaluateGameplayRole();
    };
  }

  public const func GetWasAggressiveCrowd() -> Bool {
    return this.m_wasAggressiveCrowd;
  }

  public final func CallUnregisterAggressiveNPC() -> Void {
    let unregisterEvent: ref<UnregisterAggressiveCrowd> = new UnregisterAggressiveCrowd();
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, unregisterEvent, 1.00);
  }

  private final func UnregisterAggressiveNPC() -> Void {
    this.GetAIControllerComponent().GetActionBlackboard().SetFloat(GetAllBlackboardDefs().AIAction.avoidLOSTimeStamp, 0.00);
    GameInstance.GetReactionSystem(this.GetGame()).TryUnregisteringAggressiveNPC(this.GetEntityID());
    this.SetWasAggressiveCrowd(false);
    if this.IsCrowd() {
      this.GetSensesComponent().SetCrowdsAggressiveState(false);
      this.GetSensesComponent().UpdateCrowdMappin();
    };
    this.GetSensesComponent().IgnoreLODChange(false);
    this.GetSensesComponent().Toggle(false);
    this.GetTargetTrackerComponent().ClearThreats();
    this.GetTargetTrackerComponent().Toggle(false);
    GameObject.ChangeAttitudeToNeutral(this, GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject());
  }

  protected final func ForceReEvaluateGameplayRole() -> Void {
    let evt: ref<EvaluateGameplayRoleEvent> = new EvaluateGameplayRoleEvent();
    evt.force = true;
    this.QueueEvent(evt);
  }

  protected cb func OnResetNPCHitReactionTypePrereqStateEvent(evt: ref<ResetNPCHitReactionTypePrereqStateEvent>) -> Bool {
    this.NotifyHitReactionTypeChanged(0);
  }
}

public class NonStealthQuickHackVictimEvent extends Event {

  public let instigatorID: EntityID;

  public final static func Create(instigatorID: EntityID) -> ref<NonStealthQuickHackVictimEvent> {
    let evt: ref<NonStealthQuickHackVictimEvent> = new NonStealthQuickHackVictimEvent();
    evt.instigatorID = instigatorID;
    return evt;
  }
}
