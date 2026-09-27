
public native class RPGManager extends IScriptable {

  public final static native func GetItemData(gi: GameInstance, owner: ref<GameObject>, itemID: ItemID) -> wref<gameItemData>;

  public final static native func GetInnerItemDataQuality(itemData: InnerItemData) -> gamedataQuality;

  public final static native func GetItemDataQuality(itemData: wref<gameItemData>) -> gamedataQuality;

  public final static native func GetFloatItemQuality(qualityStat: Float) -> gamedataQuality;

  public final static native func IsInnerItemDataIconic(itemData: InnerItemData) -> Bool;

  public final static native func IsItemDataIconic(itemData: wref<gameItemData>) -> Bool;

  public final static native func IsItemBroken(itemData: ref<gameItemData>) -> Bool;

  public final static native func ApplyAbilityArray(owner: wref<GameObject>, abilities: [wref<GameplayAbility_Record>]) -> Void;

  public final static native func ShouldFlipNegativeValue(record: wref<Stat_Record>) -> Bool;

  public final static native func ShouldSlotBeAvailable(owner: wref<GameObject>, item: ItemID, attachmentSlotRecord: wref<AttachmentSlot_Record>) -> Bool;

  public final static native func IsSlotAvailable(itemData: wref<gameItemData>, attachmentSlotRecord: wref<AttachmentSlot_Record>) -> Bool;

  public final static native func CalculateStatModifiers(modifiers: [wref<StatModifier_Record>], context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateAdditiveModifiers(modifiers: [wref<StatModifier_Record>], context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateMultiplierModifiers(modifiers: [wref<StatModifier_Record>], context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateAdditiveMultiplierModifiers(modifiers: [wref<StatModifier_Record>], context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateStatModifier(modifier: wref<StatModifier_Record>, context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateConstantModifier(modifier: wref<ConstantStatModifier_Record>) -> Float;

  public final static native func CalculateRandomModifier(modifier: wref<RandomStatModifier_Record>) -> Float;

  public final static native func CalculateCurveModifier(modifier: wref<CurveStatModifier_Record>, context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func CalculateCombinedModifier(modifier: wref<CombinedStatModifier_Record>, context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float;

  public final static native func GetRefObjectID(refObjectName: CName, context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> StatsObjectID;

  public final static native func CalculateBuyPrice(context: GameInstance, vendor: wref<GameObject>, itemID: ItemID, multiplier: Float) -> Int32;

  public final static native func CalculateSellPrice(context: GameInstance, vendor: wref<GameObject>, itemID: ItemID) -> Int32;

  public final static native func CalculateSellPriceItemData(context: GameInstance, vendor: wref<GameObject>, itemData: ref<gameItemData>) -> Int32;

  public final static native func CalculatePowerDifferential(target: wref<GameObject>) -> gameEPowerDifferential;

  public final static func CalculateStatModifiers(addValue: Float, multValue: Float, addMultValue: Float, const modifiers: script_ref<[wref<StatModifier_Record>]>, context: GameInstance, root: wref<GameObject>, targetID: StatsObjectID, opt instigator: StatsObjectID, opt itemStatsID: StatsObjectID) -> Float {
    let addMultMods: array<wref<StatModifier_Record>>;
    let additiveMods: array<wref<StatModifier_Record>>;
    let modType: CName;
    let multiplierMods: array<wref<StatModifier_Record>>;
    let i: Int32 = 0;
    while i < ArraySize(Deref(modifiers)) {
      modType = Deref(modifiers)[i].ModifierType();
      switch modType {
        case n"Additive":
          ArrayPush(additiveMods, Deref(modifiers)[i]);
          break;
        case n"Multiplier":
          ArrayPush(multiplierMods, Deref(modifiers)[i]);
          break;
        case n"AdditiveMultiplier":
          ArrayPush(addMultMods, Deref(modifiers)[i]);
          break;
        default:
      };
      i += 1;
    };
    addValue += RPGManager.CalculateAdditiveModifiers(additiveMods, context, root, targetID, instigator, itemStatsID);
    multValue *= RPGManager.CalculateMultiplierModifiers(multiplierMods, context, root, targetID, instigator, itemStatsID);
    addMultValue += RPGManager.CalculateAdditiveMultiplierModifiers(addMultMods, context, root, targetID, instigator, itemStatsID);
    return addValue * multValue * addMultValue;
  }

  public final static func InjectStatModifier(gi: GameInstance, obj: ref<GameObject>, modifier: ref<gameStatModifierData>) -> Void {
    GameInstance.GetStatsSystem(gi).AddModifier(Cast<StatsObjectID>(obj.GetEntityID()), modifier);
  }

  public final static func InjectStatModifierToItem(gi: GameInstance, itemData: ref<gameItemData>, modifier: ref<gameStatModifierData>) -> Void {
    GameInstance.GetStatsSystem(gi).AddModifier(itemData.GetStatsObjectID(), modifier);
  }

  public final static func IsDamageStat(stat: gamedataStatType) -> Bool {
    return Equals(stat, gamedataStatType.PhysicalDamage) || Equals(stat, gamedataStatType.ThermalDamage) || Equals(stat, gamedataStatType.ChemicalDamage) || Equals(stat, gamedataStatType.ElectricDamage) || Equals(stat, gamedataStatType.DamagePerHit) || Equals(stat, gamedataStatType.EffectiveDamagePerHit);
  }

  public final static func GetStatValueFromObject(gi: GameInstance, object: wref<GameObject>, stat: gamedataStatType) -> Float {
    return GameInstance.GetStatsSystem(gi).GetStatValue(Cast<StatsObjectID>(object.GetEntityID()), stat);
  }

  public final static func CheckPrereqs(const prereqs: script_ref<[wref<IPrereq_Record>]>, target: wref<GameObject>, opt referenceStatsID: StatsObjectID) -> Bool {
    let retVal: Bool = true;
    let i: Int32 = 0;
    while i < ArraySize(Deref(prereqs)) {
      retVal = retVal && RPGManager.CheckPrereq(Deref(prereqs)[i], target);
      if !retVal {
        break;
      };
      i += 1;
    };
    return retVal;
  }

  public final static func CheckPrereq(prereqRecord: wref<IPrereq_Record>, target: wref<GameObject>, opt referenceStatsID: StatsObjectID) -> Bool {
    let prereq: ref<IPrereq> = IPrereq.CreatePrereq(prereqRecord.GetID());
    let statPrereq: ref<StatPrereq> = prereq as StatPrereq;
    if IsDefined(statPrereq) && StatsObjectID.IsDefined(referenceStatsID) {
      if !statPrereq.IsFulfilled(target.GetGame(), target, referenceStatsID) {
        return false;
      };
    } else {
      if !prereq.IsFulfilled(target.GetGame(), target) {
        return false;
      };
    };
    return true;
  }

  public final static func CheckPerkPrereqs(itemData: ref<gameItemData>, owner: ref<GameObject>, perkRequiredName: script_ref<String>) -> Bool {
    let checkedPerkName: String;
    let i: Int32;
    let newPerkPrereq: ref<PlayerIsNewPerkBoughtPrereq_Record>;
    let newPerkRecord: ref<NewPerk_Record>;
    let newPerkType: gamedataNewPerkType;
    let perkPrereq: ref<PerkPrereq_Record>;
    let perkRecord: ref<Perk_Record>;
    let perkType: gamedataPerkType;
    let prereqs: array<wref<IPrereq_Record>>;
    RPGManager.GetItemRecord(itemData.GetID()).EquipPrereqs(prereqs);
    i = 0;
    while i < ArraySize(prereqs) {
      perkPrereq = prereqs[i] as PerkPrereq_Record;
      if IsDefined(perkPrereq) {
        checkedPerkName = perkPrereq.Perk();
        perkRecord = TweakDBInterface.GetPerkRecord(TDBID.Create("Perks." + checkedPerkName));
        if IsDefined(perkRecord) {
          perkType = perkRecord.Type();
          if !PlayerDevelopmentSystem.GetData(owner).HasPerk(perkType) {
            perkRequiredName = perkRecord.Loc_name_key();
            return true;
          };
        };
      } else {
        newPerkPrereq = prereqs[i] as PlayerIsNewPerkBoughtPrereq_Record;
        if IsDefined(newPerkPrereq) {
          checkedPerkName = newPerkPrereq.PerkType();
          newPerkRecord = TweakDBInterface.GetNewPerkRecord(TDBID.Create("NewPerks." + checkedPerkName));
          if IsDefined(newPerkRecord) {
            newPerkType = newPerkRecord.Type();
            if PlayerDevelopmentSystem.GetData(owner).IsNewPerkBought(newPerkType) < newPerkPrereq.Level() {
              perkRequiredName = newPerkRecord.Loc_name_key();
              return true;
            };
          };
        };
      };
      i += 1;
    };
    return false;
  }

  public final static func GetEquipRequirements(owner: ref<GameObject>, itemData: ref<gameItemData>) -> [SItemStackRequirementData] {
    let data: SItemStackRequirementData;
    let datas: array<SItemStackRequirementData>;
    let i: Int32;
    let prereqs: array<wref<IPrereq_Record>>;
    let statPrereqs: array<ref<StatPrereq_Record>>;
    let itemRecord: wref<Item_Record> = RPGManager.GetItemRecord(itemData.GetID());
    itemRecord.EquipPrereqs(prereqs);
    if itemRecord.UsesVariants() {
      itemRecord.GetVariantsItem(itemData.GetVariant()).VariantPrereqs(prereqs);
    };
    statPrereqs = RPGManager.GetNestedPrereqs(prereqs);
    i = 0;
    while i < ArraySize(statPrereqs) {
      data.statType = IntEnum<gamedataStatType>(Cast<Int32>(EnumValueFromName(n"gamedataStatType", statPrereqs[i].StatType())));
      if statPrereqs[i].GetStatModifiersCount() > 0 {
        data.requiredValue = StatsSystemHelper.GetStatPrereqModifiersValue(owner.GetGame(), itemData.GetStatsObjectID(), statPrereqs[i].GetID());
      } else {
        data.requiredValue = statPrereqs[i].ValueToCheck();
      };
      ArrayPush(datas, data);
      i += 1;
    };
    return datas;
  }

  private final static func GetNestedPrereqs(const prereqs: script_ref<[wref<IPrereq_Record>]>) -> [ref<StatPrereq_Record>] {
    let j: Int32;
    let multiPrereq: ref<MultiPrereq_Record>;
    let nestedPrereqs: array<wref<IPrereq_Record>>;
    let statPrereq: ref<StatPrereq_Record>;
    let statPrereqs: array<ref<StatPrereq_Record>>;
    let temps: array<ref<StatPrereq_Record>>;
    let i: Int32 = 0;
    while i < ArraySize(Deref(prereqs)) {
      multiPrereq = Deref(prereqs)[i] as MultiPrereq_Record;
      if IsDefined(multiPrereq) {
        ArrayClear(nestedPrereqs);
        multiPrereq.NestedPrereqs(nestedPrereqs);
        temps = RPGManager.GetNestedPrereqs(nestedPrereqs);
        j = 0;
        while j < ArraySize(temps) {
          ArrayPush(statPrereqs, temps[j]);
          j += 1;
        };
      } else {
        statPrereq = Deref(prereqs)[i] as StatPrereq_Record;
        if IsDefined(statPrereq) {
          ArrayPush(statPrereqs, statPrereq);
        };
      };
      i += 1;
    };
    return statPrereqs;
  }

  public final static func GetFirstUnmetEquipRequirement(owner: ref<GameObject>, const equipRequirements: script_ref<[SItemStackRequirementData]>) -> SItemStackRequirementData {
    let emptyRequirement: SItemStackRequirementData;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(owner.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(equipRequirements)) {
      if statsSystem.GetStatValue(Cast<StatsObjectID>(owner.GetEntityID()), Deref(equipRequirements)[i].statType) < Deref(equipRequirements)[i].requiredValue {
        return Deref(equipRequirements)[i];
      };
      i += 1;
    };
    emptyRequirement.statType = gamedataStatType.Invalid;
    return emptyRequirement;
  }

  public final static func GetRarityMultiplier(puppet: wref<NPCPuppet>, curveName: CName) -> Float {
    let multiplier: Float = 1.00;
    let rarity: gamedataNPCRarity = puppet.GetNPCRarity();
    let statsDataSystem: ref<StatsDataSystem> = GameInstance.GetStatsDataSystem(puppet.GetGame());
    let powerLevel: Float = GameInstance.GetStatsSystem(puppet.GetGame()).GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatType.PowerLevel);
    switch rarity {
      case gamedataNPCRarity.Trash:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_trash_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Weak:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_weak_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Rare:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_rare_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Elite:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_elite_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Officer:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_officer_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Normal:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_normal_mods", powerLevel, curveName);
        break;
      case gamedataNPCRarity.Boss:
      case gamedataNPCRarity.MaxTac:
        multiplier = statsDataSystem.GetValueFromCurve(n"puppet_preset_boss_mods", powerLevel, curveName);
        break;
      default:
        multiplier = 1.00;
    };
    return multiplier;
  }

  public final static func ResistancesList() -> [gamedataStatType] {
    let resistances: array<gamedataStatType>;
    ArrayPush(resistances, gamedataStatType.PhysicalResistance);
    ArrayPush(resistances, gamedataStatType.ChemicalResistance);
    ArrayPush(resistances, gamedataStatType.ThermalResistance);
    ArrayPush(resistances, gamedataStatType.ElectricResistance);
    return resistances;
  }

  public final static func ApplyAbility(owner: wref<GameObject>, ability: wref<GameplayAbility_Record>) -> Void {
    let GLP: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    GLP.RemovePackage(owner, ability.AbilityPackage().GetID());
    GLP.ApplyPackage(owner, owner, ability.AbilityPackage().GetID());
  }

  public final static func RemoveAbility(owner: wref<GameObject>, ability: wref<GameplayAbility_Record>) -> Void {
    let GLP: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    GLP.RemovePackage(owner, ability.AbilityPackage().GetID());
  }

  public final static func ApplyAbilityGroup(owner: wref<GameObject>, group: wref<GameplayAbilityGroup_Record>) -> Void {
    let abilities: array<wref<GameplayAbility_Record>>;
    if group.GetAbilitiesCount() > 0 {
      group.Abilities(abilities);
      RPGManager.ApplyAbilityArray(owner, abilities);
    };
  }

  public final static func RemoveAbilityGroup(owner: wref<GameObject>, group: wref<GameplayAbilityGroup_Record>) -> Void {
    let abilities: array<wref<GameplayAbility_Record>>;
    let i: Int32;
    group.Abilities(abilities);
    i = 0;
    while i < ArraySize(abilities) {
      RPGManager.RemoveAbility(owner, abilities[i]);
      i += 1;
    };
  }

  public final static func ApplyGLP(owner: wref<GameObject>, package: wref<GameplayLogicPackage_Record>) -> Void {
    let appliedPackages: array<TweakDBID>;
    let glpSys: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    glpSys.GetAppliedPackages(owner, appliedPackages);
    if !ArrayContains(appliedPackages, package.GetID()) || package.Stackable() {
      glpSys.ApplyPackage(owner, owner, package.GetID());
    };
  }

  public final static func RemoveGLP(owner: wref<GameObject>, package: wref<GameplayLogicPackage_Record>) -> Void {
    let appliedPackages: array<TweakDBID>;
    let glpSys: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    glpSys.GetAppliedPackages(owner, appliedPackages);
    if ArrayContains(appliedPackages, package.GetID()) {
      glpSys.RemovePackage(owner, package.GetID());
    };
  }

  public final static func ApplyGLPArray(owner: wref<GameObject>, const arr: script_ref<[wref<GameplayLogicPackage_Record>]>, opt ignoreAppliedPackages: Bool, opt withAnimationWrapperOverrides: Int32) -> Void {
    let appliedPackages: array<TweakDBID>;
    let hasAnimWrappers: Bool;
    let i: Int32;
    let glpSys: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    if ignoreAppliedPackages {
      i = 0;
      while i < ArraySize(Deref(arr)) {
        hasAnimWrappers = Deref(arr)[i].GetAnimationWrapperOverridesCount() > 0;
        if withAnimationWrapperOverrides == 0 || withAnimationWrapperOverrides > 0 && hasAnimWrappers || withAnimationWrapperOverrides < 0 && !hasAnimWrappers {
          glpSys.ApplyPackage(owner, owner, Deref(arr)[i].GetID());
        };
        i += 1;
      };
    } else {
      glpSys.GetAppliedPackages(owner, appliedPackages);
      i = 0;
      while i < ArraySize(Deref(arr)) {
        if Deref(arr)[i].Stackable() || !ArrayContains(appliedPackages, Deref(arr)[i].GetID()) {
          glpSys.ApplyPackage(owner, owner, Deref(arr)[i].GetID());
        };
        i += 1;
      };
    };
  }

  public final static func ApplyEffectorsArray(owner: wref<GameObject>, const arr: script_ref<[wref<Effector_Record>]>) -> Void {
    let ES: ref<EffectorSystem> = GameInstance.GetEffectorSystem(owner.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(arr)) {
      ES.ApplyEffector(owner.GetEntityID(), owner, Deref(arr)[i].GetID());
      i += 1;
    };
  }

  public final static func RemoveEffectorsArray(owner: wref<GameObject>, const arr: script_ref<[wref<Effector_Record>]>) -> Void {
    let ES: ref<EffectorSystem> = GameInstance.GetEffectorSystem(owner.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(arr)) {
      ES.RemoveEffector(owner.GetEntityID(), Deref(arr)[i].GetID());
      i += 1;
    };
  }

  public final static func ApplyStatModifierGroups(owner: wref<GameObject>, const arr: script_ref<[wref<StatModifierGroup_Record>]>) -> Void {
    let modGroupID: Uint64;
    let SS: ref<StatsSystem> = GameInstance.GetStatsSystem(owner.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(arr)) {
      modGroupID = TDBID.ToNumber(Deref(arr)[i].GetID());
      SS.DefineModifierGroupFromRecord(modGroupID, Deref(arr)[i].GetID());
      SS.ApplyModifierGroup(Cast<StatsObjectID>(owner.GetEntityID()), modGroupID);
      i += 1;
    };
  }

  public final static func RemoveStatModifierGroups(owner: wref<GameObject>, const arr: script_ref<[wref<StatModifierGroup_Record>]>) -> Void {
    let modGroupID: Uint64;
    let SS: ref<StatsSystem> = GameInstance.GetStatsSystem(owner.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(arr)) {
      modGroupID = TDBID.ToNumber(Deref(arr)[i].GetID());
      SS.RemoveModifierGroup(Cast<StatsObjectID>(owner.GetEntityID()), modGroupID);
      i += 1;
    };
  }

  public final static func GetLevelPercentage(object: ref<GameObject>) -> Int32 {
    let exp: Int32 = PlayerDevelopmentSystem.GetData(object).GetExperiencePercentage();
    return exp;
  }

  public final static func GetItemQualityFromRecord(itemRecord: ref<Item_Record>) -> gamedataQuality {
    let quality: gamedataQuality = itemRecord.Quality().Type();
    if NotEquals(quality, gamedataQuality.Random) {
      return quality;
    };
    return gamedataQuality.Invalid;
  }

  public final static func GetBumpedQuality(quality: gamedataQuality) -> gamedataQuality {
    switch quality {
      case gamedataQuality.Common:
        return gamedataQuality.Uncommon;
      case gamedataQuality.Uncommon:
        return gamedataQuality.Rare;
      case gamedataQuality.Rare:
        return gamedataQuality.Epic;
      case gamedataQuality.Epic:
        return gamedataQuality.Legendary;
      default:
        return quality;
    };
  }

  public final static func GetItemQuality(itemData: InnerItemData) -> gamedataQuality {
    return RPGManager.GetItemQuality(InnerItemData.GetStatValueByType(itemData, gamedataStatType.Quality));
  }

  public final static func ItemQualityNameToValue(q: CName) -> Float {
    let val: Float;
    switch q {
      case n"Common":
        val = 0.00;
        break;
      case n"Uncommon":
        val = 1.00;
        break;
      case n"Rare":
        val = 2.00;
        break;
      case n"Epic":
        val = 3.00;
        break;
      case n"Legendary":
        val = 4.00;
        break;
      default:
        val = 0.00;
    };
    return val;
  }

  public final static func ItemQualityEnumToValue(q: gamedataQuality) -> Float {
    let val: Float;
    switch q {
      case gamedataQuality.Common:
        val = 0.00;
        break;
      case gamedataQuality.Uncommon:
        val = 1.00;
        break;
      case gamedataQuality.Rare:
        val = 2.00;
        break;
      case gamedataQuality.Epic:
        val = 3.00;
        break;
      case gamedataQuality.Legendary:
        val = 4.00;
        break;
      default:
        val = 0.00;
    };
    return val;
  }

  public final static func SetQualityBasedOnLevel(object: wref<GameObject>) -> CName {
    let quality: CName;
    let playerLevel: Float = GameInstance.GetStatsSystem(object.GetGame()).GetStatValue(Cast<StatsObjectID>(object.GetEntityID()), gamedataStatType.Level);
    let scalingValue: Float = GameInstance.GetStatsDataSystem(object.GetGame()).GetValueFromCurve(n"quality_curves", playerLevel, n"crafted_iconic_quality_to_level");
    switch scalingValue {
      case 0.00:
        quality = n"Common";
        break;
      case 1.00:
        quality = n"Uncommon";
        break;
      case 2.00:
        quality = n"Rare";
        break;
      case 3.00:
        quality = n"Epic";
        break;
      case 4.00:
        quality = n"Legendary";
        break;
      default:
        quality = n"Common";
    };
    return quality;
  }

  public final static func GetNextItemQuality(itemData: wref<gameItemData>) -> gamedataQuality {
    if IsDefined(itemData) {
      return RPGManager.GetItemQuality(itemData.GetStatValueByType(gamedataStatType.Quality) + 1.00);
    };
    return gamedataQuality.Invalid;
  }

  public final static func GetPlayerNextLevelBasedOnRandomQuality(quality: gamedataQuality) -> Int32 {
    let playerLevel: Int32;
    switch quality {
      case gamedataQuality.Uncommon:
        playerLevel = 9;
        break;
      case gamedataQuality.Rare:
        playerLevel = 17;
        break;
      case gamedataQuality.Epic:
        playerLevel = 25;
        break;
      case gamedataQuality.Legendary:
        playerLevel = 33;
        break;
      default:
        playerLevel = -1;
    };
    return playerLevel;
  }

  public final static func GetItemQuality(itemData: wref<gameItemData>) -> gamedataQuality {
    if IsDefined(itemData) {
      return RPGManager.GetItemQuality(itemData.GetStatValueByType(gamedataStatType.Quality));
    };
    return gamedataQuality.Invalid;
  }

  public final static func GetItemTierForUpgrades(itemData: wref<gameItemData>) -> gamedataQuality {
    if IsDefined(itemData) {
      return RPGManager.GetItemTierForUpgrades(itemData.GetStatValueByType(gamedataStatType.WasItemUpgraded));
    };
    return gamedataQuality.Invalid;
  }

  public final static func IsItemIconic(itemData: wref<gameItemData>) -> Bool {
    return itemData.GetStatValueByType(gamedataStatType.IsItemIconic) > 0.00;
  }

  public final static func IsItemIconic(itemData: InnerItemData) -> Bool {
    return InnerItemData.GetStatValueByType(itemData, gamedataStatType.IsItemIconic) > 0.00;
  }

  public final static func IsItemMaxLevel(itemData: wref<gameItemData>) -> Bool {
    let tempStat: Float = itemData.GetStatValueByType(gamedataStatType.ItemLevel);
    return tempStat >= 500.00;
  }

  public final static func IsItemMaxTier(itemData: wref<gameItemData>) -> Bool {
    let tempStat: Float = itemData.GetStatValueByType(gamedataStatType.EffectiveTier);
    if IsEP1() {
      return tempStat > 9.99;
    };
    return tempStat > 8.99;
  }

  public final static func GetItemPlus(itemData: ref<gameItemData>) -> Float {
    if IsDefined(itemData) {
      return itemData.GetStatValueByType(gamedataStatType.IsItemPlus);
    };
    return 0.00;
  }

  public final static func IsItemWeapon(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Weapon);
  }

  public final static func IsItemClothing(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Clothing);
  }

  public final static func IsItemCyberware(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Cyberware);
  }

  public final static func IsItemGadget(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Gadget);
  }

  public final static func IsItemProgram(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemType(itemID), gamedataItemType.Prt_Program);
  }

  public final static func IsItemMisc(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemType(itemID), gamedataItemType.Gen_Misc);
  }

  public final static func IsItemTypeCyberwareWeapon(type: gamedataItemType) -> Bool {
    switch type {
      case gamedataItemType.Cyb_StrongArms:
      case gamedataItemType.Cyb_NanoWires:
      case gamedataItemType.Cyb_MantisBlades:
        return true;
      default:
        return false;
    };
  }

  public final static func IsItemAdaptiveStemCells(itemID: TweakDBID) -> Bool {
    return Equals(TweakDBInterface.GetCName(itemID + t".cyberwareType", n"None"), n"AdaptiveStemCells");
  }

  public final static func GetItemQuality(qualityStat: Float) -> gamedataQuality {
    let qualityInt: Int32 = RoundF(qualityStat);
    switch qualityInt {
      case 0:
        return gamedataQuality.Common;
      case 1:
        return gamedataQuality.Uncommon;
      case 2:
        return gamedataQuality.Rare;
      case 3:
        return gamedataQuality.Epic;
      case 4:
        return gamedataQuality.Legendary;
      default:
        return gamedataQuality.Common;
    };
  }

  public final static func GetItemTierForUpgrades(tierStat: Float) -> gamedataQuality {
    let tierInt: Int32 = RoundF(tierStat);
    switch tierInt {
      case 0:
        return gamedataQuality.Common;
      case 1:
        return gamedataQuality.CommonPlus;
      case 2:
        return gamedataQuality.Uncommon;
      case 3:
        return gamedataQuality.UncommonPlus;
      case 4:
        return gamedataQuality.Rare;
      case 5:
        return gamedataQuality.RarePlus;
      case 6:
        return gamedataQuality.Epic;
      case 7:
        return gamedataQuality.EpicPlus;
      case 8:
        return gamedataQuality.Legendary;
      case 9:
        return gamedataQuality.LegendaryPlus;
      case 10:
        return gamedataQuality.LegendaryPlusPlus;
      default:
        return gamedataQuality.Common;
    };
  }

  public final static func GetCraftingMaterialRecord(quality: gamedataQuality, opt isQuickhack: Bool) -> ref<Item_Record> {
    let record: ref<Item_Record>;
    switch quality {
      case gamedataQuality.Common:
        record = TweakDBInterface.GetItemRecord(t"Items.CommonMaterial1");
        break;
      case gamedataQuality.Uncommon:
        if isQuickhack {
          record = TweakDBInterface.GetItemRecord(t"Items.QuickHackUncommonMaterial1");
        } else {
          record = TweakDBInterface.GetItemRecord(t"Items.UncommonMaterial1");
        };
        break;
      case gamedataQuality.Rare:
        if isQuickhack {
          record = TweakDBInterface.GetItemRecord(t"Items.QuickHackRareMaterial1");
        } else {
          record = TweakDBInterface.GetItemRecord(t"Items.RareMaterial1");
        };
        break;
      case gamedataQuality.Epic:
        if isQuickhack {
          record = TweakDBInterface.GetItemRecord(t"Items.QuickHackEpicMaterial1");
        } else {
          record = TweakDBInterface.GetItemRecord(t"Items.EpicMaterial1");
        };
        break;
      case gamedataQuality.Legendary:
        if isQuickhack {
          record = TweakDBInterface.GetItemRecord(t"Items.QuickHackLegendaryMaterial1");
        } else {
          record = TweakDBInterface.GetItemRecord(t"Items.LegendaryMaterial1");
        };
        break;
      default:
        return record;
    };
    return record;
  }

  public final static func GetAvailableSlotsForQuality(itemData: wref<gameItemData>, quality: gamedataQuality) -> Float {
    switch quality {
      case gamedataQuality.Common:
        return 0.00;
      case gamedataQuality.Uncommon:
        return 0.00;
      case gamedataQuality.Rare:
        return 1.00;
      case gamedataQuality.Epic:
        return 2.00;
      case gamedataQuality.Legendary:
        return 3.00;
      default:
        return 0.00;
    };
    return -1.00;
  }

  public final static func GetListOfRandomStatsFromEvolutionType(evolution: gamedataWeaponEvolution) -> [wref<Stat_Record>] {
    let record: wref<UIStatsMap_Record>;
    let statMap: array<wref<Stat_Record>>;
    let tempStr: String;
    if Equals(evolution, gamedataWeaponEvolution.Invalid) {
      record = TweakDBInterface.GetUIStatsMapRecord(t"UIMaps.WeaponGeneral");
    } else {
      tempStr = "UIMaps.";
      tempStr += EnumValueToString("gamedataWeaponEvolution", Cast<Int64>(EnumInt(evolution)));
      record = TweakDBInterface.GetUIStatsMapRecord(TDBID.Create(tempStr));
    };
    record.PrimaryStats(statMap);
    return statMap;
  }

  public final static func GetDominatingDamageType(gi: GameInstance, itemData: wref<gameItemData>) -> gamedataDamageType {
    let dmgIndex: Int32;
    let tempStat: Float;
    let highestValue: Float = 0.00;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    let i: Int32 = 0;
    while i < 4 {
      tempStat = statsSystem.GetStatValueFromDamageType(itemData.GetStatsObjectID(), IntEnum<gamedataDamageType>(i));
      if tempStat > highestValue {
        highestValue = tempStat;
        dmgIndex = i;
      };
      i += 1;
    };
    return IntEnum<gamedataDamageType>(dmgIndex);
  }

  public final static func SetDroppedWeaponQuality(npc: wref<ScriptedPuppet>, itemData: wref<gameItemData>) -> Void {
    let SS: ref<StatsSystem>;
    let mod: ref<gameStatModifierData>;
    let quality: Float;
    if !IsDefined(npc) {
      return;
    };
    SS = GameInstance.GetStatsSystem(npc.GetGame());
    if RandF() < 0.90 {
      quality = 0.00;
    } else {
      quality = 1.00;
    };
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.Quality, true);
    mod = RPGManager.CreateStatModifier(gamedataStatType.Quality, gameStatModifierType.Additive, quality);
    SS.AddSavedModifier(itemData.GetStatsObjectID(), mod);
    ScriptedPuppet.EvaluateLootQualityByTask(npc);
  }

  public final static func ForceItemTier(obj: wref<GameObject>, itemData: wref<gameItemData>, forcedQuality: CName) -> Void {
    let SS: ref<StatsSystem>;
    let helperMod: ref<gameStatModifierData>;
    let plusMod: ref<gameStatModifierData>;
    let qualityMod: ref<gameStatModifierData>;
    let value: Float;
    if !IsDefined(obj) {
      return;
    };
    SS = GameInstance.GetStatsSystem(obj.GetGame());
    value = RPGManager.GetItemTierFromName(forcedQuality);
    if itemData.GetStatValueByType(gamedataStatType.Quality) * 2.00 + itemData.GetStatValueByType(gamedataStatType.IsItemPlus) == value {
      return;
    };
    helperMod = RPGManager.CreateStatModifier(gamedataStatType.ForceQualityHelper, gameStatModifierType.Additive, value);
    SS.AddSavedModifier(itemData.GetStatsObjectID(), helperMod);
    qualityMod = RPGManager.CreateStatModifierUsingCurve(gamedataStatType.Quality, gameStatModifierType.Additive, gamedataStatType.ForceQualityHelper, n"quality_curves", n"iconic_upgrades_amount_to_quality");
    plusMod = RPGManager.CreateStatModifierUsingCurve(gamedataStatType.IsItemPlus, gameStatModifierType.Additive, gamedataStatType.ForceQualityHelper, n"quality_curves", n"iconic_upgrades_amount_to_plus");
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.Quality, true);
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.RandomCurveInput, true);
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.IsItemPlus, true);
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.QualityToMaxQualityRatio, true);
    SS.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.CommonTierFailsafe, true);
    SS.AddSavedModifier(itemData.GetStatsObjectID(), qualityMod);
    SS.AddSavedModifier(itemData.GetStatsObjectID(), plusMod);
  }

  public final static func ProcessOnLootedPackages(owner: wref<GameObject>, itemID: ItemID) -> Void {
    let glp: ref<GameplayLogicPackageSystem>;
    let i: Int32;
    let packages: array<wref<GameplayLogicPackage_Record>>;
    RPGManager.GetItemRecord(itemID).OnLooted(packages);
    glp = GameInstance.GetGameplayLogicPackageSystem(owner.GetGame());
    i = 0;
    while i < ArraySize(packages) {
      glp.ApplyPackage(owner, owner, packages[i].GetID());
      i += 1;
    };
  }

  public final static func GetItemTierFromName(tierName: CName) -> Float {
    switch tierName {
      case n"Common":
        return 0.00;
      case n"CommonPlus":
        return 1.00;
      case n"Uncommon":
        return 2.00;
      case n"UncommonPlus":
        return 3.00;
      case n"Rare":
        return 4.00;
      case n"RarePlus":
        return 5.00;
      case n"Epic":
        return 6.00;
      case n"EpicPlus":
        return 7.00;
      case n"Legendary":
        return 8.00;
      case n"LegendaryPlus":
        return 9.00;
      case n"LegendaryPlusPlus":
        return 10.00;
      default:
        return 0.00;
    };
  }

  public final static func GetCombinedItemQualityValue(game: GameInstance, itemID: ItemID) -> Int32 {
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(game);
    let statsID: StatsObjectID = Cast<StatsObjectID>(itemID);
    if IsDefined(statsSystem) && StatsObjectID.IsDefined(statsID) {
      return Cast<Int32>(statsSystem.GetStatValue(statsID, gamedataStatType.Quality) * 2.00 + statsSystem.GetStatValue(statsID, gamedataStatType.IsItemPlus));
    };
    return 0;
  }

  public final static func ConvertQualityToNonPlusQuality(quality: gamedataQuality) -> gamedataQuality {
    switch quality {
      case gamedataQuality.CommonPlus:
      case gamedataQuality.Common:
        return gamedataQuality.Common;
      case gamedataQuality.UncommonPlus:
      case gamedataQuality.Uncommon:
        return gamedataQuality.Uncommon;
      case gamedataQuality.RarePlus:
      case gamedataQuality.Rare:
        return gamedataQuality.Rare;
      case gamedataQuality.EpicPlus:
      case gamedataQuality.Epic:
        return gamedataQuality.Epic;
      case gamedataQuality.LegendaryPlusPlus:
      case gamedataQuality.LegendaryPlus:
      case gamedataQuality.Legendary:
        return gamedataQuality.Legendary;
      default:
        return gamedataQuality.Invalid;
    };
  }

  public final static func ConvertQualityToItemPlusValue(quality: gamedataQuality) -> Int32 {
    switch quality {
      case gamedataQuality.LegendaryPlusPlus:
        return 2;
      case gamedataQuality.LegendaryPlus:
      case gamedataQuality.EpicPlus:
      case gamedataQuality.RarePlus:
      case gamedataQuality.UncommonPlus:
      case gamedataQuality.CommonPlus:
        return 1;
      default:
        return 0;
    };
  }

  public final static func ConvertCombinedValueToQuality(combinedValue: Int32) -> gamedataQuality {
    switch combinedValue {
      case 0:
        return gamedataQuality.Common;
      case 1:
        return gamedataQuality.CommonPlus;
      case 2:
        return gamedataQuality.Uncommon;
      case 3:
        return gamedataQuality.UncommonPlus;
      case 4:
        return gamedataQuality.Rare;
      case 5:
        return gamedataQuality.RarePlus;
      case 6:
        return gamedataQuality.Epic;
      case 7:
        return gamedataQuality.EpicPlus;
      case 8:
        return gamedataQuality.Legendary;
      case 9:
        return gamedataQuality.LegendaryPlus;
      case 10:
        return gamedataQuality.LegendaryPlusPlus;
      default:
        return gamedataQuality.Invalid;
    };
  }

  public final static func ConvertQualityToCombinedValue(quality: gamedataQuality) -> Int32 {
    switch quality {
      case gamedataQuality.Common:
        return 0;
      case gamedataQuality.CommonPlus:
        return 1;
      case gamedataQuality.Uncommon:
        return 2;
      case gamedataQuality.UncommonPlus:
        return 3;
      case gamedataQuality.Rare:
        return 4;
      case gamedataQuality.RarePlus:
        return 5;
      case gamedataQuality.Epic:
        return 6;
      case gamedataQuality.EpicPlus:
        return 7;
      case gamedataQuality.Legendary:
        return 8;
      case gamedataQuality.LegendaryPlus:
        return 9;
      case gamedataQuality.LegendaryPlusPlus:
        return 10;
      default:
        return 0;
    };
  }

  public final static func ConvertPlayerLevelToCyberwareQuality(playerLevel: Float, includeAboveLegendary: Bool) -> gamedataQuality {
    if includeAboveLegendary && playerLevel > 50.00 {
      return gamedataQuality.LegendaryPlusPlus;
    };
    if includeAboveLegendary && playerLevel > 46.00 {
      return gamedataQuality.LegendaryPlus;
    };
    if playerLevel > 39.00 {
      return gamedataQuality.Legendary;
    };
    if playerLevel > 36.00 {
      return gamedataQuality.EpicPlus;
    };
    if playerLevel > 29.00 {
      return gamedataQuality.Epic;
    };
    if playerLevel > 26.00 {
      return gamedataQuality.RarePlus;
    };
    if playerLevel > 19.00 {
      return gamedataQuality.Rare;
    };
    if playerLevel > 16.00 {
      return gamedataQuality.UncommonPlus;
    };
    if playerLevel > 9.00 {
      return gamedataQuality.Uncommon;
    };
    if playerLevel > 6.00 {
      return gamedataQuality.CommonPlus;
    };
    return gamedataQuality.Common;
  }

  public final static func HasItem(obj: wref<GameObject>, id: TweakDBID) -> Bool {
    let itemID: ItemID = ItemID.CreateQuery(id);
    return GameInstance.GetTransactionSystem(obj.GetGame()).HasItem(obj, itemID);
  }

  public final static func HasItem(obj: wref<GameObject>, id: ItemID) -> Bool {
    return GameInstance.GetTransactionSystem(obj.GetGame()).HasItem(obj, id);
  }

  public final static func GetItemType(itemID: ItemID) -> gamedataItemType {
    if ItemID.IsValid(itemID) {
      return TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)).ItemType().Type();
    };
    return gamedataItemType.Invalid;
  }

  public final static func IsClothingMod(itemID: ItemID) -> Bool {
    if ItemID.IsValid(itemID) {
      return RPGManager.IsClothingMod(RPGManager.GetItemType(itemID));
    };
    return false;
  }

  public final static func IsClothingMod(type: gamedataItemType) -> Bool {
    switch type {
      case gamedataItemType.Prt_FabricEnhancer:
        return true;
      case gamedataItemType.Prt_HeadFabricEnhancer:
        return true;
      case gamedataItemType.Prt_FaceFabricEnhancer:
        return true;
      case gamedataItemType.Prt_TorsoFabricEnhancer:
        return true;
      case gamedataItemType.Prt_OuterTorsoFabricEnhancer:
        return true;
      case gamedataItemType.Prt_PantsFabricEnhancer:
        return true;
      case gamedataItemType.Prt_BootsFabricEnhancer:
        return true;
      default:
        return false;
    };
  }

  public final static func IsWeaponMod(itemID: ItemID) -> Bool {
    if ItemID.IsValid(itemID) {
      return RPGManager.IsWeaponMod(RPGManager.GetItemType(itemID));
    };
    return false;
  }

  public final static func IsWeaponMod(type: gamedataItemType) -> Bool {
    switch type {
      case gamedataItemType.Prt_Mod:
        return true;
      case gamedataItemType.Prt_RangedMod:
        return true;
      case gamedataItemType.Prt_PowerMod:
        return true;
      case gamedataItemType.Prt_TechMod:
        return true;
      case gamedataItemType.Prt_SmartMod:
        return true;
      case gamedataItemType.Prt_AR_SMG_LMGMod:
        return true;
      case gamedataItemType.Prt_HandgunMod:
        return true;
      case gamedataItemType.Prt_Precision_Sniper_RifleMod:
        return true;
      case gamedataItemType.Prt_ShotgunMod:
        return true;
      case gamedataItemType.Prt_MeleeMod:
        return true;
      case gamedataItemType.Prt_BladeMod:
        return true;
      case gamedataItemType.Prt_BluntMod:
        return true;
      case gamedataItemType.Prt_ThrowableMod:
        return true;
      default:
        return false;
    };
  }

  public final static func IsScopeAttachment(itemID: ItemID) -> Bool {
    if ItemID.IsValid(itemID) {
      return RPGManager.IsScopeAttachment(RPGManager.GetItemType(itemID));
    };
    return false;
  }

  public final static func IsScopeAttachment(type: gamedataItemType) -> Bool {
    switch type {
      case gamedataItemType.Prt_Scope:
        return true;
      case gamedataItemType.Prt_ShortScope:
        return true;
      case gamedataItemType.Prt_LongScope:
        return true;
      case gamedataItemType.Prt_TechSniperScope:
        return true;
      case gamedataItemType.Prt_PowerSniperScope:
        return true;
      default:
        return false;
    };
  }

  public final static func IsMuzzleAttachment(type: gamedataItemType) -> Bool {
    switch type {
      case gamedataItemType.Prt_Muzzle:
        return true;
      case gamedataItemType.Prt_RifleMuzzle:
        return true;
      case gamedataItemType.Prt_HandgunMuzzle:
        return true;
      default:
        return false;
    };
  }

  public final static func ReturnRetrievableWeaponMods(itemData: wref<gameItemData>, owner: wref<GameObject>) -> Void {
    let i: Int32;
    let removedID: ItemID;
    let restoredAttachments: array<ItemAttachments>;
    let transactionSystem: ref<TransactionSystem>;
    if !IsDefined(itemData) || !IsDefined(owner) {
      return;
    };
    restoredAttachments = RPGManager.GetRetrievableAttachments(itemData);
    transactionSystem = GameInstance.GetTransactionSystem(owner.GetGame());
    i = 0;
    while i < ArraySize(restoredAttachments) {
      removedID = transactionSystem.RemovePart(owner, itemData.GetID(), restoredAttachments[i].attachmentSlotID);
      if ItemID.IsValid(removedID) {
        transactionSystem.GiveItem(owner, restoredAttachments[i].itemID, 1);
      };
      i += 1;
    };
  }

  public final static func GetRetrievableAttachments(itemData: wref<gameItemData>) -> [ItemAttachments] {
    let i: Int32;
    let innerPart: InnerItemData;
    let innerPartID: ItemID;
    let partTags: array<CName>;
    let restoredAttachments: array<ItemAttachments>;
    let slotsToCheck: array<TweakDBID>;
    let tempArr: array<TweakDBID>;
    if !IsDefined(itemData) {
      return restoredAttachments;
    };
    if Equals(RPGManager.GetItemCategory(itemData.GetID()), gamedataItemCategory.Weapon) {
      slotsToCheck = RPGManager.GetAttachmentSlotIDs();
      tempArr = RPGManager.GetModsSlotIDs(itemData.GetItemType());
      i = 0;
      while i < ArraySize(tempArr) {
        ArrayPush(slotsToCheck, tempArr[i]);
        i += 1;
      };
      i = 0;
      while i < ArraySize(slotsToCheck) {
        itemData.GetItemPart(innerPart, slotsToCheck[i]);
        innerPartID = InnerItemData.GetItemID(innerPart);
        partTags = InnerItemData.GetStaticData(innerPart).Tags();
        if ItemID.IsValid(innerPartID) && ArrayContains(partTags, n"Retrievable") {
          ArrayPush(restoredAttachments, ItemAttachments.Create(innerPartID, slotsToCheck[i]));
        };
        i += 1;
      };
    };
    return restoredAttachments;
  }

  public final static func GetItemCategory(itemID: ItemID) -> gamedataItemCategory {
    let itemCategory: wref<ItemCategory_Record>;
    let itemRecord: ref<Item_Record>;
    if ItemID.IsValid(itemID) {
      itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
      if IsDefined(itemRecord) {
        itemCategory = itemRecord.ItemCategory();
        if IsDefined(itemCategory) {
          return itemCategory.Type();
        };
      };
    };
    return gamedataItemCategory.Invalid;
  }

  public final static func GetWeaponEvolution(itemID: ItemID) -> gamedataWeaponEvolution {
    let itemRecord: ref<WeaponItem_Record>;
    let weaponEvolution: wref<WeaponEvolution_Record>;
    if ItemID.IsValid(itemID) {
      itemRecord = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(itemID));
      if IsDefined(itemRecord) {
        weaponEvolution = itemRecord.Evolution();
        if IsDefined(weaponEvolution) {
          return weaponEvolution.Type();
        };
      };
    };
    return gamedataWeaponEvolution.Invalid;
  }

  public final static func GetItemWeight(itemData: ref<gameItemData>) -> Float {
    if IsDefined(itemData) {
      return itemData.GetStatValueByType(gamedataStatType.Weight);
    };
    return 0.00;
  }

  public final static func GetItemStackWeight(owner: wref<GameObject>, itemData: wref<gameItemData>) -> Float {
    let quantity: Float = Cast<Float>(GameInstance.GetTransactionSystem(owner.GetGame()).GetItemQuantity(owner, itemData.GetID()));
    let weight: Float = RPGManager.GetItemWeight(itemData);
    return quantity * weight;
  }

  public final static func IsItemSingleInstance(itemData: wref<gameItemData>) -> Bool {
    return RPGManager.GetItemRecord(itemData.GetID()).IsSingleInstance();
  }

  public final static func GetItemFromInventory(object: ref<GameObject>, item: TweakDBID) -> ItemID {
    let i: Int32;
    let items: array<wref<gameItemData>>;
    let TS: ref<TransactionSystem> = GameInstance.GetTransactionSystem(object.GetGame());
    TS.GetItemList(object, items);
    i = i;
    while i < ArraySize(items) {
      if ItemID.GetTDBID(items[i].GetID()) == item {
        return items[i].GetID();
      };
      i += 1;
    };
    return ItemID.None();
  }

  public final static func GetAttachmentSlotIDs() -> [TweakDBID] {
    let arr: array<TweakDBID>;
    ArrayPush(arr, t"AttachmentSlots.Scope");
    ArrayPush(arr, t"AttachmentSlots.ScopeRail");
    ArrayPush(arr, t"AttachmentSlots.PowerModule");
    return arr;
  }

  public final static func GetModsSlotIDs(type: gamedataItemType) -> [TweakDBID] {
    let arr: array<TweakDBID>;
    switch type {
      case gamedataItemType.Clo_Head:
        ArrayPush(arr, t"AttachmentSlots.HeadFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.HeadFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.HeadFabricEnhancer3");
        ArrayPush(arr, t"AttachmentSlots.HeadFabricEnhancer4");
        break;
      case gamedataItemType.Clo_Feet:
        ArrayPush(arr, t"AttachmentSlots.FootFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.FootFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.FootFabricEnhancer3");
        ArrayPush(arr, t"AttachmentSlots.FootFabricEnhancer4");
        break;
      case gamedataItemType.Clo_Face:
        ArrayPush(arr, t"AttachmentSlots.FaceFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.FaceFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.FaceFabricEnhancer3");
        ArrayPush(arr, t"AttachmentSlots.FaceFabricEnhancer4");
        break;
      case gamedataItemType.Clo_InnerChest:
        ArrayPush(arr, t"AttachmentSlots.InnerChestFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.InnerChestFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.InnerChestFabricEnhancer3");
        break;
      case gamedataItemType.Clo_Legs:
        ArrayPush(arr, t"AttachmentSlots.LegsFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.LegsFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.LegsFabricEnhancer3");
        ArrayPush(arr, t"AttachmentSlots.LegsFabricEnhancer4");
        break;
      case gamedataItemType.Clo_OuterChest:
        ArrayPush(arr, t"AttachmentSlots.OuterChestFabricEnhancer1");
        ArrayPush(arr, t"AttachmentSlots.OuterChestFabricEnhancer2");
        ArrayPush(arr, t"AttachmentSlots.OuterChestFabricEnhancer3");
        break;
      case gamedataItemType.Wea_LightMachineGun:
      case gamedataItemType.Wea_SubmachineGun:
      case gamedataItemType.Wea_Rifle:
      case gamedataItemType.Wea_AssaultRifle:
        ArrayPush(arr, t"AttachmentSlots.Power_AR_SMG_LMG_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Power_AR_SMG_LMG_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Power_AR_SMG_LMG_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Power_AR_SMG_LMG_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Tech_AR_SMG_LMG_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Tech_AR_SMG_LMG_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Smart_AR_SMG_LMG_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Smart_AR_SMG_LMG_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod3");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod4");
        return arr;
      case gamedataItemType.Wea_Revolver:
      case gamedataItemType.Wea_Handgun:
        ArrayPush(arr, t"AttachmentSlots.Power_Handgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Power_Handgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Power_Handgun_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Power_Handgun_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Tech_Handgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Tech_Handgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Smart_Handgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Smart_Handgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Smart_Handgun_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Smart_Handgun_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod3");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod4");
        return arr;
      case gamedataItemType.Wea_SniperRifle:
      case gamedataItemType.Wea_PrecisionRifle:
        ArrayPush(arr, t"AttachmentSlots.Power_Precision_Sniper_Rifle_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Power_Precision_Sniper_Rifle_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Tech_Precision_Sniper_Rifle_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Tech_Precision_Sniper_Rifle_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Tech_Precision_Sniper_Rifle_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Tech_Precision_Sniper_Rifle_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Smart_Precision_Sniper_Rifle_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Smart_Precision_Sniper_Rifle_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Smart_Precision_Sniper_Rifle_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Smart_Precision_Sniper_Rifle_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod3");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod4");
        return arr;
      case gamedataItemType.Wea_ShotgunDual:
      case gamedataItemType.Wea_Shotgun:
        ArrayPush(arr, t"AttachmentSlots.Power_Shotgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Power_Shotgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Power_Shotgun_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Power_Shotgun_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Tech_Shotgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Tech_Shotgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Smart_Shotgun_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Smart_Shotgun_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod3");
        ArrayPush(arr, t"AttachmentSlots.GenericWeaponMod4");
        return arr;
      case gamedataItemType.Wea_ShortBlade:
      case gamedataItemType.Wea_Machete:
      case gamedataItemType.Wea_LongBlade:
      case gamedataItemType.Wea_Sword:
      case gamedataItemType.Wea_Katana:
      case gamedataItemType.Wea_Chainsword:
        ArrayPush(arr, t"AttachmentSlots.Blade_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Blade_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Blade_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Blade_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod3");
        return arr;
      case gamedataItemType.Wea_Knife:
      case gamedataItemType.Wea_Axe:
        ArrayPush(arr, t"AttachmentSlots.Throwable_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Throwable_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Throwable_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Throwable_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod3");
        return arr;
      case gamedataItemType.Wea_TwoHandedClub:
      case gamedataItemType.Wea_OneHandedClub:
      case gamedataItemType.Wea_Hammer:
        ArrayPush(arr, t"AttachmentSlots.Blunt_WeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.Blunt_WeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.Blunt_WeaponMod1_Collectible");
        ArrayPush(arr, t"AttachmentSlots.Blunt_WeaponMod2_Collectible");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod1");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod2");
        ArrayPush(arr, t"AttachmentSlots.MeleeWeaponMod3");
        return arr;
    };
    return arr;
  }

  public final static func IsInventoryEmpty(object: wref<GameObject>) -> Bool {
    let items: array<wref<gameItemData>>;
    GameInstance.GetTransactionSystem(object.GetGame()).GetItemList(object, items);
    return ArraySize(items) <= 0;
  }

  public final static func ProcessReadAction(choice: ref<InteractionChoiceEvent>) -> Void {
    let lootActionWrapper: LootChoiceActionWrapper = LootChoiceActionWrapper.Unwrap(choice);
    if LootChoiceActionWrapper.IsValid(lootActionWrapper) {
      if Equals(lootActionWrapper.action, n"Read") {
        ItemActionsHelper.ReadItem(choice.activator, lootActionWrapper.itemId);
      };
    };
  }

  public final static func ToggleLootHighlight(obj: wref<GameObject>, enable: Bool) -> Void {
    let recordID: TweakDBID = t"Effectors.LootHighlightEffector";
    if enable {
      GameInstance.GetEffectorSystem(obj.GetGame()).ApplyEffector(obj.GetEntityID(), obj, recordID);
    } else {
      GameInstance.GetEffectorSystem(obj.GetGame()).RemoveEffector(obj.GetEntityID(), recordID);
    };
  }

  public final static func CreateStatModifier(statType: gamedataStatType, modType: gameStatModifierType, value: Float) -> ref<gameStatModifierData> {
    let newMod: ref<gameConstantStatModifierData> = new gameConstantStatModifierData();
    newMod.statType = statType;
    newMod.modifierType = modType;
    newMod.value = value;
    return newMod;
  }

  public final static func CreateStatModifierUsingCurve(statType: gamedataStatType, modType: gameStatModifierType, refStat: gamedataStatType, curveName: CName, columnName: CName) -> ref<gameStatModifierData> {
    let newMod: ref<gameCurveStatModifierData> = new gameCurveStatModifierData();
    newMod.statType = statType;
    newMod.curveStat = refStat;
    newMod.modifierType = modType;
    newMod.curveName = curveName;
    newMod.columnName = columnName;
    return newMod;
  }

  public final static func CreateCombinedStatModifier(statType: gamedataStatType, modType: gameStatModifierType, refStat: gamedataStatType, opSymbol: gameCombinedStatOperation, value: Float, refObject: gameStatObjectsRelation) -> ref<gameStatModifierData> {
    let newMod: ref<gameCombinedStatModifierData> = new gameCombinedStatModifierData();
    newMod.statType = statType;
    newMod.modifierType = modType;
    newMod.value = value;
    newMod.refStatType = refStat;
    newMod.operation = opSymbol;
    newMod.refObject = refObject;
    return newMod;
  }

  public final static func CreateCurveModifier(statRecord: ref<CurveStatModifier_Record>) -> ref<gameStatModifierData> {
    let newMod: ref<gameCurveStatModifierData> = new gameCurveStatModifierData();
    newMod.statType = statRecord.StatType().StatType();
    newMod.modifierType = IntEnum<gameStatModifierType>(Cast<Int32>(EnumValueFromName(n"gameStatModifierType", statRecord.ModifierType())));
    newMod.curveName = StringToName(statRecord.Id());
    newMod.columnName = StringToName(statRecord.Column());
    newMod.curveStat = statRecord.RefStat().StatType();
    return newMod;
  }

  public final static func StatRecordToModifier(statRecord: ref<StatModifier_Record>) -> ref<gameStatModifierData> {
    let combinedOp: gameCombinedStatOperation;
    let modType: gameStatModifierType;
    let relation: gameStatObjectsRelation;
    let statType: gamedataStatType;
    let value: Float;
    let constMod: ref<ConstantStatModifier_Record> = statRecord as ConstantStatModifier_Record;
    let curveMod: ref<CurveStatModifier_Record> = statRecord as CurveStatModifier_Record;
    let combinedMod: ref<CombinedStatModifier_Record> = statRecord as CombinedStatModifier_Record;
    if IsDefined(constMod) {
      statType = constMod.StatType().StatType();
      modType = IntEnum<gameStatModifierType>(Cast<Int32>(EnumValueFromName(n"gameStatModifierType", constMod.ModifierType())));
      value = constMod.Value();
      return RPGManager.CreateStatModifier(statType, modType, value);
    };
    if IsDefined(curveMod) {
      return RPGManager.CreateCurveModifier(curveMod);
    };
    if IsDefined(combinedMod) {
      statType = combinedMod.StatType().StatType();
      modType = IntEnum<gameStatModifierType>(Cast<Int32>(EnumValueFromName(n"gameStatModifierType", combinedMod.ModifierType())));
      combinedOp = IntEnum<gameCombinedStatOperation>(Cast<Int32>(EnumValueFromName(n"gameCombinedStatOperation", combinedMod.OpSymbol())));
      relation = IntEnum<gameStatObjectsRelation>(Cast<Int32>(EnumValueFromName(n"gameStatObjectsRelation", combinedMod.RefObject())));
      value = constMod.Value();
      return RPGManager.CreateCombinedStatModifier(statType, modType, combinedMod.RefStatHandle().StatType(), combinedOp, value, relation);
    };
    return RPGManager.CreateStatModifier(gamedataStatType.Quantity, gameStatModifierType.Additive, 0.00);
  }

  public final static func GetPowerLevelFromContentAssignment(gi: GameInstance, contentAssignmentID: TweakDBID) -> Float {
    let constantModRecord: wref<ConstantStatModifier_Record>;
    let curveModRecord: wref<CurveStatModifier_Record>;
    let contentAssignment: wref<ContentAssignment_Record> = TweakDBInterface.GetContentAssignmentRecord(contentAssignmentID);
    if IsDefined(contentAssignment) {
      constantModRecord = contentAssignment.PowerLevelMod() as ConstantStatModifier_Record;
      curveModRecord = contentAssignment.PowerLevelMod() as CurveStatModifier_Record;
      if IsDefined(constantModRecord) {
        return constantModRecord.Value();
      };
      if IsDefined(curveModRecord) {
        return GameInstance.GetStatsDataSystem(gi).GetMinValueFromCurve(StringToName(curveModRecord.Id()), StringToName(curveModRecord.Column()));
      };
      return Cast<Float>(GameInstance.GetLevelAssignmentSystem(gi).GetLevelAssignment(contentAssignment.GetID()));
    };
    return 0.00;
  }

  public final static func CheckDifficultyToStatValue(gi: GameInstance, skill: gamedataStatType, difficulty: EGameplayChallengeLevel, id: EntityID) -> Int32 {
    let checkPowerLevel: Float;
    let entity: wref<Entity> = GameInstance.FindEntityByID(gi, id);
    let device: wref<Device> = entity as Device;
    let vehicle: wref<VehicleObject> = entity as VehicleObject;
    if IsDefined(device) {
      checkPowerLevel = RPGManager.GetPowerLevelFromContentAssignment(gi, device.GetContentScale());
    };
    if IsDefined(vehicle) {
      checkPowerLevel = RPGManager.GetStatValueFromObject(gi, vehicle, gamedataStatType.PowerLevel);
    };
    return RPGManager.GetCheckValue(gi, checkPowerLevel, difficulty);
  }

  public final static func GetCheckValue(gi: GameInstance, powerLevel: Float, difficulty: EGameplayChallengeLevel) -> Int32 {
    let curveName: CName;
    switch difficulty {
      case EGameplayChallengeLevel.NONE:
        curveName = n"none_difficulty";
        break;
      case EGameplayChallengeLevel.EASY:
        curveName = n"easy_difficulty";
        break;
      case EGameplayChallengeLevel.MEDIUM:
        curveName = n"medium_difficulty";
        break;
      case EGameplayChallengeLevel.HARD:
        curveName = n"hard_difficulty";
        break;
      case EGameplayChallengeLevel.IMPOSSIBLE:
        curveName = n"impossible_difficulty";
    };
    return RoundMath(GameInstance.GetStatsDataSystem(gi).GetValueFromCurve(n"attribute_checks", powerLevel, curveName));
  }

  public final static func CheckDifficultyToPerkLevel(perk: gamedataPerkType, difficulty: EGameplayChallengeLevel, id: EntityID) -> Int32 {
    return EnumInt(difficulty);
  }

  public final static func GetBuildScore(player: ref<GameObject>, buildToCheck: ref<PlayerBuild_Record>) -> Int32 {
    let attribute: gamedataStatType;
    let attributeBonus: gamedataStatType = gamedataStatType.Invalid;
    let attributeBaseValue: Int32 = 0;
    let attributeBonusValue: Int32 = 0;
    let maxValue: Int32 = 20;
    let buildType: gamedataPlayerBuild = buildToCheck.Type();
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
    switch buildType {
      case gamedataPlayerBuild.Netrunner:
        attribute = gamedataStatType.Intelligence;
        attributeBonus = gamedataStatType.IntelligenceSkillcheckBonus;
        break;
      case gamedataPlayerBuild.Solo:
        attribute = gamedataStatType.Strength;
        attributeBonus = gamedataStatType.StrengthSkillcheckBonus;
        break;
      case gamedataPlayerBuild.Techie:
        attribute = gamedataStatType.TechnicalAbility;
        attributeBonus = gamedataStatType.TechnicalAbilitySkillcheckBonus;
        break;
      case gamedataPlayerBuild.Reflexes:
        attribute = gamedataStatType.Reflexes;
        break;
      case gamedataPlayerBuild.Cool:
        attribute = gamedataStatType.Cool;
    };
    attributeBaseValue = Cast<Int32>(statsSystem.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), attribute));
    if NotEquals(attributeBonus, gamedataStatType.Invalid) {
      attributeBonusValue = Cast<Int32>(statsSystem.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), attributeBonus));
    };
    return Min(attributeBaseValue + attributeBonusValue, maxValue);
  }

  public final static func GetBluelineBuildCheckValue(player: ref<GameObject>, contentAssignment: ref<ContentAssignment_Record>, difficulty: EGameplayChallengeLevel) -> Int32 {
    let checkPowerLevel: Float = RPGManager.GetPowerLevelFromContentAssignment(player.GetGame(), contentAssignment.GetID());
    return RPGManager.GetCheckValue(player.GetGame(), checkPowerLevel, difficulty);
  }

  public final static func GetBluelinePaymentValue(player: ref<GameObject>, contentAssignment: ref<ContentAssignment_Record>, difficulty: EGameplayChallengeLevel) -> Int32 {
    let base: Float;
    let digitCount: Int32;
    let overrideValue: Int32;
    let playerMoney: Int32;
    let quotient: Float;
    let upToAmountCheck: Bool;
    let paymentPowerLevel: Float = RPGManager.GetPowerLevelFromContentAssignment(player.GetGame(), contentAssignment.GetID());
    let scaledPaymentValue: Float = GameInstance.GetStatsDataSystem(player.GetGame()).GetValueFromCurve(n"price_curves", paymentPowerLevel, n"power_level_to_payment_check");
    switch difficulty {
      case EGameplayChallengeLevel.NONE:
        scaledPaymentValue = 1.00;
        break;
      case EGameplayChallengeLevel.EASY:
        scaledPaymentValue *= 0.25;
        break;
      case EGameplayChallengeLevel.HARD:
        scaledPaymentValue *= 2.00;
        break;
      case EGameplayChallengeLevel.IMPOSSIBLE:
        scaledPaymentValue *= 10.00;
        break;
      default:
    };
    quotient = scaledPaymentValue;
    while quotient > 1.00 && digitCount < 10 {
      digitCount += 1;
      base = PowF(10.00, Cast<Float>(digitCount));
      quotient = scaledPaymentValue / base;
    };
    base = PowF(10.00, Cast<Float>(CeilF(Cast<Float>(digitCount) / 2.00)));
    scaledPaymentValue /= base;
    scaledPaymentValue = Cast<Float>(RoundMath(scaledPaymentValue));
    scaledPaymentValue *= base;
    overrideValue = TweakDBInterface.GetInt(contentAssignment.GetID() + t".overrideValue", 0);
    if overrideValue > 0 {
      scaledPaymentValue = Cast<Float>(overrideValue);
    };
    upToAmountCheck = TweakDBInterface.GetBool(contentAssignment.GetID() + t".upToCheck", false);
    if upToAmountCheck {
      playerMoney = GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, MarketSystem.Money());
      if playerMoney < Cast<Int32>(scaledPaymentValue) {
        scaledPaymentValue = Cast<Float>(playerMoney);
      };
    };
    return RoundF(scaledPaymentValue);
  }

  public final static func GetStatRecord(type: gamedataStatType) -> ref<Stat_Record> {
    return TweakDBInterface.GetStatRecord(TDBID.Create("BaseStats." + EnumValueToString("gamedataStatType", Cast<Int64>(EnumInt(type)))));
  }

  public final static func GetProficiencyRecord(type: gamedataProficiencyType) -> ref<Proficiency_Record> {
    return TweakDBInterface.GetProficiencyRecord(TDBID.Create("Proficiencies." + EnumValueToString("gamedataProficiencyType", Cast<Int64>(EnumInt(type)))));
  }

  public final static func GetTraitRecord(type: gamedataTraitType) -> ref<Trait_Record> {
    return TweakDBInterface.GetTraitRecord(TDBID.Create("Traits." + EnumValueToString("gamedataTraitType", Cast<Int64>(EnumInt(type)))));
  }

  public final static func GetAttributeDataRecord(type: gamedataAttributeDataType) -> ref<AttributeData_Record> {
    return TweakDBInterface.GetAttributeDataRecord(TDBID.Create("NewPerks." + EnumValueToString("gamedataAttributeDataType", Cast<Int64>(EnumInt(type)))));
  }

  public final static func GetNewPerkRecord(type: gamedataNewPerkType) -> ref<NewPerk_Record> {
    return TweakDBInterface.GetNewPerkRecord(TDBID.Create("NewPerks." + EnumValueToString("gamedataNewPerkType", Cast<Int64>(EnumInt(type)))));
  }

  public final static func GetResistanceTypeFromDamageType(damageType: gamedataDamageType) -> gamedataStatType {
    switch damageType {
      case gamedataDamageType.Physical:
        return gamedataStatType.PhysicalResistance;
      case gamedataDamageType.Thermal:
        return gamedataStatType.ThermalResistance;
      case gamedataDamageType.Chemical:
        return gamedataStatType.ChemicalResistance;
      case gamedataDamageType.Electric:
        return gamedataStatType.ElectricResistance;
      default:
        return gamedataStatType.Invalid;
    };
  }

  public final static func CalculatePowerDifferential(level: Int32) -> gameEPowerDifferential {
    if level <= -6 {
      return gameEPowerDifferential.IMPOSSIBLE;
    };
    if level > -6 && level <= -3 {
      return gameEPowerDifferential.HARD;
    };
    if level > -3 && level <= 2 {
      return gameEPowerDifferential.NORMAL;
    };
    if level > 2 && level <= 4 {
      return gameEPowerDifferential.EASY;
    };
    return gameEPowerDifferential.TRASH;
  }

  public final static func CalculateThreatValue(obj: ref<GameObject>) -> Float {
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(obj.GetGame());
    let player: StatsObjectID = Cast<StatsObjectID>(GetPlayer(obj.GetGame()).GetEntityID());
    let npc: StatsObjectID = Cast<StatsObjectID>(obj.GetEntityID());
    let threatVal: Float = 0.00;
    let maxPowerLevel: Float = 60.00;
    let minPowerLevel: Float = 0.00;
    let npcPowerLevel: Float = statsSystem.GetStatValue(npc, gamedataStatType.PowerLevel);
    let playerPowerLevel: Float = statsSystem.GetStatValue(player, gamedataStatType.PowerLevel);
    let normPowerLevelDiff: Float = MathHelper.NormalizeF(npcPowerLevel - playerPowerLevel, maxPowerLevel - minPowerLevel, minPowerLevel - maxPowerLevel);
    threatVal = normPowerLevelDiff;
    return threatVal;
  }

  public final static func GetScannerResistanceDetails(obj: ref<GameObject>, statType: gamedataStatType, opt player: ref<GameObject>) -> ScannerStatDetails {
    let executorLevel: Float;
    let extraCost: Float;
    let powerLevelDiff: Float;
    let scanStatDetails: ScannerStatDetails;
    let targetLevel: Float;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(obj.GetGame());
    let currentResist: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), statType);
    if Equals(statType, gamedataStatType.HackingResistance) && IsDefined(player) {
      scanStatDetails.baseValue = currentResist;
      executorLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.PowerLevel);
      targetLevel = statsSystem.GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatType.PowerLevel);
      powerLevelDiff = Cast<Float>(RoundMath(executorLevel) - RoundF(targetLevel));
      extraCost = GameInstance.GetStatsDataSystem(player.GetGame()).GetValueFromCurve(n"puppet_dynamic_scaling", powerLevelDiff, n"pl_diff_to_memory_cost_modifier");
      currentResist += extraCost;
    };
    scanStatDetails.statType = statType;
    scanStatDetails.value = currentResist;
    return scanStatDetails;
  }

  public final static func GetCharacterWeakspotCount(puppet: ref<gamePuppet>) -> Int32 {
    let weakspots: array<wref<Weakspot_Record>>;
    TweakDBInterface.GetCharacterRecord(puppet.GetRecordID()).Weakspots(weakspots);
    return ArraySize(weakspots);
  }

  public final static func GetStatValues(obj: ref<GameObject>, const stats: script_ref<[gamedataStatType]>) -> [gameStatTotalValue] {
    let statInfo: gameStatTotalValue;
    let statInfos: array<gameStatTotalValue>;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(obj.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(Deref(stats)) {
      statInfo.value = statsSystem.GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), Deref(stats)[i]);
      statInfo.statType = Deref(stats)[i];
      ArrayPush(statInfos, statInfo);
      i += 1;
    };
    return statInfos;
  }

  public final static func GetMinStats(obj: ref<GameObject>, const stats: script_ref<[gamedataStatType]>) -> [gameStatTotalValue] {
    let minStats: array<gameStatTotalValue>;
    let statInfos: array<gameStatTotalValue> = RPGManager.GetStatValues(obj, stats);
    let minValue: Float = 100000000.00;
    let i: Int32 = 0;
    while i < ArraySize(statInfos) {
      if statInfos[i].value < minValue {
        minValue = statInfos[i].value;
        ArrayClear(minStats);
        ArrayPush(minStats, statInfos[i]);
      } else {
        if statInfos[i].value == minValue {
          ArrayPush(minStats, statInfos[i]);
        };
      };
      i += 1;
    };
    return minStats;
  }

  public final static func GetMaxStats(obj: ref<GameObject>, const stats: script_ref<[gamedataStatType]>) -> [gameStatTotalValue] {
    let maxStats: array<gameStatTotalValue>;
    let statInfos: array<gameStatTotalValue> = RPGManager.GetStatValues(obj, stats);
    let maxValue: Float = -100000000.00;
    let i: Int32 = 0;
    while i < ArraySize(statInfos) {
      if statInfos[i].value > maxValue {
        maxValue = statInfos[i].value;
        ArrayClear(maxStats);
        ArrayPush(maxStats, statInfos[i]);
      } else {
        if statInfos[i].value == maxValue {
          ArrayPush(maxStats, statInfos[i]);
        };
      };
      i += 1;
    };
    return maxStats;
  }

  public final static func GetLowestResistances(obj: ref<GameObject>) -> [gameStatTotalValue] {
    return RPGManager.GetMinStats(obj, RPGManager.ResistancesList());
  }

  public final static func GetHighestResistances(obj: ref<GameObject>) -> [gameStatTotalValue] {
    return RPGManager.GetMaxStats(obj, RPGManager.ResistancesList());
  }

  public final static func CanPlayerCraftFromInventory(obj: wref<GameObject>) -> Bool {
    let val: Float = GameInstance.GetStatsSystem(obj.GetGame()).GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatType.CanCraftFromInventory);
    return val > 0.00;
  }

  public final static func CanPlayerUpgradeFromInventory(obj: wref<GameObject>) -> Bool {
    let val: Float = GameInstance.GetStatsSystem(obj.GetGame()).GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatType.CanUpgradeFromInventory);
    return val > 0.00;
  }

  public final static func AwardExperienceFromDamage(hitEvent: ref<gameHitEvent>, damagePercentage: Float) -> Void {
    let attackRecord: wref<Attack_Record>;
    let i: Int32;
    let player: wref<PlayerPuppet>;
    let playerXPmultiplier: Float;
    let queueExpRequest: ref<QueueCombatExperience>;
    let queueExpRequests: array<ref<QueueCombatExperience>>;
    let targetPowerLevel: Float;
    let temp: Float;
    let weaponRecord: wref<Item_Record>;
    let attackData: ref<AttackData> = hitEvent.attackData;
    let curveSetName: CName = n"activity_to_proficiency_xp";
    let additionalProf: gamedataProficiencyType = gamedataProficiencyType.Invalid;
    let inst: GameInstance = hitEvent.target.GetGame();
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(inst).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let expAwarded: Bool = true;
    let targetPuppet: wref<ScriptedPuppet> = hitEvent.target as ScriptedPuppet;
    if !IsDefined(targetPuppet) || !targetPuppet.IsActive() || !targetPuppet.AwardsExperience() || !attackData.GetInstigator().IsPlayer() || hitEvent.target.IsPlayer() {
      return;
    };
    targetPowerLevel = GameInstance.GetStatsSystem(inst).GetStatValue(Cast<StatsObjectID>(targetPuppet.GetEntityID()), gamedataStatType.PowerLevel);
    playerXPmultiplier = GameInstance.GetStatsSystem(inst).GetStatValue(Cast<StatsObjectID>(GetPlayer(inst).GetEntityID()), gamedataStatType.XPbonusMultiplier);
    queueExpRequest = new QueueCombatExperience();
    weaponRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(attackData.GetWeapon().GetItemID()));
    switch weaponRecord.ItemType().Type() {
      case gamedataItemType.Cyb_StrongArms:
      case gamedataItemType.Wea_Fists:
      case gamedataItemType.Wea_Melee:
      case gamedataItemType.Wea_OneHandedClub:
      case gamedataItemType.Wea_Hammer:
      case gamedataItemType.Wea_TwoHandedClub:
        queueExpRequest.m_experienceType = gamedataProficiencyType.StrengthSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
        break;
      case gamedataItemType.Wea_LightMachineGun:
      case gamedataItemType.Wea_HeavyMachineGun:
      case gamedataItemType.Wea_ShotgunDual:
      case gamedataItemType.Wea_Shotgun:
        temp = weaponRecord.TagsContains(n"PowerWeapon") ? 1.00 : 0.50;
        queueExpRequest.m_experienceType = gamedataProficiencyType.StrengthSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp") * temp;
        break;
      case gamedataItemType.Wea_SubmachineGun:
      case gamedataItemType.Wea_AssaultRifle:
      case gamedataItemType.Wea_Rifle:
        temp = weaponRecord.TagsContains(n"PowerWeapon") ? 1.00 : 0.50;
        queueExpRequest.m_experienceType = gamedataProficiencyType.ReflexesSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp") * temp;
        break;
      case gamedataItemType.Cyb_MantisBlades:
      case gamedataItemType.Wea_Machete:
      case gamedataItemType.Wea_Chainsword:
      case gamedataItemType.Wea_ShortBlade:
      case gamedataItemType.Wea_LongBlade:
      case gamedataItemType.Wea_Sword:
      case gamedataItemType.Wea_Katana:
        queueExpRequest.m_experienceType = gamedataProficiencyType.ReflexesSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
        break;
      case gamedataItemType.Cyb_NanoWires:
        queueExpRequest.m_experienceType = gamedataProficiencyType.IntelligenceSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
        break;
      case gamedataItemType.Wea_PrecisionRifle:
      case gamedataItemType.Wea_SniperRifle:
      case gamedataItemType.Wea_Revolver:
      case gamedataItemType.Wea_Handgun:
        temp = weaponRecord.TagsContains(n"PowerWeapon") ? 1.00 : 0.50;
        queueExpRequest.m_experienceType = gamedataProficiencyType.CoolSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp") * temp;
        break;
      case gamedataItemType.Wea_Axe:
      case gamedataItemType.Wea_Knife:
        queueExpRequest.m_experienceType = gamedataProficiencyType.CoolSkill;
        queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
        break;
      default:
        expAwarded = false;
    };
    if attackData.HasFlag(hitFlag.WeakspotHit) || attackData.HasFlag(hitFlag.Headshot) || attackData.HasFlag(hitFlag.FinisherTriggered) {
      queueExpRequest.m_amount *= 1.10;
    };
    if attackData.HasFlag(hitFlag.PerfectlyCharged) {
      queueExpRequest.m_amount *= 1.10;
    };
    if attackData.HasFlag(hitFlag.BodyPerksMeleeAttack) {
      queueExpRequest.m_amount *= 1.10;
    };
    if expAwarded {
      if StatusEffectSystem.ObjectHasStatusEffectWithTag(attackData.GetInstigator(), n"TrainingGuns") && attackData.GetWeapon().IsRanged() {
        queueExpRequest.m_amount *= 2.00;
      };
      if StatusEffectSystem.ObjectHasStatusEffectWithTag(attackData.GetInstigator(), n"TrainingMelee") && attackData.GetWeapon().IsMelee() {
        queueExpRequest.m_amount *= 2.00;
      };
      ArrayPush(queueExpRequests, queueExpRequest);
      if weaponRecord.TagsContains(n"SmartWeapon") {
        additionalProf = gamedataProficiencyType.IntelligenceSkill;
      } else {
        if weaponRecord.TagsContains(n"TechWeapon") {
          additionalProf = gamedataProficiencyType.TechnicalAbilitySkill;
        };
      };
      if NotEquals(additionalProf, gamedataProficiencyType.Invalid) {
        temp = queueExpRequest.m_amount;
        queueExpRequest = new QueueCombatExperience();
        queueExpRequest.m_experienceType = additionalProf;
        queueExpRequest.m_amount = temp;
        ArrayPush(queueExpRequests, queueExpRequest);
      };
    };
    if Equals(attackData.GetAttackType(), gamedataAttackType.Hack) {
      queueExpRequest = new QueueCombatExperience();
      queueExpRequest.m_experienceType = gamedataProficiencyType.IntelligenceSkill;
      queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
      ArrayPush(queueExpRequests, queueExpRequest);
    };
    attackRecord = attackData.GetAttackDefinition().GetRecord() as Attack_GameEffect_Record;
    if IsDefined(attackData.GetSource() as BaseGrenade) || IsDefined(attackData.GetSource() as ProjectileLauncherRound) || attackRecord.HitFlagsContains("Grenade") {
      queueExpRequest = new QueueCombatExperience();
      queueExpRequest.m_experienceType = gamedataProficiencyType.TechnicalAbilitySkill;
      queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp");
      ArrayPush(queueExpRequests, queueExpRequest);
    };
    if hitEvent.attackData.HasFlag(hitFlag.StealthHit) {
      queueExpRequest = new QueueCombatExperience();
      queueExpRequest.m_experienceType = gamedataProficiencyType.CoolSkill;
      queueExpRequest.m_amount = GameInstance.GetStatsDataSystem(inst).GetValueFromCurve(curveSetName, targetPowerLevel, n"damage_to_skill_xp") * 0.70;
      ArrayPush(queueExpRequests, queueExpRequest);
    };
    player = GetPlayer(inst);
    i = 0;
    while i < ArraySize(queueExpRequests) {
      queueExpRequest = queueExpRequests[i];
      queueExpRequest.owner = player;
      queueExpRequest.m_amount *= RPGManager.GetRarityMultiplier(hitEvent.target as NPCPuppet, n"power_level_to_dmg_xp_mult");
      queueExpRequest.m_amount *= damagePercentage;
      queueExpRequest.m_amount *= playerXPmultiplier;
      queueExpRequest.m_entity = targetPuppet.GetEntityID();
      playerDevSystem.QueueRequest(queueExpRequest);
      i += 1;
    };
    if (attackData.HasFlag(hitFlag.WasKillingBlow) || attackData.HasFlag(hitFlag.FinisherTriggered)) && StatusEffectSystem.ObjectHasStatusEffect(attackData.GetInstigator(), t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff") || StatusEffectSystem.ObjectHasStatusEffect(attackData.GetInstigator(), t"BaseStatusEffect.Tech_Master_Perk_3_Buff") || StatusEffectSystem.ObjectHasStatusEffectOfType(attackData.GetInstigator(), gamedataStatusEffectType.Berserk) || StatusEffectSystem.ObjectHasStatusEffectOfType(attackData.GetInstigator(), gamedataStatusEffectType.Sandevistan) || StatusEffectSystem.ObjectHasStatusEffectWithTag(attackData.GetInstigator(), n"CamoActiveOnPlayer") {
      queueExpRequest = new QueueCombatExperience();
      queueExpRequest.owner = player;
      queueExpRequest.m_experienceType = gamedataProficiencyType.TechnicalAbilitySkill;
      queueExpRequest.m_amount = 20.00 * playerXPmultiplier;
      queueExpRequest.m_entity = targetPuppet.GetEntityID();
      playerDevSystem.QueueRequest(queueExpRequest);
    };
  }

  public final static func AwardExperienceFromDeflect(hitEvent: ref<gameHitEvent>) -> Void {
    let blockingItem: wref<WeaponObject>;
    let damage: Float;
    let gameInstance: GameInstance;
    let health: Float;
    let healthPercent: Float;
    let parryEffect: wref<StatusEffect>;
    let playerDevSystem: ref<PlayerDevelopmentSystem>;
    let playerXPmultiplier: Float;
    let queueExpRequest: ref<QueueCombatExperience>;
    let statPoolsSystem: ref<StatPoolsSystem>;
    let player: wref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
    if !IsDefined(player) {
      return;
    };
    gameInstance = player.GetGame();
    blockingItem = GameInstance.GetTransactionSystem(gameInstance).GetItemInSlot(player, t"AttachmentSlots.WeaponRight") as WeaponObject;
    if !IsDefined(blockingItem) {
      return;
    };
    statPoolsSystem = GameInstance.GetStatPoolsSystem(gameInstance);
    damage = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    healthPercent = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health);
    health = statPoolsSystem.ToPoints(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, healthPercent);
    damage = (damage * healthPercent) / health;
    parryEffect = StatusEffectHelper.GetStatusEffectByID(player, t"BaseStatusEffect.ParryExpHarvested");
    if damage <= 0.00 || IsDefined(parryEffect) && parryEffect.GetMaxStacks() <= parryEffect.GetStackCount() {
      return;
    };
    playerDevSystem = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    playerXPmultiplier = GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.XPbonusMultiplier);
    queueExpRequest = new QueueCombatExperience();
    queueExpRequest.owner = player;
    queueExpRequest.m_entity = hitEvent.attackData.GetInstigator().GetEntityID();
    queueExpRequest.m_amount = damage * playerXPmultiplier * 0.75;
    if blockingItem.IsBlunt() {
      queueExpRequest.m_experienceType = gamedataProficiencyType.StrengthSkill;
      playerDevSystem.QueueRequest(queueExpRequest);
    } else {
      if blockingItem.IsBlade() {
        queueExpRequest.m_experienceType = gamedataProficiencyType.ReflexesSkill;
        playerDevSystem.QueueRequest(queueExpRequest);
      };
    };
    StatusEffectHelper.ApplyStatusEffect(hitEvent.attackData.GetInstigator(), t"BaseStatusEffect.ParryExpHarvested", player.GetEntityID());
  }

  public final static func AwardExperienceFromLocomotion(player: wref<PlayerPuppet>, amount: Float) -> Void {
    let cachedExp: Int32;
    let gameInstance: GameInstance;
    let playerDevSystem: ref<PlayerDevelopmentSystem>;
    let playerXPmultiplier: Float;
    let queueExpRequest: ref<AddExperience>;
    let statMod: ref<gameConstantStatModifierData>;
    let statsSystem: ref<StatsSystem>;
    let statusEffect: ref<StatusEffect>;
    let stat: gamedataStatType = gamedataStatType.LocomotionExperienceReward;
    if !IsDefined(player) || amount <= 0.00 {
      return;
    };
    statusEffect = StatusEffectHelper.GetStatusEffectByID(player, t"BaseStatusEffect.LocomotionExpHarvested");
    if IsDefined(statusEffect) && statusEffect.GetMaxStacks() <= statusEffect.GetStackCount() {
      return;
    };
    gameInstance = player.GetGame();
    playerDevSystem = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    statsSystem = GameInstance.GetStatsSystem(gameInstance);
    playerXPmultiplier = GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.XPbonusMultiplier);
    statMod = RPGManager.CreateStatModifier(stat, gameStatModifierType.Additive, amount * playerXPmultiplier) as gameConstantStatModifierData;
    statsSystem.AddModifier(Cast<StatsObjectID>(player.GetEntityID()), statMod);
    cachedExp = Cast<Int32>(statsSystem.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), stat));
    if cachedExp >= 100 {
      queueExpRequest = new AddExperience();
      queueExpRequest.Set(player, cachedExp, gamedataProficiencyType.ReflexesSkill, false);
      playerDevSystem.QueueRequest(queueExpRequest);
      statMod = RPGManager.CreateStatModifier(stat, gameStatModifierType.Additive, Cast<Float>(cachedExp) * -1.00) as gameConstantStatModifierData;
      statsSystem.AddModifier(Cast<StatsObjectID>(player.GetEntityID()), statMod);
    };
    StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.LocomotionExpHarvested", player.GetEntityID());
  }

  public final static func AwardExperienceFromResourceSpent(player: wref<PlayerPuppet>, value: Float, type: gamedataStatPoolType, opt hitEvent: ref<gameHitEvent>) -> Void {
    let gameInstance: GameInstance;
    let playerDevSystem: ref<PlayerDevelopmentSystem>;
    let playerXPmultiplier: Float;
    let queueCombatExpRequest: ref<QueueCombatExperience>;
    if !IsDefined(player) {
      return;
    };
    gameInstance = player.GetGame();
    playerDevSystem = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    playerXPmultiplier = GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.XPbonusMultiplier);
    if Equals(type, gamedataStatPoolType.Overshield) && IsDefined(hitEvent) && !hitEvent.attackData.GetInstigator().IsPlayer() && hitEvent.target.IsPlayer() {
      queueCombatExpRequest = new QueueCombatExperience();
      queueCombatExpRequest.owner = player;
      queueCombatExpRequest.m_experienceType = gamedataProficiencyType.StrengthSkill;
      queueCombatExpRequest.m_amount = value * playerXPmultiplier * 0.25;
      queueCombatExpRequest.m_entity = hitEvent.attackData.GetInstigator().GetEntityID();
      playerDevSystem.QueueRequest(queueCombatExpRequest);
    };
  }

  public final static func AwardExperienceFromQuickhack(player: wref<PlayerPuppet>, cost: Float, target: EntityID, category: gamedataHackCategory) -> Void {
    let gameInstance: GameInstance;
    let playerDevSystem: ref<PlayerDevelopmentSystem>;
    let playerXPmultiplier: Float;
    let queueExpRequest: ref<AddExperience>;
    let statusEffect: wref<StatusEffect>;
    let targetObj: wref<GameObject>;
    let targetPowerLevel: Float;
    let multiplier: Float = 1.00;
    if !IsDefined(player) || !EntityID.IsDefined(target) || Equals(category, gamedataHackCategory.NotAHack) {
      return;
    };
    targetObj = GameInstance.FindEntityByID(gameInstance, target) as GameObject;
    statusEffect = StatusEffectHelper.GetStatusEffectByID(targetObj, t"BaseStatusEffect.QuickhackExpHarvested");
    if IsDefined(statusEffect) && statusEffect.GetMaxStacks() <= statusEffect.GetStackCount() {
      return;
    };
    gameInstance = player.GetGame();
    playerDevSystem = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    playerXPmultiplier = GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.XPbonusMultiplier);
    targetPowerLevel = GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(target), gamedataStatType.PowerLevel);
    if GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(target), gamedataStatType.WasQuickHacked) < 1.00 {
      multiplier = 20.00;
    };
    if Equals(category, gamedataHackCategory.DeviceHack) {
      multiplier *= 0.30;
    };
    queueExpRequest = new AddExperience();
    queueExpRequest.owner = player;
    queueExpRequest.m_experienceType = gamedataProficiencyType.IntelligenceSkill;
    queueExpRequest.m_amount = Cast<Int32>((cost * 0.70 + targetPowerLevel * 0.20) * playerXPmultiplier * multiplier * 0.50);
    playerDevSystem.QueueRequest(queueExpRequest);
    StatusEffectHelper.ApplyStatusEffect(targetObj, t"BaseStatusEffect.QuickhackExpHarvested", player.GetEntityID());
  }

  public final static func AwardExperienceInstantly(player: wref<PlayerPuppet>, amount: Int32, type: gamedataProficiencyType) -> Void {
    let playerDevSystem: ref<PlayerDevelopmentSystem>;
    let queueExpRequest: ref<AddExperience> = new AddExperience();
    if !IsDefined(player) || amount <= 0 {
      return;
    };
    playerDevSystem = GameInstance.GetScriptableSystemsContainer(player.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    queueExpRequest = new AddExperience();
    queueExpRequest.Set(player, amount, type, false);
    playerDevSystem.QueueRequest(queueExpRequest);
  }

  public final static func CalculateMinorActivityReward(gi: GameInstance, experienceValue: Float) -> Float {
    let experienceReward: Float;
    let factVal: Int32;
    let maCount: Int32;
    let maDynamicMultiplier: Float = 1.00;
    let maPrologueMultiplier: Float = TDB.GetFloat(t"Constants.RPGManager.maPrologueMultiplier");
    let maxExperience: Int32 = TDB.GetInt(t"Constants.RPGManager.maDesiredExperience");
    let maAmount: Int32 = TDB.GetInt(t"Constants.RPGManager.maAmount");
    let baseReward: Int32 = TDB.GetInt(t"Constants.RPGManager.maBaseReward");
    if GetFact(gi, n"q005_done") <= 0 {
      experienceReward = experienceValue * maPrologueMultiplier;
      factVal = GetFact(gi, n"prologue_ma_done");
      SetFactValue(gi, n"prologue_ma_done", factVal + 1);
      SetFactValue(gi, n"maExperienceSum", GetFact(gi, n"maExperienceSum") + Cast<Int32>(experienceReward));
    } else {
      maCount = GetFact(gi, n"prologue_ma_done");
      if maAmount - maCount > 0 {
        maDynamicMultiplier = ((Cast<Float>(maxExperience) - Cast<Float>(GetFact(gi, n"maExperienceSum"))) / (Cast<Float>(maAmount) - Cast<Float>(maCount))) / Cast<Float>(baseReward);
      };
      experienceReward = experienceValue * maDynamicMultiplier;
    };
    return experienceReward;
  }

  public final static func CalculateStreetStoryReward(gi: GameInstance, experienceValue: Float) -> Float {
    let experienceReward: Float;
    let factVal: Int32;
    let stsCount: Int32;
    let stsDynamicMultiplier: Float = 1.00;
    let stsPrologueMultiplier: Float = TDB.GetFloat(t"Constants.RPGManager.stsPrologueMultiplier");
    let maxExperience: Int32 = TDB.GetInt(t"Constants.RPGManager.stsDesiredExperience");
    let stsAmount: Int32 = TDB.GetInt(t"Constants.RPGManager.stsAmount");
    let baseReward: Int32 = TDB.GetInt(t"Constants.RPGManager.stsBaseReward");
    if GetFact(gi, n"q005_done") <= 0 {
      experienceReward = experienceValue * stsPrologueMultiplier;
      factVal = GetFact(gi, n"prologue_sts_done");
      SetFactValue(gi, n"prologue_sts_done", factVal + 1);
      SetFactValue(gi, n"stsExperienceSum", GetFact(gi, n"stsExperienceSum") + Cast<Int32>(experienceReward));
    } else {
      stsCount = GetFact(gi, n"prologue_sts_done");
      if stsAmount - stsCount > 0 {
        stsDynamicMultiplier = ((Cast<Float>(maxExperience) - Cast<Float>(GetFact(gi, n"stsExperienceSum"))) / (Cast<Float>(stsAmount) - Cast<Float>(stsCount))) / Cast<Float>(baseReward);
      };
      experienceReward = experienceValue * stsDynamicMultiplier;
    };
    return experienceReward;
  }

  public final static func CalculateEP1Reward(gi: GameInstance, experienceValue: Float, playerLevel: Float) -> Float {
    let statsDataSystem: ref<StatsDataSystem> = GameInstance.GetStatsDataSystem(gi);
    let levelMult: Float = statsDataSystem.GetValueFromCurve(n"player_level_to_xp_multiplier", playerLevel, n"player_level_to_xp_mult");
    let experienceReward: Float = experienceValue * levelMult;
    return experienceReward;
  }

  public final static func GiveReward(gi: GameInstance, rewardID: TweakDBID, opt target: StatsObjectID, opt moneyMultiplier: Float) -> Void {
    RPGManager.GiveReward(gi, rewardID, 1, target, moneyMultiplier);
  }

  public final static func GiveReward(gi: GameInstance, rewardID: TweakDBID, amount: Int32, opt target: StatsObjectID, opt moneyMultiplier: Float) -> Void {
    let NCPDJobDone: ref<NCPDJobDoneEvent>;
    let achievementsArr: array<wref<Achievement_Record>>;
    let addRecipeRequest: ref<AddRecipeRequest>;
    let calculateXPOldSaves: Bool;
    let contentAssignment: TweakDBID;
    let contentLevel: Int32;
    let courierMissionsDone: Float;
    let courierMoneyMultiplier: Float;
    let currencyArr: array<wref<CurrencyReward_Record>>;
    let currencyItemID: ItemID;
    let expArr: array<wref<XPPoints_Record>>;
    let expEvt: ref<ExperiencePointsEvent>;
    let expType: gamedataProficiencyType;
    let experienceValue: Float;
    let factVal: Int32;
    let i: Int32;
    let itemArr: array<wref<InventoryItem_Record>>;
    let itemID: ItemID;
    let levelDiff: Int32;
    let moneyCalc: Float;
    let moneyQuantity: Int32;
    let photoModeItmsArr: array<wref<PhotoModeItem_Record>>;
    let player: ref<PlayerPuppet>;
    let playerLevel: Float;
    let playerXPmultiplier: Float;
    let powerDiff: gameEPowerDifferential;
    let quantity: Int32;
    let quantityMods: array<wref<StatModifier_Record>>;
    let recipesArr: array<wref<Item_Record>>;
    let rewardName: String;
    let streetCredXPmultiplier: Float;
    let craftingSystem: ref<CraftingSystem> = GameInstance.GetScriptableSystemsContainer(gi).Get(n"CraftingSystem") as CraftingSystem;
    let transSys: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    let visualizer: ref<DebugVisualizerSystem> = GameInstance.GetDebugVisualizerSystem(gi);
    let statsDataSystem: ref<StatsDataSystem> = GameInstance.GetStatsDataSystem(gi);
    let rewardRecord: ref<RewardBase_Record> = TweakDBInterface.GetRewardBaseRecord(rewardID);
    if !IsDefined(rewardRecord) {
      return;
    };
    player = GameInstance.GetPlayerSystem(gi).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    NCPDJobDone = new NCPDJobDoneEvent();
    rewardName = rewardRecord.Name();
    if NotEquals(rewardName, "") {
      visualizer.DrawText(new Vector4(5.00, 350.00, 0.00, 0.00), rewardName, gameDebugViewETextAlignment.Left, new Color(255u, 128u, 0u, 255u), 1.50);
    } else {
      rewardName = "GiveReward(): No reward name found";
      visualizer.DrawText(new Vector4(5.00, 350.00, 0.00, 0.00), rewardName, gameDebugViewETextAlignment.Left, new Color(255u, 128u, 0u, 255u), 1.50);
    };
    rewardRecord.Items(itemArr);
    i = 0;
    while i < ArraySize(itemArr) {
      quantity = itemArr[i].Quantity() * amount;
      itemID = ItemID.FromTDBID(itemArr[i].Item().GetID());
      transSys.GiveItem(player, ItemID.FromTDBID(itemArr[i].Item().GetID()), quantity);
      GameInstance.GetTelemetrySystem(player.GetGame()).LogItemReward(player, itemID);
      i += 1;
    };
    rewardRecord.Recipes(recipesArr);
    i = 0;
    while i < ArraySize(recipesArr) {
      addRecipeRequest = new AddRecipeRequest();
      addRecipeRequest.owner = player;
      addRecipeRequest.amount = 1;
      addRecipeRequest.recipe = recipesArr[i].GetID();
      craftingSystem.QueueRequest(addRecipeRequest);
      GameInstance.GetTelemetrySystem(player.GetGame()).LogItemReward(player, ItemID.FromTDBID(recipesArr[i].GetID()));
      i += 1;
    };
    rewardRecord.Experience(expArr);
    playerXPmultiplier = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.XPbonusMultiplier);
    streetCredXPmultiplier = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.StreetCredXPBonusMultiplier) / 100.00;
    i = 0;
    while i < ArraySize(expArr) {
      expEvt = new ExperiencePointsEvent();
      ArrayClear(quantityMods);
      expArr[i].QuantityModifiers(quantityMods);
      experienceValue = RPGManager.CalculateStatModifiers(quantityMods, player.GetGame(), player, target);
      expType = expArr[i].Type().Type();
      expEvt.type = expType;
      expEvt.isDebug = false;
      if NotEquals(expType, gamedataProficiencyType.Level) && NotEquals(expType, gamedataProficiencyType.StreetCred) {
        experienceValue *= playerXPmultiplier;
      } else {
        if Equals(expType, gamedataProficiencyType.StreetCred) {
          experienceValue *= 1.00 + streetCredXPmultiplier;
        };
      };
      contentAssignment = TweakDBInterface.GetForeignKey(rewardID + t".contentAssignment", t"NewPerks.Intelligence_Left_Milestone_2.preventInQueueAgain");
      if TDBID.IsValid(contentAssignment) {
        playerLevel = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.PowerLevel);
        contentLevel = GameInstance.GetLevelAssignmentSystem(player.GetGame()).GetLevelAssignment(contentAssignment);
        levelDiff = RoundMath(playerLevel - Cast<Float>(contentLevel));
        powerDiff = RPGManager.CalculatePowerDifferential(levelDiff);
        switch powerDiff {
          case gameEPowerDifferential.TRASH:
            experienceValue *= 0.80;
            break;
          case gameEPowerDifferential.EASY:
            experienceValue *= 0.90;
            break;
          case gameEPowerDifferential.HARD:
            experienceValue *= 1.10;
            break;
          case gameEPowerDifferential.IMPOSSIBLE:
            experienceValue *= 1.20;
            break;
          default:
        };
      };
      expEvt.amount = Cast<Int32>(experienceValue) * amount;
      rewardName = StrLower(rewardName);
      if Equals(expType, gamedataProficiencyType.Level) {
        calculateXPOldSaves = Cast<Bool>(GetFact(gi, n"CalculateXPOldSaves"));
        if StrBeginsWith(rewardName, "ma_") && !calculateXPOldSaves {
          expEvt.amount = Cast<Int32>(RPGManager.CalculateMinorActivityReward(gi, experienceValue));
        } else {
          if StrBeginsWith(rewardName, "sts_") && !StrBeginsWith(rewardName, "sts_ep1") && !calculateXPOldSaves {
            expEvt.amount = Cast<Int32>(RPGManager.CalculateStreetStoryReward(gi, experienceValue));
          } else {
            if StrBeginsWith(rewardName, "q3") || StrBeginsWith(rewardName, "mq3") || StrBeginsWith(rewardName, "sts_ep1") || StrBeginsWith(rewardName, "sa_ep1") {
              playerLevel = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level);
              expEvt.amount = Cast<Int32>(RPGManager.CalculateEP1Reward(gi, experienceValue, playerLevel));
            };
          };
        };
      };
      GameInstance.GetTelemetrySystem(gi).LogXPReward(expArr[i].GetID(), expEvt.amount, expEvt.type);
      player.QueueEvent(expEvt);
      if Equals(expType, gamedataProficiencyType.Level) {
        NCPDJobDone.levelXPAwarded = expEvt.amount;
      } else {
        if Equals(expType, gamedataProficiencyType.StreetCred) {
          NCPDJobDone.streetCredXPAwarded = expEvt.amount;
        };
      };
      i += 1;
    };
    moneyQuantity = 0;
    rewardRecord.CurrencyPackage(currencyArr);
    i = 0;
    while i < ArraySize(currencyArr) {
      ArrayClear(quantityMods);
      currencyArr[i].QuantityModifiers(quantityMods);
      quantity = Cast<Int32>(RPGManager.CalculateStatModifiers(quantityMods, player.GetGame(), player, target));
      if quantity > 0 {
        quantity = moneyMultiplier > 0.00 ? Cast<Int32>(Cast<Float>(quantity) * moneyMultiplier) : quantity;
        quantity *= amount;
        currencyItemID = ItemID.FromTDBID(currencyArr[i].Currency().GetID());
        if StrBeginsWith(rewardName, "sa_ep1_courier_tier") {
          factVal = GetFact(gi, n"courier_missions_done");
          courierMissionsDone = Cast<Float>(factVal);
          courierMoneyMultiplier = statsDataSystem.GetValueFromCurve(n"activities_done_to_money_multiplier", courierMissionsDone, n"courier_done_to_money_mult");
          moneyCalc = courierMoneyMultiplier > 0.00 ? Cast<Float>(quantity) * courierMoneyMultiplier : Cast<Float>(quantity);
          quantity = Cast<Int32>(moneyCalc);
          SetFactValue(gi, n"courier_missions_done", factVal + 1);
        };
        transSys.GiveItem(player, currencyItemID, quantity);
        if currencyItemID == MarketSystem.Money() {
          moneyQuantity += quantity;
        };
      };
      i += 1;
    };
    rewardRecord.Achievement(achievementsArr);
    i = 0;
    while i < ArraySize(achievementsArr) {
      RPGManager.SendAddAchievementRequest(gi, achievementsArr[i].Type(), achievementsArr[i]);
      i += 1;
    };
    rewardRecord.PhotoModeItem(photoModeItmsArr);
    i = 0;
    while i < ArraySize(photoModeItmsArr) {
      RPGManager.SendPhotoModeItemUnlockRequest(gi, photoModeItmsArr[i]);
      i += 1;
    };
    if StrBeginsWith(rewardName, "ma_") {
      GameInstance.GetUISystem(gi).QueueEvent(NCPDJobDone);
    };
    GameInstance.GetTelemetrySystem(gi).LogRewardGiven(StringToName(rewardName), rewardID, moneyQuantity);
  }

  public final static func AwardXP(gi: GameInstance, amount: Float, type: gamedataProficiencyType) -> Void {
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    let playerXPmultiplier: Float = statsSystem.GetStatValue(Cast<StatsObjectID>(GetPlayer(gi).GetEntityID()), gamedataStatType.XPbonusMultiplier);
    let awardXP: Float = amount * playerXPmultiplier;
    let xpEvent: ref<ExperiencePointsEvent> = new ExperiencePointsEvent();
    xpEvent.amount = Cast<Int32>(awardXP);
    xpEvent.type = type;
    GetPlayer(gi).QueueEvent(xpEvent);
  }

  private final static func SendAddAchievementRequest(gi: GameInstance, achievement: gamedataAchievement, achievementRecord: wref<Achievement_Record>) -> Void {
    let request: ref<AddAchievementRequest> = new AddAchievementRequest();
    request.achievement = achievement;
    GameInstance.GetScriptableSystemsContainer(gi).Get(n"DataTrackingSystem").QueueRequest(request);
  }

  private final static func SendPhotoModeItemUnlockRequest(gi: GameInstance, photoModeItm: wref<PhotoModeItem_Record>) -> Void {
    let tweakID: TweakDBID = photoModeItm.GetID();
    GameInstance.GetPhotoModeSystem(gi).UnlockPhotoModeItem(tweakID);
  }

  public final static func GiveScavengeReward(gi: GameInstance, rewardID: TweakDBID, scavengeTargetEntityID: EntityID) -> Void {
    RPGManager.GiveReward(gi, rewardID);
  }

  public final static func PrepareGameEffectAttack(gi: GameInstance, instigator: ref<GameObject>, source: ref<GameObject>, attackName: TweakDBID, opt position: Vector4, opt hitFlags: [SHitFlag], opt target: ref<GameObject>, opt tickRateOverride: Float) -> ref<Attack_GameEffect> {
    let attack: ref<Attack_GameEffect>;
    let attackContext: AttackInitContext;
    let attackEffect: ref<EffectInstance>;
    let effectDef: ref<EffectSharedDataDef>;
    let sharedData: EffectData;
    let statMods: array<ref<gameStatModifierData>>;
    let attackRecord: ref<Attack_GameEffect_Record> = TweakDBInterface.GetAttackRecord(attackName) as Attack_GameEffect_Record;
    if IsDefined(attackRecord) {
      attackContext.record = attackRecord;
      attackContext.instigator = instigator;
      attackContext.source = source;
      attack = IAttack.Create(attackContext) as Attack_GameEffect;
      attackEffect = attack.PrepareAttack(instigator);
      attack.GetStatModList(statMods);
      if Equals(position, Vector4.EmptyVector()) {
        position = source.GetWorldPosition();
      };
      sharedData = attackEffect.GetSharedData();
      effectDef = GetAllBlackboardDefs().EffectSharedData;
      EffectData.SetFloat(sharedData, effectDef.radius, attackRecord.Range());
      EffectData.SetVector(sharedData, effectDef.position, position);
      EffectData.SetVariant(sharedData, effectDef.attack, ToVariant(attack));
      EffectData.SetVariant(sharedData, effectDef.attackStatModList, ToVariant(statMods));
      EffectData.SetVariant(sharedData, effectDef.flags, ToVariant(hitFlags));
      EffectData.SetEntity(sharedData, effectDef.entity, target);
      if tickRateOverride > 0.00 {
        EffectData.SetFloat(sharedData, effectDef.tickRateOverride, tickRateOverride);
      };
      EffectData.SetName(sharedData, effectDef.slotName, n"Head");
      return attack;
    };
    return attack;
  }

  public final static func ExtractItemsOfEquipArea(type: gamedataEquipmentArea, const input: script_ref<[wref<gameItemData>]>, output: script_ref<[wref<gameItemData>]>) -> Bool {
    let itemsFound: Bool;
    let i: Int32 = 0;
    while i < ArraySize(Deref(input)) {
      if Equals(TweakDBInterface.GetItemRecord(ItemID.GetTDBID(Deref(input)[i].GetID())).EquipArea().Type(), type) {
        ArrayPush(Deref(output), Deref(input)[i]);
        itemsFound = true;
      };
      i += 1;
    };
    return itemsFound;
  }

  public final static func GetAmmoCount(owner: ref<GameObject>, itemID: ItemID) -> String {
    let ammoCount: Int32;
    let ammoQuery: ItemID;
    let weaponRecord: ref<WeaponItem_Record>;
    let transSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(owner.GetGame());
    let itemRecord: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
    let category: gamedataItemCategory = itemRecord.ItemCategory().Type();
    if Equals(category, gamedataItemCategory.Gadget) || Equals(category, gamedataItemCategory.Consumable) {
      ammoQuery = ItemID.CreateQuery(ItemID.GetTDBID(itemID));
      ammoCount = transSystem.GetItemQuantity(owner, ammoQuery);
      return ToString(ammoCount);
    };
    if Equals(category, gamedataItemCategory.Weapon) {
      weaponRecord = itemRecord as WeaponItem_Record;
      ammoQuery = ItemID.CreateQuery(weaponRecord.Ammo().GetID());
      ammoCount = transSystem.GetItemQuantity(owner, ammoQuery);
    };
    if ammoCount > 0 {
      return ToString(ammoCount);
    };
    return "";
  }

  public final static func GetAmmoCountValue(owner: ref<GameObject>, itemID: ItemID) -> Int32 {
    let ammoCount: Int32;
    let ammoQuery: ItemID;
    let category: gamedataItemCategory;
    let weaponRecord: ref<WeaponItem_Record>;
    let transSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(owner.GetGame());
    let itemRecord: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
    if IsDefined(itemRecord) {
      category = itemRecord.ItemCategory().Type();
    };
    if Equals(category, gamedataItemCategory.Gadget) || Equals(category, gamedataItemCategory.Consumable) {
      ammoQuery = ItemID.CreateQuery(ItemID.GetTDBID(itemID));
      ammoCount = transSystem.GetItemQuantity(owner, ammoQuery);
      return ammoCount;
    };
    if Equals(category, gamedataItemCategory.Weapon) && IsDefined(itemRecord) {
      weaponRecord = itemRecord as WeaponItem_Record;
      ammoQuery = ItemID.CreateQuery(weaponRecord.Ammo().GetID());
      ammoCount = transSystem.GetItemQuantity(owner, ammoQuery);
    };
    return ammoCount;
  }

  public final static func GetWeaponAmmoTDBID(weaponID: ItemID) -> TweakDBID {
    return TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weaponID)).Ammo().GetID();
  }

  public final static func GetItemRecord(itemID: ItemID) -> ref<Item_Record> {
    return TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
  }

  public final static func GetAttachmentSlotID(const slot: script_ref<String>) -> TweakDBID {
    return TDBID.Create("AttachmentSlots." + slot);
  }

  public final static func ForceEquipItemOnPlayer(puppet: ref<GameObject>, itemTDBID: TweakDBID, addToInv: Bool) -> Void {
    let equipRequest: ref<EquipRequest>;
    let itemID: ItemID;
    if puppet == null || !IsDefined(puppet as PlayerPuppet) {
      return;
    };
    itemID = ItemID.FromTDBID(itemTDBID);
    equipRequest = new EquipRequest();
    equipRequest.itemID = itemID;
    equipRequest.owner = puppet;
    equipRequest.addToInventory = addToInv;
    GameInstance.GetScriptableSystemsContainer(puppet.GetGame()).Get(n"EquipmentSystem").QueueRequest(equipRequest);
  }

  public final static func GetItemActions(itemID: ItemID) -> [wref<ObjectAction_Record>] {
    let actions: array<wref<ObjectAction_Record>>;
    TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)).ObjectActions(actions);
    return actions;
  }

  public final static func IsTechPierceEnabled(gi: GameInstance, owner: ref<GameObject>, itemID: ItemID) -> Bool {
    return GameInstance.GetTransactionSystem(gi).GetItemData(owner, itemID).GetStatValueByType(gamedataStatType.TechPierceEnabled) > 0.00;
  }

  public final static func IsRicochetChanceEnabled(gi: GameInstance, owner: ref<GameObject>, itemID: ItemID) -> Bool {
    let itemData: ref<gameItemData> = GameInstance.GetTransactionSystem(gi).GetItemData(owner, itemID);
    if IsDefined(itemData) {
      return itemData.GetStatValueByType(gamedataStatType.RicochetChance) > 0.00;
    };
    return false;
  }

  public final static func HasSmartLinkRequirement(itemData: ref<gameItemData>) -> Bool {
    if IsDefined(itemData) {
      return itemData.GetStatValueByType(gamedataStatType.ItemRequiresSmartLink) > 0.00;
    };
    return false;
  }

  public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
    let itemID: ItemID = data.ID;
    let type: gamedataItemType = RPGManager.GetItemType(itemID);
    if RPGManager.IsWeaponMod(type) || RPGManager.IsClothingMod(type) {
      return data.IsIconic;
    };
    if Equals(type, gamedataItemType.Prt_Fragment) {
      return !RPGManager.IsNonModifableSlot(slotId);
    };
    if Equals(type, gamedataItemType.Prt_ShortScope) || Equals(type, gamedataItemType.Prt_LongScope) || Equals(type, gamedataItemType.Prt_Muzzle) || Equals(type, gamedataItemType.Prt_HandgunMuzzle) || Equals(type, gamedataItemType.Prt_RifleMuzzle) || Equals(type, gamedataItemType.Prt_Program) {
      return true;
    };
    return false;
  }

  private final static func IsNonModifableSlot(slot: TweakDBID) -> Bool {
    return slot == t"AttachmentSlots.StrongArmsKnuckles" || slot == t"AttachmentSlots.MantisBladesEdge" || slot == t"AttachmentSlots.NanoWiresCable" || slot == t"AttachmentSlots.ProjectileLauncherRound";
  }

  public final static func CanItemBeDropped(puppet: ref<GameObject>, itemData: ref<gameItemData>) -> Bool {
    let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(puppet.GetGame()).Get(GetAllBlackboardDefs().UI_QuickSlotsData);
    let consumableBeingUsed: ItemID = FromVariant<ItemID>(blackboard.GetVariant(GetAllBlackboardDefs().UI_QuickSlotsData.consumableBeingUsed));
    if IsDefined(itemData) {
      if ItemID.IsValid(consumableBeingUsed) && TweakDBInterface.GetConsumableItemRecord(ItemID.GetTDBID(itemData.GetID())) == TweakDBInterface.GetConsumableItemRecord(ItemID.GetTDBID(consumableBeingUsed)) {
        return false;
      };
      return !itemData.HasTag(n"IconicWeapon") && !itemData.HasTag(n"Quest") && !itemData.HasTag(n"UnequipBlocked") && IsDefined(ItemActionsHelper.GetDropAction(itemData.GetID()));
    };
    return false;
  }

  public final static func CanItemBeDisassembled(gameInstance: GameInstance, itemID: ItemID) -> Bool {
    return CraftingSystem.GetInstance(gameInstance).CanItemBeDisassembled(GetPlayer(gameInstance), itemID);
  }

  public final static func HasDownloadFundsAction(itemID: ItemID) -> Bool {
    let actions: array<wref<ObjectAction_Record>> = RPGManager.GetItemActions(itemID);
    let i: Int32 = 0;
    while i < ArraySize(actions) {
      if Equals(actions[i].ActionName(), n"DownloadFunds") {
        return true;
      };
      i += 1;
    };
    return false;
  }

  public final static func CanDownloadFunds(gi: GameInstance, itemID: ItemID) -> Bool {
    let fact: CName;
    let actions: array<wref<ObjectAction_Record>> = RPGManager.GetItemActions(itemID);
    let i: Int32 = 0;
    while i < ArraySize(actions) {
      if Equals(actions[i].ActionName(), n"DownloadFunds") {
        fact = TweakDBInterface.GetCName(actions[i].GetID() + t".factToCheck", n"None");
        if IsNameValid(fact) && GetFact(gi, fact) <= 0 {
          return true;
        };
      };
      i += 1;
    };
    return false;
  }

  public final static func CanItemBeDisassembled(gameInstance: GameInstance, itemData: wref<gameItemData>) -> Bool {
    let CS: ref<CraftingSystem>;
    let blackboard: ref<IBlackboard> = GameInstance.GetBlackboardSystem(gameInstance).Get(GetAllBlackboardDefs().UI_QuickSlotsData);
    let consumableBeingUsed: ItemID = FromVariant<ItemID>(blackboard.GetVariant(GetAllBlackboardDefs().UI_QuickSlotsData.consumableBeingUsed));
    if IsDefined(itemData) {
      if ItemID.IsValid(consumableBeingUsed) && TweakDBInterface.GetConsumableItemRecord(ItemID.GetTDBID(itemData.GetID())) == TweakDBInterface.GetConsumableItemRecord(ItemID.GetTDBID(consumableBeingUsed)) {
        return false;
      };
      CS = CraftingSystem.GetInstance(gameInstance);
      return CS.CanItemBeDisassembled(itemData);
    };
    return false;
  }

  public final static func IsItemEquipped(owner: wref<GameObject>, itemID: ItemID) -> Bool {
    let ES: ref<EquipmentSystem> = EquipmentSystem.GetInstance(owner);
    let result: Bool = ES.IsEquipped(owner, itemID);
    return result;
  }

  public final static func IsItemCrafted(itemData: wref<gameItemData>) -> Bool {
    let value: Float = itemData.GetStatValueByType(gamedataStatType.IsItemCrafted);
    return value > 0.00;
  }

  public final static func IsItemCrafted(gi: GameInstance, itemId: ItemID) -> Bool {
    let statsID: StatsObjectID = Cast<StatsObjectID>(itemId);
    let value: Float = GameInstance.GetStatsSystem(gi).GetStatValue(statsID, gamedataStatType.IsItemCrafted);
    return value > 0.00;
  }

  public final static func ConsumeItem(obj: wref<GameObject>, evt: ref<InteractionChoiceEvent>) -> Bool {
    let blackboard: ref<IBlackboard>;
    let eqs: ref<EquipmentSystem>;
    let itemQuantity: Int32;
    let itemType: gamedataItemType;
    let request: ref<EquipmentSystemWeaponManipulationRequest>;
    let lootActionWrapper: LootChoiceActionWrapper = LootChoiceActionWrapper.Unwrap(evt);
    let gameInstance: GameInstance = obj.GetGame();
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gameInstance);
    if Equals(lootActionWrapper.action, n"Consume") {
      itemQuantity = GameInstance.GetTransactionSystem(gameInstance).GetItemQuantity(obj, lootActionWrapper.itemId);
      transactionSystem.TransferItem(obj, evt.activator, lootActionWrapper.itemId, itemQuantity);
      itemType = RPGManager.GetItemType(lootActionWrapper.itemId);
      if Equals(itemType, gamedataItemType.Con_Inhaler) || Equals(itemType, gamedataItemType.Con_Injector) {
        blackboard = GameInstance.GetBlackboardSystem(gameInstance).Get(GetAllBlackboardDefs().UI_QuickSlotsData);
        blackboard.SetVariant(GetAllBlackboardDefs().UI_QuickSlotsData.containerConsumable, ToVariant(lootActionWrapper.itemId));
        eqs = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"EquipmentSystem") as EquipmentSystem;
        request = new EquipmentSystemWeaponManipulationRequest();
        request.owner = evt.activator;
        request.requestType = EquipmentManipulationAction.RequestConsumable;
        eqs.QueueRequest(request);
      } else {
        ItemActionsHelper.ConsumeItem(evt.activator, lootActionWrapper.itemId, true);
        return true;
      };
    } else {
      if Equals(lootActionWrapper.action, n"Eat") {
        itemQuantity = GameInstance.GetTransactionSystem(gameInstance).GetItemQuantity(obj, lootActionWrapper.itemId);
        transactionSystem.TransferItem(obj, evt.activator, lootActionWrapper.itemId, itemQuantity);
        ItemActionsHelper.EatItem(evt.activator, lootActionWrapper.itemId, true);
        return true;
      };
      if Equals(lootActionWrapper.action, n"Drink") {
        itemQuantity = GameInstance.GetTransactionSystem(gameInstance).GetItemQuantity(obj, lootActionWrapper.itemId);
        transactionSystem.TransferItem(obj, evt.activator, lootActionWrapper.itemId, itemQuantity);
        ItemActionsHelper.DrinkItem(evt.activator, lootActionWrapper.itemId, true);
        return true;
      };
    };
    return false;
  }

  public final static func IsWeaponMelee(type: gamedataItemType) -> Bool {
    return Equals(type, gamedataItemType.Wea_Fists) || Equals(type, gamedataItemType.Wea_Knife) || Equals(type, gamedataItemType.Wea_Katana) || Equals(type, gamedataItemType.Wea_Sword) || Equals(type, gamedataItemType.Wea_OneHandedClub) || Equals(type, gamedataItemType.Wea_LongBlade) || Equals(type, gamedataItemType.Wea_ShortBlade) || Equals(type, gamedataItemType.Wea_Melee) || Equals(type, gamedataItemType.Wea_Axe) || Equals(type, gamedataItemType.Wea_Chainsword) || Equals(type, gamedataItemType.Wea_Machete) || Equals(type, gamedataItemType.Wea_Hammer);
  }

  public final static func BreakItem(gi: GameInstance, owner: ref<GameObject>, itemID: ItemID) -> Bool {
    let chance: Float;
    let rand: Float;
    let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(gi).GetItemData(owner, itemID);
    if !IsDefined(itemData) {
      return false;
    };
    if Equals(RPGManager.GetItemDataQuality(itemData), gamedataQuality.Common) {
      chance = TweakDBInterface.GetFloat(t"GlobalStats.ChanceForItemToBeBroken.value", 1.00);
      rand = RandF();
      if rand < chance {
        return true;
      };
    };
    return false;
  }

  public final static func DropManyItems(gameInstance: GameInstance, obj: wref<GameObject>, const items: script_ref<[ItemModParams]>) -> Void {
    let LM: ref<LootManager>;
    let dropList: array<DropInstruction>;
    let i: Int32 = 0;
    while i < ArraySize(Deref(items)) {
      ArrayPush(dropList, DropInstruction.Create(Deref(items)[i].itemID, Deref(items)[i].quantity));
      RPGManager.ReturnRetrievableWeaponMods(RPGManager.GetItemData(gameInstance, obj, Deref(items)[i].itemID), obj);
      i += 1;
    };
    LM = GameInstance.GetLootManager(gameInstance);
    LM.SpawnItemDropOfManyItems(obj, dropList, n"playerDropBag", obj.GetWorldPosition());
  }

  public final static func GetRandomizedHealingConsumable(puppet: wref<ScriptedPuppet>) -> TweakDBID {
    let list: array<TweakDBID>;
    let rand: Int32;
    ArrayPush(list, t"Items.FirstAidWhiffV0");
    ArrayPush(list, t"Items.BonesMcCoy70V0");
    rand = RandRange(0, ArraySize(list) + 1);
    return list[rand];
  }

  public final static func GetRandomizedGadget(puppet: wref<ScriptedPuppet>) -> TweakDBID {
    let list: array<TweakDBID>;
    let rand: Int32 = RandRange(0, ArraySize(list) + 1);
    return list[rand];
  }

  public final static func ForceUnequipItemFromPlayer(puppet: ref<GameObject>, slotTDBID: TweakDBID, removeItem: Bool) -> Void {
    let itemID: ItemID;
    let transactionSys: ref<TransactionSystem>;
    if puppet == null && !IsDefined(puppet as PlayerPuppet) {
      return;
    };
    if !TDBID.IsValid(slotTDBID) {
      return;
    };
    transactionSys = GameInstance.GetTransactionSystem(puppet.GetGame());
    itemID = transactionSys.GetItemInSlot(puppet, slotTDBID).GetItemID();
    transactionSys.RemoveItemFromSlot(puppet, slotTDBID, true);
    if removeItem {
      transactionSys.RemoveItem(puppet, itemID, 1);
    };
  }

  public final static func ToggleHolsteredArmAppearance(puppet: ref<GameObject>, setHoleInArm: Bool) -> Void {
    let itemObj: ref<ItemObject>;
    let switchEvent: ref<gameuiPersonalLinkSwitcherEvent>;
    let player: ref<PlayerPuppet> = puppet as PlayerPuppet;
    if !IsDefined(player) {
      return;
    };
    switchEvent = new gameuiPersonalLinkSwitcherEvent();
    switchEvent.isAdvanced = setHoleInArm;
    itemObj = GameInstance.GetTransactionSystem(player.GetGame()).GetItemInSlot(player, RPGManager.GetAttachmentSlotID("RightArm"));
    if IsDefined(itemObj) {
      itemObj.QueueEvent(switchEvent);
    };
  }

  public final static func TogglePersonalLinkAppearance(puppet: ref<GameObject>) -> Void {
    let itemObj: ref<ItemObject>;
    let meshEvent: ref<entAppearanceEvent>;
    let player: ref<PlayerPuppet> = puppet as PlayerPuppet;
    if !IsDefined(player) {
      return;
    };
    itemObj = GameInstance.GetTransactionSystem(player.GetGame()).GetItemInSlot(player, RPGManager.GetAttachmentSlotID("PersonalLink"));
    if ItemID.GetTDBID(EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.RightArm)) == t"Items.HolsteredStrongArms" {
      meshEvent = new entAppearanceEvent();
      meshEvent.appearanceName = n"only_plug";
      itemObj.QueueEvent(meshEvent);
      return;
    };
  }

  public final static func HasStatFlag(owner: wref<GameObject>, flag: gamedataStatType) -> Bool {
    if !IsDefined(owner) || !owner.IsAttached() {
      return false;
    };
    return GameInstance.GetStatsSystem(owner.GetGame()).GetStatBoolValue(Cast<StatsObjectID>(owner.GetEntityID()), flag);
  }

  public final static func DoesPlayerHaveQuickHack(player: wref<PlayerPuppet>, quickHackTweak: TweakDBID) -> Bool {
    let actionIDs: array<TweakDBID> = RPGManager.GetPlayerQuickHackList(player);
    let i: Int32 = 0;
    while i < ArraySize(actionIDs) {
      if actionIDs[i] == quickHackTweak {
        return true;
      };
      i += 1;
    };
    return false;
  }

  public final static func GetPlayerQuickHackList(player: wref<PlayerPuppet>) -> [TweakDBID] {
    let actionIDs: array<TweakDBID>;
    let playerActions: array<PlayerQuickhackData> = RPGManager.GetPlayerQuickHackListWithQuality(player);
    let i: Int32 = 0;
    while i < ArraySize(playerActions) {
      ArrayPush(actionIDs, playerActions[i].actionRecord.GetID());
      i += 1;
    };
    return actionIDs;
  }

  public final static func GetPlayerQuickHackListWithQuality(player: wref<PlayerPuppet>) -> [PlayerQuickhackData] {
    let actions: array<wref<ObjectAction_Record>>;
    let i: Int32;
    let i1: Int32;
    let itemID: ItemID;
    let itemRecord: wref<Item_Record>;
    let parts: array<SPartSlots>;
    let quickhackData: PlayerQuickhackData;
    let quickhackDataEmpty: PlayerQuickhackData;
    let systemReplacementID: ItemID;
    let tweakItemID: TweakDBID;
    let quickhackDataArray: array<PlayerQuickhackData> = player.GetCachedQuickHackList();
    if ArraySize(quickhackDataArray) > 0 {
      return quickhackDataArray;
    };
    systemReplacementID = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
    itemRecord = RPGManager.GetItemRecord(systemReplacementID);
    tweakItemID = itemRecord.GetID();
    if EquipmentSystem.IsCyberdeckEquipped(player) {
      itemRecord.ObjectActions(actions);
      i = 0;
      while i < ArraySize(actions) {
        if Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack) || Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) || Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.VehicleQuickHack) {
          quickhackData = quickhackDataEmpty;
          quickhackData.actionRecord = actions[i];
          quickhackData.quality = itemRecord.Quality().Value();
          ArrayPush(quickhackDataArray, quickhackData);
        };
        i += 1;
      };
      parts = ItemModificationSystem.GetAllSlots(player, systemReplacementID);
      i = 0;
      while i < ArraySize(parts) {
        ArrayClear(actions);
        itemRecord = RPGManager.GetItemRecord(parts[i].installedPart);
        tweakItemID = itemRecord.GetID();
        itemID = ItemID.FromTDBID(tweakItemID);
        if IsDefined(itemRecord) {
          itemRecord.ObjectActions(actions);
          i1 = 0;
          while i1 < ArraySize(actions) {
            if Equals(actions[i1].ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack) || Equals(actions[i1].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) || Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.VehicleQuickHack) {
              quickhackData = quickhackDataEmpty;
              quickhackData.actionRecord = actions[i1];
              quickhackData.quality = itemRecord.Quality().Value();
              quickhackData.itemID = itemID;
              ArrayPush(quickhackDataArray, quickhackData);
            };
            i1 += 1;
          };
        };
        i += 1;
      };
    };
    ArrayClear(actions);
    itemRecord = RPGManager.GetItemRecord(EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.Splinter));
    if IsDefined(itemRecord) {
      itemRecord.ObjectActions(actions);
      i = 0;
      while i < ArraySize(actions) {
        if Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack) || Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) || Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.VehicleQuickHack) {
          quickhackData = quickhackDataEmpty;
          quickhackData.actionRecord = actions[i];
          ArrayPush(quickhackDataArray, quickhackData);
        };
        i += 1;
      };
    };
    RPGManager.RemoveDuplicatedHacks(quickhackDataArray);
    PlayerPuppet.ChacheQuickHackList(player, quickhackDataArray);
    return quickhackDataArray;
  }

  public final static func GetMonoWireQuickhackRecord(weaponObject: ref<WeaponObject>) -> ref<Item_Record> {
    let quickhackSlotInnerData: InnerItemData;
    let selectedQuickhackItemID: ItemID;
    if !WeaponObject.IsOfType(weaponObject.GetItemID(), gamedataItemType.Cyb_NanoWires) {
      return null;
    };
    weaponObject.GetItemData().GetItemPart(quickhackSlotInnerData, t"AttachmentSlots.NanoWiresQuickhackSlot");
    selectedQuickhackItemID = InnerItemData.GetItemID(quickhackSlotInnerData);
    return RPGManager.GetItemRecord(selectedQuickhackItemID);
  }

  public final static func GetMonoWireQuickHackData(playerOwner: ref<PlayerPuppet>, targetScriptedPuppet: ref<ScriptedPuppet>, weaponObject: ref<WeaponObject>) -> ref<QuickhackData> {
    let context: GetActionsContext;
    let hasSameActionName: Bool;
    let i: Int32;
    let isQuickhackOfDeviceOrPuppetType: Bool;
    let j: Int32;
    let monowireQuickHackData: ref<QuickhackData>;
    let newActionHasBiggerPriority: Bool;
    let quickhackRecordActions: array<wref<ObjectAction_Record>>;
    let selectedQuickhackActionRecord: ref<ObjectAction_Record>;
    let targetActionRecords: array<wref<ObjectAction_Record>>;
    let targetPuppetActions: array<ref<PuppetAction>>;
    let quickhackRecord: ref<Item_Record> = RPGManager.GetMonoWireQuickhackRecord(weaponObject);
    if !IsDefined(targetScriptedPuppet) || !IsDefined(quickhackRecord) {
      return null;
    };
    context = targetScriptedPuppet.GetPuppetPS().GenerateContext(gamedeviceRequestType.Remote, Device.GetInteractionClearance(), playerOwner, targetScriptedPuppet.GetEntityID());
    targetScriptedPuppet.GetRecord().ObjectActions(targetActionRecords);
    targetScriptedPuppet.GetPuppetPS().GetAllChoices(targetActionRecords, context, targetPuppetActions);
    if ArraySize(targetPuppetActions) == 0 {
      return null;
    };
    quickhackRecord.ObjectActions(quickhackRecordActions);
    selectedQuickhackActionRecord = null;
    i = 0;
    while i < ArraySize(targetPuppetActions) {
      j = ArraySize(quickhackRecordActions) - 1;
      while j >= 0 {
        hasSameActionName = Equals(quickhackRecordActions[j].ActionName(), targetPuppetActions[i].GetObjectActionRecord().ActionName());
        isQuickhackOfDeviceOrPuppetType = Equals(quickhackRecordActions[j].ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack) || Equals(quickhackRecordActions[j].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack);
        if hasSameActionName && isQuickhackOfDeviceOrPuppetType {
          if !IsDefined(selectedQuickhackActionRecord) {
            selectedQuickhackActionRecord = quickhackRecordActions[j];
          } else {
            newActionHasBiggerPriority = quickhackRecordActions[j].Priority() > selectedQuickhackActionRecord.Priority();
            if newActionHasBiggerPriority {
              selectedQuickhackActionRecord = quickhackRecordActions[j];
            };
          };
        };
        j -= 1;
      };
      if IsDefined(selectedQuickhackActionRecord) {
        break;
      };
      i += 1;
    };
    if !IsDefined(selectedQuickhackActionRecord) {
      return null;
    };
    monowireQuickHackData = new QuickhackData();
    monowireQuickHackData.m_actionOwner = targetScriptedPuppet.GetEntityID();
    monowireQuickHackData.m_actionOwnerName = StringToName(targetScriptedPuppet.GetTweakDBFullDisplayName(true));
    monowireQuickHackData.m_action = targetPuppetActions[i];
    monowireQuickHackData.m_uploadTime = targetPuppetActions[i].GetActivationTime();
    monowireQuickHackData.m_duration = targetScriptedPuppet.GetQuickHackDurationFromLongestEffect(selectedQuickhackActionRecord, targetScriptedPuppet, Cast<StatsObjectID>(targetScriptedPuppet.GetEntityID()), playerOwner.GetEntityID());
    monowireQuickHackData.m_action.SetObjectActionID(selectedQuickhackActionRecord.GetID());
    monowireQuickHackData.m_cost = 0;
    monowireQuickHackData.m_title = LocKeyToString(selectedQuickhackActionRecord.ObjectActionUI().Caption());
    return monowireQuickHackData;
  }

  public final static func CreateSimpleQuickhackData(playerOwner: ref<PlayerPuppet>, targetScriptedPuppet: ref<ScriptedPuppet>, quickhackActionRecord: ref<ObjectAction_Record>) -> ref<QuickhackData> {
    let i: Int32;
    let monowireQuickHackData: ref<QuickhackData>;
    let targetActionRecords: array<wref<ObjectAction_Record>>;
    let targetPuppetActions: array<ref<PuppetAction>>;
    let quickHackActionFound: Bool = false;
    let context: GetActionsContext = targetScriptedPuppet.GetPuppetPS().GenerateContext(gamedeviceRequestType.Remote, Device.GetInteractionClearance(), playerOwner, targetScriptedPuppet.GetEntityID());
    targetScriptedPuppet.GetRecord().ObjectActions(targetActionRecords);
    targetScriptedPuppet.GetPuppetPS().GetAllChoices(targetActionRecords, context, targetPuppetActions);
    i = 0;
    while i < ArraySize(targetPuppetActions) {
      if Equals(quickhackActionRecord.ActionName(), targetPuppetActions[i].GetObjectActionRecord().ActionName()) {
        quickHackActionFound = true;
        break;
      };
      i += 1;
    };
    if !quickHackActionFound {
      return null;
    };
    monowireQuickHackData = new QuickhackData();
    monowireQuickHackData.m_actionOwner = targetScriptedPuppet.GetEntityID();
    monowireQuickHackData.m_actionOwnerName = StringToName(targetScriptedPuppet.GetTweakDBFullDisplayName(true));
    monowireQuickHackData.m_action = targetPuppetActions[i];
    monowireQuickHackData.m_uploadTime = targetPuppetActions[i].GetActivationTime();
    monowireQuickHackData.m_duration = targetScriptedPuppet.GetQuickHackDurationFromLongestEffect(quickhackActionRecord, targetScriptedPuppet, Cast<StatsObjectID>(targetScriptedPuppet.GetEntityID()), playerOwner.GetEntityID());
    monowireQuickHackData.m_action.SetObjectActionID(quickhackActionRecord.GetID());
    monowireQuickHackData.m_cost = 0;
    return monowireQuickHackData;
  }

  public final static func IncrementQuickHackBlackboard(gameInstance: GameInstance, actionID: TweakDBID) -> Void {
    let playerBlackboard: ref<IBlackboard>;
    let uploadingQuickHackIDs: array<TweakDBID>;
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    if IsDefined(playerPuppet) {
      playerBlackboard = GameInstance.GetBlackboardSystem(gameInstance).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
      uploadingQuickHackIDs = FromVariant<array<TweakDBID>>(playerBlackboard.GetVariant(GetAllBlackboardDefs().PlayerStateMachine.UploadingQuickHackIDs));
      ArrayPush(uploadingQuickHackIDs, actionID);
      playerBlackboard.SetVariant(GetAllBlackboardDefs().PlayerStateMachine.UploadingQuickHackIDs, ToVariant(uploadingQuickHackIDs));
    };
  }

  public final static func DecrementQuickHackBlackboard(gameInstance: GameInstance, actionID: TweakDBID) -> Void {
    let playerBlackboard: ref<IBlackboard>;
    let uploadingQuickHackIDs: array<TweakDBID>;
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(gameInstance).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    if IsDefined(playerPuppet) {
      playerBlackboard = GameInstance.GetBlackboardSystem(gameInstance).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
      uploadingQuickHackIDs = FromVariant<array<TweakDBID>>(playerBlackboard.GetVariant(GetAllBlackboardDefs().PlayerStateMachine.UploadingQuickHackIDs));
      ArrayRemove(uploadingQuickHackIDs, actionID);
      playerBlackboard.SetVariant(GetAllBlackboardDefs().PlayerStateMachine.UploadingQuickHackIDs, ToVariant(uploadingQuickHackIDs));
    };
  }

  private final static func RemoveDuplicatedHacks(commands: script_ref<[PlayerQuickhackData]>) -> Void {
    let i1: Int32;
    let indexesToRemove: array<Int32>;
    let i: Int32 = ArraySize(Deref(commands)) - 1;
    while i >= 0 {
      i1 = 0;
      while i1 < i {
        if Equals(Deref(commands)[i].actionRecord.ActionName(), Deref(commands)[i1].actionRecord.ActionName()) && Equals(Deref(commands)[i].actionRecord.ObjectActionType().Type(), Deref(commands)[i1].actionRecord.ObjectActionType().Type()) {
          if Deref(commands)[i].actionRecord.Priority() >= Deref(commands)[i1].actionRecord.Priority() {
            if !ArrayContains(indexesToRemove, i1) {
              ArrayPush(indexesToRemove, i1);
            };
          } else {
            if !ArrayContains(indexesToRemove, i1) {
              ArrayPush(indexesToRemove, i1);
            };
          };
        };
        i1 += 1;
      };
      i -= 1;
    };
    indexesToRemove = ArraySortReverse(indexesToRemove);
    i = 0;
    while i < ArraySize(indexesToRemove) {
      ArrayErase(Deref(commands), indexesToRemove[i]);
      i += 1;
    };
  }

  private final static func RemoveDuplicatedHacks(deck: script_ref<[wref<ObjectAction_Record>]>, splinter: script_ref<[wref<ObjectAction_Record>]>) -> Void {
    let i1: Int32;
    let i: Int32 = ArraySize(Deref(deck)) - 1;
    while i >= 0 {
      i1 = ArraySize(Deref(splinter)) - 1;
      while i1 >= 0 {
        if Equals(Deref(deck)[i].ActionName(), Deref(splinter)[i1].ActionName()) {
          if Deref(deck)[i].Priority() >= Deref(splinter)[i1].Priority() {
            ArrayErase(Deref(splinter), i1);
          } else {
            ArrayErase(Deref(deck), i);
          };
        };
        i1 -= 1;
      };
      i -= 1;
    };
  }

  public final static func GetPlayerCurrentHealthPercent(gi: GameInstance) -> Float {
    let player: wref<PlayerPuppet> = GameInstance.GetPlayerSystem(gi).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    if IsDefined(player) {
      return GameInstance.GetStatPoolsSystem(gi).GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, true);
    };
    return -1.00;
  }

  public final static func GetVendorWareRequirement(game: GameInstance, record: wref<VendorWare_Record>, itemStatsID: StatsObjectID) -> SItemStackRequirementData {
    let data: SItemStackRequirementData;
    let statPrereq: ref<StatPrereq_Record> = record.AvailabilityPrereq() as StatPrereq_Record;
    if IsDefined(statPrereq) {
      data.statType = IntEnum<gamedataStatType>(Cast<Int32>(EnumValueFromName(n"gamedataStatType", statPrereq.StatType())));
      if StatsObjectID.IsDefined(itemStatsID) && statPrereq.GetStatModifiersCount() > 0 {
        data.requiredValue = StatsSystemHelper.GetStatPrereqModifiersValue(game, itemStatsID, statPrereq.GetID());
      } else {
        data.requiredValue = statPrereq.ValueToCheck();
      };
    } else {
      data.statType = gamedataStatType.Invalid;
      data.requiredValue = -1.00;
    };
    return data;
  }

  public final static func CyberwareHasUpgrade(game: GameInstance, itemID: ItemID, currentQuality: gamedataQuality, desiredQuality: gamedataQuality, out upgradeItemRecord: ref<Item_Record>) -> Bool {
    let confirmedUpgradeRecord: ref<Item_Record>;
    let qualityUpgrade: Int32 = RPGManager.ConvertQualityToCombinedValue(desiredQuality) - RPGManager.ConvertQualityToCombinedValue(currentQuality);
    let potentialUpgradeRecord: ref<Item_Record> = RPGManager.GetItemRecord(itemID).NextUpgradeItem();
    while qualityUpgrade >= 1 {
      if TDBID.IsValid(potentialUpgradeRecord.GetID()) {
        confirmedUpgradeRecord = potentialUpgradeRecord;
        potentialUpgradeRecord = confirmedUpgradeRecord.NextUpgradeItem();
      } else {
        break;
      };
      qualityUpgrade -= 1;
    };
    if TDBID.IsValid(confirmedUpgradeRecord.GetID()) && qualityUpgrade <= 0 {
      upgradeItemRecord = confirmedUpgradeRecord;
      return true;
    };
    return false;
  }

  public final static func CyberwareHasSideUpgrade(itemID: ItemID, out sideUpgradeItemRecord: ref<Item_Record>) -> Bool {
    let sideUpgradeRecord: ref<Item_Record> = RPGManager.GetItemRecord(itemID).SideUpgradeItem();
    if TDBID.IsValid(sideUpgradeRecord.GetID()) {
      sideUpgradeItemRecord = sideUpgradeRecord;
      return true;
    };
    return false;
  }

  public final static func CanUpgradeCyberware(owner: ref<GameObject>, itemID: ItemID, isEquipped: Bool, selectedQuality: gamedataQuality, out upgradeItemQuality: gamedataQuality, out upgradeItemRecord: ref<Item_Record>, out costData: CyberwareUpgradeCostData, opt updateOutputOnFailure: Bool) -> Bool {
    let checkQualityValue: Int32;
    let currentItemQuality: gamedataQuality;
    let itemCombinedQualityValue: Int32;
    let potentialCostData: CyberwareUpgradeCostData;
    let potentialUpgradeItemRecord: ref<Item_Record>;
    let potentialUpgradeQuality: gamedataQuality;
    let game: GameInstance = owner.GetGame();
    if !isEquipped {
      return false;
    };
    itemCombinedQualityValue = RPGManager.GetCombinedItemQualityValue(game, itemID);
    currentItemQuality = RPGManager.ConvertCombinedValueToQuality(itemCombinedQualityValue);
    if NotEquals(selectedQuality, gamedataQuality.Invalid) {
      checkQualityValue = RPGManager.ConvertQualityToCombinedValue(selectedQuality);
    } else {
      checkQualityValue = itemCombinedQualityValue + 1;
    };
    if checkQualityValue <= RPGManager.ConvertQualityToCombinedValue(IsEP1() ? gamedataQuality.LegendaryPlusPlus : gamedataQuality.LegendaryPlus) {
      potentialUpgradeQuality = RPGManager.ConvertCombinedValueToQuality(checkQualityValue);
      if RPGManager.CyberwareHasUpgrade(game, itemID, currentItemQuality, potentialUpgradeQuality, potentialUpgradeItemRecord) {
        if RPGManager.CanAffordAndPerformCyberwareUpgrade(owner, currentItemQuality, potentialUpgradeItemRecord, potentialCostData) {
          upgradeItemRecord = potentialUpgradeItemRecord;
          upgradeItemQuality = potentialUpgradeQuality;
          costData = potentialCostData;
          return true;
        };
      };
    };
    if updateOutputOnFailure {
      upgradeItemRecord = potentialUpgradeItemRecord;
      upgradeItemQuality = potentialUpgradeQuality;
      costData = potentialCostData;
    };
    return false;
  }

  public final static func CanAffordAndPerformCyberwareUpgrade(owner: ref<GameObject>, currentQuality: gamedataQuality, upgradeItemRecord: ref<Item_Record>, out costData: CyberwareUpgradeCostData) -> Bool {
    let currentItemPlusValue: Int32;
    let currentNonPlusQuality: gamedataQuality;
    let upgradeIsValid: Bool;
    let newQuality: gamedataQuality = upgradeItemRecord.QualityHandle().Type();
    let upgradeItemPlusValue: Int32 = RPGManager.ConvertQualityToItemPlusValue(newQuality);
    let upgradeNonPlusQuality: gamedataQuality = RPGManager.ConvertQualityToNonPlusQuality(newQuality);
    if upgradeItemPlusValue > 0 {
      currentItemPlusValue = RPGManager.ConvertQualityToItemPlusValue(currentQuality);
      currentNonPlusQuality = RPGManager.ConvertQualityToNonPlusQuality(currentQuality);
      if Equals(currentNonPlusQuality, upgradeNonPlusQuality) && upgradeItemPlusValue - currentItemPlusValue == 1 {
        upgradeIsValid = true;
      };
    } else {
      upgradeIsValid = true;
    };
    if upgradeIsValid {
      costData.materialRecordID = RPGManager.GetCraftingMaterialRecord(upgradeNonPlusQuality).GetID();
      costData.materialCount = RPGManager.GetCyberwareUpgradeCost(upgradeItemRecord);
      if GameInstance.GetTransactionSystem(owner.GetGame()).GetItemQuantityWithDuplicates(owner, ItemID.CreateQuery(costData.materialRecordID)) >= costData.materialCount {
        return true;
      };
    };
    return false;
  }

  public final static func GetCyberwareUpgradeCost(itemRecord: ref<Item_Record>) -> Int32 {
    let baseCost: Float;
    let quality: gamedataQuality = itemRecord.QualityHandle().Type();
    let coreCW: Bool = itemRecord.IsCoreCW();
    switch quality {
      case gamedataQuality.CommonPlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.commonPlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.commonPlus");
        };
        break;
      case gamedataQuality.Uncommon:
        baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.uncommon");
        break;
      case gamedataQuality.UncommonPlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.uncommonPlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.uncommonPlus");
        };
        break;
      case gamedataQuality.Rare:
        baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.rare");
        break;
      case gamedataQuality.RarePlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.rarePlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.rarePlus");
        };
        break;
      case gamedataQuality.Epic:
        baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.epic");
        break;
      case gamedataQuality.EpicPlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.epicPlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.epicPlus");
        };
        break;
      case gamedataQuality.Legendary:
        baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.legendary");
        break;
      case gamedataQuality.LegendaryPlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.legendaryPlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.legendaryPlus");
        };
        break;
      case gamedataQuality.LegendaryPlusPlus:
        if coreCW {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.legendaryPlusPlus_CoreCW");
        } else {
          baseCost = TDB.GetFloat(t"Items.CyberwareBaseUpgradeCosts.legendaryPlusPlus");
        };
        break;
      default:
        return 0;
    };
    return Cast<Int32>(itemRecord.UpgradeCostMult() * baseCost);
  }

  public final static func GetCyberwareUpgradeShardCount(owner: ref<GameObject>, quality: gamedataQuality) -> Int32 {
    return GameInstance.GetTransactionSystem(owner.GetGame()).GetItemQuantityWithDuplicates(owner, ItemID.CreateQuery(RPGManager.GetCyberwareUpgradeShardID(quality)));
  }

  public final static func GetCyberwareUpgradeShardItemData(owner: ref<GameObject>, quality: gamedataQuality) -> wref<gameItemData> {
    return GameInstance.GetTransactionSystem(owner.GetGame()).GetItemDataByTDBID(owner, RPGManager.GetCyberwareUpgradeShardID(quality));
  }

  public final static func GetCyberwareUpgradeShardID(quality: gamedataQuality) -> TweakDBID {
    let requiredShardID: TweakDBID;
    switch quality {
      case gamedataQuality.Uncommon:
        requiredShardID = t"Items.CyberwareUpgradeShardUncommon";
        break;
      case gamedataQuality.Rare:
        requiredShardID = t"Items.CyberwareUpgradeShardRare";
        break;
      case gamedataQuality.Epic:
        requiredShardID = t"Items.CyberwareUpgradeShardEpic";
        break;
      case gamedataQuality.Legendary:
        requiredShardID = t"Items.CyberwareUpgradeShardLegendary";
        break;
      default:
        requiredShardID = t"Items.CyberwareUpgradeShard";
    };
    return requiredShardID;
  }

  public final static func ShouldShowCWChoice(owner: ref<GameObject>, itemData: wref<UIInventoryItem>) -> Bool {
    let playerDevelopmentData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(owner);
    return playerDevelopmentData.IsNewPerkBoughtAnyLevel(gamedataNewPerkType.Tech_Inbetween_Right_2) && NotEquals(itemData.GetEquipmentArea(), gamedataEquipmentArea.SystemReplacementCW);
  }

  private final static func GetCyberwareUpgradeItemDataWithOffset(owner: ref<GameObject>, upgradeItemRecord: ref<Item_Record>, statsShardTDBID: TweakDBID, seed: Uint32, offset: Int32) -> ref<gameItemData> {
    let newItemModParams: ItemModParams;
    let optionId: ItemID = ItemID.FromTDBID(upgradeItemRecord.GetID());
    newItemModParams.itemID = optionId;
    let statsShardItemID: ItemID = ItemID.CreateFromSeedWithOffset(statsShardTDBID, seed, offset);
    ArrayPush(newItemModParams.customPartsToInstall, statsShardItemID);
    return Inventory.CreateItemData(newItemModParams, owner);
  }

  public final static func GetCyberwareUpgradeData(owner: ref<GameObject>, itemData: wref<UIInventoryItem>, upgradeItemRecord: ref<Item_Record>, costData: CyberwareUpgradeCostData, seed: Uint32, inventorySystem: wref<UIInventoryScriptableSystem>, useMultichoice: Bool) -> ref<RipperdocTokenPopupData> {
    let existingStatsShard: InnerItemData;
    let newItemModParams: ItemModParams;
    let sideItemModParams: ItemModParams;
    let statsShardItemID: ItemID;
    let statsShardSlotTDBID: TweakDBID;
    let statsShardTDBID: TweakDBID;
    let useSideItem: Bool;
    let data: ref<RipperdocTokenPopupData> = new RipperdocTokenPopupData();
    data.notificationName = n"base\\gameplay\\gui\\widgets\\notifications\\ripperdoc_token_popup.inkwidget";
    data.isBlocking = true;
    data.useCursor = true;
    data.costData = costData;
    data.queueName = n"modal_popup";
    let upgradeQualityValue: Int32 = upgradeItemRecord.QualityHandle().Value();
    if upgradeQualityValue >= 8 {
      statsShardTDBID = t"Items.CyberwareStatsShardLegendary";
    } else {
      if upgradeQualityValue >= 6 {
        statsShardTDBID = t"Items.CyberwareStatsShardEpic";
      } else {
        if upgradeQualityValue >= 4 {
          statsShardTDBID = t"Items.CyberwareStatsShardRare";
        } else {
          if upgradeQualityValue >= 2 {
            statsShardTDBID = t"Items.CyberwareStatsShardUncommon";
          } else {
            statsShardTDBID = t"Items.CyberwareStatsShardCommon";
          };
        };
      };
    };
    statsShardSlotTDBID = t"AttachmentSlots.StatsShardSlot";
    newItemModParams.itemID = ItemID.FromTDBID(upgradeItemRecord.GetID());
    newItemModParams.quantity = 1;
    if itemData.GetItemData().HasPartInSlot(statsShardSlotTDBID) {
      itemData.GetItemData().GetItemPart(existingStatsShard, statsShardSlotTDBID);
      statsShardItemID = ItemID.DuplicateRandomSeedWithOffset(InnerItemData.GetItemID(existingStatsShard), InnerItemData.GetStaticData(existingStatsShard).GetRecordID(), 0);
      ArrayPush(newItemModParams.customPartsToInstall, statsShardItemID);
    };
    useSideItem = PlayerDevelopmentSystem.GetData(GetPlayer(owner.GetGame())).IsNewPerkBought(gamedataNewPerkType.Tech_Central_Milestone_3) >= 3;
    useSideItem = useSideItem && Equals(upgradeItemRecord.EquipAreaHandle().Type(), gamedataEquipmentArea.MusculoskeletalSystemCW);
    if useSideItem {
      sideItemModParams.itemID = ItemID.FromTDBID(upgradeItemRecord.SideUpgradeItemHandle().GetID());
      ArrayPush(sideItemModParams.customPartsToInstall, statsShardItemID);
      sideItemModParams.quantity = 1;
      data.option1SideItemData = Inventory.CreateItemData(sideItemModParams, owner);
      data.option2SideItemData = RPGManager.GetCyberwareUpgradeItemDataWithOffset(owner, upgradeItemRecord.SideUpgradeItemHandle(), statsShardTDBID, seed, 1);
      data.option3SideItemData = RPGManager.GetCyberwareUpgradeItemDataWithOffset(owner, upgradeItemRecord.SideUpgradeItemHandle(), statsShardTDBID, seed, 2);
    };
    data.option1GameItemData = Inventory.CreateItemData(newItemModParams, owner);
    data.option1InventoryItem = UIInventoryItem.Make(owner, useSideItem ? data.option1SideItemData : data.option1GameItemData, inventorySystem.GetInventoryItemsManager());
    if useMultichoice {
      data.option2GameItemData = RPGManager.GetCyberwareUpgradeItemDataWithOffset(owner, upgradeItemRecord, statsShardTDBID, seed, 1);
      data.option2InventoryItem = UIInventoryItem.Make(owner, useSideItem ? data.option2SideItemData : data.option2GameItemData, inventorySystem.GetInventoryItemsManager());
      if upgradeQualityValue >= 4 {
        data.option3GameItemData = RPGManager.GetCyberwareUpgradeItemDataWithOffset(owner, upgradeItemRecord, statsShardTDBID, seed, 2);
        data.option3InventoryItem = UIInventoryItem.Make(owner, useSideItem ? data.option3SideItemData : data.option3GameItemData, inventorySystem.GetInventoryItemsManager());
      };
    };
    data.baseItemData = itemData;
    return data;
  }

  public final static func CreateReplaceEquipmentRequest(owner: ref<GameObject>, equippedItemID: ItemID, upgradeItemID: ItemID, opt partItemID: ItemID) -> Void {
    let equipmentSystem: ref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(owner.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;
    let replaceEquipmentRequest: ref<ReplaceEquipmentRequest> = new ReplaceEquipmentRequest();
    replaceEquipmentRequest.owner = owner;
    replaceEquipmentRequest.slotIndex = equipmentSystem.GetItemSlotIndex(owner, equippedItemID);
    replaceEquipmentRequest.itemID = upgradeItemID;
    replaceEquipmentRequest.addToInventory = true;
    replaceEquipmentRequest.rerollIdOnAddToInventory = false;
    replaceEquipmentRequest.removeOldItem = true;
    replaceEquipmentRequest.customPartToGenerateID = partItemID;
    replaceEquipmentRequest.transferInstalledParts = true;
    equipmentSystem.QueueRequest(replaceEquipmentRequest);
  }

  public final static func HandleBuyShardPopupClosed(owner: ref<GameObject>, equippedItemId: ItemID, resultData: ref<RipperdocTokenPopupCloseData>) -> Void {
    let statsShardData: InnerItemData;
    let statsShardItemID: ItemID;
    let statsShardSlotTDBID: TweakDBID;
    if resultData.confirm {
      statsShardSlotTDBID = t"AttachmentSlots.StatsShardSlot";
      if resultData.chosenOptionData.HasPartInSlot(statsShardSlotTDBID) {
        resultData.chosenOptionData.GetItemPart(statsShardData, statsShardSlotTDBID);
        statsShardItemID = InnerItemData.GetItemID(statsShardData);
      };
      RPGManager.CreateReplaceEquipmentRequest(owner, equippedItemId, resultData.chosenOptionData.GetID(), statsShardItemID);
      GameInstance.GetTransactionSystem(owner.GetGame()).RemoveItemByTDBID(owner, resultData.costData.materialRecordID, resultData.costData.materialCount);
      GameInstance.GetInventoryManager(owner.GetGame()).IncrementCyberwareUpgradeSeed(3u);
    };
  }

  public final static func IsItemEffectivelyIdentical(itemID1: ItemID, itemID2: ItemID) -> Bool {
    if ItemID.GetTDBID(itemID1) == ItemID.GetTDBID(itemID2) && ItemID.GetRngSeed(itemID1) == ItemID.GetRngSeed(itemID2) {
      return true;
    };
    return false;
  }

  public final static func HealPuppetAfterQuickhack(gi: GameInstance, executor: ref<GameObject>) -> Void {
    let statSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
    if statSystem.GetStatBoolValue(Cast<StatsObjectID>((executor as ScriptedPuppet).GetEntityID()), gamedataStatType.CanQuickhackHealPuppet) {
      GameInstance.GetStatusEffectSystem(gi).ApplyStatusEffect((executor as ScriptedPuppet).GetEntityID(), t"BaseStatusEffect.QuickhackConsumableHealing");
    };
  }

  public final static func ForceEquipStrongArms(player: ref<PlayerPuppet>, instantStatChange: Bool) -> Bool {
    let TS: ref<TransactionSystem>;
    let armsCW: ItemID;
    let itemData: ref<gameItemData>;
    let record: ref<WeaponItem_Record>;
    if !IsDefined(player) {
      return false;
    };
    TS = GameInstance.GetTransactionSystem(player.GetGame());
    armsCW = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.ArmsCW);
    if !IsDefined(TS) || !ItemID.IsValid(armsCW) {
      return false;
    };
    record = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(armsCW));
    if IsDefined(record) && Equals(record.ItemType().Type(), gamedataItemType.Cyb_StrongArms) {
      if TS.IsSlotEmpty(player, t"AttachmentSlots.WeaponRight") && !TS.IsSlotEmpty(player, t"AttachmentSlots.RightArm") {
        if instantStatChange {
          EquipmentSystemPlayerData.UpdateArmSlot(player, armsCW, false);
          itemData = RPGManager.GetItemData(player.GetGame(), player, armsCW);
          itemData.AddStatsOnEquip(player);
        };
        TS.AddItemToSlot(player, t"AttachmentSlots.RightArm", armsCW);
        return true;
      };
    };
    return false;
  }

  public final static func ForceUnequipStrongArms(player: ref<PlayerPuppet>) -> Bool {
    let TS: ref<TransactionSystem>;
    let armsCW: ItemID;
    let record: ref<WeaponItem_Record>;
    if !IsDefined(player) {
      return false;
    };
    TS = GameInstance.GetTransactionSystem(player.GetGame());
    armsCW = EquipmentSystem.GetData(player).GetActiveItem(gamedataEquipmentArea.ArmsCW);
    if !IsDefined(TS) || !ItemID.IsValid(armsCW) {
      return false;
    };
    record = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(armsCW));
    if IsDefined(record) && Equals(record.ItemType().Type(), gamedataItemType.Cyb_StrongArms) {
      EquipmentSystemPlayerData.UpdateArmSlot(player, armsCW, true);
      return true;
    };
    return false;
  }

  public final static func ForceEquipPersonalLink(player: ref<PlayerPuppet>) -> Bool {
    let TS: ref<TransactionSystem>;
    let itemID: ItemID;
    let playerPuppet: wref<PlayerPuppet>;
    let playerStateMachineBlackboard: ref<IBlackboard>;
    if !IsDefined(player) {
      return false;
    };
    TS = GameInstance.GetTransactionSystem(player.GetGame());
    itemID = ItemID.CreateQuery(t"Items.personal_link");
    if !IsDefined(TS) || !ItemID.IsValid(itemID) {
      return false;
    };
    if !TS.HasItem(player, itemID) {
      TS.GiveItem(player, itemID, 1);
    };
    TS.RemoveItemFromSlot(player, t"AttachmentSlots.PersonalLink");
    TS.AddItemToSlot(player, t"AttachmentSlots.PersonalLink", itemID);
    playerPuppet = GameInstance.GetPlayerSystem(player.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    playerStateMachineBlackboard = GameInstance.GetBlackboardSystem(player.GetGame()).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    playerStateMachineBlackboard.SetBool(GetAllBlackboardDefs().PlayerStateMachine.IsInteractingViaPersonalLink, true);
    return true;
  }

  public final static func ForceUnequipPersonalLink(player: ref<PlayerPuppet>) -> Bool {
    let TS: ref<TransactionSystem>;
    let playerPuppet: wref<PlayerPuppet>;
    let playerStateMachineBlackboard: ref<IBlackboard>;
    if !IsDefined(player) {
      return false;
    };
    TS = GameInstance.GetTransactionSystem(player.GetGame());
    if !IsDefined(TS) {
      return false;
    };
    TS.RemoveItemFromSlot(player, t"AttachmentSlots.PersonalLink");
    playerPuppet = GameInstance.GetPlayerSystem(player.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    playerStateMachineBlackboard = GameInstance.GetBlackboardSystem(player.GetGame()).GetLocalInstanced(playerPuppet.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
    playerStateMachineBlackboard.SetBool(GetAllBlackboardDefs().PlayerStateMachine.IsInteractingViaPersonalLink, false);
    return true;
  }
}

public abstract class MathHelper extends IScriptable {

  public final static func PositiveInfinity() -> Float {
    return 100000000.00;
  }

  public final static func NegativeInfinity() -> Float {
    return -100000000.00;
  }

  public final static func EulerNumber() -> Float {
    return 2.72;
  }

  public final static func IsFloatInRange(value: Float, min: Float, max: Float, opt leftClosed: Bool, opt rightClosed: Bool) -> Bool {
    if leftClosed && rightClosed {
      return value >= min && value <= max;
    };
    if leftClosed && !rightClosed {
      return value >= min && value < max;
    };
    if !leftClosed && rightClosed {
      return value > min && value <= max;
    };
    return value > min && value < max;
  }

  public final static func NormalizeF(value: Float, min: Float, max: Float) -> Float {
    let numerator: Float = value - min;
    let denominator: Float = max - min;
    return numerator / denominator;
  }

  public final static func RandFromNormalDist(opt mean: Float, opt stdDev: Float) -> Float {
    let output: Float;
    let randStandardNormal: Float;
    let uniform1: Float;
    let uniform2: Float;
    if stdDev == 0.00 {
      stdDev = 1.00;
    };
    uniform1 = RandF();
    uniform2 = RandF();
    randStandardNormal = SqrtF(-2.00 * LogF(uniform1)) * CosF(6.28 * uniform2);
    output = randStandardNormal * stdDev + mean;
    return output;
  }
}

public class StatusEffectTriggerListener extends CustomValueStatPoolsListener {

  public let m_owner: wref<GameObject>;

  public let m_statusEffect: TweakDBID;

  public let m_statPoolType: gamedataStatPoolType;

  public let m_instigator: wref<GameObject>;

  protected cb func OnStatPoolMinValueReached(value: Float) -> Bool {
    let gameInstance: GameInstance;
    let puppet: ref<ScriptedPuppet> = this.m_owner as ScriptedPuppet;
    if IsDefined(puppet) {
      gameInstance = puppet.GetGame();
      GameInstance.GetStatusEffectSystem(gameInstance).ApplyStatusEffect(puppet.GetEntityID(), this.m_statusEffect, GameObject.GetTDBID(this.m_instigator), this.m_instigator.GetEntityID());
      GameInstance.GetStatPoolsSystem(gameInstance).RequestRemovingStatPool(Cast<StatsObjectID>(puppet.GetEntityID()), this.m_statPoolType);
      GameObject.RemoveStatusEffectTriggerListener(puppet, this);
    };
  }
}

public class PhoneCallUploadDurationListener extends CustomValueStatPoolsListener {

  public let m_gameInstance: GameInstance;

  public let m_requesterPuppet: wref<ScriptedPuppet>;

  public let m_requesterID: EntityID;

  public let m_duration: Float;

  @default(PhoneCallUploadDurationListener, gamedataStatPoolType.PhoneCallDuration)
  public let m_statPoolType: gamedataStatPoolType;

  protected cb func OnStatPoolAdded() -> Bool {
    this.SendUploadStartedEvent();
    this.SetRegenBehavior();
  }

  protected func SetRegenBehavior() -> Void {
    let regenMod: StatPoolModifier;
    let activationTime: Float = this.m_duration;
    regenMod.enabled = true;
    regenMod.valuePerSec = 100.00 / activationTime;
    regenMod.rangeEnd = 100.00;
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestSettingModifier(Cast<StatsObjectID>(this.m_requesterID), this.m_statPoolType, gameStatPoolModificationTypes.Regeneration, regenMod);
  }

  protected cb func OnStatPoolRemoved() -> Bool {
    this.SendUploadFinishedEvent();
    this.UnregisterListener();
  }

  protected cb func OnStatPoolMaxValueReached(value: Float) -> Bool {
    if Equals(this.m_statPoolType, gamedataStatPoolType.CallReinforcementProgress) {
      this.m_requesterPuppet.GetPuppetStateBlackboard().SetBool(GetAllBlackboardDefs().PuppetState.HasCalledReinforcements, true);
    };
    this.SendUploadFinishedEvent();
    this.UnregisterListener();
  }

  private final func UnregisterListener() -> Void {
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestUnregisteringListener(Cast<StatsObjectID>(this.m_requesterID), this.m_statPoolType, this);
  }

  private final func SendUploadStartedEvent() -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    evt.state = EUploadProgramState.STARTED;
    evt.duration = this.m_duration;
    evt.progressBarType = EProgressBarType.UPLOAD;
    evt.progressBarContext = EProgressBarContext.PhoneCall;
    evt.iconRecord = TweakDBInterface.GetChoiceCaptionIconPartRecord(t"ChoiceCaptionParts.PhoneCall");
    evt.statPoolType = this.m_statPoolType;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_requesterID, evt);
  }

  protected final func SendUploadFinishedEvent() -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    evt.state = EUploadProgramState.COMPLETED;
    evt.progressBarContext = EProgressBarContext.PhoneCall;
    evt.statPoolType = this.m_statPoolType;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_requesterID, evt);
  }
}

