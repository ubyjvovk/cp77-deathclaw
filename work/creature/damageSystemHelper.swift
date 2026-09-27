
public abstract class DamageSystemHelper extends IScriptable {

  public final static func GetHitShape(hitEvent: ref<gameHitEvent>) -> HitShapeData {
    return hitEvent.hitRepresentationResult.hitShapes[0];
  }

  public final static func GetHitShapeUserDataBase(const data: script_ref<HitShapeData>) -> ref<HitShapeUserDataBase> {
    return Deref(data).userData as HitShapeUserDataBase;
  }

  public final static func GetLocalizedDamageMultiplier(type: EHitShapeType, armorPenetration: Float, useModernFormula: Bool) -> Float {
    let multiplier: Float;
    if useModernFormula {
      switch type {
        case EHitShapeType.None:
          multiplier = 0.00;
          break;
        case EHitShapeType.Flesh:
          multiplier = 1.00;
          break;
        case EHitShapeType.Metal:
          multiplier = 1.00 - 0.50 * (1.00 - armorPenetration);
          break;
        case EHitShapeType.Cyberware:
          multiplier = 1.00 - 0.50 * (1.00 - armorPenetration);
          break;
        case EHitShapeType.Armor:
          multiplier = 1.00 - 0.50 * (1.00 - armorPenetration);
          break;
        default:
          multiplier = 1.00;
      };
    } else {
      switch type {
        case EHitShapeType.None:
          multiplier = 0.00;
          break;
        case EHitShapeType.Flesh:
          multiplier = 1.00;
          break;
        case EHitShapeType.Metal:
          multiplier = 0.85;
          break;
        case EHitShapeType.Cyberware:
          multiplier = 0.60;
          break;
        case EHitShapeType.Armor:
          multiplier = 0.85;
          break;
        default:
          multiplier = 1.00;
      };
    };
    return multiplier;
  }

  public final static func IsHitShapeArmored(type: EHitShapeType) -> Bool {
    switch type {
      case EHitShapeType.None:
        return false;
      case EHitShapeType.Flesh:
        return false;
      case EHitShapeType.Metal:
        return true;
      case EHitShapeType.Cyberware:
        return true;
      case EHitShapeType.Armor:
        return true;
      default:
        return false;
    };
  }

  public final static func GetHitShapeTypeFromData(const data: script_ref<HitShapeData>) -> EHitShapeType {
    let baseData: ref<HitShapeUserDataBase> = Deref(data).userData as HitShapeUserDataBase;
    if IsDefined(baseData) {
      return baseData.m_hitShapeType;
    };
    return EHitShapeType.None;
  }

  public final static func IsProtectionLayer(const data: script_ref<HitShapeData>) -> Bool {
    let baseData: ref<HitShapeUserDataBase> = Deref(data).userData as HitShapeUserDataBase;
    if IsDefined(baseData) {
      return baseData.m_isProtectionLayer;
    };
    return false;
  }

  public final static func DoQuickHacksPierceProtection(const data: script_ref<HitShapeData>) -> Bool {
    let baseData: ref<HitShapeUserDataBase> = Deref(data).userData as HitShapeUserDataBase;
    if IsDefined(baseData) {
      return baseData.m_quickHacksPierceProtection;
    };
    return false;
  }
}
