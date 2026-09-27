
public class InjectCombatThreatCommandTask extends AIbehaviortaskScript {

  protected inline edit let m_inCommand: ref<AIArgumentMapping>;

  protected let m_currentCommand: wref<AIInjectCombatThreatCommand>;

  protected let m_threatPersistenceSource: ref<AIThreatPersistenceSource_Record>;

  protected let m_activationTimeStamp: Float;

  protected let m_commandDuration: Float;

  protected let m_target: wref<GameObject>;

  protected let m_targetID: EntityID;

  protected func Activate(context: ScriptExecutionContext) -> Void {
    AIbehaviortaskScript.SetUpdateInterval(context, AIBehaviorScriptBase.RandomizeOffsetForUpdateInterval(0.20));
  }

  protected func Update(context: ScriptExecutionContext) -> AIbehaviorUpdateOutcome {
    let attitudeOwner: ref<AttitudeAgent>;
    let attitudeTarget: ref<AttitudeAgent>;
    let globalRef: GlobalNodeRef;
    let target: wref<GameObject>;
    let targetID: EntityID;
    let targetTrackerComponent: ref<TargetTrackerComponent>;
    let rawCommand: ref<IScriptable> = ScriptExecutionContext.GetScriptableMappingValue(context, this.m_inCommand);
    let typedCommand: ref<AIInjectCombatThreatCommand> = rawCommand as AIInjectCombatThreatCommand;
    if IsDefined(this.m_currentCommand) && !IsDefined(typedCommand) {
      this.CancelCommand(context);
      return AIbehaviorUpdateOutcome.IN_PROGRESS;
    };
    if typedCommand == this.m_currentCommand {
      if IsDefined(this.m_currentCommand) {
        if !ScriptedPuppet.IsActive(ScriptExecutionContext.GetOwner(context)) {
          ScriptExecutionContext.DebugLog(context, n"InjectCombatThreatCommand", "Canceling command, owner is Dead, Defeated or Unconscious");
          this.CancelCommand(context);
          if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
            AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, true);
          };
        } else {
          if EntityID.IsDefined(this.m_targetID) && !IsDefined(this.m_target) {
            this.CancelCommand(context);
            ScriptExecutionContext.DebugLog(context, n"InjectCombatThreatCommand", "Canceling command, entity streamed out");
            if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
              AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, false);
            };
          } else {
            if this.m_commandDuration >= 0.00 && EngineTime.ToFloat(ScriptExecutionContext.GetAITime(context)) > this.m_activationTimeStamp + this.m_commandDuration {
              this.CancelCommand(context);
              ScriptExecutionContext.DebugLog(context, n"InjectCombatThreatCommand", "Canceling command, duration expired");
              if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
                AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, true);
              };
            };
          };
        };
      };
      return AIbehaviorUpdateOutcome.IN_PROGRESS;
    };
    this.m_currentCommand = typedCommand;
    this.m_commandDuration = typedCommand.duration;
    if typedCommand.duration > 0.00 {
      this.m_commandDuration = 0.00;
    };
    this.m_activationTimeStamp = EngineTime.ToFloat(ScriptExecutionContext.GetAITime(context));
    if !GetGameObjectFromEntityReference(typedCommand.targetPuppetRef, ScriptExecutionContext.GetOwner(context).GetGame(), target) {
      globalRef = ResolveNodeRef(typedCommand.targetNodeRef, Cast<GlobalNodeRef>(GlobalNodeID.GetRoot()));
      targetID = Cast<EntityID>(globalRef);
      target = GameInstance.FindEntityByID(AIBehaviorScriptBase.GetGame(context), targetID) as GameObject;
    };
    this.m_target = target;
    this.m_targetID = target.GetEntityID();
    this.m_threatPersistenceSource = TweakDBInterface.GetAIThreatPersistenceSourceRecord(t"AIThreatPersistenceSource.CommandInjectThreat");
    if EntityID.IsDefined(this.m_targetID) && !IsDefined(this.m_target) {
      this.CancelCommand(context);
      ScriptExecutionContext.DebugLog(context, n"InjectCombatThreatCommand", "Canceling command, entity streamed out");
      if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
        AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, false);
      };
    } else {
      if IsDefined(target) && target != ScriptExecutionContext.GetOwner(context) {
        targetTrackerComponent = ScriptExecutionContext.GetOwner(context).GetTargetTrackerComponent();
        if IsDefined(targetTrackerComponent) && target.IsPuppet() && target != ScriptExecutionContext.GetOwner(context) {
          attitudeOwner = ScriptExecutionContext.GetOwner(context).GetAttitudeAgent();
          attitudeTarget = target.GetAttitudeAgent();
          if !typedCommand.dontForceHostileAttitude {
            if IsDefined(attitudeOwner) && IsDefined(attitudeTarget) {
              attitudeOwner.SetAttitudeTowardsAgentGroup(attitudeTarget, attitudeOwner, EAIAttitude.AIA_Hostile);
            };
          };
          if IsDefined(attitudeOwner) && IsDefined(attitudeTarget) && Equals(attitudeOwner.GetAttitudeTowards(attitudeTarget), EAIAttitude.AIA_Hostile) {
            targetTrackerComponent.AddThreat(target, true, target.GetWorldPosition(), 1.00, this.m_commandDuration, typedCommand.isPersistent);
            if this.m_commandDuration < 0.00 {
              targetTrackerComponent.SetThreatPersistence(target, true, Cast<Uint32>(this.m_threatPersistenceSource.EnumValue()));
            };
          } else {
            targetTrackerComponent.AddThreat(target, false, target.GetWorldPosition(), 1.00, this.m_commandDuration, typedCommand.isPersistent);
            if this.m_commandDuration < 0.00 {
              targetTrackerComponent.SetThreatPersistence(target, true, Cast<Uint32>(this.m_threatPersistenceSource.EnumValue()));
            };
          };
        };
      } else {
        this.CancelCommand(context);
        ScriptExecutionContext.DebugLog(context, n"InjectCombatThreatCommand", "No target or targetting self");
        if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
          AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, true);
        };
      };
    };
    return AIbehaviorUpdateOutcome.IN_PROGRESS;
  }

  private final func Deactivate(context: ScriptExecutionContext) -> Void {
    this.CancelCommand(context);
  }

  protected final func CancelCommand(context: ScriptExecutionContext) -> Void {
    if this.m_commandDuration < 0.00 {
      TargetTrackingExtension.SetThreatPersistence(ScriptExecutionContext.GetOwner(context) as ScriptedPuppet, this.m_target, false, Cast<Uint32>(this.m_threatPersistenceSource.EnumValue()));
    };
    ScriptExecutionContext.SetMappingValue(context, this.m_inCommand, ToVariant(null));
    this.m_activationTimeStamp = 0.00;
    this.m_commandDuration = 0.00;
    this.m_currentCommand = null;
    this.m_target = null;
    this.m_targetID = this.m_target.GetEntityID();
  }
}