public class QuickHackDurationListener extends ActionUploadListener {

  protected cb func OnStatPoolAdded() -> Bool {
    this.SendUploadStartedEvent(this.m_action);
    this.SetRegenBehavior();
  }

  protected func SetRegenBehavior() -> Void {
    let regenMod: StatPoolModifier;
    let activationTime: Float = this.m_action.GetDurationValue();
    regenMod.enabled = true;
    regenMod.valuePerSec = 100.00 / activationTime;
    regenMod.rangeEnd = 100.00;
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestSettingModifier(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackDuration, gameStatPoolModificationTypes.Regeneration, regenMod);
  }

  protected cb func OnStatPoolMaxValueReached(value: Float) -> Bool {
    this.m_action.CompleteAction(this.m_gameInstance);
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestRemovingStatPool(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackDuration);
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestUnregisteringListener(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackDuration, this);
    this.SendUploadFinishedEvent();
  }

  protected func SendUploadStartedEvent(action: ref<ScriptableDeviceAction>) -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    let uploadDuration: Float = this.m_action.GetDurationValue();
    evt.state = EUploadProgramState.STARTED;
    evt.duration = uploadDuration;
    evt.progressBarType = EProgressBarType.DURATION;
    evt.action = action;
    evt.iconRecord = action.GetInteractionIcon();
    evt.statPoolType = gamedataStatPoolType.QuickHackDuration;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), evt);
  }

  protected final func SendUploadFinishedEvent() -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    evt.state = EUploadProgramState.COMPLETED;
    evt.action = this.m_action;
    evt.statPoolType = gamedataStatPoolType.QuickHackDuration;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), evt);
  }
}

