trigger ReadinessAssessmentGuard on Readiness_Assessment__c (before insert, before update, before delete) {
    if(!(ReadinessWorkspace.allowsWrite('assessment') && (Trigger.isInsert))) for(Readiness_Assessment__c record:Trigger.isDelete?Trigger.old:Trigger.new) record.addError('Use the readiness app to record evidence. Saved evidence is append-only; retire use cases instead of deleting them.');
}
