@IsTest
private class NonprofitAIReadinessTest {
    @TestSetup static void seed() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permission : [SELECT Id FROM PermissionSet
                    WHERE Name IN ('Readiness_Follow_Up','Readiness_Staff_Reader')]) {
                assignments.add(new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=permission.Id));
            }
            insert assignments;
        }
        List<Account> accounts = new List<Account>{
            new Account(Name='SYNTHETIC AI Readiness pilot'),
            new Account(Name='SYNTHETIC AI Readiness improving'),
            new Account(Name='SYNTHETIC AI Readiness poor')};
        insert accounts;
        List<Contact> contacts = new List<Contact>();
        for (Integer a=0; a<3; a++) {
            for (Integer i=0; i<(a == 2 ? 4 : 10); i++) {
                contacts.add(new Contact(AccountId=accounts[a].Id, LastName='SYNTHETIC sentinel name',
                    Email=a == 1 && i>=8 ? null : 'sentinel-'+a+'-'+(a == 1 && i<2 ? 0 : i)+'@example.invalid',
                    Description='SYNTHETIC safeguarding sentinel must never escape'));
            }
        }
        insert contacts;
    }
    private static Map<String,Object> runScenario(String scenario) {
        NonprofitAIReadiness.Request request = new NonprofitAIReadiness.Request();
        request.scenario = scenario;
        String output = NonprofitAIReadiness.assess(new List<NonprofitAIReadiness.Request>{request})[0].output;
        System.assert(!output.contains('sentinel'), 'Personal sentinel values must never escape');
        System.assert(!output.contains('@'), 'Email values must never escape');
        return (Map<String,Object>)JSON.deserializeUntyped(output);
    }
    @IsTest static void fixedProfileMetadataPersistsOnNormalAndSuppressedAssessments() {
        Map<String,Object> specification = (Map<String,Object>)JSON.deserializeUntyped(
            [SELECT Body FROM StaticResource WHERE Name='CheckSpecifications' LIMIT 1].Body.toString());
        for (String scenario : new List<String>{'pilot','poor'}) {
            Map<String,Object> result = runScenario(scenario);
            System.assertEquals('donor-summary-demo-v1',result.get('rubric_version'));
            System.assertEquals(specification.get('version'),result.get('specification_version'));
            System.assertEquals(0,((Map<String,Object>)result.get('profile_overrides')).size());
            System.assertEquals('readiness_not_established',result.get('decision'));
        }
    }
    @IsTest static void lightningUsesSameBoundary() {
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(
            NonprofitAIReadiness.assessScenario('poor'));
        System.assertEquals(null,result.get('metrics'));
        System.assertEquals('invalid_scenario',((Map<String,Object>)JSON.deserializeUntyped(
            NonprofitAIReadiness.assessScenario('untrusted'))).get('error'));
    }
    @IsTest static void cleanData() {
        Map<String,Object> result = runScenario('pilot');
        Map<String,Object> data = (Map<String,Object>)result.get('data');
        System.assertEquals(100, data.get('score'));
        System.assertEquals('Data quality: 100%. Checks passed: 4 of 4. Checks completed: 4 of 4 (100%).',
            result.get('data_summary'));
        System.assertEquals(100, data.get('coverage'));
        System.assertEquals('readiness_not_established',result.get('decision'));
        System.assertEquals(10, ((Map<String,Object>)result.get('metrics')).get('contacts'));
    }
    @IsTest static void assessAccessibleOrganizationAndOrphans() {
        insert new Contact(LastName='SYNTHETIC orphan', Email='orphan@example.invalid');
        Map<String,Object> result = runScenario('organization');
        Map<String,Object> metrics = (Map<String,Object>)result.get('metrics');
        System.assertEquals('accessible_organization_records',result.get('scope'));
        System.assertEquals(25,metrics.get('contacts'));
        System.assertEquals(24,metrics.get('linked_contacts'));
        System.assertEquals(23,metrics.get('email_present'));
        System.assertEquals(1,metrics.get('repeated_email_rows'));
        System.assertEquals(50,((Map<String,Object>)result.get('data')).get('score'));
        System.assertEquals('readiness_not_established',result.get('decision'));
    }
    @IsTest static void differentScore() {
        Map<String,Object> result = runScenario('improving');
        Map<String,Object> metrics = (Map<String,Object>)result.get('metrics');
        System.assertEquals(1, metrics.get('repeated_email_rows'));
        System.assertEquals(50, ((Map<String,Object>)result.get('data')).get('score'));
        System.assertEquals('Data quality: 50%. Checks passed: 2 of 4. Checks completed: 4 of 4 (100%).',
            result.get('data_summary'));
    }
    @IsTest static void suppressSmallCohort() {
        Map<String,Object> result = runScenario('poor');
        System.assertEquals(null,result.get('metrics'));
        System.assertEquals('Data quality: Not assessed. Checks completed: 0 of 4 (0%).',result.get('data_summary'));
        System.assertEquals(true,((Map<String,Object>)result.get('privacy')).get('suppressed'));
        System.assertEquals(0,((Map<String,Object>)result.get('data')).get('coverage'));
        System.assertEquals(null,((Map<String,Object>)result.get('data')).get('score'));
    }
    @IsTest static void agentReceivesDeterministicSuppressedPriorities() {
        List<Object> suppressed = (List<Object>)runScenario('poor').get('priorities');
        List<Object> clean = (List<Object>)runScenario('pilot').get('priorities');
        System.assertEquals(3,suppressed.size());
        System.assertEquals(JSON.serialize(clean),JSON.serialize(suppressed),
            'Suppression must not leak hidden data defects through recommendations');
        List<String> genericKeys = new List<String>{'controls','privacy','staff'};
        for (Integer i=0;i<3;i++) {
            Map<String,Object> item = (Map<String,Object>)suppressed[i];
            System.assertEquals(4,item.size());
            System.assertEquals(genericKeys[i],item.get('key'));
            System.assertEquals(i<2 ? 'High' : 'Medium',item.get('priority'));
            System.assertNotEquals(null,item.get('impact'));
            System.assertNotEquals(null,item.get('recommendation'));
        }
    }
    @IsTest static void agentReceivesMeasuredHighPrioritiesWithoutInventingCritical() {
        delete [SELECT Id FROM Contact];
        List<Contact> contacts = new List<Contact>();
        for (Integer i=0;i<5;i++) contacts.add(new Contact(LastName='SYNTHETIC sentinel priority',
            Email=i<2 ? 'sentinel-priority@example.invalid' : null));
        insert contacts;
        List<Object> items = (List<Object>)runScenario('organization').get('priorities');
        System.assertEquals(7,items.size());
        List<String> expectedKeys = new List<String>{'controls','privacy','email_completeness',
            'duplicate_indicator','account_linkage','staff','sufficient_data'};
        for (Integer i=0;i<items.size();i++) {
            Map<String,Object> item = (Map<String,Object>)items[i];
            System.assertEquals(expectedKeys[i],item.get('key'));
            System.assertEquals(i<5 ? 'High' : i==5 ? 'Medium' : 'Low',item.get('priority'));
        }
    }
    @IsTest static void rejectInputsAndMissingCohort() {
        System.assertEquals('invalid_scenario',runScenario('pilot WHERE Name != null').get('error'));
        System.assertEquals('cohort_unavailable',runScenario('blocked').get('error'));
        System.assertEquals(0,NonprofitAIReadiness.assess(null).size());
        System.assertEquals(true,NonprofitAIReadiness.assess(new List<NonprofitAIReadiness.Request>{null})[0].output.contains('invalid_scenario'));
    }
    @IsTest static void restrictedUserGetsSanitizedDenial() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1];
        String uniqueName = 'readiness-denied-'+UserInfo.getOrganizationId()+'@example.invalid';
        User restricted = new User(ProfileId=profile.Id, Username=uniqueName,
            Email='restricted@example.invalid', LastName='SYNTHETIC restricted', Alias='rdydny',
            TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert restricted;
        System.runAs(restricted) {
            String output = NonprofitAIReadiness.assessScenario('organization');
            System.assertEquals('assessment_unavailable',
                ((Map<String,Object>)JSON.deserializeUntyped(output)).get('error'));
            System.assert(!output.contains('SYNTHETIC'));
            System.assert(!output.contains('SELECT'));
            String taskOutput = NonprofitAIReadiness.createFollowUpTasks();
            System.assertEquals('task_creation_unavailable',
                ((Map<String,Object>)JSON.deserializeUntyped(taskOutput)).get('error'));
            System.assert(!taskOutput.contains('SELECT'));
            String inventoryOutput = NonprofitAIReadiness.capabilityInventory();
            System.assert(!inventoryOutput.contains('SELECT'));
            System.assert(!inventoryOutput.contains('@'));
            System.assert(!inventoryOutput.contains('sentinel'));
            System.assertEquals(3,((List<Object>)((Map<String,Object>)
                JSON.deserializeUntyped(inventoryOutput)).get('capabilities')).size());
        }
    }
    @IsTest static void followUpTasksBelongToRunnerAndAreReused() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Map<String,Object> first = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals(4,first.get('created'));
            System.assertEquals(0,first.get('reused'));
            List<Task> tasks = [SELECT Id,OwnerId,Subject,Description,Status,Priority FROM Task];
            System.assertEquals(4,tasks.size());
            for (Task task : tasks) {
                System.assertEquals(UserInfo.getUserId(),task.OwnerId);
                System.assert(task.Subject.startsWith('AI Readiness: '));
                System.assert(task.Description.contains('https://trailhead.salesforce.com/') ||
                    task.Description.contains('https://www.edpb.europa.eu/'));
                System.assertEquals('Not Started',task.Status);
                System.assert(task.Description.startsWith('Assessment priority: '));
                System.assert(task.Description.contains('Impact: '));
                System.assertEquals(task.Subject.contains('safeguards') || task.Subject.contains('erasure') ? 'High' : 'Normal',task.Priority);
            }
            Map<String,Object> second = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals(0,second.get('created'));
            System.assertEquals(4,second.get('reused'));
            System.assertEquals(0,second.get('updated'));
            tasks[0].Description='Old task recommendation';
            tasks[0].Priority='Low';
            update tasks[0];
            Map<String,Object> refreshed = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals(0,refreshed.get('created'));
            System.assertEquals(1,refreshed.get('updated'));
            System.assert([SELECT Description FROM Task WHERE Id=:tasks[0].Id].Description.startsWith('Assessment priority: '));
        }
    }
    @IsTest static void dataSeverityReflectsMeasuredImpact() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            delete [SELECT Id FROM Contact];
            List<Contact> contacts = new List<Contact>();
            for (Integer i=0;i<5;i++) contacts.add(new Contact(LastName='SYNTHETIC priority',
                Email=i<2 ? 'priority@example.invalid' : null));
            insert contacts;
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals(7,result.get('created'));
            Map<String,String> priorities = new Map<String,String>();
            for (Task task : [SELECT Subject,Priority,Description FROM Task]) {
                priorities.put(task.Subject,task.Priority);
                System.assert(!task.Description.startsWith('Assessment priority: Critical'));
            }
            System.assertEquals('High',priorities.get('AI Readiness: Review missing contact emails'));
            System.assertEquals('High',priorities.get('AI Readiness: Review possible duplicate contacts'));
            System.assertEquals('High',priorities.get('AI Readiness: Review unlinked contacts'));
            System.assertEquals('Low',priorities.get('AI Readiness: Confirm representative assessment data'));
        }
    }
    @IsTest static void suppressedAssessmentCreatesNoTasks() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            delete [SELECT Id FROM Contact];
            Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals('assessment_unavailable',result.get('error'));
            System.assertEquals(0,[SELECT COUNT() FROM Task]);
        }
    }
    @IsTest static void inventoryContainsOnlyAggregateEvidence() {
        String output = NonprofitAIReadiness.capabilityInventory();
        System.assert(!output.contains('sentinel'));
        System.assert(!output.contains('@'));
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(output);
        System.assert(((String)result.get('limitations')).contains('do not prove activity'));
        List<Object> capabilities = (List<Object>)result.get('capabilities');
        System.assertEquals(3,capabilities.size());
        for (Object entry : capabilities) {
            Map<String,Object> capability = (Map<String,Object>)entry;
            System.assertEquals('not_verified',capability.get('usage'));
            System.assertEquals(null,capability.get('visibleRecords'));
        }
        for (Object entry : (List<Object>)result.get('licenses')) {
            Map<String,Object> license = (Map<String,Object>)entry;
            System.assert(((Decimal)license.get('remaining')) >= 0);
            System.assertEquals(6,license.size());
            System.assertNotEquals(null,license.get('relevance'));
        }
    }
    @IsTest static void deletionLifecycleExcludesDeletedContact() {
        Map<String,Object> beforeResult = runScenario('organization');
        Decimal beforeCount = (Decimal)((Map<String,Object>)beforeResult.get('metrics')).get('contacts');
        Contact fictional = new Contact(LastName='SYNTHETIC erasure sentinel',
            Email='erasure-sentinel@example.invalid');
        insert fictional;
        Map<String,Object> insertedResult = runScenario('organization');
        System.assertEquals(beforeCount+1,
            ((Map<String,Object>)insertedResult.get('metrics')).get('contacts'));
        delete fictional;
        Map<String,Object> afterResult = runScenario('organization');
        System.assertEquals(beforeCount,
            ((Map<String,Object>)afterResult.get('metrics')).get('contacts'));
        // Soft deletion excludes current aggregates but remains recoverable, not legal erasure.
        System.assertEquals(1,[SELECT COUNT() FROM Contact WHERE Id=:fictional.Id AND IsDeleted=true ALL ROWS]);
        String output = NonprofitAIReadiness.assessScenario('organization');
        System.assert(!output.contains('erasure-sentinel'));
        System.assert(!output.contains('SYNTHETIC erasure'));
    }
    @IsTest static void licenseRelevanceFiltersUnrelatedProducts() {
        for (String label : new List<String>{'Salesforce','Agentforce','Einstein GPT','Copilot',
            'Prompt Builder','Data Cloud','Customer Data Platform','Fundraising','Digital Agent Fundraising'}) {
            System.assertNotEquals(null,NonprofitAIReadiness.licenseRelevance(label),label);
        }
        for (String label : new List<String>{'Chatter Free','Identity','Customer Community',
            'Health Cloud','Financial Services Cloud','Code Builder','Salesforce Integration'}) {
            System.assertEquals(null,NonprofitAIReadiness.licenseRelevance(label),label);
        }
        System.assertEquals(null,NonprofitAIReadiness.licenseRelevance(null));
        System.assert(NonprofitAIReadiness.licenseRelevance('Digital Agent Fundraising').contains('does not prove'));
    }
    @IsTest static void readOnlyAssessorCannotCreateFollowUpTasks() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1];
        User assessor = new User(ProfileId=profile.Id,
            Username='readiness-readonly-'+UserInfo.getOrganizationId()+'@example.invalid',
            Email='readonly@example.invalid',LastName='SYNTHETIC read-only',Alias='rdyread',
            TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert assessor;
        PermissionSet readOnly = [SELECT Id FROM PermissionSet WHERE Name='Readiness_Assessor' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId=assessor.Id,PermissionSetId=readOnly.Id);
        System.runAs(assessor) {
            List<Contact> fictional = new List<Contact>();
            for (Integer i=0;i<10;i++) fictional.add(new Contact(OwnerId=assessor.Id,
                LastName='SYNTHETIC read-only sentinel',Email='readonly-'+i+'@example.invalid'));
            // System-mode fixture setup does not grant the assessor write permissions.
            insert fictional;
            String assessmentOutput = NonprofitAIReadiness.assessScenario('organization');
            Map<String,Object> assessment = (Map<String,Object>)JSON.deserializeUntyped(assessmentOutput);
            System.assert(!assessment.containsKey('error'),'Read-only assessor must collect aggregate evidence');
            System.assert(!assessment.containsKey('staff_review'),'Missing staff outcome access must not expose saved evidence');
            System.assert(!assessmentOutput.contains('PRIVATE_REVIEW_REFERENCE_SENTINEL'));
            System.assert(((Decimal)((Map<String,Object>)assessment.get('metrics')).get('contacts')) >= 10);
            String taskOutput = NonprofitAIReadiness.createFollowUpTasks();
            System.assertEquals('task_creation_unavailable',
                ((Map<String,Object>)JSON.deserializeUntyped(taskOutput)).get('error'));
            System.assert(!taskOutput.contains('SELECT'));
            System.assert(!taskOutput.contains('sentinel'));
            System.assert(!taskOutput.contains('@'));
        }
        System.assertEquals(0,[SELECT COUNT() FROM Task WHERE OwnerId=:assessor.Id]);
    }
    @IsTest static void genericTaskRightsDoNotAuthorizeReadinessFollowUp() {
        User genericTaskUser = new User(ProfileId=UserInfo.getProfileId(),
            Username='readiness-generic-task-'+UserInfo.getOrganizationId()+'@example.invalid',
            Email='generic-task@example.invalid',LastName='SYNTHETIC generic Task rights',Alias='rdytask',
            TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert genericTaskUser;
        insert new PermissionSetAssignment(AssigneeId=genericTaskUser.Id,
            PermissionSetId=[SELECT Id FROM PermissionSet WHERE Name='Readiness_Assessor' LIMIT 1].Id);
        System.runAs(genericTaskUser) {
            System.assert(Schema.sObjectType.Task.isCreateable());
            System.assert(Schema.sObjectType.Task.isUpdateable());
            System.assert(!FeatureManagement.checkPermission('Readiness_Create_Follow_Up'));
            Integer queriesBefore = Limits.getQueries();
            Integer writesBefore = Limits.getDmlStatements();
            String output = NonprofitAIReadiness.createFollowUpTasks();
            System.assertEquals(queriesBefore,Limits.getQueries(),'Denied action must not collect evidence');
            System.assertEquals(writesBefore,Limits.getDmlStatements(),'Denied action must not write');
            System.assertEquals('{"error":"task_creation_unavailable"}',output);
        }
        System.assertEquals(0,[SELECT COUNT() FROM Task WHERE OwnerId=:genericTaskUser.Id]);
    }
    @IsTest static void nonAdminFollowUpPermissionCreatesAndRefreshesOnlyOwnTasks() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' LIMIT 1];
        User runner = new User(ProfileId=profile.Id,
            Username='readiness-followup-'+UserInfo.getOrganizationId()+'@example.invalid',
            Email='followup@example.invalid',LastName='SYNTHETIC follow-up',Alias='rdyflup',
            TimeZoneSidKey='Europe/Amsterdam',LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert runner;
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permission : [SELECT Id FROM PermissionSet
                WHERE Name IN ('Readiness_Assessor','Readiness_Follow_Up')]) {
            assignments.add(new PermissionSetAssignment(AssigneeId=runner.Id,PermissionSetId=permission.Id));
        }
        System.assertEquals(2,assignments.size());
        insert assignments;
        System.runAs(runner) {
            System.assert(FeatureManagement.checkPermission('Readiness_Create_Follow_Up'));
            System.assertEquals(false,Schema.sObjectType.Contact.isCreateable());
            System.assertEquals(false,Schema.sObjectType.Contact.isUpdateable());
            System.assertEquals(false,Schema.sObjectType.Contact.isDeletable());
            System.assertEquals(false,[SELECT Profile.PermissionsModifyAllData FROM User
                WHERE Id=:runner.Id].Profile.PermissionsModifyAllData);
            List<Contact> fictional = new List<Contact>();
            for (Integer i=0;i<10;i++) fictional.add(new Contact(OwnerId=runner.Id,
                LastName='SYNTHETIC follow-up sentinel',Email='followup-'+i+'@example.invalid'));
            // System-mode fixtures do not grant Contact writes to the runtime user.
            insert fictional;
            Map<String,Object> first = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assert(!first.containsKey('error'),'Optional permission must enable follow-up creation');
            List<Task> tasks = [SELECT Id,OwnerId,Description FROM Task WHERE OwnerId=:runner.Id WITH USER_MODE];
            Integer created = tasks.size();
            System.assert(created > 0);
            System.assertEquals(created,first.get('created'));
            for (Task task : tasks) {
                System.assertEquals(runner.Id,task.OwnerId);
                System.assert(!task.Description.contains('sentinel'));
                System.assert(!task.Description.contains('@example.invalid'));
            }
            update as user new Task(Id=tasks[0].Id,Description='Outdated recommendation');
            Map<String,Object> refreshed = (Map<String,Object>)JSON.deserializeUntyped(
                NonprofitAIReadiness.createFollowUpTasks());
            System.assertEquals(0,refreshed.get('created'));
            System.assertEquals(created,refreshed.get('reused'));
            System.assertEquals(1,refreshed.get('updated'));
            System.assert([SELECT Description FROM Task WHERE Id=:tasks[0].Id WITH USER_MODE]
                .Description.startsWith('Assessment priority: '));
        }
    }
    @IsTest static void cacheBatchQueries() {
        NonprofitAIReadiness.Request request = new NonprofitAIReadiness.Request();
        request.scenario='pilot';
        Test.startTest();
        List<NonprofitAIReadiness.Response> results = NonprofitAIReadiness.assess(
            new List<NonprofitAIReadiness.Request>{request,request});
        System.assertEquals(7,Limits.getQueries());
        Test.stopTest();
        System.assertEquals(2,results.size());
        System.assertEquals(results[0].output,results[1].output);
    }
    @IsTest static void unlimitedLicenseDoesNotLookLikeZeroSpareSeats() {
        Map<String,Object> row = NonprofitAIReadiness.licenseRow('Example',-1,3,'user');
        System.assertEquals(null,row.get('total'));
        System.assertEquals(null,row.get('remaining'));
        System.assertEquals(3,row.get('assigned'));
    }
    @IsTest static void standardTaskPriorityMapping() {
        System.assertEquals('High',NonprofitAIReadiness.taskPriority('Critical'));
        System.assertEquals('High',NonprofitAIReadiness.taskPriority('High'));
        System.assertEquals('Normal',NonprofitAIReadiness.taskPriority('Medium'));
        System.assertEquals('Low',NonprofitAIReadiness.taskPriority('Low'));
    }
    private static void saveStaffExercise(Boolean critical) {
        Map<String,Object> key = (Map<String,Object>)JSON.deserializeUntyped(ReadinessStaffReview.getQuestions());
        List<Object> reviews = new List<Object>();
        for (Object value : (List<Object>)key.get('questions')) {
            Map<String,Object> question = (Map<String,Object>)value;
            Map<String,String> actions = new Map<String,String>();
            for (Object action : (List<Object>)question.get('required_actions')) {
                actions.put((String)((Map<String,Object>)action).get('id'),'yes');
            }
            List<String> failures = new List<String>();
            if (critical && question.get('id') == 'sensitive_data') {
                failures.add((String)((Map<String,Object>)((List<Object>)question.get('critical_failures'))[0]).get('id'));
            }
            reviews.add(new Map<String,Object>{'question_id'=>question.get('id'),'answer'=>'yes',
                'reviewer_confirmed'=>true,'evidence_ref'=>'PRIVATE_REVIEW_REFERENCE_SENTINEL',
                'actions'=>actions,'critical_failures'=>failures});
        }
        insert new AI_Readiness_Staff_Review__c(Version__c=(String)key.get('version'),
            Snapshot__c=JSON.serialize(new Map<String,Object>{'version'=>key.get('version'),'mode'=>'actual','reviews'=>reviews}));
    }
    @IsTest static void organizationUsesOnlyOwnSafeStaffExercise() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            saveStaffExercise(false);
            Map<String,Object> result = runScenario('organization');
            System.assert(result.containsKey('staff_review'));
            Map<String,Object> review = (Map<String,Object>)result.get('staff_review');
            System.assertEquals(100,((Map<String,Object>)review.get('staff')).get('score'));
            System.assertEquals('Staff exercises: 100.0%. Checks passed: 7 of 7. Checks completed: 100.0% coverage. Scope: your saved exercises only; whole-team readiness is not established.',
                result.get('staff_summary'));
            System.assertEquals('readiness_not_established',result.get('decision'));
            for (Object value : (List<Object>)result.get('priorities')) {
                System.assert(!((String)((Map<String,Object>)value).get('key')).startsWith('staff'));
            }
            System.assert(!JSON.serialize(result).contains('PRIVATE_REVIEW_REFERENCE_SENTINEL'));
            Map<String,Object> practice = runScenario('pilot');
            System.assert(practice.containsKey('staff_review'),'Contact scope must retain the same own recorded staff assessment');
            System.assertEquals(review,practice.get('staff_review'));
            System.assertEquals(2,((List<Object>)practice.get('priorities')).size());
        }
    }
    @IsTest static void observedCriticalStaffFailureBlocksAndCreatesTargetedHighTask() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            saveStaffExercise(true);
            Map<String,Object> result = runScenario('organization');
            System.assertEquals('not_ready',result.get('decision'));
            System.assertEquals('Staff exercises: 85.7%. Checks passed: 6 of 7. Checks completed: 100.0% coverage. Scope: your saved exercises only; whole-team readiness is not established.',
                result.get('staff_summary'));
            Map<String,Object> first = (Map<String,Object>)((List<Object>)result.get('priorities'))[0];
            System.assertEquals('staff_sensitive_data',first.get('key'));
            System.assertEquals('Critical',first.get('priority'));
            System.assert(((String)first.get('recommendation')).contains('https://trailhead.salesforce.com/'));
            Map<String,Object> tasks = (Map<String,Object>)JSON.deserializeUntyped(NonprofitAIReadiness.createFollowUpTasks());
            System.assert(!tasks.containsKey('error'));
            List<Task> targeted = [SELECT Priority,Description FROM Task WHERE Subject='AI Readiness: Practice sensitive data handling'];
            System.assertEquals(1,targeted.size());
            System.assertEquals('High',targeted[0].Priority);
            System.assert(targeted[0].Description.contains('Assessment priority: Critical'));
            System.assert(!targeted[0].Description.contains('PRIVATE_REVIEW_REFERENCE_SENTINEL'));
            System.assertEquals(0,[SELECT COUNT() FROM Task WHERE Subject='AI Readiness: Complete staff readiness practice']);
        }
    }

}