public class QuickHackUploadListener extends ActionUploadListener {

  public func Initialize() -> Void;

  protected cb func OnStatPoolAdded() -> Bool {
    let psmBB: ref<IBlackboard>;
    let enableQHSoundActivation: Bool = true;
    if this.m_action.IsQuickHack() {
      this.SendUploadStartedEvent(this.m_action);
      psmBB = GameInstance.GetBlackboardSystem(this.m_gameInstance).GetLocalInstanced(this.m_action.GetExecutor().GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
      if IsDefined(psmBB) {
        enableQHSoundActivation = psmBB.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision) == 1;
      };
      if enableQHSoundActivation {
        this.PlayQuickHackSound(n"ui_focus_mode_scanning_qh");
      };
    };
    this.SetRegenBehavior();
  }

  protected func SetRegenBehavior() -> Void {
    let regenMod: StatPoolModifier;
    let activationTime: Float = this.m_action.GetActivationTime();
    regenMod.enabled = true;
    regenMod.valuePerSec = 100.00 / activationTime;
    regenMod.rangeEnd = 100.00;
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestSettingModifier(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload, gameStatPoolModificationTypes.Regeneration, regenMod);
  }

  protected cb func OnStatPoolMaxValueReached(value: Float) -> Bool {
    this.m_action.CompleteAction(this.m_gameInstance);
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestRemovingStatPool(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload);
    GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestUnregisteringListener(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload, this);
    if this.m_action.IsQuickHack() {
      this.SendUploadFinishedEvent();
    };
  }

