
public native class EnvironmentDamageReceiverComponent extends IPlacedComponent {

  private native let cooldown: Float;

  private final func DealDamageFromParticle(particleDamageRecords: [ref<ParticleDamage_Record>], instigator: ref<GameObject>, source: ref<GameObject>) -> Void {
    let attack: ref<Attack_GameEffect>;
    let flag: SHitFlag;
    let gameEffectAttackRecord: ref<Attack_GameEffect_Record>;
    let hitFlags: array<SHitFlag>;
    let i: Int32;
    let object: ref<GameObject> = this.GetEntity() as GameObject;
    let gi: GameInstance = object.GetGame();
    flag.flag = hitFlag.None;
    flag.source = n"Environment";
    ArrayPush(hitFlags, flag);
    if instigator == null {
      instigator = object;
    };
    if source == null {
      source = object;
    };
    i = 0;
    while i < ArraySize(particleDamageRecords) {
      gameEffectAttackRecord = particleDamageRecords[i].Attack() as Attack_GameEffect_Record;
      if IsDefined(gameEffectAttackRecord) {
        attack = RPGManager.PrepareGameEffectAttack(gi, instigator, source, gameEffectAttackRecord.GetID(), hitFlags, object);
        if IsDefined(attack) {
          attack.StartAttack();
        };
      };
      this.cooldown += particleDamageRecords[i].Cooldown();
      i = i + 1;
    };
  }
}
