
public final native class DamageSystem extends IDamageSystem {

  public let m_previewTarget: previewTargetStruct;

  public let m_previewLock: Bool;

  public let m_previewRWLockTemp: RWLock;

  public final native func QueueHitEvent(evt: ref<gameHitEvent>, receiver: wref<GameObject>) -> Void;

  public final native func QueueMissEvent(evt: ref<gameMissEvent>) -> Void;

  public final native func StartProjectionPipeline(evt: ref<gameProjectedHitEvent>) -> Void;

  public final static native func GetDamageModFromCurve(curve: CName, value: Float) -> Float;

  private final func ProcessPipeline(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    this.ProcessSyncStageCallbacks(gameDamagePipelineStage.PreProcess, hitEvent, DMGPipelineType.Damage);
    if this.PreProcess(hitEvent, cache) {
      this.ProcessSyncStageCallbacks(gameDamagePipelineStage.Process, hitEvent, DMGPipelineType.Damage);
      this.Process(hitEvent, cache);
      this.ProcessSyncStageCallbacks(gameDamagePipelineStage.ProcessHitReaction, hitEvent, DMGPipelineType.Damage);
      this.ProcessHitReaction(hitEvent);
      this.ProcessSyncStageCallbacks(gameDamagePipelineStage.PostProcess, hitEvent, DMGPipelineType.Damage);
      this.PostProcess(hitEvent);
    };
  }

  private final func ProcessMissPipeline(missEvent: ref<gameMissEvent>) -> Void {
    this.ProcessSyncStageMissCallbacks(missEvent);
  }

  private final func ProcessProjectionPipeline(hitEvent: ref<gameProjectedHitEvent>, cache: ref<CacheData>) -> Void {
    if this.CheckProjectionPipelineTargetConditions(hitEvent) {
      hitEvent.projectionPipeline = true;
      this.ProcessSyncStageCallbacks(gameDamagePipelineStage.PreProcess, hitEvent, DMGPipelineType.ProjectedDamage);
      if this.PreProcess(hitEvent, cache) {
        this.ProcessSyncStageCallbacks(gameDamagePipelineStage.Process, hitEvent, DMGPipelineType.ProjectedDamage);
        this.Process(hitEvent, cache);
        this.ProcessSyncStageCallbacks(gameDamagePipelineStage.PostProcess, hitEvent, DMGPipelineType.ProjectedDamage);
        this.FillInDamageBlackboard(hitEvent);
      };
    };
  }

  private final func CheckProjectionPipelineTargetConditions(hitEvent: ref<gameProjectedHitEvent>) -> Bool {
    let hitZone: EHitReactionZone;
    let hittingBreach: Bool;
    let previewLockLocal: Bool;
    let previewTargetLocal: previewTargetStruct;
    RWLock.AcquireShared(this.m_previewRWLockTemp);
    previewLockLocal = this.m_previewLock;
    previewTargetLocal.currentlyTrackedTarget = this.m_previewTarget.currentlyTrackedTarget;
    previewTargetLocal.currentBodyPart = this.m_previewTarget.currentBodyPart;
    previewTargetLocal.currentlyHittingBreach = this.m_previewTarget.currentlyHittingBreach;
    RWLock.ReleaseShared(this.m_previewRWLockTemp);
    if previewLockLocal {
      return false;
    };
    hitZone = this.GetHitReactionZone(hitEvent);
    hittingBreach = BreachFinderComponent.TryProcessBreachHit(hitEvent, Equals(hitZone, EHitReactionZone.Head), true);
    if !IsDefined(previewTargetLocal.currentlyTrackedTarget) || previewTargetLocal.currentlyTrackedTarget != hitEvent.target || NotEquals(previewTargetLocal.currentlyHittingBreach, hittingBreach) || NotEquals(previewTargetLocal.currentBodyPart, hitZone) && (Equals(previewTargetLocal.currentBodyPart, EHitReactionZone.Head) || Equals(hitZone, EHitReactionZone.Head)) {
      this.SetPreviewTargetStruct(hitEvent.target, hitZone, hittingBreach);
      return true;
    };
    return false;
  }

  private final func SetPreviewTargetStruct(trackedTarget: wref<GameObject>, bodyPart: EHitReactionZone, hittingBreach: Bool) -> Void {
    RWLock.Acquire(this.m_previewRWLockTemp);
    this.m_previewTarget.currentlyTrackedTarget = trackedTarget;
    this.m_previewTarget.currentBodyPart = bodyPart;
    this.m_previewTarget.currentlyHittingBreach = hittingBreach;
    RWLock.Release(this.m_previewRWLockTemp);
  }

  public final func ClearPreviewTargetStruct() -> Void {
    this.SetPreviewTargetStruct(null, EHitReactionZone.Special, false);
  }

  public final func SetPreviewLock(newState: Bool) -> Void {
    RWLock.Acquire(this.m_previewRWLockTemp);
    this.m_previewLock = newState;
    RWLock.Release(this.m_previewRWLockTemp);
  }

  private final func GetHitReactionZone(hitEvent: ref<gameProjectedHitEvent>) -> EHitReactionZone {
    let hitShapes: array<HitShapeData> = hitEvent.hitRepresentationResult.hitShapes;
    let hitUserData: ref<HitShapeUserDataBase> = DamageSystemHelper.GetHitShapeUserDataBase(hitShapes[0]);
    return HitShapeUserDataBase.GetHitReactionZone(hitUserData);
  }

  private final func CreateDebugDataName(gameObject: wref<GameObject>) -> CName {
    let displayName: String;
    let entityIDString: String;
    let result: CName;
    if !IsDefined(gameObject) {
      return n"[Unkown]";
    };
    entityIDString = EntityID.ToDebugStringDecimal(gameObject.GetEntityID());
    displayName = gameObject.GetDisplayName();
    if Equals(displayName, "") {
      return StringToName(NameToString(gameObject.GetClassName()) + " | " + entityIDString);
    };
    result = StringToName(GetLocalizedText(displayName) + " | " + entityIDString);
    return result;
  }

  private final func GatherDebugData(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>, out hitDebugData: ref<HitDebugData>) -> Void {
    let appliedDamage: ref<DamageDebugData>;
    let calculatedDamage: ref<DamageDebugData>;
    let damageType: gamedataDamageType;
    let entityIDString: String;
    let hitFlagEnums: String;
    let i: Int32;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let flags: array<SHitFlag> = attackData.GetFlags();
    let appliedDamages: array<Float> = hitEvent.attackComputed.GetAttackValues();
    let calculatedDamages: array<Float> = hitEvent.attackComputed.GetOriginalAttackValues();
    hitDebugData.attackTime = attackData.GetAttackTime();
    hitDebugData.instigator = attackData.GetInstigator();
    hitDebugData.source = attackData.GetSource();
    hitDebugData.target = hitEvent.target;
    hitDebugData.sourceHitPosition = attackData.GetSource().GetWorldPosition();
    hitDebugData.targetHitPosition = hitEvent.target.GetWorldPosition();
    hitDebugData.instigatorName = this.CreateDebugDataName(hitDebugData.instigator);
    hitDebugData.sourceName = this.CreateDebugDataName(hitDebugData.source);
    hitDebugData.targetName = this.CreateDebugDataName(hitDebugData.target);
    hitDebugData.sourceAttackDebugData = attackData.GetAttackDefinition().GetDebugData();
    if IsDefined(attackData.GetWeapon()) {
      entityIDString = EntityID.ToDebugStringDecimal(attackData.GetWeapon().GetEntityID());
      hitDebugData.sourceWeaponName = StringToName(TDBID.ToStringDEBUG(ItemID.GetTDBID(attackData.GetWeapon().GetItemID())) + " | " + entityIDString);
      if Equals(hitDebugData.sourceWeaponName, n"None") {
        hitDebugData.sourceWeaponName = StringToName("[Unkown] " + entityIDString);
      };
    };
    hitDebugData.sourceAttackName = StringToName(TDBID.ToStringDEBUG(attackData.GetAttackDefinition().GetRecord().GetID()));
    i = 0;
    while i < ArraySize(appliedDamages) {
      damageType = IntEnum<gamedataDamageType>(i);
      appliedDamage = new DamageDebugData();
      appliedDamage.statPoolType = gamedataStatPoolType.Health;
      appliedDamage.damageType = damageType;
      appliedDamage.value = appliedDamages[i];
      ArrayPush(hitDebugData.appliedDamages, appliedDamage);
      calculatedDamage = new DamageDebugData();
      calculatedDamage.statPoolType = gamedataStatPoolType.Health;
      calculatedDamage.damageType = damageType;
      calculatedDamage.value = calculatedDamages[i];
      ArrayPush(hitDebugData.calculatedDamages, calculatedDamage);
      i += 1;
    };
    hitDebugData.hitType = StringToName(EnumValueToString("gamedataAttackType", EnumInt(attackData.GetAttackType())));
    i = 0;
    while i < ArraySize(flags) {
      hitFlagEnums += EnumValueToString("hitFlag", EnumInt(flags[i].flag));
      hitFlagEnums += "," + ToString(flags[i].source);
      hitFlagEnums += "|";
      i += 1;
    };
    hitDebugData.hitFlags = StringToName(hitFlagEnums);
  }

  private final func FillInDamageBlackboard(hitEvent: ref<gameHitEvent>) -> Void {
    let damage: Int32;
    let player: wref<PlayerPuppet> = hitEvent.attackData.GetInstigator() as PlayerPuppet;
    let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_NameplateData);
    if IsDefined(player) && IsDefined(blackboard) {
      damage = Cast<Int32>(hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health));
      if damage != blackboard.GetInt(GetAllBlackboardDefs().UI_NameplateData.DamageProjection) {
        blackboard.SetInt(GetAllBlackboardDefs().UI_NameplateData.DamageProjection, damage, true);
      };
    };
  }

  private final func GatherServerData(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>, out serverHitData: ref<ServerHitData>) -> Void {
    if hitEvent.attackData.HasFlag(hitFlag.DealNoDamage) {
      return;
    };
    serverHitData.damageInfos = this.ConvertHitDataToDamageInfo(hitEvent);
    serverHitData.instigator = hitEvent.attackData.GetInstigator();
  }

  public final func ConvertHitDataToDamageInfo(hitEvent: ref<gameHitEvent>) -> [DamageInfo] {
    let attackValues: array<Float>;
    let breachComponent: ref<BreachComponent>;
    let breachFinder: ref<BreachFinderComponent>;
    let dmgInfo: DamageInfo;
    let dmgPosition: Vector4;
    let finalDmgValue: Float;
    let i: Int32;
    let player: ref<PlayerPuppet>;
    let result: array<DamageInfo>;
    let hitShapes: array<HitShapeData> = hitEvent.hitRepresentationResult.hitShapes;
    dmgInfo.userData = new DamageInfoUserData();
    dmgInfo.userData.flags = hitEvent.attackData.GetFlags();
    if ArraySize(hitShapes) != 0 {
      dmgPosition = hitShapes[0].result.hitPositionEnter;
      dmgInfo.userData.hitShapeType = DamageSystemHelper.GetHitShapeTypeFromData(hitShapes[0]);
    } else {
      dmgPosition = hitEvent.hitPosition;
    };
    if hitEvent.attackData.HasFlag(hitFlag.BreachHit) && !AttackData.IsRangedOrDirectOrThrown(hitEvent.attackData.GetAttackType()) {
      player = hitEvent.attackData.GetInstigator() as PlayerPuppet;
      if IsDefined(player) {
        breachFinder = player.GetBreachFinderComponent();
        if IsDefined(breachFinder) {
          breachComponent = breachFinder.GetTrackedBreachComponent();
          if IsDefined(breachComponent) {
            dmgPosition = breachComponent.GetPosition();
          };
        };
      };
    };
    dmgInfo.hitPosition = dmgPosition;
    dmgInfo.hitType = hitEvent.attackData.GetHitType();
    if IsDefined(hitEvent.target) {
      if !IsMultiplayer() || hitEvent.target.IsReplicated() || EntityID.IsStatic(hitEvent.target.GetEntityID()) {
        dmgInfo.entityHit = hitEvent.target;
      };
    };
    if IsDefined(hitEvent.attackData.GetInstigator()) {
      if !IsMultiplayer() || hitEvent.attackData.GetInstigator().IsReplicated() || EntityID.IsStatic(hitEvent.attackData.GetInstigator().GetEntityID()) {
        dmgInfo.instigator = hitEvent.attackData.GetInstigator();
      };
    };
    if !hitEvent.attackData.HasFlag(hitFlag.DamageNullified) {
      attackValues = hitEvent.attackComputed.GetAttackValues();
      i = 0;
      while i < ArraySize(attackValues) {
        finalDmgValue += attackValues[i];
        i += 1;
      };
    } else {
      finalDmgValue = 0.00;
    };
    if AttackData.IsDoT(hitEvent.attackData) {
      dmgInfo.damageType = hitEvent.attackComputed.GetDominatingDamageType();
    } else {
      dmgInfo.damageType = gamedataDamageType.Physical;
    };
    dmgInfo.damageValue = finalDmgValue;
    ArrayPush(result, dmgInfo);
    return result;
  }

  private final func ProcessClientHit(serverHitData: ref<ServerHitData>) -> Void {
    if IsDefined(serverHitData.instigator) && serverHitData.instigator.IsControlledByLocalPeer() {
      serverHitData.instigator.DisplayHitUI(serverHitData.damageInfos);
    };
  }

  private final func ProcessClientKill(serverKillData: ref<ServerKillData>) -> Void {
    if IsDefined(serverKillData.killInfo.killerEntity) && serverKillData.killInfo.killerEntity.IsControlledByLocalPeer() {
      serverKillData.killInfo.killerEntity.DisplayKillUI(serverKillData.killInfo);
    };
  }

  private final func PreProcess(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Bool {
    this.ConvertDPSToHitDamage(hitEvent);
    this.CalculateDamageVariants(hitEvent);
    this.CacheLocalVars(hitEvent, cache);
    if Cast<Bool>(GetDamageSystemLogFlags() & damageSystemLogFlags.GENERAL) {
    };
    this.ModifyHitFlagsForPlayer(hitEvent, cache);
    if this.CheckForQuickExit(hitEvent, cache) {
      return false;
    };
    this.InvulnerabilityCheck(hitEvent, cache);
    this.ImmortalityCheck(hitEvent, cache);
    this.DeathCheck(hitEvent);
    this.ModifyHitData(hitEvent);
    return true;
  }

  private final func ConvertDPSToHitDamage(hitEvent: ref<gameHitEvent>) -> Void {
    let projectilesPerShot: Float;
    let statsSystem: ref<StatsSystem>;
    let weaponObject: ref<WeaponObject> = hitEvent.attackData.GetWeapon();
    if !IsDefined(weaponObject) {
      return;
    };
    if !hitEvent.attackData.GetInstigator().IsPlayer() {
      if weaponObject.IsRanged() && !AttackData.IsMelee(hitEvent.attackData.GetAttackType()) {
        statsSystem = GameInstance.GetStatsSystem(hitEvent.attackData.GetSource().GetGame());
        projectilesPerShot = statsSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.ProjectilesPerShot);
        if projectilesPerShot > 0.00 {
          hitEvent.attackComputed.MultAttackValue(1.00 / projectilesPerShot);
        };
      };
    };
  }

  private final func CalculateDamageVariants(hitEvent: ref<gameHitEvent>) -> Void {
    let rand: Float;
    if hitEvent.projectionPipeline {
      return;
    };
    if hitEvent.attackData.GetInstigator().IsPlayer() && !hitEvent.target.IsPlayer() {
      rand = RandRangeF(0.90, 1.10);
      hitEvent.attackComputed.MultAttackValue(rand);
    };
  }

  private final func ModifyHitData(hitEvent: ref<gameHitEvent>) -> Void {
    DamageManager.ModifyHitData(hitEvent);
    if hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) == 0.00 {
      hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"no_valid_damage");
    };
    this.ProcessDamageReduction(hitEvent);
    this.ProcessLocalizedDamage(hitEvent);
    this.ProcessInstantKill(hitEvent);
    this.ProcessDodge(hitEvent);
    this.ProcessEvasion(hitEvent);
    this.ProcessMitigation(hitEvent);
    this.ProcessPlayerIncomingDamageMultiplier(hitEvent);
    this.PreProcessVehicleTarget(hitEvent);
  }

  private final func ProcessDamageReduction(hitEvent: ref<gameHitEvent>) -> Void {
    let attackValues: array<Float>;
    let damageType: gamedataDamageType;
    let i: Int32;
    let instigatorNpcType: gamedataNPCType;
    let resistance: Float;
    let target: ref<GameObject> = hitEvent.target;
    let instigatorPuppet: ref<ScriptedPuppet> = hitEvent.attackData.GetInstigator() as ScriptedPuppet;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(target.GetGame());
    if hitEvent.attackData.HasFlag(hitFlag.ReduceDamage) {
      hitEvent.attackComputed.MultAttackValue(0.10);
    };
    if StatusEffectSystem.ObjectHasStatusEffectOfType(instigatorPuppet, gamedataStatusEffectType.Poisoned) && instigatorPuppet != target {
      hitEvent.attackComputed.MultAttackValue(1.00 - statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.PercentDamageReductionFromPoisonedEnemies));
    };
    if AttackData.IsExplosion(attackType) || hitEvent.attackData.HasFlag(hitFlag.BreachExplosion) {
      resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.ExplosionResistance) * 0.01;
      if resistance != 0.00 {
        hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
      };
    };
    if AttackData.IsMelee(attackType) {
      resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.MeleeResistance) * 0.01;
      if resistance != 0.00 {
        hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
      };
    };
    if AttackData.IsHack(attackType) {
      resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.QuickhackResistance) * 0.01;
      if resistance != 0.00 {
        hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
      };
    };
    if AttackData.IsDoT(hitEvent.attackData) {
      resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.DamageOverTimeResistance) * 0.01;
      if resistance != 0.00 {
        hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
      };
    };
    if IsDefined(instigatorPuppet) {
      if Equals(instigatorPuppet.GetNPCRarity(), gamedataNPCRarity.Boss) || Equals(instigatorPuppet.GetNPCRarity(), gamedataNPCRarity.MaxTac) {
        resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.BossResistance) * 0.01;
        if resistance != 0.00 {
          hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
        };
      };
      instigatorNpcType = instigatorPuppet.GetNPCType();
      if Equals(instigatorNpcType, gamedataNPCType.Drone) || Equals(instigatorNpcType, gamedataNPCType.Android) || Equals(instigatorNpcType, gamedataNPCType.Mech) {
        resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.MechResistance) * 0.01;
        if resistance != 0.00 {
          hitEvent.attackComputed.MultAttackValue(1.00 - resistance);
        };
      };
    };
    if AttackData.IsRangedOnly(attackType) {
      return;
    };
    attackValues = hitEvent.attackComputed.GetAttackValues();
    i = 0;
    while i < ArraySize(attackValues) {
      if attackValues[i] > 0.00 {
        damageType = IntEnum<gamedataDamageType>(i);
        if NotEquals(damageType, gamedataDamageType.Physical) {
          resistance = statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), RPGManager.GetResistanceTypeFromDamageType(damageType)) * 0.01;
          attackValues[i] = MaxF(attackValues[i] * (1.00 - resistance), 1.00);
        };
      };
      i += 1;
    };
    hitEvent.attackComputed.SetAttackValues(attackValues);
  }

  private final func ProcessLocalizedDamage(hitEvent: ref<gameHitEvent>) -> Void {
    let hitShapeDamageMod: Float;
    let hitUserData: ref<HitShapeUserDataBase>;
    let immunity: Int32;
    let multValue: Float;
    let hitShapes: array<HitShapeData> = hitEvent.hitRepresentationResult.hitShapes;
    if !hitEvent.attackData.GetInstigator().IsPlayer() {
      return;
    };
    if AttackData.IsAreaOfEffect(hitEvent.attackData.GetAttackType()) {
      return;
    };
    if ArraySize(hitShapes) > 0 {
      hitUserData = DamageSystemHelper.GetHitShapeUserDataBase(hitShapes[0]);
    };
    if !IsDefined(hitUserData) {
      if IsDefined(hitEvent.target as WeakspotObject) {
        BreachFinderComponent.TryProcessBreachHit(hitEvent, false);
      };
      return;
    };
    if hitEvent.attackData.HasFlag(hitFlag.DamageNullified) {
      hitEvent.attackComputed.MultAttackValue(0.00);
    };
    if HitShapeUserDataBase.IsInternalWeakspot(hitUserData) || IsDefined(hitEvent.target as WeakspotObject) {
      hitEvent.attackData.AddFlag(hitFlag.WeakspotHit, n"ProcessLocalizedDamage");
    };
    if AttackData.IsRangedOrDirectOrThrown(hitEvent.attackData.GetAttackType()) && HitShapeUserDataBase.IsHitReactionZoneHead(hitUserData) {
      GameInstance.GetTelemetrySystem(hitEvent.target.GetGame()).LogHeadshotGGP(1);
      multValue = this.GetHeadshotDamageModifier(GameInstance.GetStatsSystem(hitEvent.target.GetGame()), hitEvent.attackData);
      immunity = Cast<Int32>(GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.HeadshotImmunity));
      if !FloatIsEqual(multValue, 0.00) && immunity == 0 {
        hitEvent.attackData.AddFlag(hitFlag.Headshot, n"ProcessLocalizedDamage");
      };
    };
    BreachFinderComponent.TryProcessBreachHit(hitEvent, hitEvent.attackData.HasFlag(hitFlag.Headshot));
    hitShapeDamageMod = HitShapeUserDataBase.GetHitShapeDamageMod(hitUserData);
    if hitShapeDamageMod != 0.00 {
      hitEvent.attackComputed.MultAttackValue(hitShapeDamageMod);
    };
    if Equals(hitUserData.m_hitShapeType, EHitShapeType.None) {
      hitEvent.attackComputed.MultAttackValue(0.00);
    };
  }

  private final func ProcessInstantKill(hitEvent: ref<gameHitEvent>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    let targetID: StatsObjectID = Cast<StatsObjectID>(hitEvent.target.GetEntityID());
    if hitEvent.projectionPipeline {
      return;
    };
    if attackData.HasFlag(hitFlag.Kill) {
      attackData.AddFlag(hitFlag.DealNoDamage, n"instant_kill");
      attackData.AddFlag(hitFlag.DontShowDamageFloater, n"instant_kill");
      GameInstance.GetStatPoolsSystem(GetGameInstance()).RequestSettingStatPoolMinValue(targetID, gamedataStatPoolType.Health, attackData.GetInstigator());
    };
  }

  private final func ProcessDodge(hitEvent: ref<gameHitEvent>) -> Void {
    if GameInstance.GetStatsSystem(GetGameInstance()).GetStatBoolValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.IsDodging) {
      hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"ProcessDodge");
      if hitEvent.target.IsPlayer() {
        this.SetTutorialFact(n"gmpl_player_dodged_attack");
      };
    };
  }

  private final func ProcessEvasion(hitEvent: ref<gameHitEvent>) -> Void {
    let randomFloat: Float;
    let evasionChance: Float = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.Evasion);
    if evasionChance > 0.00 && !hitEvent.attackData.HasFlag(hitFlag.DamageOverTime) {
      randomFloat = RandRangeF(0.00, 100.00);
      if evasionChance > randomFloat {
        hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"ProcessEvasion");
        hitEvent.attackData.AddFlag(hitFlag.WasEvaded, n"ProcessEvasion");
      };
    };
  }

  private final func ProcessMitigation(hitEvent: ref<gameHitEvent>) -> Void {
    let mitigationMult: Float;
    let randomFloat: Float;
    let mitigationChance: Float = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.MitigationChance);
    if mitigationChance > 0.00 {
      randomFloat = RandRangeF(0.00, 100.00);
      if mitigationChance > randomFloat {
        mitigationMult = 1.00 - GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.MitigationStrength) * 0.01;
        hitEvent.attackComputed.MultAttackValue(mitigationMult);
        hitEvent.attackData.AddFlag(hitFlag.WasMitigated, n"ProcessMitigation");
      };
    };
  }

  private final func ProcessPlayerIncomingDamageMultiplier(hitEvent: ref<gameHitEvent>) -> Void {
    let playerIncomingDamageMultiplier: Float = hitEvent.attackData.GetAttackDefinition().GetRecord().PlayerIncomingDamageMultiplier() * PreventionSystem.GetDamageToPlayerMultiplier(hitEvent.target.GetGame());
    if IsDefined(hitEvent.target as PlayerPuppet) || ScriptedPuppet.IsPlayerCompanion(hitEvent.target) {
      if playerIncomingDamageMultiplier != 1.00 {
      };
      hitEvent.attackComputed.MultAttackValue(playerIncomingDamageMultiplier);
    } else {
      if ScriptedPuppet.IsPlayerCompanion(hitEvent.attackData.GetInstigator()) && !hitEvent.target.IsPlayer() {
        hitEvent.attackComputed.MultAttackValue(playerIncomingDamageMultiplier);
      };
    };
  }

  private final func InvulnerabilityCheck(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    if hitEvent.attackData.HasFlag(hitFlag.IgnoreImmortalityModes) {
      return;
    };
    if this.IsTargetInvulnerable(cache) {
      hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"invulnerable");
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.GENERAL) {
      };
    };
    if GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.IsInvulnerable) > 0.00 {
      hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"invulnerable stat flag");
    };
  }

  private final func DEBUG_InvulnerabilityCheckForVehicle(hitEvent: ref<gameHitEvent>) -> Bool {
    let targetVehicle: ref<VehicleObject> = hitEvent.target as VehicleObject;
    if IsDefined(targetVehicle) {
      return VehicleComponent.PlayerPassengerHasGodModeFromCheatSystem(hitEvent.target.GetGame(), hitEvent.target.GetEntityID(), gameGodModeType.Invulnerable);
    };
    return false;
  }

  private final func ImmortalityCheck(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    if hitEvent.attackData.HasFlag(hitFlag.IgnoreImmortalityModes) {
      return;
    };
    if this.IsTargetImmortal(cache) {
      hitEvent.attackData.AddFlag(hitFlag.ImmortalTarget, n"immortal");
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.GENERAL) {
      };
    };
  }

  private final func DeathCheck(hitEvent: ref<gameHitEvent>) -> Void {
    let deviceTarget: ref<Device> = hitEvent.target as Device;
    let gameObjectTarget: ref<GameObject> = hitEvent.target;
    let puppetTarget: ref<ScriptedPuppet> = hitEvent.target as ScriptedPuppet;
    if IsDefined(deviceTarget) && deviceTarget.GetDevicePS().IsBroken() || IsDefined(gameObjectTarget) && gameObjectTarget.IsDead() {
      hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"dead");
    };
    if IsDefined(puppetTarget) && puppetTarget.IsDeadNoStatPool() {
      hitEvent.attackData.AddFlag(hitFlag.TargetWasAlreadyDeadNoStatPool, n"dead");
    };
  }

  private final func SendVehicleImpactTelemetryIfValid(hitEvent: ref<gameHitEvent>) -> Void {
    let vehicleHitEvent: ref<gameVehicleHitEvent>;
    if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Physical) <= 0.00 {
      return;
    };
    if !hitEvent.attackData.GetInstigator().IsPlayer() {
      return;
    };
    vehicleHitEvent = hitEvent as gameVehicleHitEvent;
    if !hitEvent.attackData.HasFlag(hitFlag.VehicleImpact) && !IsDefined(vehicleHitEvent) {
      return;
    };
    GameInstance.GetTelemetrySystem(hitEvent.attackData.GetInstigator().GetGame()).LogPlayerVehicleImpact();
  }

  private final func Process(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    if hitEvent.attackData.HasFlag(hitFlag.DealNoDamage) {
      return;
    };
    this.ProcessPlayerFixedPercentageOverride(hitEvent);
    this.ProcessDeviceExplosionDamageToTierNPC(hitEvent);
    this.ProcessGrenadeExplosionDamageToPlayer(hitEvent);
    this.CalculateSourceModifiers(hitEvent, cache);
    this.CalculateTargetModifiers(hitEvent);
    this.CalculateSourceVsTargetModifiers(hitEvent);
    this.CalculateGlobalModifiers(hitEvent, cache);
    this.ProcessCrowdTarget(hitEvent);
    this.ProcessVehicleTarget(hitEvent, cache);
    this.ProcessVehicleHit(hitEvent);
    this.ProcessRagdollHit(hitEvent);
    this.ProcessTurretAttack(hitEvent);
    this.ProcessDeviceTarget(hitEvent);
    this.ProcessQuickHackModifiers(hitEvent);
    this.ProcessOneShotProtection(hitEvent);
    if !hitEvent.projectionPipeline {
      this.DealDamages(hitEvent);
    };
  }

  private final func ProcessHitReaction(hitEvent: ref<gameHitEvent>) -> Void {
    hitEvent.target.ReactToHitProcess(hitEvent);
  }

  private final func ProcessRagdollHit(hitEvent: ref<gameHitEvent>) -> Void {
    let curveDamagePercentage: Float;
    let heightDeltaMultiplier: Float;
    let isHighFall: Bool;
    let targetIsFriendly: Bool;
    let targetMaxHealth: Float;
    let targetPuppet: ref<ScriptedPuppet>;
    let terminalVelocityReached: Bool;
    let ragdollHitEvent: ref<gameRagdollHitEvent> = hitEvent as gameRagdollHitEvent;
    if !IsDefined(ragdollHitEvent) {
      return;
    };
    targetPuppet = hitEvent.target as ScriptedPuppet;
    if !IsDefined(targetPuppet) {
      return;
    };
    if targetPuppet.IsCrowd() {
      if targetPuppet as NPCPuppet.m_shouldBeImmuneToVehicleHit {
        hitEvent.attackComputed.SetAttackValue(0.00);
        return;
      };
    };
    targetIsFriendly = Equals(GameObject.GetAttitudeTowards(targetPuppet, GameInstance.GetPlayerSystem(targetPuppet.GetGame()).GetLocalPlayerControlledGameObject()), EAIAttitude.AIA_Friendly);
    if targetIsFriendly {
      hitEvent.attackComputed.SetAttackValue(0.00);
      return;
    };
    terminalVelocityReached = ragdollHitEvent.speedDelta >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollImpactKillVelocityThreshold", 11.00);
    isHighFall = ragdollHitEvent.speedDelta >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollHighFallVelocityThreshold", 8.00) && ragdollHitEvent.heightDelta >= TweakDBInterface.GetFloat(t"AIGeneralSettings.ragdollHighFallHeightThreshold", 6.00);
    targetMaxHealth = GameInstance.GetStatsSystem(targetPuppet.GetGame()).GetStatValue(Cast<StatsObjectID>(targetPuppet.GetEntityID()), gamedataStatType.Health);
    if terminalVelocityReached || isHighFall {
      if IsDefined(targetPuppet as NPCPuppet) {
        (targetPuppet as NPCPuppet).SetMyKiller(hitEvent.attackData.GetInstigator());
        (targetPuppet as NPCPuppet).MarkForDeath();
      };
      hitEvent.attackComputed.SetAttackValue(targetMaxHealth, gamedataDamageType.Physical);
      hitEvent.attackData.AddFlag(hitFlag.DeterministicDamage, n"ragdoll_collision");
    } else {
      if NotEquals(RPGManager.CalculatePowerDifferential(targetPuppet), gameEPowerDifferential.IMPOSSIBLE) {
        curveDamagePercentage = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"puppet_ragdoll_force_to_damage", ragdollHitEvent.speedDelta, n"ragdoll_speed_to_damage");
        heightDeltaMultiplier = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"puppet_ragdoll_force_to_damage", ragdollHitEvent.heightDelta, n"ragdoll_altitude_difference_multiplier");
        hitEvent.attackComputed.SetAttackValue(curveDamagePercentage * heightDeltaMultiplier * targetMaxHealth, gamedataDamageType.Physical);
      };
    };
  }

  private final func ProcessCrowdTarget(hitEvent: ref<gameHitEvent>) -> Void {
    let targetPuppet: ref<NPCPuppet> = hitEvent.target as NPCPuppet;
    let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator();
    if !IsDefined(targetPuppet) || !targetPuppet.IsCrowd() || IsDefined(hitEvent as gameRagdollHitEvent) || IsDefined(hitEvent as gameVehicleHitEvent) {
      return;
    };
    if hitEvent.projectionPipeline {
      return;
    };
    if instigator.IsPlayer() {
      NPCPuppet.TutorialAddIllegalActionFact(targetPuppet);
      if !NPCPuppet.IsInCombat(targetPuppet) {
        hitEvent.attackData.AddFlag(hitFlag.DontShowDamageFloater, n"target is crowd");
      };
    };
  }

  private final func ProcessTurretAttack(hitEvent: ref<gameHitEvent>) -> Void {
    let isTurretFriendlyToPlayer: Bool;
    let instigatorTurret: ref<SecurityTurret> = hitEvent.attackData.GetInstigator() as SecurityTurret;
    if !IsDefined(instigatorTurret) {
      return;
    };
    isTurretFriendlyToPlayer = Equals(GameObject.GetAttitudeTowards(instigatorTurret, GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerControlledGameObject()), EAIAttitude.AIA_Friendly);
    if isTurretFriendlyToPlayer {
      hitEvent.attackComputed.MultAttackValue(0.60);
    };
  }

  private final func ProcessTurretDamageTakenFromMelee(hitEvent: ref<gameHitEvent>) -> Void {
    let targetTurret: ref<SecurityTurret> = hitEvent.target as SecurityTurret;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    if IsDefined(targetTurret) && (AttackData.IsLightMelee(attackType) || AttackData.IsStrongMelee(attackType) || hitEvent.attackData.HasFlag(hitFlag.BodyPerksMeleeAttack)) {
      hitEvent.attackComputed.MultAttackValue(1.20);
    };
  }

  private final func ProcessDeviceTarget(hitEvent: ref<gameHitEvent>) -> Void {
    let targetDevice: ref<Device> = hitEvent.target as Device;
    if IsDefined(targetDevice) && !targetDevice.ShouldShowDamageNumber() {
      hitEvent.attackData.AddFlag(hitFlag.DontShowDamageFloater, n"device");
    };
  }

  private final func ProcessOneShotProtection(hitEvent: ref<gameHitEvent>) -> Void {
    let damageCap: Float;
    let damages: array<Float>;
    let difficulty: gameDifficulty;
    let i: Int32;
    let maxHealth: Float;
    let maxPercentDamagePerHit: Float;
    let reductionProportion: Float;
    let statsDataSys: ref<StatsDataSystem>;
    let weapon: wref<WeaponObject> = hitEvent.attackData.GetWeapon();
    if !IsDefined(weapon) {
      return;
    };
    if !hitEvent.attackData.GetInstigator().IsPlayer() && hitEvent.target.IsPlayer() {
      statsDataSys = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame());
      difficulty = statsDataSys.GetDifficulty();
      switch difficulty {
        case gameDifficulty.Story:
          maxPercentDamagePerHit = TDB.GetFloat(t"Constants.DamageSystem.maxPercentDamagePerHitStory");
          break;
        case gameDifficulty.Easy:
          maxPercentDamagePerHit = TDB.GetFloat(t"Constants.DamageSystem.maxPercentDamagePerHitEasy");
          break;
        case gameDifficulty.Hard:
          maxPercentDamagePerHit = TDB.GetFloat(t"Constants.DamageSystem.maxPercentDamagePerHitHard");
          break;
        case gameDifficulty.VeryHard:
          maxPercentDamagePerHit = TDB.GetFloat(t"Constants.DamageSystem.maxPercentDamagePerHitVeryHard");
      };
      maxHealth = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.Health);
      damageCap = (maxHealth * maxPercentDamagePerHit) / 100.00;
      if hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) > damageCap {
        reductionProportion = damageCap / hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
        damages = hitEvent.attackComputed.GetAttackValues();
        i = 0;
        while i < ArraySize(damages) {
          damages[i] *= reductionProportion;
          i += 1;
        };
        hitEvent.attackComputed.SetAttackValues(damages);
      };
    };
  }

  private final func ProcessPlayerFixedPercentageOverride(hitEvent: ref<gameHitEvent>) -> Void {
    let attackRecord: ref<Attack_GameEffect_Record>;
    let difficulty: gameDifficulty;
    let hitFlags: array<String>;
    let i: Int32;
    let instig: wref<GameObject>;
    let isExplosionReductionPerkBought: Bool;
    let numerOfDamageTypes: Float;
    let overridePlayerDamageFixedPercentage: Float;
    let playerMaxHealth: Float;
    let statsDataSys: ref<StatsDataSystem>;
    let totalDamage: Float;
    let player: wref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
    if !IsDefined(player) {
      return;
    };
    if StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.DeviceExplosionInvulnerability") {
      return;
    };
    if !(Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Explosion) || Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.PressureWave)) {
      return;
    };
    attackRecord = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    hitFlags = attackRecord.HitFlags();
    i = 0;
    while i < ArraySize(hitFlags) {
      if Equals(hitFlags[i], "OverridePlayerDamageWithFixedPercentage") {
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Physical) > 0.00 {
          numerOfDamageTypes = numerOfDamageTypes + 1.00;
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Thermal) > 0.00 {
          numerOfDamageTypes = numerOfDamageTypes + 1.00;
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Electric) > 0.00 {
          numerOfDamageTypes = numerOfDamageTypes + 1.00;
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Chemical) > 0.00 {
          numerOfDamageTypes = numerOfDamageTypes + 1.00;
        };
        playerMaxHealth = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Health);
        overridePlayerDamageFixedPercentage = TweakDBInterface.GetFloat(attackRecord.GetID() + t".overridePlayerDamageFixedPercentage", 0.20);
        statsDataSys = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame());
        difficulty = statsDataSys.GetDifficulty();
        switch difficulty {
          case gameDifficulty.Story:
            overridePlayerDamageFixedPercentage *= 0.50;
            break;
          case gameDifficulty.Easy:
            overridePlayerDamageFixedPercentage *= 0.75;
            break;
          case gameDifficulty.Hard:
            overridePlayerDamageFixedPercentage *= 1.00;
            break;
          case gameDifficulty.VeryHard:
            overridePlayerDamageFixedPercentage *= 1.30;
        };
        isExplosionReductionPerkBought = PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Tech_Left_Perk_3_01) == 1;
        instig = hitEvent.attackData.GetInstigator();
        if isExplosionReductionPerkBought && instig.IsPlayer() {
          overridePlayerDamageFixedPercentage *= 0.50;
        };
        totalDamage = (overridePlayerDamageFixedPercentage * playerMaxHealth) / numerOfDamageTypes;
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Physical) > 0.00 {
          hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Physical);
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Thermal) > 0.00 {
          hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Thermal);
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Electric) > 0.00 {
          hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Electric);
        };
        if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Chemical) > 0.00 {
          hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Chemical);
        };
      };
      i += 1;
    };
    if ArrayContains(hitFlags, "DeviceExplosionAttack") {
      StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.DeviceExplosionInvulnerability", player.GetEntityID());
    };
  }

  private final func ProcessDeviceExplosionDamageToTierNPC(hitEvent: ref<gameHitEvent>) -> Void {
    let attackRecord: ref<Attack_GameEffect_Record>;
    let bonusDamageMult: Float;
    let hitFlags: array<String>;
    let i: Int32;
    let isHackedExplosionPerkBought: Bool;
    let npcHealth: Float;
    let npcRarityMultiplier: Float;
    let player: ref<GameObject>;
    let targetNpcRarity: gamedataNPCRarity;
    let totalDamage: Float;
    let npc: wref<ScriptedPuppet> = hitEvent.target as NPCPuppet;
    if !IsDefined(npc) {
      return;
    };
    if !Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Explosion) {
      return;
    };
    attackRecord = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    hitFlags = attackRecord.HitFlags();
    i = 0;
    while i < ArraySize(hitFlags) {
      if Equals(hitFlags[i], "OverrideNPCDamageBasedOnTiers") {
        npcHealth = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatType.Health);
        targetNpcRarity = (hitEvent.target as ScriptedPuppet).GetNPCRarity();
        switch targetNpcRarity {
          case gamedataNPCRarity.Trash:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".trashNPCMaxHPDamage", 0.20);
            break;
          case gamedataNPCRarity.Weak:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".weakNPCMaxHPDamage", 0.20);
            break;
          case gamedataNPCRarity.Normal:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".normalNPCMaxHPDamage", 0.20);
            break;
          case gamedataNPCRarity.Officer:
          case gamedataNPCRarity.Rare:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".rareNPCMaxHPDamage", 0.20);
            break;
          case gamedataNPCRarity.Elite:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".eliteNPCMaxHPDamage", 0.20);
            break;
          case gamedataNPCRarity.Boss:
          case gamedataNPCRarity.MaxTac:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".bossNPCMaxHPDamage", 0.02);
            break;
          default:
            npcRarityMultiplier = TweakDBInterface.GetFloat(attackRecord.GetID() + t".normalNPCMaxHPDamage", 0.02);
        };
        totalDamage = npcHealth * npcRarityMultiplier;
        player = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerControlledGameObject();
        isHackedExplosionPerkBought = PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Left_Perk_1_1) == 1;
        if isHackedExplosionPerkBought {
          bonusDamageMult = 1.00;
          if hitEvent.attackData.HasFlag(hitFlag.QuickHack) {
            bonusDamageMult += 0.40;
          };
          if StatusEffectSystem.ObjectHasStatusEffect(npc, t"BaseStatusEffect.DistractionDuration") || StatusEffectSystem.ObjectHasStatusEffect(npc, t"BaseStatusEffect.WasQuickHacked") {
            bonusDamageMult += 0.80;
          };
          totalDamage *= bonusDamageMult;
        };
        hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Thermal);
      };
      i += 1;
    };
  }

  private final func ProcessGrenadeExplosionDamageToPlayer(hitEvent: ref<gameHitEvent>) -> Void {
    let attackRecord: ref<Attack_GameEffect_Record>;
    let difficulty: gameDifficulty;
    let grenadeFromNpc: Bool;
    let hitFlags: array<String>;
    let isExplosionReductionPerkBought: Bool;
    let overridePlayerDamageFixedPercentage: Float;
    let playerMaxHealth: Float;
    let totalDamage: Float;
    let tweakid: TweakDBID;
    let player: wref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
    let instig: wref<GameObject> = hitEvent.attackData.GetInstigator();
    if !IsDefined(player) {
      return;
    };
    attackRecord = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    hitFlags = attackRecord.HitFlags();
    if !ArrayContains(hitFlags, "PlayerGrenadeDamageOverride") {
      return;
    };
    grenadeFromNpc = isExplosionReductionPerkBought = false;
    if instig.IsNPC() {
      grenadeFromNpc = true;
    };
    if ArrayContains(hitFlags, "PlayerEMPGrenadeDOTOverride") || ArrayContains(hitFlags, "EmpGrenade") {
      tweakid = t"Items.GrenadeEMPRegular";
    } else {
      if ArrayContains(hitFlags, "PlayerBurnGrenadeDOTOverride") {
        tweakid = t"Items.GrenadeIncendiaryRegular";
      } else {
        if ArrayContains(hitFlags, "PlayerBioGrenadeDOTOverride") {
          tweakid = t"Items.GrenadeBiohazardRegular";
        } else {
          if ArrayContains(hitFlags, "PlayerFragGrenadeDamageOverride") {
            tweakid = t"Items.GrenadeFragRegular";
          };
        };
      };
    };
    if TDBID.IsValid(tweakid) {
      difficulty = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame()).GetDifficulty();
      if Equals(grenadeFromNpc, false) {
        switch difficulty {
          case gameDifficulty.Story:
            overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".storyDifficultySelfDamagePerTick");
            break;
          case gameDifficulty.Easy:
            overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".normalDifficultySelfDamagePerTick");
            break;
          case gameDifficulty.Hard:
            overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".hardDifficultySelfDamagePerTick");
            break;
          case gameDifficulty.VeryHard:
            overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".veryHardDifficultySelfDamagePerTick");
        };
        isExplosionReductionPerkBought = PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Tech_Left_Perk_3_01) == 1;
      } else {
        if grenadeFromNpc {
          switch difficulty {
            case gameDifficulty.Story:
              overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".npc_storyDifficultySelfDamagePerTick");
              break;
            case gameDifficulty.Easy:
              overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".npc_normalDifficultySelfDamagePerTick");
              break;
            case gameDifficulty.Hard:
              overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".npc_hardDifficultySelfDamagePerTick");
              break;
            case gameDifficulty.VeryHard:
              overridePlayerDamageFixedPercentage = TDB.GetFloat(tweakid + t".npc_veryHardDifficultySelfDamagePerTick");
          };
        };
      };
    };
    playerMaxHealth = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Health);
    totalDamage = overridePlayerDamageFixedPercentage * 0.01 * playerMaxHealth;
    if isExplosionReductionPerkBought {
      totalDamage *= 0.50;
    };
    if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Physical) > 0.00 {
      hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Physical);
    };
    if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Thermal) > 0.00 {
      hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Thermal);
    };
    if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Electric) > 0.00 {
      hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Electric);
    };
    if hitEvent.attackComputed.GetAttackValue(gamedataDamageType.Chemical) > 0.00 {
      hitEvent.attackComputed.SetAttackValue(totalDamage, gamedataDamageType.Chemical);
    };
  }

  private final func ProcessQuickHackModifiers(hitEvent: ref<gameHitEvent>) -> Void {
    let attackRecord: ref<Attack_GameEffect_Record>;
    let attackType: gamedataAttackType;
    let attackValues: array<Float>;
    let currentMemory: Float;
    let damageMultiplier: Float;
    let hitFlags: array<String>;
    let i: Int32;
    let j: Int32;
    let maxMemory: Float;
    let statValue: Float;
    let statusEffects: array<ref<StatusEffect>>;
    let targetNpcRarity: gamedataNPCRarity;
    let targetNpcType: gamedataNPCType;
    let tempValue: Float;
    let statusEffectSystem: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(GetGameInstance());
    let player: wref<PlayerPuppet> = hitEvent.attackData.GetInstigator() as PlayerPuppet;
    if !IsDefined(player) {
      return;
    };
    if !hitEvent.target.IsPuppet() {
      return;
    };
    if hitEvent.attackData.HasFlag(hitFlag.CriticalHit) {
      attackType = hitEvent.attackData.GetAttackType();
      if GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.ShortCircuitOnCriticalHit) == 1.00 && !statusEffectSystem.HasStatusEffectWithTag(hitEvent.target.GetEntityID(), n"Overload") && (Equals(attackType, gamedataAttackType.ChargedWhipAttack) || Equals(attackType, gamedataAttackType.Melee) || Equals(attackType, gamedataAttackType.QuickMelee) || Equals(attackType, gamedataAttackType.Ranged) || Equals(attackType, gamedataAttackType.StrongMelee) || Equals(attackType, gamedataAttackType.Thrown) || Equals(attackType, gamedataAttackType.WhipAttack)) {
        statusEffectSystem.ApplyStatusEffect(hitEvent.target.GetEntityID(), t"BaseStatusEffect.Overload", GameObject.GetTDBID(player), player.GetEntityID(), 1u, hitEvent.hitDirection);
      };
    };
    if statusEffectSystem.HasStatusEffect(hitEvent.target.GetEntityID(), t"BaseStatusEffect.OverheatLevel4") && NotEquals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Hack) {
      attackValues = hitEvent.attackComputed.GetAttackValues();
      attackValues[3] += attackValues[2] * TweakDBInterface.GetFloat(t"Items.OverheatLvl4Program.bonusThermalDamageFactor", 0.00);
      hitEvent.attackComputed.SetAttackValues(attackValues);
    };
    if statusEffectSystem.HasStatusEffect(hitEvent.target.GetEntityID(), t"BaseStatusEffect.OverheatLevel4PlusPlus") && NotEquals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Hack) {
      attackValues = hitEvent.attackComputed.GetAttackValues();
      attackValues[3] += attackValues[2] * TweakDBInterface.GetFloat(t"Items.OverheatLvl4PlusPlusProgram.bonusThermalDamageFactor", 0.00);
      hitEvent.attackComputed.SetAttackValues(attackValues);
    };
    if NotEquals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Hack) {
      return;
    };
    damageMultiplier = 1.00;
    attackRecord = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    hitFlags = attackRecord.HitFlags();
    targetNpcType = (hitEvent.target as ScriptedPuppet).GetNPCType();
    targetNpcRarity = (hitEvent.target as ScriptedPuppet).GetNPCRarity();
    i = 0;
    while i < ArraySize(hitFlags) {
      if Equals(hitFlags[i], "FleshDamageBonus") {
        if Equals(targetNpcType, gamedataNPCType.Human) {
          damageMultiplier += TweakDBInterface.GetFloat(attackRecord.GetID() + t".fleshDamageBonusMultiplier", 1.00);
        };
      };
      if hitEvent.attackData.GetInstigator() == player && Equals(hitFlags[i], "DamageBasedOnMissingMemoryBonus") {
        currentMemory = GameInstance.GetStatPoolsSystem(player.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Memory, false);
        maxMemory = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Memory);
        if currentMemory < maxMemory {
          tempValue = maxMemory - currentMemory;
          if statusEffectSystem.HasStatusEffect(player.GetEntityID(), t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff") {
            tempValue *= TDB.GetFloat(attackRecord.GetID() + t".damageBasedOnMissingMemoryBonusMultiplier") * 2.00;
          } else {
            tempValue *= TDB.GetFloat(attackRecord.GetID() + t".damageBasedOnMissingMemoryBonusMultiplier");
          };
          damageMultiplier += MinF(tempValue, TDB.GetFloat(attackRecord.GetID() + t".damageBasedOnMissingMemoryBonusMax"));
        };
      };
      if Equals(hitFlags[i], "CyberwareMalfunctionDamageBonus") {
        tempValue = 0.00;
        statusEffectSystem.GetAppliedEffectsWithTag(hitEvent.target.GetEntityID(), n"CyberwareMalfunction", statusEffects);
        j = 0;
        while j < ArraySize(statusEffects) {
          tempValue += Cast<Float>(statusEffects[j].GetStackCount());
          j += 1;
        };
        tempValue *= TweakDBInterface.GetFloat(attackRecord.GetID() + t".cyberwareMalfunctionDamageBonus", 0.00);
        damageMultiplier += tempValue;
      };
      if Equals(hitFlags[i], "NonEliteDamageBonus") {
        if Equals(targetNpcRarity, gamedataNPCRarity.Normal) || Equals(targetNpcRarity, gamedataNPCRarity.Trash) || Equals(targetNpcRarity, gamedataNPCRarity.Weak) || Equals(targetNpcRarity, gamedataNPCRarity.Rare) || Equals(targetNpcRarity, gamedataNPCRarity.Officer) {
          damageMultiplier += TweakDBInterface.GetFloat(attackRecord.GetID() + t".nonEliteDamageBonusMultiplier", 0.00);
        };
      };
      if Equals(hitFlags[i], "DamageOverTime") {
        damageMultiplier += GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.QuickhackDamageOverTimeBonusMultiplier);
      };
      i += 1;
    };
    if StatusEffectSystem.ObjectHasStatusEffect(hitEvent.target, t"MinigameAction.VulnerabilityMinigame") {
      statValue = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.QuickhackExtraDamageMultiplier);
      if statValue > 0.00 {
        damageMultiplier += statValue;
      };
    };
    if hitEvent.attackData.GetInstigator().IsPlayer() {
      statValue = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.QuickhackDamageBonusMultiplier);
      if statValue > 0.00 {
        damageMultiplier += statValue;
      };
    };
    if damageMultiplier != 1.00 {
      hitEvent.attackComputed.MultAttackValue(damageMultiplier);
    };
  }

  private final func PreProcessVehicleTarget(hitEvent: ref<gameHitEvent>) -> Void {
    let hitComponentName: CName;
    let targetVehicle: ref<VehicleObject> = hitEvent.target as VehicleObject;
    if IsDefined(targetVehicle) {
      hitComponentName = hitEvent.hitComponent.GetName();
      if targetVehicle.ShouldDamageSystemIgnoreHit(hitComponentName) {
        hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"DamageSystemIgnoreHit");
      };
      hitEvent.attackData.AddFlag(hitFlag.ForceNoCrit, n"PreProcessVehicleTarget");
    };
  }

  private final func ProcessVehicleTarget(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    let godModeSystem: ref<GodModeSystem>;
    let instigator: ref<GameObject>;
    let minimumHealthPercent: Float;
    let statsSystem: ref<StatsSystem>;
    let targetVehicle: ref<VehicleObject>;
    let vehicleDamageQualityDivisor: Float;
    let weaponObject: ref<WeaponObject>;
    let weaponType: gamedataItemType;
    let multiplier: Float = 1.00;
    if hitEvent.projectionPipeline {
      return;
    };
    targetVehicle = hitEvent.target as VehicleObject;
    weaponObject = hitEvent.attackData.GetWeapon();
    if IsDefined(targetVehicle) {
      if targetVehicle.IsPlayerMounted() || targetVehicle.IsCrowdVehicle() || !targetVehicle.HasPassengers() {
        hitEvent.attackData.AddFlag(hitFlag.DontShowDamageFloater, n"Target is either the player vehicle, a crowd vehicle or does not have any passengers");
      };
      if targetVehicle.GetVehicleComponent().IsVehicleImmuneInDecay() {
        hitEvent.attackComputed.MultAttackValue(0.00);
        hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"VehicleInDecayState");
        return;
      };
      instigator = hitEvent.attackData.GetInstigator();
      if hitEvent.attackData.HasFlag(hitFlag.PlayerWallImpact) {
        hitEvent.attackComputed.MultAttackValue(0.00);
        hitEvent.attackData.AddFlag(hitFlag.DealNoDamage, n"PlayerWallImpact");
        return;
      };
      if hitEvent.attackData.HasFlag(hitFlag.VehicleImpact) {
        hitEvent.attackComputed.SetAttackValues(hitEvent.attackComputed.GetOriginalAttackValues());
        multiplier = hitEvent.attackData.GetVehicleImpactForce();
        if targetVehicle.IsPlayerDriver() {
          if PlayerDevelopmentSystem.GetData(VehicleComponent.GetDriver(targetVehicle.GetGame(), targetVehicle, targetVehicle.GetEntityID())).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Body_Right_Milestone_1) {
            multiplier *= 0.50;
          };
        } else {
          if instigator.IsPlayer() && hitEvent.attackData.HasFlag(hitFlag.VehicleImpactWithPlayer) {
            if PlayerDevelopmentSystem.GetData(instigator).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Body_Right_Milestone_1) {
              multiplier *= 1.50;
            };
          };
        };
      } else {
        weaponType = RPGManager.GetItemRecord(weaponObject.GetItemID()).ItemType().Type();
        statsSystem = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
        if !this.IsOverridenExplosionVsVehicleHit(hitEvent) {
          if !targetVehicle.IsPlayerMounted() && instigator.IsPlayer() {
            multiplier *= 1.00 + statsSystem.GetStatValue(Cast<StatsObjectID>(instigator.GetEntityID()), gamedataStatType.VehicleDamagePercentBonus);
            multiplier *= 1.00 + statsSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.WeaponVehicleDamagePercentBonus);
            vehicleDamageQualityDivisor = statsSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.VehicleDamageQualityDivisor);
            if vehicleDamageQualityDivisor > 0.00 {
              multiplier /= vehicleDamageQualityDivisor;
            };
            multiplier *= this.GetVehiclePerksDamageMultiplier(hitEvent.attackData);
          } else {
            hitEvent.attackComputed.MultAttackValue(0.00);
            if targetVehicle.IsPlayerMounted() {
              if targetVehicle.TrySetHitCooldown() {
                hitEvent.attackComputed.SetAttackValue(15.00, gamedataDamageType.Physical);
              } else {
                hitEvent.attackComputed.SetAttackValue(1.00, gamedataDamageType.Physical);
              };
            } else {
              hitEvent.attackComputed.SetAttackValue(4.00, gamedataDamageType.Physical);
            };
          };
          switch weaponType {
            case gamedataItemType.Wea_HeavyMachineGun:
              multiplier *= 1.30;
              break;
            default:
          };
        };
      };
      hitEvent.attackComputed.MultAttackValue(multiplier);
      minimumHealthPercent = statsSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.VehicleMinHealthPercentWhenDamaged);
      if Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.QuickMelee) {
        minimumHealthPercent = MaxF(minimumHealthPercent, TweakDBInterface.GetFloat(t"player.quickMelee.quickMeleeVehicleMinHealthPercentWhenDamaged", 20.00));
      };
      godModeSystem = GameInstance.GetGodModeSystem(hitEvent.target.GetGame());
      if godModeSystem.HasGodMode(hitEvent.target.GetEntityID(), gameGodModeType.Immortal) {
        minimumHealthPercent = MaxF(minimumHealthPercent, targetVehicle.GetVehicleComponent().GetVehicleDecayThreshold() + 1.00);
      };
      if minimumHealthPercent > 0.00 {
        hitEvent.attackData.SetMinimumHealthPercent(minimumHealthPercent);
      };
    };
  }

  private final func CalculateVehicleTargetRangedDamage(weaponObject: ref<WeaponObject>, chargeDamageMultiplier: Float, statSystem: ref<StatsSystem>) -> Float {
    let multiplier: Float = 1.00;
    let desiredWeaponDPS: Float = 90.00;
    let weaponMultiplier: Float = statSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.CycleTimeBase);
    weaponMultiplier /= statSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.ProjectilesPerShot);
    multiplier *= desiredWeaponDPS * weaponMultiplier;
    if chargeDamageMultiplier > 0.00 {
      multiplier *= chargeDamageMultiplier;
    };
    return multiplier;
  }

  private final func CalculateVehicleTargetMeleeDamage(weaponObject: ref<WeaponObject>, attackType: gamedataAttackType, isBodySlam: Bool, statSystem: ref<StatsSystem>) -> Float {
    let weaponMultiplier: Float;
    let multiplier: Float = 1.00;
    let physicalImpulse: Float = 1.00;
    let desiredWeaponDPS: Float = 24.00;
    let strongMeleeMultiplier: Float = 2.50;
    let bodySlamMultiplier: Float = 0.30;
    if Equals(attackType, gamedataAttackType.QuickMelee) {
      multiplier = desiredWeaponDPS;
      physicalImpulse = 10.00;
    } else {
      if isBodySlam {
        multiplier = desiredWeaponDPS * bodySlamMultiplier;
      } else {
        weaponMultiplier = statSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.AttacksPerSecondBase);
        multiplier *= desiredWeaponDPS / weaponMultiplier;
        if Equals(attackType, gamedataAttackType.StrongMelee) {
          multiplier *= strongMeleeMultiplier;
        };
      };
      physicalImpulse = statSystem.GetStatValue(Cast<StatsObjectID>(weaponObject.GetEntityID()), gamedataStatType.PhysicalImpulse);
    };
    multiplier *= PowF(physicalImpulse, 0.30) - 0.80;
    return multiplier;
  }

  private final func ProcessVehicleHit(hitEvent: ref<gameHitEvent>) -> Void {
    let curveDamagePercentage: Float;
    let instaKilledByVehicleCollision: Bool;
    let isCrowdOrCivilian: Bool;
    let isMechanical: Bool;
    let magnitude: Float;
    let preyVelocityComponent: Vector4;
    let resultantVelocity: Vector4;
    let targetIsFriendly: Bool;
    let targetMaxHealth: Float;
    let targetPuppet: ref<ScriptedPuppet>;
    let vehicleHitEvent: ref<gameVehicleHitEvent> = hitEvent as gameVehicleHitEvent;
    if !IsDefined(vehicleHitEvent) {
      return;
    };
    targetPuppet = hitEvent.target as ScriptedPuppet;
    if !IsDefined(targetPuppet) {
      return;
    };
    if targetPuppet.IsCrowd() {
      if targetPuppet as NPCPuppet.m_shouldBeImmuneToVehicleHit {
        hitEvent.attackComputed.SetAttackValue(0.00);
        return;
      };
    };
    targetIsFriendly = Equals(GameObject.GetAttitudeTowards(targetPuppet, GameInstance.GetPlayerSystem(targetPuppet.GetGame()).GetLocalPlayerControlledGameObject()), EAIAttitude.AIA_Friendly);
    if targetIsFriendly {
      hitEvent.attackComputed.SetAttackValue(0.00);
      return;
    };
    preyVelocityComponent = Vector4.Normalize(vehicleHitEvent.vehicleVelocity) * Vector4.Dot(vehicleHitEvent.preyVelocity, vehicleHitEvent.vehicleVelocity) / Vector4.Length(vehicleHitEvent.vehicleVelocity);
    resultantVelocity = vehicleHitEvent.vehicleVelocity + preyVelocityComponent;
    magnitude = Vector4.Length(resultantVelocity);
    targetMaxHealth = GameInstance.GetStatsSystem(targetPuppet.GetGame()).GetStatValue(Cast<StatsObjectID>(targetPuppet.GetEntityID()), gamedataStatType.Health);
    isCrowdOrCivilian = targetPuppet.IsCrowd() || targetPuppet.IsCivilian();
    isMechanical = targetPuppet.HasMechanicalImpactComponent();
    instaKilledByVehicleCollision = magnitude >= TweakDBInterface.GetFloat(t"AIGeneralSettings.vehicleHitKillThreshold", 25.00) || isCrowdOrCivilian && magnitude >= TweakDBInterface.GetFloat(t"AIGeneralSettings.vehicleHitCrowdKillThreshold", 20.00);
    if !isMechanical && instaKilledByVehicleCollision {
      if IsDefined(targetPuppet as NPCPuppet) {
        (targetPuppet as NPCPuppet).SetMyKiller(hitEvent.attackData.GetInstigator());
        (targetPuppet as NPCPuppet).MarkForDeath();
      };
      hitEvent.attackComputed.SetAttackValue(targetMaxHealth, gamedataDamageType.Physical);
      hitEvent.attackData.AddFlag(hitFlag.DeterministicDamage, n"vehicle_collision");
    } else {
      if isCrowdOrCivilian {
        if hitEvent.attackData.GetInstigator().IsPlayer() {
          curveDamagePercentage = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", magnitude, n"crowd_hit_damage");
          if curveDamagePercentage == 0.00 {
            if GameObject.IsCooldownActive(targetPuppet, n"vehicleSlowHitOnCivilian") {
              curveDamagePercentage = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", magnitude, n"crowd_hit_high_damage");
              GameObject.StartCooldown(targetPuppet, n"vehicleSlowHitOnCivilian", 0.00);
            } else {
              hitEvent.attackData.AddFlag(hitFlag.DontShowDamageFloater, n"dealing 0 damage");
            };
            GameObject.StartCooldown(targetPuppet, n"vehicleSlowHitOnCivilian", 3.00);
          };
        } else {
          curveDamagePercentage = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", magnitude, n"crowd_hit_high_damage");
        };
      } else {
        curveDamagePercentage = GameInstance.GetStatsDataSystem(targetPuppet.GetGame()).GetValueFromCurve(n"vehicle_collision_damage", magnitude, n"npc_hit_damage");
      };
      if isMechanical {
        curveDamagePercentage = MinF(curveDamagePercentage, 0.25);
      };
      hitEvent.attackComputed.SetAttackValue(curveDamagePercentage * targetMaxHealth, gamedataDamageType.Physical);
      if Equals(RPGManager.CalculatePowerDifferential(targetPuppet), gameEPowerDifferential.IMPOSSIBLE) {
        hitEvent.attackComputed.MultAttackValue(0.50);
      };
    };
    GameInstance.GetTelemetrySystem(targetPuppet.GetGame()).LogDamageByVehicle(hitEvent);
  }

  private final func DealDamages(hitEvent: ref<gameHitEvent>) -> Void {
    let resourcesLost: array<SDamageDealt>;
    let forReal: Bool = !GameInstance.GetRuntimeInfo(GetGameInstance()).IsClient();
    StatPoolsManager.ApplyDamage(hitEvent, forReal, resourcesLost);
    this.SendDamageEvents(hitEvent, resourcesLost);
  }

  private final func SendDamageEvents(hitEvent: ref<gameHitEvent>, const resourcesLost: script_ref<[SDamageDealt]>) -> Void {
    let damageDealtEvent: ref<gameTargetDamageEvent>;
    let damageReceivedEvent: ref<gameDamageReceivedEvent>;
    let totalDamage: Float = 0.00;
    let i: Int32 = 0;
    while i < ArraySize(Deref(resourcesLost)) {
      totalDamage += Deref(resourcesLost)[i].value;
      i += 1;
    };
    damageDealtEvent = new gameTargetDamageEvent();
    damageDealtEvent.target = hitEvent.target;
    damageDealtEvent.attackData = hitEvent.attackData;
    damageDealtEvent.hitPosition = hitEvent.hitPosition;
    damageDealtEvent.hitDirection = hitEvent.hitDirection;
    damageDealtEvent.hitRepresentationResult = hitEvent.hitRepresentationResult;
    damageDealtEvent.damage = totalDamage;
    hitEvent.attackData.GetInstigator().QueueEvent(damageDealtEvent);
    if totalDamage > 0.00 {
      damageReceivedEvent = new gameDamageReceivedEvent();
      damageReceivedEvent.totalDamageReceived = totalDamage;
      damageReceivedEvent.hitEvent = hitEvent;
      hitEvent.target.QueueEvent(damageReceivedEvent);
    };
  }

  private final func PostProcess(hitEvent: ref<gameHitEvent>) -> Void {
    let poiseDamage: Float;
    this.ProcessStatusEffects(hitEvent);
    this.ProcessReturnedDamage(hitEvent);
    DamageManager.PostProcess(hitEvent);
    if hitEvent.attackData.GetInstigator().IsPlayer() && hitEvent.attackData.GetInstigator().HasFinisherAvailable() && hitEvent.target.CanReceivePoiseDamage() && !hitEvent.attackData.GetInstigator().GetIsInFastFinisher() {
      poiseDamage = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
      switch hitEvent.attackData.GetAttackType() {
        case gamedataAttackType.QuickMelee:
          poiseDamage *= TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_3.poiseQuickMeleeMultiplier", 1.00);
          break;
        case gamedataAttackType.StrongMelee:
          poiseDamage *= TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_3.poiseStrongMeleeMultiplier", 1.00);
      };
      if GameObject.TargetHasDebuff(hitEvent.target) {
        poiseDamage *= TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_3.poiseDebufMultiplier", 1.00);
      };
      if hitEvent.target.IsInFinisherHealthThreshold(hitEvent.attackData.GetInstigator()) {
        poiseDamage *= TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_3.poiseBossLowHealthMultiplier", 1.00);
      };
      GameInstance.GetStatPoolsSystem(hitEvent.target.GetGame()).RequestChangingStatPoolValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatPoolType.Poise, -poiseDamage, hitEvent.attackData.GetInstigator(), false, false);
    };
    if !hitEvent.attackData.HasFlag(hitFlag.TargetWasAlreadyDeadNoStatPool) && hitEvent.attackData.GetInstigator().IsPlayer() {
      this.SendDamageRequestToPreventionSystem(hitEvent);
    };
  }

  private final func SendDamageRequestToPreventionSystem(hitEvent: ref<gameHitEvent>) -> Void {
    let npcMaxHealth: Float = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.Health);
    let damage: Float = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    let damageDealtPercent: Float = damage / npcMaxHealth;
    if damageDealtPercent > 0.01 {
      PreventionSystem.CreateNewPreventionDamageRequest(GetGameInstance(), hitEvent.target, hitEvent.attackData.GetAttackTime(), hitEvent.attackData.GetAttackType(), damageDealtPercent, false);
    };
  }

  protected final static func HasGrandFinaleStatFlag(const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
    return RPGManager.HasStatFlag(scriptInterface.executionOwner, gamedataStatType.CanDoGrandFinaleWithMantisBlades);
  }

  private final func ProcessStatusEffects(hitEvent: ref<gameHitEvent>) -> Void {
    let effectDamages: array<wref<StatusEffectAttackData_Record>>;
    let i: Int32;
    let instantApply: Bool;
    let instantEffects: array<SHitStatusEffect>;
    let statusEffectID: TweakDBID;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let target: ref<GameObject> = hitEvent.target;
    let targetId: EntityID = target.GetEntityID();
    let targetPuppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
    let statusEffectSystem: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(GetGameInstance());
    let instigator: ref<GameObject> = attackData.GetInstigator();
    let hasPerkPurchased: Bool = RPGManager.HasStatFlag(instigator, gamedataStatType.CanDoGrandFinaleWithMantisBlades);
    let playerJustLeaped: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(instigator, n"JustLeaped");
    let isMechanical: Bool = targetPuppet.IsMechanical();
    let isExo: Bool = AIActionHelper.CheckAbility(targetPuppet, TweakDBInterface.GetGameplayAbilityRecord(t"Ability.IsExo"));
    if attackData.WasBlocked() || !instigator.IsPlayer() && attackData.WasDeflectedAny() || attackData.HasFlag(hitFlag.FriendlyFireIgnored) {
      return;
    };
    if GameObject.IsVehicle(hitEvent.target) && !this.ShouldProcessStatusEffectsOnVehicleDriver(hitEvent, targetId) {
      return;
    };
    if !target.IsPlayer() && instigator.IsPlayer() && Equals(GameObject.GetAttitudeTowards(target, instigator), EAIAttitude.AIA_Friendly) {
      return;
    };
    instantEffects = hitEvent.attackData.GetStatusEffects();
    i = 0;
    while i < ArraySize(instantEffects) {
      statusEffectID = instantEffects[i].id;
      if !this.IsImmune(target, statusEffectID, attackData) {
        statusEffectSystem.ApplyStatusEffect(targetId, statusEffectID, GameObject.GetTDBID(instigator), instigator.GetEntityID(), Cast<Uint32>(instantEffects[i].stacks), hitEvent.hitDirection);
      };
      i += 1;
    };
    attackData.GetAttackDefinition().GetRecord().StatusEffects(effectDamages);
    i = 0;
    while i < ArraySize(effectDamages) {
      statusEffectID = effectDamages[i].StatusEffect().GetID();
      if !this.IsImmune(target, statusEffectID, attackData) {
        instantApply = effectDamages[i].ApplyImmediately();
        if instantApply {
          statusEffectSystem.ApplyStatusEffect(targetId, statusEffectID, GameObject.GetTDBID(instigator), instigator.GetEntityID(), 1u, hitEvent.hitDirection);
        } else {
          StatPoolsManager.ApplyStatusEffectDamage(hitEvent, effectDamages[i].ResistPool(), statusEffectID);
        };
      };
      i += 1;
    };
    if instigator.IsPlayer() && statusEffectSystem.HasStatusEffectWithTag(targetId, n"GagOpportunity") {
      statusEffectSystem.RemoveStatusEffect(targetId, t"BaseStatusEffect.GagOpportunity");
      statusEffectSystem.ApplyStatusEffect(targetId, t"BaseStatusEffect.Gag");
    };
    if !target.IsPlayer() && instigator.IsPlayer() && hasPerkPurchased && playerJustLeaped && !isMechanical && !isExo {
      StatusEffectHelper.ApplyStatusEffect(target, t"BaseStatusEffect.MantisBladesRelicDismemberment");
    };
    this.ProcessStatusEffectApplicationStats(hitEvent);
  }

  private final static func GetMantisBladesCripplingRandStatusEffectID() -> TweakDBID {
    let appliedStatusEffect: TweakDBID;
    let statusEffectsIDs: array<TweakDBID>;
    let statusEffectNames: array<String> = TDB.GetStringArray(t"BaseStatusEffect.CripplingStatusEffects");
    let size: Int32 = ArraySize(statusEffectNames);
    let i: Int32 = 0;
    while i < size {
      ArrayPush(statusEffectsIDs, TDBID.Create(statusEffectNames[i]));
      i += 1;
    };
    i = RandRange(0, ArraySize(statusEffectsIDs));
    appliedStatusEffect = statusEffectsIDs[i];
    return appliedStatusEffect;
  }

  private final func ProcessStatusEffectApplicationStats(hitEvent: ref<gameHitEvent>) -> Void {
    let bleedingID: TweakDBID;
    let burningID: TweakDBID;
    let electrocutedID: TweakDBID;
    let poisonedID: TweakDBID;
    let stunnedID: TweakDBID;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let attackSubType: gamedataAttackSubtype = hitEvent.attackData.GetAttackSubtype();
    let isTargetPlayer: Bool = hitEvent.target.IsPlayer();
    let isTargetPuppet: Bool = hitEvent.target.IsPuppet();
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(hitEvent.target.GetGame());
    if isTargetPuppet && (AttackData.IsLightMelee(attackType) || AttackData.IsStrongMelee(attackType) || AttackData.IsRangedOrDirectOrThrown(attackType)) && NotEquals(attackSubType, gamedataAttackSubtype.BodySlamAttack) {
      if isTargetPlayer {
        bleedingID = t"BaseStatusEffect.PlayerBleeding";
        burningID = t"BaseStatusEffect.PlayerBurning";
        poisonedID = t"BaseStatusEffect.PlayerPoisoned";
        electrocutedID = t"BaseStatusEffect.PlayerElectrocuted";
      } else {
        if transactionSystem.HasTag(hitEvent.attackData.GetInstigator(), n"Saburo_Tanto_Bleed", hitEvent.attackData.GetWeapon().GetItemID()) {
          bleedingID = t"BaseStatusEffect.Tanto_Saburo_Bleeding";
        } else {
          if transactionSystem.HasTag(hitEvent.attackData.GetInstigator(), n"Saburo_Katana_Bleed", hitEvent.attackData.GetWeapon().GetItemID()) {
            bleedingID = t"BaseStatusEffect.Katana_Saburo_Bleeding";
          } else {
            if Equals(TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(hitEvent.attackData.GetWeapon().GetItemID())).Evolution().Type(), gamedataWeaponEvolution.Blade) {
              bleedingID = t"BaseStatusEffect.KenjutsuBleeding";
            } else {
              bleedingID = t"BaseStatusEffect.Bleeding";
            };
          };
        };
        if transactionSystem.HasTag(hitEvent.attackData.GetInstigator(), n"Padre_Burn", hitEvent.attackData.GetWeapon().GetItemID()) {
          burningID = t"BaseStatusEffect.Liberty_Padre_Burning";
        } else {
          if transactionSystem.HasTag(hitEvent.attackData.GetInstigator(), n"AirDrop_Burn", hitEvent.attackData.GetWeapon().GetItemID()) {
            burningID = t"BaseStatusEffect.AirDrop_Burning";
          } else {
            burningID = t"BaseStatusEffect.Burning";
          };
        };
        if Equals(TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(hitEvent.attackData.GetWeapon().GetItemID())).ItemType().Type(), gamedataItemType.Wea_Knife) {
          poisonedID = t"BaseStatusEffect.KnifePoison";
        } else {
          if transactionSystem.HasTag(hitEvent.attackData.GetInstigator(), n"Hercules_Poison", hitEvent.attackData.GetWeapon().GetItemID()) {
            poisonedID = t"BaseStatusEffect.Hercules_Poison";
          } else {
            poisonedID = t"BaseStatusEffect.Poisoned";
          };
        };
        electrocutedID = t"BaseStatusEffect.Electrocuted";
        stunnedID = t"BaseStatusEffect.Stun";
      };
      this.ApplyStatusEffectByApplicationRate(hitEvent, gamedataStatType.BleedingApplicationRate, bleedingID);
      this.ApplyStatusEffectByApplicationRate(hitEvent, gamedataStatType.BurningApplicationRate, burningID);
      this.ApplyStatusEffectByApplicationRate(hitEvent, gamedataStatType.PoisonedApplicationRate, poisonedID);
      this.ApplyStatusEffectByApplicationRate(hitEvent, gamedataStatType.ElectrocutedApplicationRate, electrocutedID);
      this.ApplyStatusEffectByApplicationRate(hitEvent, gamedataStatType.StunApplicationRate, stunnedID);
    };
  }

  private final func ApplyStatusEffectByApplicationRate(hitEvent: ref<gameHitEvent>, statType: gamedataStatType, effect: TweakDBID) -> Void {
    let rand: Float;
    let ss: ref<StatsSystem> = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    let ses: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(hitEvent.target.GetGame());
    let weapon: wref<WeaponObject> = hitEvent.attackData.GetWeapon();
    let value: Float = ss.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), statType) / 100.00;
    if hitEvent.target.IsPlayer() {
      return;
    };
    if !FloatIsEqual(value, 0.00) {
      rand = RandRangeF(0.00, 1.00);
      if rand <= value {
        if !this.IsImmune(hitEvent.target, effect, hitEvent.attackData) {
          ses.ApplyStatusEffect(hitEvent.target.GetEntityID(), effect, hitEvent.attackData.GetInstigator().GetEntityID());
          hitEvent.attackData.AddFlag(Equals(statType, gamedataStatType.StunApplicationRate) ? hitFlag.StunApplied : hitFlag.DotApplied, n"SETriggered");
        };
      };
    };
  }

  private final func ShouldProcessStatusEffectsOnVehicleDriver(hitEvent: ref<gameHitEvent>, out driverEntityID: EntityID) -> Bool {
    let effectTag: CName;
    let rec: ref<Attack_GameEffect_Record>;
    let vehicle: ref<VehicleObject> = hitEvent.target as VehicleObject;
    if !IsDefined(vehicle) || !vehicle.IsPlayerDriver() {
      return false;
    };
    rec = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    effectTag = rec.EffectTag();
    if Equals(effectTag, n"flashbang_explosion") {
      driverEntityID = GameInstance.GetPlayerSystem(hitEvent.target.GetGame()).GetLocalPlayerControlledGameObject().GetEntityID();
      return true;
    };
    return false;
  }

  private final func IsImmune(target: ref<GameObject>, statusEffectID: TweakDBID, attackData: ref<AttackData>) -> Bool {
    let i: Int32;
    let immunityStats: array<wref<Stat_Record>>;
    let player: ref<PlayerPuppet>;
    let statsSystem: ref<StatsSystem>;
    let tags: array<CName>;
    let statusEffect: wref<StatusEffect_Record> = TweakDBInterface.GetStatusEffectRecord(statusEffectID);
    if !IsDefined(statusEffect) {
      return true;
    };
    tags = statusEffect.GameplayTags();
    if target.IsPlayer() {
      if ArrayContains(tags, n"DoNotApplyOnPlayer") {
        return true;
      };
      if Equals(statusEffect.StatusEffectType().Type(), gamedataStatusEffectType.Defeated) {
        return true;
      };
      if Equals(statusEffect.StatusEffectType().Type(), gamedataStatusEffectType.UncontrolledMovement) {
        return true;
      };
    } else {
      if target.IsPuppet() && Equals(statusEffect.StatusEffectType().Type(), gamedataStatusEffectType.UncontrolledMovement) {
        if !ScriptedPuppet.CanRagdoll(target) {
          return true;
        };
      } else {
        if Equals(statusEffect.StatusEffectType().Type(), gamedataStatusEffectType.Poisoned) {
          player = GameInstance.GetPlayerSystem(target.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
          if IsDefined(attackData.GetInstigator()) && attackData.GetInstigator().IsPlayer() && IsDefined(attackData.GetWeapon()) && attackData.GetWeapon().IsThrowable() && PlayerDevelopmentSystem.GetData(player).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Cool_Right_Perk_2_1) {
            return false;
          };
        };
      };
    };
    if GameInstance.GetGodModeSystem(target.GetGame()).HasGodMode(target.GetEntityID(), gameGodModeType.Invulnerable) {
      if ArrayContains(tags, n"Debuff") {
        return true;
      };
    };
    statusEffect.ImmunityStats(immunityStats);
    statsSystem = GameInstance.GetStatsSystem(target.GetGame());
    i = 0;
    while i < ArraySize(immunityStats) {
      if statsSystem.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), immunityStats[i].StatType()) > 0.00 {
        return true;
      };
      i += 1;
    };
    return false;
  }

  private final func ProcessReturnedDamage(hitEvent: ref<gameHitEvent>) -> Void {
    if hitEvent.attackData.HasFlag(hitFlag.CannotReturnDamage) {
      return;
    };
  }

  private final func CalculateGlobalModifiers(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    let targetID: StatsObjectID = Cast<StatsObjectID>(hitEvent.target.GetEntityID());
    let factVal: Int32 = GetFact(GetGameInstance(), n"cheat_weak");
    if factVal > 0 {
      attackData.ClearDamage();
      hitEvent.attackComputed.AddAttackValue(0.01, gamedataDamageType.Physical);
      attackData.AddFlag(hitFlag.CannotModifyDamage, n"cheat_weak");
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.GENERAL) {
      };
    };
    if attackData.GetInstigator().IsPlayer() {
      factVal = GetFact(GetGameInstance(), n"cheat_op");
      if factVal > 0 {
        hitEvent.attackComputed.SetAttackValue(GameInstance.GetStatPoolsSystem(GetGameInstance()).GetStatPoolMaxPointValue(targetID, gamedataStatPoolType.Health) * 0.60, gamedataDamageType.Physical);
        attackData.ClearDamage();
        attackData.AddFlag(hitFlag.CannotModifyDamage, n"cheat_op");
        if Cast<Bool>(cache.logFlags & damageSystemLogFlags.GENERAL) {
        };
      };
    };
    DamageManager.CalculateGlobalModifiers(hitEvent);
  }

  private final func CalculateTargetModifiers(hitEvent: ref<gameHitEvent>) -> Void {
    DamageManager.CalculateTargetModifiers(hitEvent);
    this.ProcessArmor(hitEvent);
    this.ProcessOnVehicleMitigation(hitEvent);
  }

  private final func CalculateSourceModifiers(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    DamageManager.CalculateSourceModifiers(hitEvent);
    this.ProcessChargeAttack(hitEvent, cache);
    this.ProcessPierceAttack(hitEvent);
    this.ProcessRicochet(hitEvent);
    this.ProcessCriticalHit(hitEvent);
    this.ProcessDamageMultipliers(hitEvent);
    this.ProcessCyberwareModifiers(hitEvent);
    this.ProcessStealthAttack(hitEvent);
    this.ProcessNPCPassengerVehicleCollision(hitEvent);
    this.ProcessSpreadingMultiplier(hitEvent);
  }

  private final func ProcessPierceAttack(hitEvent: ref<gameHitEvent>) -> Void {
    let damageFactor: Float;
    let statsOwner: EntityID;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    let weaponObject: ref<WeaponObject> = attackData.GetWeapon();
    if !IsDefined(weaponObject) {
      return;
    };
    if hitEvent.hasPiercedTechSurface {
      statsOwner = weaponObject.GetEntityID();
      weaponObject = attackData.GetWeapon();
      damageFactor = 1.00 + statsSystem.GetStatValue(Cast<StatsObjectID>(statsOwner), gamedataStatType.TechPierceDamageFactor);
      if damageFactor > 0.00 {
        hitEvent.attackComputed.MultAttackValue(damageFactor);
      };
    };
  }

  private final func ProcessChargeAttack(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    let chargeDamageMult: Float;
    let chargeNormalized: Float;
    let maxChargeModifier: Float;
    let maxChargeThreshold: Float;
    let statsOwner: EntityID;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    let weaponObject: ref<WeaponObject> = attackData.GetWeapon();
    if !IsDefined(weaponObject) {
      return;
    };
    if attackData.GetInstigator().IsPlayer() {
      chargeNormalized = attackData.GetWeaponCharge();
      if chargeNormalized > 0.00 {
        statsOwner = weaponObject.GetEntityID();
        maxChargeThreshold = weaponObject.GetMaxChargeTreshold();
        if maxChargeThreshold == WeaponObject.GetOverchargeThreshold(weaponObject) {
          maxChargeModifier = 1.66;
        } else {
          if maxChargeThreshold == WeaponObject.GetFullyChargedThreshold(weaponObject) {
            maxChargeModifier = 1.33;
          } else {
            maxChargeModifier = 1.00;
          };
        };
        if chargeNormalized >= 1.00 {
          chargeDamageMult = 1.00 + statsSystem.GetStatValue(Cast<StatsObjectID>(statsOwner), gamedataStatType.ChargeFullMultiplier) * maxChargeModifier;
        } else {
          chargeDamageMult = 1.00 + statsSystem.GetStatValue(Cast<StatsObjectID>(statsOwner), gamedataStatType.ChargeMultiplier) * chargeNormalized * maxChargeModifier;
        };
        cache.chargeDamageMultiplier = chargeDamageMult;
        hitEvent.attackComputed.MultAttackValue(chargeDamageMult);
      };
    };
  }

  private final func ProcessRicochet(hitEvent: ref<gameHitEvent>) -> Void {
    let baseRicochetDamage: Float;
    let bonusCritChance: Float;
    let bonusDmg: Float;
    if hitEvent.attackData.GetInstigator().IsPlayer() {
      if hitEvent.attackData.GetNumRicochetBounces() > 0 {
        baseRicochetDamage = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.BaseRicochetDamageModifier);
        hitEvent.attackComputed.MultAttackValue(baseRicochetDamage);
        bonusDmg = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.BonusRicochetDamage);
        if !FloatIsEqual(bonusDmg, 0.00) {
          hitEvent.attackComputed.MultAttackValue(1.00 + bonusDmg / 100.00);
        };
        bonusCritChance = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(ScriptedPuppet.GetActiveWeapon(hitEvent.attackData.GetInstigator()).GetEntityID()), gamedataStatType.BonusRicochetCritChance);
        if !FloatIsEqual(bonusCritChance, 0.00) {
          hitEvent.attackData.SetAdditionalCritChance(bonusCritChance);
        };
      };
    };
  }

  private final func ProcessSpreadingMultiplier(hitEvent: ref<gameHitEvent>) -> Void {
    let multiplier: Float;
    if hitEvent.attackData.GetInstigator().IsPlayer() {
      if hitEvent.attackData.GetNumAttackSpread() > 0 {
        multiplier = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(ScriptedPuppet.GetActiveWeapon(hitEvent.attackData.GetInstigator()).GetEntityID()), gamedataStatType.SpreadingAttackDamageMultiplier);
        hitEvent.attackComputed.MultAttackValue(multiplier);
      };
    };
  }

  private final func ProcessStealthAttack(hitEvent: ref<gameHitEvent>) -> Void {
    let canStealthHit: Bool;
    let hitNotQuickMelee: Bool;
    let powerDifferential: gameEPowerDifferential;
    let stealthHitDamageBonus: Float;
    let stealthHitMult: Float;
    let player: wref<PlayerPuppet> = hitEvent.attackData.GetInstigator() as PlayerPuppet;
    if IsDefined(player) && IsDefined(hitEvent.target as ScriptedPuppet) {
      if IsDefined(hitEvent.attackData.GetWeapon()) {
        if !AttackData.IsPlayerInCombat(hitEvent.attackData) || StatusEffectHelper.HasStatusEffectWithTagConst(player, n"ExtendedStealth") {
          canStealthHit = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetWeapon().GetEntityID()), gamedataStatType.CanSilentKill) > 0.00;
          hitNotQuickMelee = NotEquals(hitEvent.attackData.GetAttackType(), gamedataAttackType.QuickMelee);
          if canStealthHit && hitNotQuickMelee {
            powerDifferential = RPGManager.CalculatePowerDifferential(hitEvent.target);
            if NotEquals(powerDifferential, gameEPowerDifferential.IMPOSSIBLE) {
              stealthHitDamageBonus = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.StealthHitDamageBonus);
              stealthHitMult = GameInstance.GetStatsSystem(GetGameInstance()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.StealthHitDamageMultiplier);
              hitEvent.attackComputed.AddAttackValue(stealthHitDamageBonus, gamedataDamageType.Physical);
              if stealthHitMult > 1.00 {
                hitEvent.attackComputed.MultAttackValue(stealthHitMult);
              };
            };
          };
        };
      };
    };
  }

  private final func ProcessNPCPassengerVehicleCollision(hitEvent: ref<gameHitEvent>) -> Void {
    if hitEvent.attackData.GetInstigator().IsPlayer() {
      if hitEvent.attackData.HasFlag(hitFlag.NPCPassengerVehicleCollision) {
        if PlayerDevelopmentSystem.GetData(hitEvent.attackData.GetInstigator()).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Body_Right_Milestone_1) {
          hitEvent.attackComputed.MultAttackValue(1.50);
        };
      };
    };
  }

  private final func CalculateSourceVsTargetModifiers(hitEvent: ref<gameHitEvent>) -> Void {
    this.ProcessVehicleVsExplosion(hitEvent);
    this.ProcessBikeMelee(hitEvent);
    this.ProcessEffectiveRange(hitEvent);
    this.ProcessBlockAndDeflect(hitEvent);
    if Cast<Bool>(GetFact(GetGameInstance(), n"story_mode")) {
      this.ScalePlayerDamage(hitEvent);
    };
  }

  private final func CacheLocalVars(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    let target: ref<GameObject> = hitEvent.target;
    cache.logFlags = GetDamageSystemLogFlags();
    if IsDefined(target) {
      cache.TEMP_ImmortalityCached = GetImmortality(target, cache.targetImmortalityMode);
    };
  }

  private final func ModifyHitFlagsForPlayer(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !attackData.GetInstigator().IsPlayer() {
      return;
    };
    attackData.RemoveFlag(hitFlag.FriendlyFire, n"PreAttack");
  }

  private final func CheckForQuickExit(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Bool {
    let mountingInfo: MountingInfo;
    let targetAttitudeOwner: wref<GameObject>;
    let vehicle: wref<VehicleObject>;
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !IsDefined(attackData) {
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
      };
      return true;
    };
    if !IsDefined(hitEvent.target) {
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
      };
      return true;
    };
    if !IsDefined(attackData.GetSource()) {
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
      };
      return true;
    };
    if !GameInstance.IsValid(GetGameInstance()) {
      if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
      };
      return true;
    };
    if IsDefined(hitEvent.target as VehicleObject) && VehicleComponent.GetVehicle(GetGameInstance(), attackData.GetSource().GetEntityID(), vehicle) {
      if vehicle == hitEvent.target {
        if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
        };
        return true;
      };
    };
    if IsDefined(attackData.GetInstigator() as VehicleObject) && VehicleComponent.GetVehicle(GetGameInstance(), hitEvent.target, vehicle) {
      if vehicle == attackData.GetInstigator() {
        if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
        };
        return true;
      };
    };
    if hitEvent.target == attackData.GetInstigator() {
      if !attackData.HasFlag(hitFlag.CanDamageSelf) {
        attackData.AddFlag(hitFlag.DealNoDamage, n"SelfDamageIgnored");
        if Cast<Bool>(cache.logFlags & damageSystemLogFlags.ASSERT) {
        };
        return true;
      };
    } else {
      if !attackData.HasFlag(hitFlag.FriendlyFire) {
        mountingInfo = GameInstance.GetMountingFacility(hitEvent.target.GetGame()).GetMountingInfoSingleWithObjects(hitEvent.target);
        if EntityID.IsDefined(mountingInfo.parentId) {
          targetAttitudeOwner = GameInstance.FindEntityByID(hitEvent.target.GetGame(), mountingInfo.parentId) as GameObject;
        };
        if (targetAttitudeOwner as ScriptedPuppet) == null {
          targetAttitudeOwner = hitEvent.target;
        };
        if Equals(GameObject.GetAttitudeBetween(targetAttitudeOwner, attackData.GetInstigator()), EAIAttitude.AIA_Friendly) && !StatusEffectSystem.ObjectHasStatusEffect(attackData.GetInstigator(), t"BaseStatusEffect.DoNotBlockShootingOnFriendlyFire") {
          attackData.AddFlag(hitFlag.DealNoDamage, n"FriendlyFireIgnored");
          attackData.AddFlag(hitFlag.DontShowDamageFloater, n"FriendlyFireIgnored");
          attackData.AddFlag(hitFlag.FriendlyFireIgnored, n"FriendlyFireIgnored");
        };
      };
    };
    if AttackData.IsDoT(hitEvent.attackData) && StatusEffectSystem.ObjectHasStatusEffectWithTag(hitEvent.target, n"Defeated") {
      return true;
    };
    return false;
  }

  private final func IsTargetImmortal(cache: ref<CacheData>) -> Bool {
    if !cache.TEMP_ImmortalityCached {
      return false;
    };
    return Equals(cache.targetImmortalityMode, gameGodModeType.Immortal);
  }

  private final func IsTargetInvulnerable(cache: ref<CacheData>) -> Bool {
    if !cache.TEMP_ImmortalityCached {
      return false;
    };
    return Equals(cache.targetImmortalityMode, gameGodModeType.Invulnerable);
  }

  public final func IsOverridenExplosionVsVehicleHit(hitEvent: ref<gameHitEvent>) -> Bool {
    return hitEvent.attackData.HasFlag(hitFlag.ExplosionOverride);
  }

  public final func ProcessVehicleVsExplosion(hitEvent: ref<gameHitEvent>) -> Void {
    let explosionDamageVSVehicles: Float;
    if !hitEvent.target.IsVehicle() {
      return;
    };
    if !AttackData.IsExplosion(hitEvent.attackData.GetAttackType()) {
      return;
    };
    explosionDamageVSVehicles = hitEvent.attackData.GetAttackDefinition().GetRecord().ExplosionDamageVSVehicles();
    if explosionDamageVSVehicles <= 0.00 {
      return;
    };
    explosionDamageVSVehicles *= this.GetVehiclePerksDamageMultiplier(hitEvent.attackData);
    hitEvent.attackComputed.SetAttackValue(explosionDamageVSVehicles, gamedataDamageType.Physical);
    hitEvent.attackData.AddFlag(hitFlag.ExplosionOverride, n"vs_vehicle_explosion_tuning");
  }

  public final func ProcessBikeMelee(hitEvent: ref<gameHitEvent>) -> Void {
    let bikeDmgScale: Float;
    let bikeVel: Vector4;
    let mountedBike: ref<BikeObject>;
    let playerPuppet: ref<PlayerPuppet>;
    let targetVel: Vector4;
    let velDelta: Vector4;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let targetVehicle: ref<VehicleObject> = hitEvent.target as VehicleObject;
    let targetPuppet: ref<gamePuppet> = hitEvent.target as gamePuppet;
    if !attackData.GetInstigator().IsPlayer() {
      return;
    };
    if !(AttackData.IsMelee(attackData.GetAttackType()) || AttackData.IsThrown(attackData.GetAttackType())) {
      return;
    };
    playerPuppet = attackData.GetInstigator() as PlayerPuppet;
    mountedBike = playerPuppet.GetMountedVehicle() as BikeObject;
    if !IsDefined(mountedBike) {
      return;
    };
    bikeVel = mountedBike.GetLinearVelocity();
    if IsDefined(targetVehicle) {
      targetVel = targetVehicle.GetLinearVelocity();
    } else {
      if IsDefined(targetPuppet) {
        targetVel = targetPuppet.GetVelocity();
      };
    };
    velDelta = bikeVel - targetVel;
    bikeDmgScale = 1.00 + ProportionalClampF(8.00, 30.00, Vector4.Length(velDelta), 0.00, 4.00);
    hitEvent.attackComputed.MultAttackValue(bikeDmgScale, gamedataDamageType.Physical);
    if Vector4.Length(velDelta) > 8.00 {
      attackData.AddFlag(hitFlag.HighSpeedMelee, n"BikeStrike");
      attackData.SetHitReactionSeverityMax(4);
    };
  }

  public final func ProcessEffectiveRange(hitEvent: ref<gameHitEvent>) -> Void {
    let attackDistance: Float;
    let attackWeapon: ref<WeaponObject>;
    let baseGrenade: ref<BaseGrenade>;
    let damageMod: Float;
    let effectiveRange: Float;
    let percentOfRange: Float;
    let attackData: ref<AttackData> = hitEvent.attackData;
    if AttackData.IsExplosion(attackData.GetAttackType()) {
      baseGrenade = attackData.GetSource() as BaseGrenade;
      if IsDefined(baseGrenade) {
        effectiveRange = baseGrenade.GetAttackRadius();
      } else {
        effectiveRange = attackData.GetAttackDefinition().GetRecord().Range();
      };
      attackDistance = Vector4.Length(attackData.GetAttackPosition() - hitEvent.hitPosition);
      percentOfRange = ClampF(attackDistance / effectiveRange, 0.00, 1.00);
      damageMod = GameInstance.GetStatsDataSystem(GetGameInstance()).GetValueFromCurve(n"explosions", percentOfRange, n"distance_to_damage_reduction");
      hitEvent.attackComputed.MultAttackValue(damageMod);
      return;
    };
    attackWeapon = attackData.GetWeapon();
    if !IsDefined(attackWeapon) {
      return;
    };
    damageMod = DamageSystem.GetEffectiveRangeModifierForWeapon(attackData, hitEvent.hitPosition, GameInstance.GetStatsSystem(GetGameInstance()));
    if damageMod != 1.00 {
      hitEvent.attackComputed.MultAttackValue(damageMod);
    };
  }

  public final static func GetEffectiveRangeModifierForWeapon(attackData: ref<AttackData>, hitPosition: Vector4, statsSystem: ref<StatsSystem>) -> Float {
    let attackDistance: Float;
    let effectiveRange: Float;
    let itemRecord: ref<WeaponItem_Record>;
    let result: Float = 1.00;
    if attackData.GetInstigator().IsPlayer() {
      effectiveRange = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetWeapon().GetEntityID()), gamedataStatType.EffectiveRange);
      itemRecord = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(attackData.GetWeapon().GetItemID()));
      attackDistance = Vector4.Length(attackData.GetAttackPosition() - hitPosition);
      if attackDistance < effectiveRange {
        if IsNameValid(itemRecord.EffectiveRangeCurve()) {
          result = DamageSystem.GetDamageModFromCurve(itemRecord.EffectiveRangeCurve(), attackDistance);
        };
      } else {
        if IsNameValid(itemRecord.EffectiveRangeFalloffCurve()) {
          if IsDefined(attackData.GetWeapon()) && statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetWeapon().GetEntityID()), gamedataStatType.DamageFalloffDisabled) <= 0.00 {
            attackDistance = attackDistance - effectiveRange;
            result = DamageSystem.GetDamageModFromCurve(itemRecord.EffectiveRangeFalloffCurve(), attackDistance);
          };
        };
      };
    };
    return result;
  }

  public final func ProcessArmor(hitEvent: ref<gameHitEvent>) -> Void {
    let appliedStatusEffects: array<ref<StatusEffect>>;
    let armorMeltMaxPercent: Float;
    let armorPenetration: Float;
    let armorPoints: Float;
    let attackValues: array<Float>;
    let damageMultiplier: Float;
    let effectiveHealthPerArmorPoint: Float;
    let hitShapeArmorPoints: Float;
    let hitUserData: ref<HitShapeUserDataBase>;
    let i: Int32;
    let reducedValue: Float;
    let statsSystem: ref<StatsSystem>;
    let statusEffectSystem: ref<StatusEffectSystem>;
    let targetIsPlayer: Bool;
    let weapon: wref<WeaponObject>;
    let hitShapes: array<HitShapeData> = hitEvent.hitRepresentationResult.hitShapes;
    if AttackData.IsDoT(hitEvent.attackData) {
      return;
    };
    weapon = hitEvent.attackData.GetWeapon();
    if !IsDefined(weapon) {
      return;
    };
    armorPenetration = this.GetArmorPenetrationValue(weapon, hitEvent);
    if armorPenetration >= 1.00 {
      return;
    };
    statsSystem = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    statusEffectSystem = GameInstance.GetStatusEffectSystem(hitEvent.target.GetGame());
    targetIsPlayer = hitEvent.target.IsPlayer();
    armorPoints = statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.Armor);
    if hitEvent.attackData.GetInstigator().IsPlayer() && ArraySize(hitShapes) > 0 {
      hitUserData = DamageSystemHelper.GetHitShapeUserDataBase(hitShapes[0]);
      if IsDefined(hitUserData) && DamageSystemHelper.IsHitShapeArmored(hitUserData.m_hitShapeType) {
        hitShapeArmorPoints = statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.HitShapeArmor);
        if hitShapeArmorPoints > armorPoints {
          armorPoints = hitShapeArmorPoints;
        };
      };
    };
    statusEffectSystem.GetAppliedEffectsWithTag(hitEvent.target.GetEntityID(), n"OverheatArmorMelt", appliedStatusEffects);
    if ArraySize(appliedStatusEffects) > 0 {
      armorMeltMaxPercent = TweakDBInterface.GetFloat(appliedStatusEffects[0].GetRecord().GetID() + t".armorMeltMaxPercent", 0.00);
      armorPoints *= 1.00 - (1.00 - ClampF(appliedStatusEffects[0].GetRemainingDuration(), 0.00, 5.00) / 5.00) * armorMeltMaxPercent;
    };
    if armorPenetration != 0.00 {
      armorPoints *= 1.00 - armorPenetration;
    };
    effectiveHealthPerArmorPoint = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame()).GetArmorEffectivenessValue(targetIsPlayer);
    if targetIsPlayer {
      effectiveHealthPerArmorPoint *= statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.ArmorEffectivenessMultiplier);
    };
    if armorPoints >= 0.00 {
      damageMultiplier = 1.00 / (1.00 + armorPoints * effectiveHealthPerArmorPoint);
      if armorPoints > 0.00 && armorPenetration <= 0.00 && !hitEvent.attackData.HasFlag(hitFlag.CriticalHit) {
        hitEvent.attackData.SetHitType(gameuiHitType.Glance);
      };
    } else {
      damageMultiplier = 1.00 - armorPoints * effectiveHealthPerArmorPoint;
    };
    attackValues = hitEvent.attackComputed.GetAttackValues();
    i = 0;
    while i < ArraySize(attackValues) {
      if attackValues[i] > 0.00 {
        reducedValue = attackValues[i] * damageMultiplier;
        if reducedValue < 1.00 {
          reducedValue = 1.00;
        };
        attackValues[i] = reducedValue;
      };
      i += 1;
    };
    hitEvent.attackComputed.SetAttackValues(attackValues);
  }

  public final func ProcessOnVehicleMitigation(hitEvent: ref<gameHitEvent>) -> Void {
    let bikeDamageTaken: Float;
    let isAOE: Bool;
    let isRanged: Bool;
    let mountedBike: ref<BikeObject>;
    let mountedVehicle: ref<VehicleObject>;
    let playerBikeVel: Vector4;
    let statsSystem: ref<StatsSystem>;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let playerPuppet: ref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
    let mountedExplosionFactor: Float = 1.00;
    if !IsDefined(playerPuppet) || hitEvent.attackData.HasFlag(hitFlag.CannotModifyDamage) {
      return;
    };
    mountedVehicle = playerPuppet.GetMountedVehicle();
    if mountedVehicle == null {
      return;
    };
    mountedBike = mountedVehicle as BikeObject;
    if IsDefined(mountedBike) && AttackData.IsRangedOnly(attackType) {
      statsSystem = GameInstance.GetStatsSystem(playerPuppet.GetGame());
      bikeDamageTaken = statsSystem.GetStatValue(Cast<StatsObjectID>(playerPuppet.GetEntityID()), gamedataStatType.OnBikeDamageTakenPercent);
      if bikeDamageTaken >= 1.00 && bikeDamageTaken < 0.00 {
        return;
      };
      playerBikeVel = mountedBike.GetLinearVelocity();
      bikeDamageTaken = ProportionalClampF(statsSystem.GetStatValue(Cast<StatsObjectID>(playerPuppet.GetEntityID()), gamedataStatType.OnBikeDamageTakenPercentMinSpeed), statsSystem.GetStatValue(Cast<StatsObjectID>(playerPuppet.GetEntityID()), gamedataStatType.OnBikeDamageTakenPercentMaxSpeed), Vector4.Length(playerBikeVel), 1.00, bikeDamageTaken);
      hitEvent.attackComputed.MultAttackValue(bikeDamageTaken);
    } else {
      isRanged = hitEvent.attackData.GetWeapon().IsRanged();
      isAOE = AttackData.IsExplosion(attackType);
      if !isRanged && isAOE && hitEvent.attackData.GetSource() != mountedVehicle {
        if mountedVehicle.GetRecord().IsArmoredVehicle() {
          mountedExplosionFactor = 0.33;
        } else {
          mountedExplosionFactor = IsDefined(mountedBike) ? 0.75 : 0.50;
        };
        hitEvent.attackComputed.MultAttackValue(mountedExplosionFactor);
      };
    };
  }

  private final const func GetSubAttackSubType(attackData: ref<AttackData>) -> gamedataAttackSubtype {
    let attackSubTypeRecord: ref<AttackSubtype_Record>;
    let attackRecord: ref<Attack_Melee_Record> = attackData.GetAttackDefinition().GetRecord() as Attack_Melee_Record;
    if IsDefined(attackRecord) {
      attackSubTypeRecord = attackRecord.AttackSubtype();
      if IsDefined(attackSubTypeRecord) {
        return attackSubTypeRecord.Type();
      };
    };
    return gamedataAttackSubtype.Invalid;
  }

  public final func ProcessCriticalHit(hitEvent: ref<gameHitEvent>) -> Void {
    let accumulatedCritChance: Float;
    let accumulatedCritDamage: Float;
    let isQuickHack: Bool;
    let playerCritChance: Float;
    let weaponCritChance: Float;
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let attackData: ref<AttackData> = hitEvent.attackData;
    let criticalHit: Bool = attackData.HasFlag(hitFlag.CriticalHit);
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(GetGameInstance());
    if attackData.HasFlag(hitFlag.CannotModifyDamage) || attackData.HasFlag(hitFlag.DeterministicDamage) || attackData.HasFlag(hitFlag.ForceNoCrit) && !attackData.HasFlag(hitFlag.BreachHit) || hitEvent.target.IsPlayer() || !attackData.GetInstigator().IsPlayer() {
      return;
    };
    if !criticalHit {
      if Equals(attackType, gamedataAttackType.Hack) || attackData.HasFlag(hitFlag.QuickHack) {
        if statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.CanQuickHackCriticallyHit) <= 0.00 {
          return;
        };
        isQuickHack = true;
      } else {
        if AttackData.IsEffect(attackType) && !AttackData.CanEffectCriticallyHit(attackData, statsSystem) {
          return;
        };
        if IsDefined(hitEvent.attackData.GetSource() as WeaponGrenade) && !AttackData.CanGrenadeCriticallyHit(attackData, statsSystem) {
          return;
        };
      };
      if Equals(this.GetSubAttackSubType(attackData), gamedataAttackSubtype.DeflectAttack) && PlayerDevelopmentSystem.GetData(attackData.GetInstigator()).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Reflexes_Right_Perk_2_2) {
        criticalHit = true;
      };
      if !criticalHit {
        if isQuickHack {
          accumulatedCritChance = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.QuickHackCritChance) / 100.00;
        } else {
          if IsDefined(attackData.GetInstigator()) {
            playerCritChance = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.CritChance) / 100.00;
          };
          if IsDefined(attackData.GetWeapon()) {
            if this.AllowWeaponCrit(attackData) {
              weaponCritChance = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetWeapon().GetEntityID()), gamedataStatType.CritChance) / 100.00;
            };
          };
          accumulatedCritChance = playerCritChance + weaponCritChance + hitEvent.attackData.GetAdditionalCritChance();
        };
        if accumulatedCritChance >= 1.00 {
          criticalHit = true;
        } else {
          if hitEvent.projectionPipeline {
            return;
          };
          criticalHit = RandF() <= accumulatedCritChance;
        };
      };
    };
    if criticalHit && !attackData.HasFlag(hitFlag.CriticalHitNoDamageModifier) {
      accumulatedCritDamage = this.GetCritDamageModifier(statsSystem, attackData);
      if accumulatedCritDamage > 0.00 {
        attackData.AddFlag(hitFlag.CriticalHit, n"critical_hit");
      } else {
        attackData.RemoveFlag(hitFlag.CriticalHit);
      };
    };
    if !hitEvent.attackData.HasFlag(hitFlag.Special) {
      hitEvent.attackData.SetHitType(Equals(attackData.GetHitType(), gameuiHitType.Glance) ? gameuiHitType.Glance : gameuiHitType.Hit);
    };
    if attackData.HasFlag(hitFlag.CriticalHit) {
      hitEvent.attackData.SetHitType(gameuiHitType.CriticalHit);
    };
  }

  public final func ProcessDamageMultipliers(hitEvent: ref<gameHitEvent>) -> Void {
    let breachDamage: Float;
    let breachFinder: ref<BreachFinderComponent>;
    let critDamage: Float;
    let headshotDamage: Float;
    let player: ref<PlayerPuppet>;
    let statsSystem: ref<StatsSystem>;
    let weakspotDamage: Float;
    let attackData: ref<AttackData> = hitEvent.attackData;
    if attackData.HasFlag(hitFlag.ReflexesMasterPerk1) {
      return;
    };
    statsSystem = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    if attackData.HasFlag(hitFlag.Headshot) {
      headshotDamage = this.GetHeadshotDamageModifier(statsSystem, attackData);
    };
    if attackData.HasFlag(hitFlag.CriticalHit) && !attackData.HasFlag(hitFlag.CriticalHitNoDamageModifier) {
      critDamage = this.GetCritDamageModifier(statsSystem, attackData);
    };
    if attackData.HasFlag(hitFlag.WeakspotHit) {
      weakspotDamage = this.GetWeakspotDamageModifier(statsSystem, attackData);
    };
    if attackData.HasFlag(hitFlag.BreachHit) {
      player = attackData.GetInstigator() as PlayerPuppet;
      if IsDefined(player) {
        breachFinder = player.GetBreachFinderComponent();
        if IsDefined(breachFinder) {
          breachDamage = 0.05 * breachFinder.GetBreachStreak();
        };
      };
    };
    hitEvent.attackComputed.MultAttackValue(1.00 + headshotDamage + critDamage + weakspotDamage + breachDamage);
    if (hitEvent.target as VehicleObject) == null {
      hitEvent.attackComputed.MultAttackValue(this.GetVehiclePerksDamageMultiplier(hitEvent.attackData));
    };
  }

  public final func ProcessCyberwareModifiers(hitEvent: ref<gameHitEvent>) -> Void {
    let attackValues: array<Float>;
    let damageType: gamedataDamageType;
    let health: Float;
    let i: Int32;
    let maxHealth: Float;
    let weapon: ref<WeaponObject>;
    let statSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
    let target: ref<GameObject> = hitEvent.target;
    let instigator: ref<GameObject> = hitEvent.attackData.GetInstigator();
    let instigatorID: EntityID = instigator.GetEntityID();
    let attackType: gamedataAttackType = hitEvent.attackData.GetAttackType();
    let tempDamage: Float = 0.00;
    if target == instigator {
      return;
    };
    health = GameInstance.GetStatPoolsSystem(target.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatPoolType.Health, false);
    maxHealth = GameInstance.GetStatPoolsSystem(target.GetGame()).GetStatPoolMaxPointValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatPoolType.Health);
    tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.AllDamageDonePercentBonus);
    if AttackData.IsExplosion(attackType) {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.ExplosionDamagePercentBonus);
    };
    if AttackData.IsMelee(attackType) {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.MeleeDamagePercentBonus);
    };
    if FloatIsEqual(health, maxHealth) {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.BonusPercentDamageToEnemiesAtFullHealth);
    };
    if health <= maxHealth / 2.00 {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.BonusPercentDamageToEnemiesBelowHalfHealth);
    };
    if StatusEffectSystem.ObjectHasStatusEffectOfType(target, gamedataStatusEffectType.Burning) {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.BonusPercentDamageVsBurningEnemies);
    };
    if AttackData.IsDoT(hitEvent.attackData) {
      tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.DamageOverTimePercentBonus);
    };
    weapon = hitEvent.attackData.GetWeapon();
    if IsDefined(weapon) {
      if weapon.WeaponHasTag(n"SmartWeapon") {
        tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.SmartWeaponDamagePercentBonus);
      };
      if weapon.WeaponHasTag(n"TechWeapon") {
        tempDamage += statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.TechWeaponDamagePercentBonus);
      };
    };
    attackValues = hitEvent.attackComputed.GetAttackValues();
    i = 0;
    while i < ArraySize(attackValues) {
      if attackValues[i] > 0.00 {
        damageType = IntEnum<gamedataDamageType>(i);
        switch damageType {
          case gamedataDamageType.Thermal:
            attackValues[i] *= 1.00 + tempDamage + statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.ThermalDamagePercentBonus);
            break;
          case gamedataDamageType.Electric:
            attackValues[i] *= 1.00 + tempDamage + statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.ElectricDamagePercentBonus);
            break;
          case gamedataDamageType.Chemical:
            attackValues[i] *= 1.00 + tempDamage + statSystem.GetStatValue(Cast<StatsObjectID>(instigatorID), gamedataStatType.ChemicalDamagePercentBonus);
            break;
          default:
            attackValues[i] *= 1.00 + tempDamage;
        };
      };
      i += 1;
    };
    hitEvent.attackComputed.SetAttackValues(attackValues);
  }

  protected final func GetArmorPenetrationValue(weapon: ref<WeaponObject>, hitEvent: ref<gameHitEvent>) -> Float {
    let armorPenetration: Float;
    if !IsDefined(weapon) {
      return 0.00;
    };
    armorPenetration = WeaponObject.CanIgnoreArmor(weapon);
    if hitEvent.attackData.HasFlag(hitFlag.BreachHit) {
      armorPenetration += 0.25;
    };
    if GameInstance.GetStatsSystem(weapon.GetGame()).GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.TechPierceEnabled) > 0.00 && WeaponObject.GetWeaponChargeNormalized(weapon) >= WeaponObject.TechPierceChargeLevel(weapon) {
      armorPenetration += 0.25;
    };
    return armorPenetration;
  }

  protected final func GetHeadshotDamageModifier(statSystem: ref<StatsSystem>, attackData: ref<AttackData>) -> Float {
    if attackData.HasFlag(hitFlag.ForceHeadshotMult25) {
      return 0.25;
    };
    if attackData.HasFlag(hitFlag.ForceHeadshotMult10) {
      return 0.10;
    };
    return statSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.HeadshotDamageMultiplier);
  }

  protected final func GetWeakspotDamageModifier(statSystem: ref<StatsSystem>, attackData: ref<AttackData>) -> Float {
    if attackData.HasFlag(hitFlag.ForceWeakspotMult25) {
      return 0.25;
    };
    if attackData.HasFlag(hitFlag.ForceWeakspotMult10) {
      return 0.10;
    };
    return statSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.WeakspotDamageMultiplier);
  }

  protected final func GetCritDamageModifier(statSystem: ref<StatsSystem>, attackData: ref<AttackData>) -> Float {
    let playerCritDamage: Float;
    let weaponCritDamage: Float;
    if IsDefined(attackData.GetInstigator()) {
      playerCritDamage = statSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.CritDamage) / 100.00;
    };
    if this.AllowWeaponCrit(attackData) {
      weaponCritDamage = statSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetWeapon().GetEntityID()), gamedataStatType.CritDamage) / 100.00;
    };
    return playerCritDamage + weaponCritDamage;
  }

  protected final func GetVehiclePerksDamageMultiplier(attackData: ref<AttackData>) -> Float {
    let statsSystem: ref<StatsSystem>;
    let weaponObject: ref<WeaponObject>;
    let weaponType: gamedataItemType;
    let damageMultiplier: Float = 1.00;
    let instigator: ref<GameObject> = attackData.GetInstigator();
    if !instigator.IsPlayer() {
      return damageMultiplier;
    };
    if !VehicleComponent.IsMountedToVehicle(instigator.GetGame(), instigator.GetEntityID()) {
      return damageMultiplier;
    };
    weaponObject = attackData.GetWeapon();
    if !IsDefined(weaponObject) {
      return damageMultiplier;
    };
    statsSystem = GameInstance.GetStatsSystem(instigator.GetGame());
    weaponType = RPGManager.GetItemRecord(weaponObject.GetItemID()).ItemType().Type();
    if Equals(weaponType, gamedataItemType.Wea_VehiclePowerWeapon) || Equals(weaponType, gamedataItemType.Wea_VehicleMissileLauncher) {
      damageMultiplier = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.GearheadDamageMultiplier);
    } else {
      if weaponObject.IsRanged() || weaponObject.IsMelee() {
        if PlayerDevelopmentSystem.GetData(instigator).IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Cool_Left_Milestone_1) && StatusEffectSystem.ObjectHasStatusEffect(instigator, t"BaseStatusEffect.DriverCombatVehicleManeuvers") {
          damageMultiplier = statsSystem.GetStatValue(Cast<StatsObjectID>(attackData.GetInstigator().GetEntityID()), gamedataStatType.RoadWarriorDamageMultiplier);
        };
      };
    };
    return damageMultiplier;
  }

  protected final func AllowWeaponCrit(attackData: ref<AttackData>) -> Bool {
    return !AttackData.IsDoT(attackData) && (attackData.GetWeapon().IsRanged() || attackData.GetWeapon().IsMelee());
  }

  private final func ProcessBlockAndDeflect(hitEvent: ref<gameHitEvent>) -> Void {
    let attackingItem: wref<ItemObject>;
    let blockFactor: Float;
    let blockingItem: wref<ItemObject>;
    let currentStamina: Float;
    let meleeAttackRecord: ref<Attack_Melee_Record>;
    let meleeCostToBlock: Float;
    let newStamina: Float;
    let playerTarget: ref<PlayerPuppet>;
    let staminaReduction: Float;
    let statPoolsSystem: ref<StatPoolsSystem>;
    let statsSystem: ref<StatsSystem>;
    let targetID: EntityID;
    let blockBreakTDBID: TweakDBID = t"BaseStatusEffect.BlockBroken";
    let computedDamageFactor: Float = 1.00;
    if AttackData.IsMelee(hitEvent.attackData.GetAttackType()) {
      if !hitEvent.attackData.WasBlocked() && !hitEvent.attackData.WasDeflected() {
        return;
      };
      blockingItem = GameInstance.GetTransactionSystem(hitEvent.target.GetGame()).GetItemInSlot(hitEvent.target, t"AttachmentSlots.WeaponRight");
      attackingItem = hitEvent.attackData.GetWeapon();
      if !IsDefined(blockingItem) || !IsDefined(attackingItem) {
        return;
      };
      statsSystem = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
      statPoolsSystem = GameInstance.GetStatPoolsSystem(hitEvent.target.GetGame());
      if !(Equals(RPGManager.GetItemRecord(blockingItem.GetItemID()).ItemType().Type(), gamedataItemType.Wea_Fists) && NotEquals(RPGManager.GetItemRecord(attackingItem.GetItemID()).ItemType().Type(), gamedataItemType.Wea_Fists)) {
        computedDamageFactor = 0.00;
      };
      if hitEvent.attackData.WasDeflected() {
        RPGManager.AwardExperienceFromDeflect(hitEvent);
      };
      if hitEvent.attackData.WasBlocked() {
        targetID = hitEvent.target.GetEntityID();
        currentStamina = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatPoolType.Stamina, false);
        playerTarget = hitEvent.target as PlayerPuppet;
        blockFactor = statsSystem.GetStatValue(Cast<StatsObjectID>(targetID), gamedataStatType.BlockFactor);
        if IsDefined(playerTarget) {
          if StatusEffectSystem.ObjectHasStatusEffect(hitEvent.target, t"BaseStatusEffect.PlayerExhausted") {
            StatusEffectHelper.ApplyStatusEffect(hitEvent.target, blockBreakTDBID);
            hitEvent.attackData.RemoveFlag(hitFlag.WasBlocked, n"BlockBreak");
            computedDamageFactor = TweakDBInterface.GetFloat(t"Constants.DamageSystem.blockBreakPlayerDamageFactor", 0.50);
          } else {
            meleeAttackRecord = hitEvent.attackData.GetAttackDefinition().GetRecord() as Attack_Melee_Record;
            meleeCostToBlock = statsSystem.GetStatValue(Cast<StatsObjectID>(attackingItem.GetEntityID()), gamedataStatType.StaminaCostToBlock);
            if IsDefined(meleeAttackRecord) {
              meleeCostToBlock = meleeCostToBlock * meleeAttackRecord.BlockCostFactor();
            };
            staminaReduction = meleeCostToBlock / blockFactor;
            newStamina = MaxF(currentStamina - staminaReduction, 0.00);
            if newStamina <= 0.00 {
              StatusEffectHelper.ApplyStatusEffect(hitEvent.target, blockBreakTDBID);
              hitEvent.attackData.RemoveFlag(hitFlag.WasBlocked, n"BlockBreak");
              computedDamageFactor = TweakDBInterface.GetFloat(t"Constants.DamageSystem.blockBreakPlayerDamageFactor", 0.50);
            };
            PlayerStaminaHelpers.ModifyStamina(playerTarget, -staminaReduction);
            PlayerStaminaHelpers.OnPlayerBlock(playerTarget);
          };
          this.SetTutorialFact(n"gmpl_player_blocked_attack");
        } else {
          staminaReduction = statsSystem.GetStatValue(Cast<StatsObjectID>(targetID), gamedataStatType.Stamina) / blockFactor;
          newStamina = MaxF(currentStamina - staminaReduction, 0.00);
          if newStamina <= 0.00 {
            StatusEffectHelper.ApplyStatusEffect(hitEvent.target, blockBreakTDBID);
            newStamina = 0.00;
          };
          statPoolsSystem.RequestSettingStatPoolValue(Cast<StatsObjectID>(targetID), gamedataStatPoolType.Stamina, newStamina, hitEvent.attackData.GetInstigator(), false);
        };
      };
      if computedDamageFactor != 1.00 {
        hitEvent.attackComputed.MultAttackValue(computedDamageFactor);
      };
    } else {
      if AttackData.IsRangedOnly(hitEvent.attackData.GetAttackType()) {
        this.ProcessBulletBlockAndDeflect(hitEvent);
      };
    };
  }

  private final func ProcessBulletBlockAndDeflect(hitEvent: ref<gameHitEvent>) -> Void {
    let attackingItem: wref<ItemObject>;
    let blockingItem: wref<ItemObject>;
    let currentStamina: Float;
    let damagePerc: Float;
    let i: Int32;
    let isBulletTimeActive: Bool;
    let isDeflect: Bool;
    let maxStaminaDamagePerc: Float;
    let meleeCostToBlock: Float;
    let newStamina: Float;
    let originalDamages: array<Float>;
    let perkLevel: Int32;
    let playerDevelopmentData: ref<PlayerDevelopmentData>;
    let playerMaxHealth: Float;
    let playerTarget: ref<PlayerPuppet>;
    let staminaReduction: Float;
    let statPoolsSystem: ref<StatPoolsSystem>;
    let statsSystem: ref<StatsSystem>;
    let targetID: EntityID;
    let totalOriginalDamage: Float;
    let computedDamageFactor: Float = 1.00;
    if !(hitEvent.attackData.WasBulletBlocked() || hitEvent.attackData.WasBulletDeflected()) {
      return;
    };
    blockingItem = GameInstance.GetTransactionSystem(hitEvent.target.GetGame()).GetItemInSlot(hitEvent.target, t"AttachmentSlots.WeaponRight");
    attackingItem = hitEvent.attackData.GetWeapon();
    if !IsDefined(blockingItem) || !IsDefined(attackingItem) {
      return;
    };
    playerTarget = hitEvent.target as PlayerPuppet;
    if !IsDefined(playerTarget) {
      return;
    };
    playerDevelopmentData = PlayerDevelopmentSystem.GetData(playerTarget);
    perkLevel = playerDevelopmentData.IsNewPerkBought(gamedataNewPerkType.Reflexes_Right_Milestone_2);
    if perkLevel < 2 {
      return;
    };
    if !(blockingItem as WeaponObject).IsBlade() {
      return;
    };
    computedDamageFactor = 0.00;
    statsSystem = GameInstance.GetStatsSystem(playerTarget.GetGame());
    statPoolsSystem = GameInstance.GetStatPoolsSystem(playerTarget.GetGame());
    targetID = playerTarget.GetEntityID();
    currentStamina = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatPoolType.Stamina, false);
    isBulletTimeActive = playerDevelopmentData.IsNewPerkBought(gamedataNewPerkType.Reflexes_Right_Perk_2_3) > 0 && GameInstance.GetTimeSystem(playerTarget.GetGame()).IsTimeDilationActive();
    if !isBulletTimeActive {
      meleeCostToBlock = statsSystem.GetStatValue(Cast<StatsObjectID>(blockingItem.GetEntityID()), gamedataStatType.StaminaCostToBlock);
      staminaReduction = meleeCostToBlock / 2.00;
      totalOriginalDamage = 0.00;
      originalDamages = hitEvent.attackComputed.GetOriginalAttackValues();
      i = 0;
      while i < ArraySize(originalDamages) {
        totalOriginalDamage += originalDamages[i];
        i += 1;
      };
      playerMaxHealth = GameInstance.GetStatsSystem(playerTarget.GetGame()).GetStatValue(Cast<StatsObjectID>(playerTarget.GetEntityID()), gamedataStatType.Health);
      if playerMaxHealth > 0.00 {
        damagePerc = totalOriginalDamage / playerMaxHealth;
        maxStaminaDamagePerc = 0.50;
        if damagePerc < maxStaminaDamagePerc {
          staminaReduction *= MaxF(0.20, damagePerc / maxStaminaDamagePerc);
        };
      };
      newStamina = MaxF(currentStamina - staminaReduction, 0.00);
      if newStamina <= 0.00 {
        computedDamageFactor = TweakDBInterface.GetFloat(t"Constants.DamageSystem.blockBreakPlayerDamageFactor", 0.50);
      };
      PlayerStaminaHelpers.ModifyStamina(playerTarget, -staminaReduction);
      PlayerStaminaHelpers.OnPlayerBlock(playerTarget);
    };
    if computedDamageFactor != 1.00 {
      hitEvent.attackComputed.MultAttackValue(computedDamageFactor);
    };
    isDeflect = hitEvent.attackData.HasFlag(hitFlag.WasBulletDeflected) && playerDevelopmentData.IsNewPerkBought(gamedataNewPerkType.Reflexes_Right_Perk_2_1) > 0 && currentStamina > statsSystem.GetStatValue(Cast<StatsObjectID>(targetID), gamedataStatType.Stamina) * statsSystem.GetStatValue(Cast<StatsObjectID>(targetID), gamedataStatType.Reflexes_Right_Milestone_2_StaminaDeflectPerc);
    if hitEvent.attackData.HasFlag(hitFlag.WasBulletParried) || isDeflect {
      this.ProcessBulletDeflect(hitEvent, isBulletTimeActive, blockingItem);
    } else {
      GameObject.PlaySound(playerTarget, n"w_perk_lead_and_steel");
    };
  }

  private final func ProcessBulletDeflect(hitEvent: ref<gameHitEvent>, isBulletTimeActive: Bool, blockingItem: wref<ItemObject>) -> Void {
    let angleDist: EulerAngles;
    let attack: ref<Attack_GameEffect>;
    let attackContext: AttackInitContext;
    let currentStaminaPerc: Float;
    let damageMultiplier: Float;
    let damageStat: gamedataStatType;
    let damageType: gamedataDamageType;
    let effect: ref<EffectInstance>;
    let exactPosition: Vector4;
    let forward: Vector4;
    let i: Int32;
    let maxOffset: Float;
    let minOffset: Float;
    let muzzlePosition: Vector4;
    let offset: Vector3;
    let originalDamages: array<Float>;
    let playerWeaponDamage: Float;
    let position: Vector4;
    let slotPosition: Vector4;
    let statMods: array<ref<gameStatModifierData>>;
    let statsSystem: ref<StatsSystem>;
    let target: ref<GameObject>;
    let targetComponent: wref<TargetingComponent>;
    let totalOriginalDamage: Float;
    let player: ref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
    let attackingItem: wref<ItemObject> = hitEvent.attackData.GetWeapon();
    let attackingObject: ref<WeaponObject> = attackingItem as WeaponObject;
    let baseOffset: Float = TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_2.baseOffset", 0.00);
    let offsetMult: Float = TweakDBInterface.GetFloat(t"NewPerks.Reflexes_Right_Milestone_2.offsetMult", 0.00);
    WeaponObject.TriggerWeaponEffects(blockingItem as WeaponObject, gamedataFxAction.MeleeBlock);
    if hitEvent.attackData.HasFlag(hitFlag.WasBulletParried) {
      GameObject.PlaySound(player, n"w_melee_katana_impact_block");
    } else {
      GameObject.PlaySound(player, n"w_melee_perks_katana_bullet_deflecting");
    };
    muzzlePosition = blockingItem.GetWorldPosition();
    GameInstance.GetTargetingSystem(player.GetGame()).GetDefaultCrosshairData(player, exactPosition, forward);
    if isBulletTimeActive || hitEvent.attackData.HasFlag(hitFlag.WasBulletParried) {
      target = GameInstance.GetTargetingSystem(GetGameInstance()).GetObjectClosestToCrosshair(player, angleDist, TSQ_EnemyNPC());
      if IsDefined(target) {
        targetComponent = GameInstance.GetTargetingSystem(GetGameInstance()).GetComponentClosestToCrosshair(player, angleDist, TSQ_EnemyNPC()) as TargetingComponent;
        if IsDefined(targetComponent) && AbsF(angleDist.Yaw) < 6.00 && AbsF(angleDist.Pitch) < 4.00 {
          exactPosition = Matrix.GetTranslation(targetComponent.GetLocalToWorld());
        } else {
          if AIActionHelper.GetTargetSlotPosition(target, n"Chest", slotPosition) {
            exactPosition = slotPosition;
          } else {
            if IsDefined(targetComponent) {
              exactPosition = Matrix.GetTranslation(targetComponent.GetLocalToWorld());
            } else {
              exactPosition = target.GetWorldPosition();
            };
          };
        };
        forward = exactPosition - player.GetWorldPosition();
      };
    };
    currentStaminaPerc = GameInstance.GetStatPoolsSystem(player.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Stamina, true) / 100.00;
    minOffset = baseOffset + offsetMult * (1.00 - currentStaminaPerc);
    maxOffset = minOffset;
    offset = DamageSystem.GetRandomOffset(new Vector3(-minOffset, -minOffset, -minOffset), new Vector3(maxOffset, maxOffset, maxOffset));
    position = exactPosition + Vector4.Vector3To4(offset);
    attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.Reflexes_Right_Milestone_2_Deflect");
    if isBulletTimeActive || hitEvent.attackData.HasFlag(hitFlag.WasBulletParried) {
      attackContext.record = TweakDBInterface.GetAttackRecord(t"Attacks.Reflexes_Right_Milestone_2_ParryDeflect");
    };
    attackContext.source = player;
    attackContext.instigator = attackContext.source;
    attack = IAttack.Create(attackContext) as Attack_GameEffect;
    originalDamages = hitEvent.attackComputed.GetOriginalAttackValues();
    damageMultiplier = 1.00;
    if hitEvent.attackData.HasFlag(hitFlag.WasBulletParried) {
      totalOriginalDamage = 0.00;
      i = 0;
      while i < ArraySize(originalDamages) {
        totalOriginalDamage += originalDamages[i];
        i += 1;
      };
      if totalOriginalDamage > 0.00 {
        statsSystem = GameInstance.GetStatsSystem(player.GetGame());
        playerWeaponDamage = statsSystem.GetStatValue(Cast<StatsObjectID>(blockingItem.GetEntityID()), gamedataStatType.EffectiveDamagePerHit);
        if playerWeaponDamage > totalOriginalDamage {
          damageMultiplier = playerWeaponDamage / totalOriginalDamage;
        };
      };
    };
    i = 0;
    while i < ArraySize(originalDamages) {
      damageType = IntEnum<gamedataDamageType>(i);
      switch damageType {
        case gamedataDamageType.Thermal:
          damageStat = gamedataStatType.ThermalDamage;
          break;
        case gamedataDamageType.Electric:
          damageStat = gamedataStatType.ElectricDamage;
          break;
        case gamedataDamageType.Chemical:
          damageStat = gamedataStatType.ChemicalDamage;
          break;
        default:
          damageStat = gamedataStatType.PhysicalDamage;
      };
      attack.AddStatModifier(RPGManager.CreateStatModifier(damageStat, gameStatModifierType.Additive, originalDamages[i] * damageMultiplier));
      i += 1;
    };
    attack.GetStatModList(statMods);
    effect = attack.PrepareAttack(player);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.position, position);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.muzzlePosition, muzzlePosition);
    EffectData.SetVector(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.forward, Vector4.Normalize(forward));
    EffectData.SetBool(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.playerOwnedWeapon, true);
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.fxPackage, ToVariant(attackingObject.GetFxPackage()));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attack, ToVariant(attack));
    EffectData.SetVariant(effect.GetSharedData(), GetAllBlackboardDefs().EffectSharedData.attackStatModList, ToVariant(statMods));
    attack.StartAttack();
  }

  private final static func GetRandomOffset(minOffset: Vector3, maxOffset: Vector3) -> Vector3 {
    let randomOffset: Vector3;
    randomOffset.X = RandRangeF(minOffset.X, maxOffset.X);
    randomOffset.Y = RandRangeF(minOffset.Y, maxOffset.Y);
    randomOffset.Z = RandRangeF(minOffset.Z, maxOffset.Z);
    return randomOffset;
  }

  private final func ProcessLevelDifference(const hitEvent: ref<gameHitEvent>) -> Void {
    let curveName: CName;
    let instigatorLevel: Float;
    let levelDiff: Float;
    let multiplier: Float;
    let statsSystem: ref<StatsSystem>;
    let targetLevel: Float;
    if hitEvent.target == (hitEvent.target as VehicleObject) {
      return;
    };
    if hitEvent.target.IsPlayer() || hitEvent.attackData.GetInstigator().IsPlayer() {
      statsSystem = GameInstance.GetStatsSystem(hitEvent.target.GetGame());
      instigatorLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.PowerLevel);
      targetLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.PowerLevel);
      levelDiff = instigatorLevel - targetLevel;
      if hitEvent.target.IsPlayer() {
        curveName = n"pl_diff_to_npc_damage_multiplier";
      } else {
        if Equals(hitEvent.attackData.GetAttackType(), gamedataAttackType.Hack) || hitEvent.attackData.HasFlag(hitFlag.QuickHack) {
          curveName = n"pl_diff_to_hackdamage_multiplier";
        } else {
          curveName = n"pl_diff_to_damage_multiplier";
        };
      };
      multiplier = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame()).GetValueFromCurve(n"puppet_dynamic_scaling", levelDiff, curveName);
      hitEvent.attackComputed.MultAttackValue(multiplier);
    };
  }

  private final func ScalePlayerDamage(const hitEvent: ref<gameHitEvent>) -> Void {
    let baseNPCHealth: Float;
    let multiplier: Float;
    let playerLevel: Float;
    let statsSystem: ref<StatsSystem>;
    let targetLevel: Float;
    let weaponLevel: Float;
    let targetPuppet: wref<NPCPuppet> = hitEvent.target as NPCPuppet;
    let targetHealth: Float = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.target.GetEntityID()), gamedataStatType.Health);
    if NotEquals(targetPuppet.GetNPCRarity(), gamedataNPCRarity.Boss) && NotEquals(targetPuppet.GetNPCRarity(), gamedataNPCRarity.MaxTac) {
      statsSystem = GameInstance.GetStatsSystem(targetPuppet.GetGame());
      baseNPCHealth = GameInstance.GetStatsDataSystem(hitEvent.target.GetGame()).GetValueFromCurve(n"puppet_powerLevelToHealth", 1.00, n"puppet_powerLevelToHealth");
      baseNPCHealth *= RPGManager.GetRarityMultiplier(targetPuppet, n"power_level_to_health_mod");
      multiplier = targetHealth / baseNPCHealth;
      if hitEvent.attackData.GetInstigator().IsPlayer() {
        playerLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetInstigator().GetEntityID()), gamedataStatType.PowerLevel);
        targetLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(targetPuppet.GetEntityID()), gamedataStatType.PowerLevel);
        if playerLevel < targetLevel {
          weaponLevel = GameInstance.GetStatsSystem(hitEvent.target.GetGame()).GetStatValue(Cast<StatsObjectID>(hitEvent.attackData.GetWeapon().GetEntityID()), gamedataStatType.PowerLevel);
          multiplier *= GameInstance.GetStatsDataSystem(hitEvent.target.GetGame()).GetValueFromCurve(n"puppet_dynamic_scaling", weaponLevel, n"story_mode_weapon_multiplier");
        };
      };
      hitEvent.attackComputed.MultAttackValue(multiplier);
    };
    if hitEvent.target.IsPlayer() && targetHealth > hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health) && !hitEvent.attackData.GetInstigator().IsPrevention() && !hitEvent.attackData.HasFlag(hitFlag.IgnoreDifficulty) {
      hitEvent.attackComputed.MultAttackValue(0.00);
    };
  }

  public final native func RegisterListener(damageListener: ref<ScriptedDamageSystemListener>, registereeID: EntityID, callbackType: gameDamageCallbackType, opt damagePipelineType: DMGPipelineType) -> Void;

  public final native func UnregisterListener(damageListener: ref<ScriptedDamageSystemListener>, registereeID: EntityID, callbackType: gameDamageCallbackType, opt damagePipelineType: DMGPipelineType) -> Void;

  public final native func RegisterSyncListener(damageListener: ref<ScriptedDamageSystemListener>, registereeID: EntityID, callbackType: gameDamageCallbackType, stage: gameDamagePipelineStage, opt damagePipelineType: DMGPipelineType) -> Void;

  public final native func UnregisterSyncListener(damageListener: ref<ScriptedDamageSystemListener>, registereeID: EntityID, callbackType: gameDamageCallbackType, stage: gameDamagePipelineStage, opt damagePipelineType: DMGPipelineType) -> Void;

  public final native func ProcessSyncStageCallbacks(stage: gameDamagePipelineStage, hitEvent: ref<gameHitEvent>, damagePipelineType: DMGPipelineType) -> Void;

  public final native func ProcessSyncStageMissCallbacks(missEvent: ref<gameMissEvent>) -> Void;

  private final func SetTutorialFact(factName: CName) -> Void {
    let questSystem: ref<QuestsSystem> = GameInstance.GetQuestsSystem(GetGameInstance());
    questSystem.SetFact(factName, questSystem.GetFact(factName) + 1);
  }

  private final func DebugDraw_VehicleHit(gameInstance: GameInstance, hitPosition: Vector4, hitDirection: Vector4, hitMagnitude: Float) -> Void {
    if IsFinal() {
      return;
    };
    GameInstance.GetDebugVisualizerSystem(gameInstance).DrawArrow(hitPosition, hitPosition + hitDirection, new Color(255u, 0u, 0u, 255u), 3.00);
    GameInstance.GetDebugVisualizerSystem(gameInstance).DrawText3D(hitPosition, FloatToString(hitMagnitude), new Color(255u, 0u, 0u, 255u), 3.00);
  }
}

public native class ScriptedDamageSystemListener extends IDamageSystemListener {

  protected func OnHitTriggered(hitEvent: ref<gameHitEvent>) -> Void;

  protected func OnMissTriggered(missEvent: ref<gameMissEvent>) -> Void;

  protected func OnHitReceived(hitEvent: ref<gameHitEvent>) -> Void;

  protected func OnPipelineProcessed(hitEvent: ref<gameHitEvent>) -> Void;
}