  protected func SendUploadStartedEvent(action: ref<ScriptableDeviceAction>) -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    let uploadDuration: Float = this.m_action.GetActivationTime();
    evt.state = EUploadProgramState.STARTED;
    evt.duration = uploadDuration;
    evt.progressBarType = EProgressBarType.UPLOAD;
    evt.action = action;
    evt.iconRecord = action.GetInteractionIcon();
    evt.statPoolType = gamedataStatPoolType.QuickHackUpload;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), evt);
    QuickhackModule.RequestRefreshQuickhackMenu(this.m_gameInstance, this.m_action.GetRequesterID());
  }

  protected final func SendUploadFinishedEvent() -> Void {
    let evt: ref<UploadProgramProgressEvent> = new UploadProgramProgressEvent();
    evt.state = EUploadProgramState.COMPLETED;
    evt.action = this.m_action;
    if this.m_action.m_isActionQueueingUsed {
      evt.deviceActionQueue = this.m_action.m_deviceActionQueue;
    };
    evt.statPoolType = gamedataStatPoolType.QuickHackUpload;
    GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), evt);
    this.PlayQuickHackSound(n"ui_focus_mode_scanning_qh_done");
    if this.m_action.GetExecutor().IsPlayer() {
      RPGManager.DecrementQuickHackBlackboard(this.m_gameInstance, this.m_action.GetObjectActionID());
    };
  }

  protected final func PlayQuickHackSound(eventName: CName) -> Void {
    let flag: audioAudioEventFlags = audioAudioEventFlags.Unique;
    GameObject.PlaySoundEventWithParams(this.m_action.GetExecutor(), eventName, flag);
  }

  protected final func RemoveLink(owner: wref<ScriptedPuppet>) -> Void {
    let evt: ref<RemoveLinkEvent>;
    if !IsDefined(owner) {
      return;
    };
    evt = new RemoveLinkEvent();
    owner.QueueEvent(evt);
  }

  protected final func RemoveLinkedStatusEffects(owner: wref<ScriptedPuppet>, opt ssAction: Bool) -> Void {
    let evt: ref<RemoveLinkedStatusEffectsEvent>;
    if !IsDefined(owner) {
      return;
    };
    evt = new RemoveLinkedStatusEffectsEvent();
    evt.ssAction = ssAction;
    owner.QueueEvent(evt);
  }
}

