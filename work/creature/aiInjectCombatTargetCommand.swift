
public class InjectCombatTargetCommandTask extends AIbehaviortaskScript {

  protected inline edit let m_inCommand: ref<AIArgumentMapping>;

  protected let m_currentCommand: wref<AIInjectCombatTargetCommand>;

  protected let m_threatPersistenceSource: ref<AIThreatPersistenceSource_Record>;

  protected let m_activationTimeStamp: Float;

  protected let m_commandDuration: Float;

  protected let m_target: wref<GameObject>;

  protected let m_targetID: EntityID;

  protected func Activate(context: ScriptExecutionContext) -> Void {
    AIbehaviortaskScript.SetUpdateInterval(context, AIBehaviorScriptBase.RandomizeOffsetForUpdateInterval(0.20));
  }

  protected func Update(context: ScriptExecutionContext) -> AIbehaviorUpdateOutcome {
    let globalRef: GlobalNodeRef;
    let target: wref<GameObject>;
    let rawCommand: ref<IScriptable> = ScriptExecutionContext.GetScriptableMappingValue(context, this.m_inCommand);
    let typedCommand: ref<AIInjectCombatTargetCommand> = rawCommand as AIInjectCombatTargetCommand;
    if IsDefined(this.m_currentCommand) && !IsDefined(typedCommand) {
      this.CancelCommand(context);
      return AIbehaviorUpdateOutcome.IN_PROGRESS;
    };
    if typedCommand == this.m_currentCommand {
      if IsDefined(this.m_currentCommand) {
        if !AIActionHelper.IsCommandCombatTargetValid(context, n"InjectCombatTargetCommand") {
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
              ScriptExecutionContext.DebugLog(context, n"InjectCombatTargetCommand", "Canceling command, duration expired");
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
      target = GameInstance.FindEntityByID(AIBehaviorScriptBase.GetGame(context), Cast<EntityID>(globalRef)) as GameObject;
    };
    this.m_target = target;
    this.m_targetID = Cast<EntityID>(globalRef);
    this.m_threatPersistenceSource = TweakDBInterface.GetAIThreatPersistenceSourceRecord(t"AIThreatPersistenceSource.CommandInjectCombatTarget");
    if EntityID.IsDefined(this.m_targetID) && !IsDefined(this.m_target) {
      this.CancelCommand(context);
      ScriptExecutionContext.DebugLog(context, n"InjectCombatTargetCommand", "Canceling command, entity streamed out");
      if IsDefined(typedCommand) && Equals(typedCommand.state, AICommandState.Executing) {
        AIBehaviorScriptBase.GetPuppet(context).GetAIControllerComponent().StopExecutingCommand(typedCommand, false);
      };
    } else {
      if !AIActionHelper.SetCommandCombatTarget(context, target, this.m_commandDuration != 0.00, Cast<Uint32>(this.m_threatPersistenceSource.EnumValue())) {
        this.CancelCommand(context);
        ScriptExecutionContext.DebugLog(context, n"InjectCombatTargetCommand", "Canceling command, unable to set CommandCombatTarget");
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
    AIActionHelper.ClearCommandCombatTarget(context, Cast<Uint32>(this.m_threatPersistenceSource.EnumValue()));
    ScriptExecutionContext.SetMappingValue(context, this.m_inCommand, ToVariant(null));
    this.m_activationTimeStamp = 0.00;
    this.m_commandDuration = 0.00;
    this.m_currentCommand = null;
    this.m_target = null;
    this.m_targetID = this.m_target.GetEntityID();
  }
}
