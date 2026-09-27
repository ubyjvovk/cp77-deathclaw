
public native class TargetFilterResult extends IScriptable {

  public native let hitEntId: EntityID;

  public native let hitComponent: wref<IComponent>;

  public func OnReset() -> Void;

  public func OnClone(out cloneDestination: ref<TargetFilterResult>) -> Void;
}

public native class TargetFilter_Script extends TargetFilter {

  public final native func GetFilterMask() -> Uint64;

  public final native func GetFilter() -> QueryFilter;

  public final native func SetFilter(queryFilter: QueryFilter) -> Void;

  public final native func TestFilterMask(mask: Uint64) -> Bool;

  public final native func GetResult(destination: ref<TargetFilterResult>) -> Void;

  public func PreFilter(const defaultPos: script_ref<Vector4>) -> Void;

  public func Filter(hitInfo: TargetHitInfo, workingState: ref<TargetFilterResult>) -> Void;

  public func PostFilter() -> Void;

  public func CreateFilterResult() -> ref<TargetFilterResult> {
    return null;
  }
}