public class UploadFromNPCToNPCListener extends QuickHackUploadListener {

  public let m_npcPuppet: wref<ScriptedPuppet>;

  public func OnStatPoolValueChanged(oldValue: Float, newValue: Float, percToPoints: Float) -> Void {
    let uploadEvent: ref<UploadProgramProgressEvent>;
    if !ScriptedPuppet.IsActive(this.m_npcPuppet) {
      this.RemoveLinkedStatusEffects(this.m_npcPuppet);
      GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestRemovingStatPool(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload);
      GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestUnregisteringListener(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload, this);
      uploadEvent = new UploadProgramProgressEvent();
      uploadEvent.state = EUploadProgramState.COMPLETED;
      GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), uploadEvent);
    };
  }
}

public class UploadFromNPCToPlayerListener extends QuickHackUploadListener {

  public let m_playerPuppet: wref<ScriptedPuppet>;

  public let m_npcPuppet: wref<ScriptedPuppet>;

  public let m_npcSquad: [EntityID];

  public let m_HUDData: HUDProgressBarData;

  public let m_hudBlackboard: wref<IBlackboard>;

  private let m_startUploadTimeStamp: Float;

  private let m_ssAction: Bool;

  private let m_preventionHackLoopAction: Bool;

  private let m_shouldStopRevealOnPreventionDeescalation: Bool;

