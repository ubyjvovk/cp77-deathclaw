
public native class ScriptStatsListener extends IStatsListener {

  public func OnStatChanged(ownerID: StatsObjectID, statType: gamedataStatType, diff: Float, total: Float) -> Void;

  public func OnGodModeChanged(ownerID: EntityID, newType: gameGodModeType) -> Void;

  public final native func SetStatType(statType: gamedataStatType) -> Void;
}

public class StatsSystemHelper extends IScriptable {

  public final static func GetDetailedStatInfo(obj: ref<GameObject>, statType: gamedataStatType, statData: script_ref<gameStatDetailedData>) -> Bool {
    let detailsArray: array<gameStatDetailedData> = GameInstance.GetStatsSystem(obj.GetGame()).GetStatDetails(Cast<StatsObjectID>(obj.GetEntityID()));
    let i: Int32 = 0;
    while i < ArraySize(detailsArray) {
      if Equals(detailsArray[i].statType, statType) {
        statData = detailsArray[i];
        return true;
      };
      i += 1;
    };
    return false;
  }

  public final static func GetStatPrereqModifiersValue(game: GameInstance, ownerID: StatsObjectID, statPrereqID: TweakDBID) -> Float {
    let modifiersValue: Float;
    let statModifiers: array<wref<StatModifier_Record>>;
    let record: ref<StatPrereq_Record> = TweakDBInterface.GetStatPrereqRecord(statPrereqID);
    record.StatModifiers(statModifiers);
    modifiersValue = GameInstance.GetStatsSystem(game).CalculateModifierListValue(ownerID, statModifiers);
    return modifiersValue;
  }

  public final static func GetStatValue(obj: ref<GameObject>, objID: StatsObjectID, statType: gamedataStatType) -> Float {
    return GameInstance.GetStatsSystem(obj.GetGame()).GetStatValue(objID, statType);
  }

  public final static func GetStatValue(obj: ref<GameObject>, statType: gamedataStatType) -> Float {
    return GameInstance.GetStatsSystem(obj.GetGame()).GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), statType);
  }
}
