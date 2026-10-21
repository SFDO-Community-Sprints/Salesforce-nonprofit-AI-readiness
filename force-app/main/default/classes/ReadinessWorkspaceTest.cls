@IsTest private class ReadinessWorkspaceTest {
    @TestSetup static void setup() {
        Profile profile=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1];
        List<User> users=new List<User>();
        for(String alias:new List<String>{'wsedit','wsother','wsread','wsrec'}) users.add(new User(Alias=alias,Email=alias+'@example.invalid',EmailEncodingKey='UTF-8',LastName=alias,LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='GMT',ProfileId=profile.Id,Username=alias+System.now().getTime()+'@example.invalid'));
        insert users;
        Map<String,Id> roles=new Map<String,Id>();for(PermissionSet role:[SELECT Id,Name FROM PermissionSet WHERE Name IN ('Readiness_Assessor','Readiness_Workspace_Reviewer','Readiness_Assessment_Recorder','Readiness_Security_Reader')]) roles.put(role.Name,role.Id);
        List<PermissionSetAssignment> assignments=new List<PermissionSetAssignment>();
        for(User user:users) {
            if(user.Alias=='wsedit'||user.Alias=='wsother') assignments.add(new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=roles.get('Readiness_Workspace_Reviewer')));
            if(user.Alias=='wsedit') assignments.add(new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=roles.get('Readiness_Security_Reader')));
            if(user.Alias!='wsrec') assignments.add(new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=roles.get('Readiness_Assessor')));
            if(user.Alias=='wsrec'||user.Alias=='wsedit') assignments.add(new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=roles.get('Readiness_Assessment_Recorder')));
        }
        insert assignments;
    }
    private static User actor(String alias) {return [SELECT Id FROM User WHERE Alias=:alias LIMIT 1];}
    private static Map<String,Object> parse(String encoded) {return (Map<String,Object>)JSON.deserializeUntyped(encoded);}
    private static Map<String,Object> caseInput() {return new Map<String,Object>{'name'=>'Donor summary','purpose'=>'Approved summary only','owner'=>'Fictional business owner','status'=>'Proposed','groundingFields'=>new List<Object>{'Contact.Email','Contact.AccountId'}};}
    private static Map<String,Object> answerInput() {return new Map<String,Object>{'scope'=>'company','questionId'=>'privacy_owner','answer'=>'yes','responsible'=>'Fictional privacy owner','evidence'=>'policy-2026','reviewDate'=>String.valueOf(Date.today()),'notes'=>'PRIVATE NOTE MUST NOT ENTER REPORT'};}
    @IsTest static void scopesPersistAndPrivateAnswersStayOutOfReports() {
        System.runAs(actor('wsedit')) {
            Map<String,Object> first=parse(ReadinessWorkspace.saveUseCase(JSON.serialize(caseInput())));
            Map<String,Object> other=caseInput();other.put('name','Volunteer summary');Map<String,Object> second=parse(ReadinessWorkspace.saveUseCase(JSON.serialize(other)));
            System.assertNotEquals(first.get('id'),second.get('id'));
            ReadinessWorkspace.saveAnswer(JSON.serialize(answerInput()));
            Map<String,Object> partial=answerInput();partial.put('answer','partial');ReadinessWorkspace.saveAnswer(JSON.serialize(partial));
            Map<String,Object> workspace=parse(ReadinessWorkspace.loadWorkspace());System.assertEquals(2,((List<Object>)workspace.get('useCases')).size());System.assertEquals(1,((List<Object>)workspace.get('answers')).size());
            String report=ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>()));
            System.assert(!report.contains('PRIVATE NOTE'));System.assert(!report.contains('Fictional privacy owner'));System.assert(report.contains('reported_policy'));
            Map<String,Object> saved=parse(report);System.assertEquals(true,saved.get('historySaved'));
            String snapshotId=(String)saved.get('assessmentId');
            Map<String,Object> loaded=parse(ReadinessWorkspace.loadHistory(snapshotId));System.assertEquals('Saved assessment',loaded.get('source'));System.assertEquals(saved.get('version'),loaded.get('version'));
            System.assertEquals(UserInfo.getName(),loaded.get('recordedBy'));
            System.assert(![SELECT Report__c FROM Readiness_Assessment__c WHERE Id=:snapshotId].Report__c.contains('recordedBy'),'Actor is UI-only provenance, never stored in sanitized assessment');
            System.assert(!saved.containsKey('recordedBy'),'Scan and MCP reports must not gain actor names');
            ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>()));System.assertEquals(2,[SELECT COUNT() FROM Readiness_Assessment__c]);
            System.assertEquals('partial',((Map<String,Object>)((List<Object>)workspace.get('answers'))[0]).get('answer'));
            Integer failed=0;for(Object raw:(List<Object>)saved.get('findings')) {Map<String,Object> row=(Map<String,Object>)raw;if(row.get('questionId')=='privacy_owner'&&row.get('status')=='fail') failed++;}System.assertEquals(1,failed,'Partial policy never passes');
        }
    }
    @IsTest static void recordFieldsAndIdempotentHydrationPreserveEvidence() {
        System.runAs(actor('wsedit')) {
            Map<String,Object> saved=parse(ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>())));
            Id assessmentId=(Id)saved.get('assessmentId');
            Readiness_Assessment__c stored=[SELECT Id,Report__c,Summary__c,Observed_At__c,Score__c,Coverage__c,Passed__c,Failed__c,Unknown__c,Rubric__c,Scope__c,Source__c FROM Readiness_Assessment__c WHERE Id=:assessmentId WITH USER_MODE];
            System.assertEquals(Decimal.valueOf(String.valueOf(saved.get('coverage'))),stored.Coverage__c);
            System.assertEquals(saved.get('version'),stored.Rubric__c);System.assertNotEquals(null,stored.Observed_At__c);
            System.assertEquals('Live organization assessment',stored.Source__c);
            System.assertEquals(0,ReadinessWorkspace.hydrateAssessments());
            String report=stored.Report__c,summary=stored.Summary__c;
            // Reproduce a pre-projection snapshot without changing its stored evidence.
            ReadinessWorkspace.writing='assessment_projection';
            try {update as system new Readiness_Assessment__c(Id=assessmentId,Observed_At__c=null,Score__c=null,Coverage__c=null,Rubric__c=null);} finally {ReadinessWorkspace.writing=null;}
            System.assertEquals(1,ReadinessWorkspace.hydrateAssessments());System.assertEquals(0,ReadinessWorkspace.hydrateAssessments());
            stored=[SELECT Report__c,Summary__c,Observed_At__c,Rubric__c FROM Readiness_Assessment__c WHERE Id=:assessmentId];
            System.assertEquals(report,stored.Report__c);System.assertEquals(summary,stored.Summary__c);System.assertNotEquals(null,stored.Observed_At__c);System.assertEquals(saved.get('version'),stored.Rubric__c);
            Database.SaveResult forged=Database.update(new Readiness_Assessment__c(Id=assessmentId,Score__c=100),false,AccessLevel.SYSTEM_MODE);System.assertEquals(false,forged.isSuccess());
            ReadinessWorkspace.writing='assessment_projection';
            try {forged=Database.update(new Readiness_Assessment__c(Id=assessmentId,Summary__c='{}'),false,AccessLevel.SYSTEM_MODE);System.assertEquals(false,forged.isSuccess(),'Projection context cannot alter original evidence');} finally {ReadinessWorkspace.writing=null;}
            System.assertEquals(false,Readiness_Assessment__c.SObjectType.getDescribe().isUpdateable(),'Recorder has no object edit permission');
        }
        System.runAs(actor('wsread')) {Boolean denied=false;try {ReadinessWorkspace.hydrateAssessments();}catch(Exception expected){denied=true;}System.assert(denied);}
    }
    @IsTest static void actualRecordAccessAndNarrowRoles() {
        String caseId,assessmentId;
        System.runAs(actor('wsedit')) {
            caseId=(String)parse(ReadinessWorkspace.saveUseCase(JSON.serialize(caseInput()))).get('id');
            assessmentId=(String)parse(ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>()))).get('assessmentId');
        }
        System.runAs(actor('wsother')) {
            Map<String,Object> workspace=parse(ReadinessWorkspace.loadWorkspace());System.assertEquals(0,((List<Object>)workspace.get('useCases')).size());System.assertEquals(0,((List<Object>)workspace.get('history')).size());
            Map<String,Object> updateInput=caseInput();updateInput.put('id',caseId);Boolean denied=false;try {ReadinessWorkspace.saveUseCase(JSON.serialize(updateInput));}catch(Exception expected){denied=true;}System.assert(denied);
            denied=false;try {ReadinessWorkspace.loadHistory(assessmentId);}catch(Exception expected){denied=true;}System.assert(denied);
        }
        System.runAs(actor('wsread')) {
            System.assertEquals(false,parse(ReadinessWorkspace.loadWorkspace()).get('canEdit'));Boolean denied=false;try {ReadinessWorkspace.saveUseCase(JSON.serialize(caseInput()));}catch(Exception expected){denied=true;}System.assert(denied);
            System.assertEquals(false,parse(ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>()))).get('historySaved'));
        }
        System.runAs(actor('wsrec')) {Map<String,Object> result=parse(ReadinessWorkspace.loadWorkspace());System.assertEquals(false,result.get('canEdit'));System.assertEquals(true,result.get('canRecord'));}
    }
    @IsTest static void rejectsForgedInputAndUnapprovedPolicies() {
        System.runAs(actor('wsedit')) {
            for(String input:new List<String>{'null','[]','{"name":"Missing fields"}'}) {Boolean denied=false;try {ReadinessWorkspace.saveUseCase(input);}catch(Exception expected){denied=true;}System.assert(denied);}
            Map<String,Object> input=caseInput();input.put('groundingFields',new List<Object>{'Contact.Email FROM User'});Boolean denied=false;try {ReadinessWorkspace.saveUseCase(JSON.serialize(input));}catch(Exception expected){denied=true;}System.assert(denied);
            input=caseInput();input.put('minimumCompleteness',90);denied=false;try {ReadinessWorkspace.saveUseCase(JSON.serialize(input));}catch(Exception expected){denied=true;}System.assert(denied);
            input.put('policyApproved',true);input.put('policyReference','approved-data-policy');System.assertNotEquals(null,parse(ReadinessWorkspace.saveUseCase(JSON.serialize(input))).get('id'));
            Map<String,Object> answer=answerInput();answer.put('reviewDate',String.valueOf(Date.today().addDays(1)));denied=false;try {ReadinessWorkspace.saveAnswer(JSON.serialize(answer));}catch(Exception expected){denied=true;}System.assert(denied);
            answer=answerInput();answer.put('scope','implementation');denied=false;try {ReadinessWorkspace.saveAnswer(JSON.serialize(answer));}catch(Exception expected){denied=true;}System.assert(denied,'Question cannot move into another scope');
            answer=answerInput();answer.put('evidence','');denied=false;try {ReadinessWorkspace.saveAnswer(JSON.serialize(answer));}catch(Exception expected){denied=true;}System.assert(denied);
        }
    }
    @IsTest static void evidenceMustComeThroughValidatedAppAndRemainAppendOnly() {
        Database.SaveResult forged=Database.insert(new Readiness_Assessment__c(Report__c='{"score":100}',Summary__c='{}'),false);System.assertEquals(false,forged.isSuccess());
        forged=Database.insert(new Readiness_Answer__c(Scope__c='company',Question__c='privacy_owner',Response__c='{"answer":"yes"}'),false);System.assertEquals(false,forged.isSuccess());
        forged=Database.insert(new Readiness_Use_Case__c(Name='Forged',Definition__c='{}'),false);System.assertEquals(false,forged.isSuccess());
        System.runAs(actor('wsedit')) {
            Map<String,Object> input=caseInput();String id=(String)parse(ReadinessWorkspace.saveUseCase(JSON.serialize(input))).get('id');input.put('id',id);input.put('name','Renamed');ReadinessWorkspace.saveUseCase(JSON.serialize(input));
            String snapshotId=(String)parse(ReadinessWorkspace.decorateOrganization(ReadinessOrgHealth.summarize(new List<Object>(),new List<Object>()))).get('assessmentId');
            Database.SaveResult updated=Database.update(new Readiness_Assessment__c(Id=snapshotId,Report__c='{}'),false);System.assertEquals(false,updated.isSuccess());
            Database.DeleteResult deleted=Database.delete(new Readiness_Assessment__c(Id=snapshotId),false);System.assertEquals(false,deleted.isSuccess());
        }
    }
    @IsTest static void actualIntegrationBindingRemainsConfigurationOnly() {
        String username=[SELECT Username FROM User WHERE Alias='wsread' LIMIT 1].Username;
        System.runAs(actor('wsedit')) {
            Map<String,Object> input=caseInput();input.put('integrationUsername',username);
            Map<String,Object> saved=parse(ReadinessWorkspace.saveUseCase(JSON.serialize(input)));
            System.assertNotEquals(null,saved.get('integrationUserId'));
            Map<String,Object> result=parse(ReadinessWorkspace.scanUseCase((String)saved.get('id')));
            Boolean sawBroad=false,sawRuntime=false;
            for(Object raw:(List<Object>)result.get('findings')) {Map<String,Object> row=(Map<String,Object>)raw;
                if(row.get('id')=='scope_global_broad') {sawBroad=true;System.assertEquals('pass',row.get('status'));}
                if(row.get('id')=='scope_runtime') {sawRuntime=true;System.assertEquals('unknown',row.get('status'));}
            }
            System.assert(sawBroad,'A focused nonadmin Security Reader can inspect actual grants');System.assert(sawRuntime);
            System.assert(!JSON.serialize(result).contains(username),'Reports exclude usernames');
        }
    }
    @IsTest static void implementationPoliciesDoNotReplaceRuntimeEvidence() {
        System.runAs(actor('wsedit')) {
            String caseId=(String)parse(ReadinessWorkspace.saveUseCase(JSON.serialize(caseInput()))).get('id');
            Map<String,Object> answer=new Map<String,Object>{'scope'=>'implementation','questionId'=>'human_approval_policy','useCaseId'=>caseId,'answer'=>'yes','responsible'=>'Approver','evidence'=>'approval-procedure','reviewDate'=>String.valueOf(Date.today())};
            ReadinessWorkspace.saveAnswer(JSON.serialize(answer));
            Map<String,Object> scoped=parse(ReadinessWorkspace.scanUseCase(caseId));System.assertEquals(caseId,scoped.get('useCaseId'));System.assertEquals(true,scoped.get('historySaved'));System.assertEquals(false,scoped.get('readinessEstablished'));
            Boolean policyPass=false,runtimeUnknown=false;
            for(Object raw:(List<Object>)scoped.get('findings')) {Map<String,Object> row=(Map<String,Object>)raw;if(row.get('id')=='governance_human_approval_policy') policyPass=row.get('status')=='pass';if(row.get('id')=='runtime_consequential_approval') runtimeUnknown=row.get('status')=='unknown';}
            System.assert(policyPass);System.assert(runtimeUnknown,'Reported approval policy cannot pass actual workflow verification');System.assertNotEquals(null,scoped.get('scopeDefinition'));
        }
    }
}