  private let m_squadScriptInterface: ref<SquadScriptInterface>;

  private let m_useInterruptionPrereqs: Bool;

  public func Initialize() -> Void {
    let tbid: TweakDBID = this.m_action.GetObjectActionID();
    let isPositionReveal: Bool = tbid == t"AIQuickHack.HackRevealPosition";
    let isPreventionPositionReveal: Bool = this.m_action.GetObjectActionID() == t"AIQuickHack.PreventionHackRevealPosition";
    this.m_useInterruptionPrereqs = this.m_action.GetObjectActionRecord().GetInterruptionPrereqsCount() > 0;
    this.m_hudBlackboard = GameInstance.GetBlackboardSystem(this.m_gameInstance).Get(GetAllBlackboardDefs().UI_HUDProgressBar);
    if isPositionReveal || isPreventionPositionReveal {
      this.m_ssAction = true;
      this.m_shouldStopRevealOnPreventionDeescalation = isPreventionPositionReveal;
      AISquadHelper.GetSquadmatesID(this.m_npcPuppet, this.m_npcSquad);
      AISquadHelper.GetSquadMemberInterface(this.m_npcPuppet, this.m_squadScriptInterface);
    } else {
      if this.m_action.GetObjectActionID() == t"AIQuickHack.PreventionSystemHackerLoop" || this.m_action.GetObjectActionID() == t"AIQuickHack.PreventionSystemHackerLoop2" || this.m_action.GetObjectActionID() == t"AIQuickHack.PreventionSystemHackerLoop3" {
        this.m_preventionHackLoopAction = true;
      };
    };
  }

