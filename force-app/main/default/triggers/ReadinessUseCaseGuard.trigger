trigger ReadinessUseCaseGuard on Readiness_Use_Case__c (before insert, before update, before delete) {
    if(!(ReadinessWorkspace.allowsWrite('case') && (Trigger.isInsert || Trigger.isUpdate))) for(Readiness_Use_Case__c record:Trigger.isDelete?Trigger.old:Trigger.new) record.addError('Use the readiness app to record evidence. Saved evidence is append-only; retire use cases instead of deleting them.');
}
