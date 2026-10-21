// Deploy current metadata and run post-deploy.apex first. This seeds planning inputs, never results.
String host = URL.getOrgDomainUrl().getHost();
if (!host.endsWith('.scratch.my.salesforce.com') ||
    ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('Demo seeding requires a scratch org.');
}
if(!FeatureManagement.checkPermission('Readiness_Manage_Workspace')) throw new IllegalArgumentException('Run the latest post-deploy setup before seeding the workspace.');
Map<String,List<Object>> scopes=new Map<String,List<Object>>{
    'Fictional donor summary'=>new List<Object>{'Contact.Email','Contact.AccountId'},
    'Fictional account context'=>new List<Object>{'Account.Name','Contact.AccountId'}
};
Integer created=0;
for(String name:scopes.keySet()) {
    if([SELECT COUNT() FROM Readiness_Use_Case__c WHERE Name=:name WITH USER_MODE]>0) continue;
    Map<String,Object> input=new Map<String,Object>{'name'=>name,'owner'=>'Demo coordinator (fictional)','purpose'=>'Fictional planning input for a read-only summary demonstration. Not an approved deployment.','status'=>'Proposed','groundingFields'=>scopes.get(name),'allowedActions'=>'Read approved summary aggregates only.','excludedActions'=>'No exports, changes, eligibility decisions or consequential actions.','handover'=>'A real accountable owner must define and demonstrate handover.','stopOwner'=>'Not assigned; demonstration only.'};
    Map<String,Object> saved=(Map<String,Object>)JSON.deserializeUntyped(ReadinessWorkspace.saveUseCase(JSON.serialize(input)));
    System.assert(saved.get('id')!=null,'Planning record creation must succeed.');
    created++;
}
System.debug('Workspace demo: '+created+' fictional planning records created. No scores, policy approvals, integration identity or human demonstrations were seeded.');