  protected cb func OnStatPoolAdded() -> Bool {
    this.SendUploadStartedEvent(this.m_action);
    SaveLocksManager.RequestSaveLockAdd(this.m_playerPuppet.GetGame(), n"PlayerBeingHacked");
  }

  protected func SendUploadStartedEvent(action: ref<ScriptableDeviceAction>) -> Void {
    let isQuickhackPanelOpen: Bool;
    this.m_HUDData.active = true;
    this.m_HUDData.header = LocKeyToString(action.GetObjectActionRecord().ObjectActionUI().Caption());
    if this.m_preventionHackLoopAction {
      this.m_HUDData.bottomText = "LocKey#22169";
      this.m_HUDData.failedText = "LocKey#92701";
      this.m_HUDData.completedText = "LocKey#92701";
      this.m_HUDData.type = SimpleMessageType.Vehicle;
    };
    this.m_startUploadTimeStamp = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_npcPuppet.GetGame()));
    this.m_hudBlackboard.SetBool(GetAllBlackboardDefs().UI_HUDProgressBar.Active, this.m_HUDData.active);
    this.m_hudBlackboard.SetString(GetAllBlackboardDefs().UI_HUDProgressBar.Header, this.m_HUDData.header);
    this.m_hudBlackboard.SetString(GetAllBlackboardDefs().UI_HUDProgressBar.BottomText, this.m_HUDData.bottomText, true);
    this.m_hudBlackboard.SetString(GetAllBlackboardDefs().UI_HUDProgressBar.FailedText, this.m_HUDData.failedText, true);
    this.m_hudBlackboard.SetString(GetAllBlackboardDefs().UI_HUDProgressBar.CompletedText, this.m_HUDData.completedText, true);
    this.m_hudBlackboard.SetVariant(GetAllBlackboardDefs().UI_HUDProgressBar.MessageType, ToVariant(this.m_HUDData.type), true);
    isQuickhackPanelOpen = GameInstance.GetBlackboardSystem(this.m_gameInstance).Get(GetAllBlackboardDefs().UI_QuickSlotsData).GetBool(GetAllBlackboardDefs().UI_QuickSlotsData.quickhackPanelOpen);
    if isQuickhackPanelOpen {
      GameInstance.GetDelaySystem(this.m_gameInstance).DelayEventNextFrame(this.m_playerPuppet, new RefreshQuickhackMenuEvent());
    };
  }

  public final func ForceClose() -> Void {
    this.OnStatPoolMaxValueReached(100.00);
  }

  private final func TryStartCombat(player: wref<ScriptedPuppet>, npc: wref<ScriptedPuppet>, targetTracker: wref<TargetTrackingExtension>) -> Void {
    if AIActionHelper.TryChangingAttitudeToHostile(npc, player) {
      targetTracker.AddThreat(player, true, player.GetWorldPosition(), 1.00, -1.00, false);
      this.m_npcPuppet.TriggerSecuritySystemNotification(player.GetWorldPosition(), player, ESecurityNotificationType.COMBAT);
    };
  }

  protected cb func OnStatPoolMaxValueReached(value: Float) -> Bool {
    let actionEffects: array<wref<ObjectActionEffect_Record>>;
    let i: Int32;
    let targetTracker: wref<TargetTrackingExtension>;
    if this.m_preventionHackLoopAction && PreventionSystemHackerLoop.KeepProgressBarAliveAfterCompletion(this.m_gameInstance) {
      return false;
    };
    PreventionSystemHackerLoop.UpdateOtherProgressBarReference(this.m_gameInstance, null);
    super.OnStatPoolMaxValueReached(value);
    this.RemoveLink(this.m_npcPuppet);
    ScriptedPuppet.SendActionSignal(this.m_npcPuppet, n"HackingCompleted", 1.00);
    this.m_HUDData.active = false;
    this.m_hudBlackboard.SetBool(GetAllBlackboardDefs().UI_HUDProgressBar.Active, this.m_HUDData.active);
    this.m_action.GetObjectActionRecord().CompletionEffects(actionEffects);
    this.m_npcPuppet.AddLinkedStatusEffect(this.m_npcPuppet.GetEntityID(), this.m_playerPuppet.GetEntityID(), actionEffects);
    this.m_playerPuppet.AddLinkedStatusEffect(this.m_npcPuppet.GetEntityID(), this.m_playerPuppet.GetEntityID(), actionEffects);
    SaveLocksManager.RequestSaveLockRemove(this.m_playerPuppet.GetGame(), n"PlayerBeingHacked");
    StatusEffectHelper.RemoveStatusEffect(this.m_playerPuppet, t"AIQuickHackStatusEffect.BeingHacked");
    if this.m_ssAction {
      this.m_playerPuppet.RemoveLinkedStatusEffects(true);
      if !TargetTrackingExtension.Get(GameInstance.FindEntityByID(this.m_playerPuppet.GetGame(), this.m_npcSquad[0]) as ScriptedPuppet, targetTracker) {
        if !TargetTrackingExtension.Get(this.m_npcPuppet, targetTracker) {
          return false;
        };
      };
      this.TryStartCombat(this.m_playerPuppet, this.m_npcPuppet, targetTracker);
      i = 0;
      while i < ArraySize(this.m_npcSquad) {
        this.TryStartCombat(this.m_playerPuppet, GameInstance.FindEntityByID(this.m_playerPuppet.GetGame(), this.m_npcSquad[i]) as ScriptedPuppet, targetTracker);
        i += 1;
      };
    };
  }

  private final func IsSquadAlive() -> Bool {
    let i: Int32;
    let squadmate: wref<ScriptedPuppet>;
    let squadmates: array<wref<Entity>>;
    if !IsDefined(this.m_squadScriptInterface) {
      return false;
    };
    squadmates = this.m_squadScriptInterface.ListMembersWeak();
    i = 0;
    while i < ArraySize(squadmates) {
      squadmate = squadmates[i] as ScriptedPuppet;
      if ScriptedPuppet.IsActive(squadmate) {
        return true;
      };
      i += 1;
    };
    return false;
  }

  private final func StopHackBasedOnTier(currentTier: Int32) -> Bool {
    let allowedInTier2: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_playerPuppet, n"AllowTracingInTier2");
    let allowedInTier3: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_playerPuppet, n"AllowTracingInTier3");
    let allowedInTier4: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_playerPuppet, n"AllowTracingInTier4");
    let allowedInTier5: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_playerPuppet, n"AllowTracingInTier5");
    if currentTier == 2 {
      return !allowedInTier2;
    };
    if currentTier == 3 {
      return !allowedInTier3;
    };
    if currentTier == 4 {
      return !allowedInTier4;
    };
    if currentTier == 5 {
      return !allowedInTier5;
    };
    if currentTier == 6 {
      return true;
    };
    return false;
  }

  public func OnStatPoolValueChanged(oldValue: Float, newValue: Float, percToPoints: Float) -> Void {
    let evt: ref<UploadProgramProgressEvent>;
    let hackingMinigameBB: ref<IBlackboard>;
    let immune: Bool;
    let maxRevealDistance: Float;
    let psmBB: ref<IBlackboard>;
    let sceneTier: Int32;
    let stopHack: Bool;
    let playerDetected: Bool = false;
    let playerIsInCombat: Bool = (this.m_playerPuppet as PlayerPuppet).IsInCombat();
    let statSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_gameInstance);
    let preventionSystem: ref<PreventionSystem> = GameInstance.GetScriptableSystemsContainer(this.m_gameInstance).Get(n"PreventionSystem") as PreventionSystem;
    let quickhackShieldValue: Float = GameInstance.GetStatsSystem(this.m_playerPuppet.GetGame()).GetStatValue(Cast<StatsObjectID>(this.m_playerPuppet.GetEntityID()), gamedataStatType.QuickhackShield);
    if this.m_preventionHackLoopAction {
      if PreventionSystemHackerLoop.ShouldForceUpdateProgressBar(this.m_gameInstance) {
        newValue += PreventionSystemHackerLoop.GetProgressBarForcedValue(this.m_gameInstance);
        if newValue > 99.99 {
          newValue = 100.00;
        };
      };
      PreventionSystemHackerLoop.UpdateOtherProgressBarReference(this.m_gameInstance, null);
      PreventionSystemHackerLoop.UpdateHackLoopProgressBarValue(this.m_gameInstance, newValue, this);
    } else {
      PreventionSystemHackerLoop.UpdateOtherProgressBarReference(this.m_gameInstance, this);
    };
    this.m_HUDData.progress = newValue / 100.00;
    this.m_hudBlackboard.SetFloat(GetAllBlackboardDefs().UI_HUDProgressBar.Progress, this.m_HUDData.progress);
    if !this.m_ssAction && newValue > 15.00 && quickhackShieldValue > 0.00 && !StatusEffectSystem.ObjectHasStatusEffect(this.m_playerPuppet, t"BaseStatusEffect.AntiVirusCooldown") {
      StatusEffectHelper.ApplyStatusEffect(this.m_playerPuppet, t"BaseStatusEffect.AntiVirusCooldown");
      immune = true;
    };
    if this.m_useInterruptionPrereqs {
      stopHack = immune || this.m_action.CanInterrupt(this.m_npcPuppet);
    } else {
      if this.m_ssAction {
        hackingMinigameBB = GameInstance.GetBlackboardSystem(this.m_playerPuppet.GetGame()).Get(GetAllBlackboardDefs().HackingMinigame);
        psmBB = (this.m_playerPuppet as PlayerPuppet).GetPlayerStateMachineBlackboard();
        maxRevealDistance = statSystem.GetStatValue(Cast<StatsObjectID>(this.m_playerPuppet.GetEntityID()), gamedataStatType.RevealPositionMaxDistance);
        sceneTier = psmBB.GetInt(GetAllBlackboardDefs().PlayerStateMachine.HighLevel);
        if !ScriptedPuppet.IsActive(this.m_playerPuppet) || playerIsInCombat || Vector4.Distance(this.m_playerPuppet.GetWorldPosition(), hackingMinigameBB.GetVector4(GetAllBlackboardDefs().HackingMinigame.LastPlayerHackPosition)) > maxRevealDistance || this.StopHackBasedOnTier(sceneTier) || !ScriptedPuppet.IsActive(this.m_npcPuppet) && !this.IsSquadAlive() || this.m_shouldStopRevealOnPreventionDeescalation && !preventionSystem.IsChasingPlayer() || GameInstance.GetStatusEffectSystem(this.m_playerPuppet.GetGame()).HasStatusEffect(this.m_playerPuppet.GetEntityID(), t"BaseStatusEffect.RevealInterrupted") {
          stopHack = true;
          playerDetected = playerIsInCombat;
        };
      } else {
        if immune || !ScriptedPuppet.IsActive(this.m_npcPuppet) || !ScriptedPuppet.IsActive(this.m_playerPuppet) || this.m_action.GetObjectActionID() != t"AIQuickHack.HackReveal" && (StatusEffectSystem.ObjectHasStatusEffect(this.m_npcPuppet, t"AIQuickHackStatusEffect.HackingInterrupted") || StatusEffectSystem.ObjectHasStatusEffect(this.m_npcPuppet, t"AIQuickHackStatusEffect.HackRevealInterrupted") || StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_npcPuppet, n"CyberwareMalfunction")) || this.m_action.GetObjectActionID() == t"AIQuickHack.HackReveal" && playerIsInCombat {
          stopHack = true;
        };
      };
    };
    if stopHack {
      PreventionSystemHackerLoop.UpdateOtherProgressBarReference(this.m_gameInstance, null);
      if this.m_preventionHackLoopAction && newValue > 99.99 {
        return;
      };
      StatusEffectHelper.RemoveStatusEffect(this.m_playerPuppet, t"BaseStatusEffect.RevealInterrupted");
      StatusEffectHelper.RemoveStatusEffect(this.m_playerPuppet, t"BaseStatusEffect.ForcedQHUploadAwarenessBumps");
      (this.m_playerPuppet as PlayerPuppet).SetIsBeingRevealed(false);
      immune = false;
      this.RemoveLink(this.m_npcPuppet);
      this.RemoveLinkedStatusEffects(this.m_npcPuppet, this.m_ssAction);
      SaveLocksManager.RequestSaveLockRemove(this.m_playerPuppet.GetGame(), n"PlayerBeingHacked");
      this.m_HUDData.failedText = playerDetected || this.m_action.GetObjectActionID() == t"AIQuickHack.HackReveal" && playerIsInCombat ? "LocKey#92985" : "LocKey#15353";
      this.m_HUDData.active = false;
      this.m_hudBlackboard.SetString(GetAllBlackboardDefs().UI_HUDProgressBar.FailedText, this.m_HUDData.failedText);
      this.m_hudBlackboard.SetBool(GetAllBlackboardDefs().UI_HUDProgressBar.Active, this.m_HUDData.active);
      GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestRemovingStatPool(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload);
      GameInstance.GetStatPoolsSystem(this.m_gameInstance).RequestUnregisteringListener(Cast<StatsObjectID>(this.m_action.GetRequesterID()), gamedataStatPoolType.QuickHackUpload, this);
      evt = new UploadProgramProgressEvent();
      evt.state = EUploadProgramState.COMPLETED;
      GameInstance.GetPersistencySystem(this.m_gameInstance).QueueEntityEvent(this.m_action.GetRequesterID(), evt);
    };
  }
}

