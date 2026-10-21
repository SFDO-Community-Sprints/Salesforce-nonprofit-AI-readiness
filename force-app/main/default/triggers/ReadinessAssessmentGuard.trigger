trigger ReadinessAssessmentGuard on Readiness_Assessment__c (before insert, before update, before delete) {
    for(Readiness_Assessment__c record:Trigger.isDelete?Trigger.old:Trigger.new) {
        Boolean allowed=Trigger.isInsert&&ReadinessWorkspace.allowsWrite('assessment');
        if(Trigger.isUpdate) allowed=ReadinessWorkspace.allowsAssessmentProjection(record,Trigger.oldMap.get(record.Id));
        if(!allowed) record.addError('Use the readiness app to record evidence. Saved evidence is append-only; retire use cases instead of deleting them.');
    }
}
