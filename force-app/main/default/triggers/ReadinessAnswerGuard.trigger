trigger ReadinessAnswerGuard on Readiness_Answer__c (before insert, before update, before delete) {
    if(!(ReadinessWorkspace.allowsWrite('answer') && (Trigger.isInsert))) for(Readiness_Answer__c record:Trigger.isDelete?Trigger.old:Trigger.new) record.addError('Use the readiness app to record evidence. Saved evidence is append-only; retire use cases instead of deleting them.');
}