public static func OperatorGreater(q1: gamedataQuality, q2: gamedataQuality) -> Bool {
  let result: Bool;
  if Equals(q1, gamedataQuality.Invalid) || Equals(q1, gamedataQuality.Count) || Equals(q2, gamedataQuality.Invalid) || Equals(q2, gamedataQuality.Count) {
    return false;
  };
  switch q1 {
    case gamedataQuality.Common:
      return false;
    case gamedataQuality.Uncommon:
      result = Equals(q2, gamedataQuality.Common) ? true : false;
      break;
    case gamedataQuality.Rare:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) ? true : false;
      break;
    case gamedataQuality.Epic:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) || Equals(q2, gamedataQuality.Rare) ? true : false;
      break;
    case gamedataQuality.Legendary:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) || Equals(q2, gamedataQuality.Rare) || Equals(q2, gamedataQuality.Epic) ? true : false;
      break;
    default:
      return false;
  };
  return result;
}

public static func OperatorGreaterEqual(q1: gamedataQuality, q2: gamedataQuality) -> Bool {
  let result: Bool;
  if Equals(q1, gamedataQuality.Invalid) || Equals(q1, gamedataQuality.Count) || Equals(q2, gamedataQuality.Invalid) || Equals(q2, gamedataQuality.Count) {
    return false;
  };
  switch q1 {
    case gamedataQuality.Common:
      result = Equals(q2, gamedataQuality.Common) ? true : false;
      break;
    case gamedataQuality.Uncommon:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) ? true : false;
      break;
    case gamedataQuality.Rare:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) || Equals(q2, gamedataQuality.Rare) ? true : false;
      break;
    case gamedataQuality.Epic:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) || Equals(q2, gamedataQuality.Rare) || Equals(q2, gamedataQuality.Epic) ? true : false;
      break;
    case gamedataQuality.Legendary:
      result = Equals(q2, gamedataQuality.Common) || Equals(q2, gamedataQuality.Uncommon) || Equals(q2, gamedataQuality.Rare) || Equals(q2, gamedataQuality.Epic) || Equals(q2, gamedataQuality.Legendary) ? true : false;
      break;
    default:
      return false;
  };
  return result;
}

public static func OperatorLess(q1: gamedataQuality, q2: gamedataQuality) -> Bool {
  let result: Bool;
  if Equals(q1, gamedataQuality.Invalid) || Equals(q1, gamedataQuality.Count) || Equals(q2, gamedataQuality.Invalid) || Equals(q2, gamedataQuality.Count) {
    return false;
  };
  switch q2 {
    case gamedataQuality.Common:
      return false;
    case gamedataQuality.Uncommon:
      result = Equals(q1, gamedataQuality.Common) ? true : false;
      break;
    case gamedataQuality.Rare:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) ? true : false;
      break;
    case gamedataQuality.Epic:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) || Equals(q1, gamedataQuality.Rare) ? true : false;
      break;
    case gamedataQuality.Legendary:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) || Equals(q1, gamedataQuality.Rare) || Equals(q1, gamedataQuality.Epic) ? true : false;
      break;
    default:
      return false;
  };
  return result;
}

public static func OperatorLessEqual(q1: gamedataQuality, q2: gamedataQuality) -> Bool {
  let result: Bool;
  if Equals(q1, gamedataQuality.Invalid) || Equals(q1, gamedataQuality.Count) || Equals(q2, gamedataQuality.Invalid) || Equals(q2, gamedataQuality.Count) {
    return false;
  };
  switch q2 {
    case gamedataQuality.Common:
      result = Equals(q1, gamedataQuality.Common) ? true : false;
      break;
    case gamedataQuality.Uncommon:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) ? true : false;
      break;
    case gamedataQuality.Rare:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) || Equals(q1, gamedataQuality.Rare) ? true : false;
      break;
    case gamedataQuality.Epic:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) || Equals(q1, gamedataQuality.Rare) || Equals(q1, gamedataQuality.Epic) ? true : false;
      break;
    case gamedataQuality.Legendary:
      result = Equals(q1, gamedataQuality.Common) || Equals(q1, gamedataQuality.Uncommon) || Equals(q1, gamedataQuality.Rare) || Equals(q1, gamedataQuality.Epic) || Equals(q1, gamedataQuality.Legendary) ? true : false;
      break;
    default:
      return false;
  };
  return result;
}
