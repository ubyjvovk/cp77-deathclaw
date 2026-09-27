
public static func TSF_NPC() -> TargetSearchFilter {
  let tsf: TargetSearchFilter = TSF_And(TSF_All(IntEnum<TSFMV>(2050)), TSF_Not(TSFMV.Obj_Player));
  return tsf;
}

public static func TSF_EnemyNPC() -> TargetSearchFilter {
  let tsf: TargetSearchFilter = TSF_And(TSF_All(IntEnum<TSFMV>(2114)), TSF_Not(TSFMV.Obj_Player));
  return tsf;
}

public static func TSF_Quickhackable() -> TargetSearchFilter {
  let tsf: TargetSearchFilter = TSF_And(TSF_All(TSFMV.St_QuickHackable), TSF_Not(TSFMV.Obj_Player), TSF_Not(TSFMV.Att_Friendly), TSF_Any(IntEnum<TSFMV>(520)));
  return tsf;
}

public static func TSQ_ALL() -> TargetSearchQuery {
  let tsq: TargetSearchQuery;
  return tsq;
}

public static func TSQ_NPC() -> TargetSearchQuery {
  let tsq: TargetSearchQuery;
  tsq.searchFilter = TSF_NPC();
  return tsq;
}

public static func TSQ_EnemyNPC() -> TargetSearchQuery {
  let tsq: TargetSearchQuery;
  tsq.searchFilter = TSF_EnemyNPC();
  return tsq;
}
