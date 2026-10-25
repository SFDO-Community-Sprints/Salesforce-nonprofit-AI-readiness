@IsTest
private class AIR_Tests {
    /**
     * Runs tests as the current (admin) user with the AIR_Admin permission set, so user-mode
     * queries see the AIR fields. Reusing the running user avoids consuming a licence.
     */
    private static User adminWithAccess() {
        Id userId = UserInfo.getUserId();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'AIR_Admin' LIMIT 1];
        if (
            [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :ps.Id] == 0
        ) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
        }
        return new User(Id = userId);
    }

    private static void createData() {
        Account acc = new Account(Name = 'AIR Household');
        insert acc;
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;
        Database.insert(
            new List<Contact>{
                new Contact(
                    LastName = 'Donor 1',
                    Email = 'one@example.com',
                    AccountId = acc.Id,
                    MailingPostalCode = '1000AA'
                ),
                new Contact(
                    LastName = 'Donor 1',
                    Email = 'one@example.com',
                    AccountId = acc.Id,
                    MailingPostalCode = '1000AA'
                ),
                new Contact(LastName = 'Donor 3', LeadSource = 'Other')
            },
            options
        );
    }

    private static String answersJson(List<AIR_Check__mdt> checks, String answer) {
        List<Map<String, Object>> answers = new List<Map<String, Object>>();
        for (AIR_Check__mdt c : checks) {
            answers.add(
                new Map<String, Object>{
                    'code' => c.DeveloperName,
                    'answer' => answer,
                    'notes' => 'Test note',
                    'responsible' => 'Test owner',
                    'dueDate' => '2030-01-31'
                }
            );
        }
        return JSON.serialize(answers);
    }

    private static User newUser(String profileName, String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        return new User(
            ProfileId = p.Id,
            LastName = alias,
            Alias = alias,
            Email = alias + '@example.com',
            Username = alias + '.' + Datetime.now().getTime() + '@air-test.example.com',
            TimeZoneSidKey = 'Europe/Amsterdam',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }

    @IsTest
    static void agentUserChecksFlagExcessAccess() {
        User agent = newUser('Standard User', 'airagent');
        User adminAgent = newUser('System Administrator', 'airadmin');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<User>{ agent, adminAgent };
            PermissionSet ps = new PermissionSet(Name = 'AIR_Test_Agent', Label = 'AIR Test Agent');
            insert ps;
            insert new ObjectPermissions(
                ParentId = ps.Id,
                SobjectType = 'Account',
                PermissionsRead = true,
                PermissionsViewAllRecords = true
            );
            insert new PermissionSetAssignment(AssigneeId = agent.Id, PermissionSetId = ps.Id);
        }
        System.runAs(adminWithAccess()) {
            AIR_Use_Case__c uc = new AIR_Use_Case__c(
                Name = 'Agent test',
                Agent_User__c = agent.Id,
                Grounding_Fields__c = 'Contact.Email'
            );
            insert uc;
            Test.startTest();
            AIR_CheckContext ctx = new AIR_CheckContext(uc);
            Assert.areEqual(AIR_Catalogue.PASSED, AIR_ScanService.evaluate('IntegrationUser', ctx).status);
            Assert.areEqual(AIR_Catalogue.PASSED, AIR_ScanService.evaluate('UserNoAllData', ctx).status);
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('UserNoObjectViewAll', ctx).status);
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('UserAccessMatchesScope', ctx).status);
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('UserApiOnly', ctx).status);
            Assert.isNotNull(AIR_ScanService.evaluate('UserSensitiveFields', ctx).status);
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('AgentLeastPrivilege', ctx).status);

            ctx.agentUserId = adminAgent.Id;
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('IntegrationUser', ctx).status);
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('UserNoAllData', ctx).status);
            Assert.isNotNull(AIR_ScanService.evaluate('UserSensitiveFields', ctx).status);
            // The new admin has never logged in, so it counts as dormant.
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('InactiveAdmins', ctx).status);
            Test.stopTest();
        }
    }

    @IsTest
    static void controllerHandlesEmptyStateAndErrors() {
        System.runAs(adminWithAccess()) {
            AIR_Controller.AssessmentDTO detail = AIR_Controller.getAssessmentDetail(null);
            Assert.isNull(detail.assessmentId);
            Assert.isFalse(detail.categories.isEmpty());

            AIR_Use_Case__c uc = new AIR_Use_Case__c(Name = 'Agent user test');
            insert uc;
            AIR_Controller.ChecklistDTO checklist = AIR_Controller.setAgentUser(uc.Id, UserInfo.getUserName());
            Assert.isNotNull(checklist);
            Assert.areEqual(
                UserInfo.getUserId(),
                [SELECT Agent_User__c FROM AIR_Use_Case__c WHERE Id = :uc.Id].Agent_User__c
            );
            List<AIR_Controller.UseCaseDTO> useCases = AIR_Controller.getUseCases();
            Assert.areEqual(1, useCases.size());

            try {
                AIR_Controller.setAgentUser(null, 'nobody');
                Assert.fail('Expected an error without a use case');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
        }
    }

    @IsTest
    static void consistencyChecksReadFieldMetadata() {
        System.runAs(adminWithAccess()) {
            createData();
            AIR_Use_Case__c uc = new AIR_Use_Case__c(
                Name = 'Consistency test',
                Grounding_Fields__c = 'Contact.MailingCountry\nContact.Description\nAIR_Use_Case__c.Business_Owner__c\nAIR_Use_Case__c.Description__c'
            );
            insert uc;
            AIR_CheckContext ctx = new AIR_CheckContext(uc);
            Test.startTest();
            // 2 of 4 grounding fields are long text.
            Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_ScanService.evaluate('FreeTextVolume', ctx).status);
            for (String handler : new List<String>{ 'TextShouldBePicklist', 'LookAlikeFields', 'FieldDescriptions' }) {
                AIR_CheckOutcome outcome = AIR_ScanService.evaluate(handler, ctx);
                Assert.areNotEqual(AIR_Catalogue.NOT_CHECKED, outcome.status, handler + ': ' + outcome.evidence);
            }
            AIR_CheckContext noScope = new AIR_CheckContext();
            for (
                String handler : new List<String>{
                    'FreeTextVolume',
                    'TextShouldBePicklist',
                    'LookAlikeFields',
                    'FieldDescriptions'
                }
            ) {
                Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate(handler, noScope).status);
            }
            Test.stopTest();
        }
        Assert.areEqual(
            AIR_AutomatedChecks.normalizeLabel('Preferred E-mail'),
            AIR_AutomatedChecks.normalizeLabel('preferred email')
        );
    }

    @IsTest
    static void specialCategoryDataIsRecognised() {
        Assert.areEqual('health', AIR_AutomatedChecks.sensitiveCategory('Medical Notes', 'Medical_Notes__c'));
        Assert.areEqual('religion', AIR_AutomatedChecks.sensitiveCategory(null, 'npsp__Religion__c'));
        Assert.areEqual('minors', AIR_AutomatedChecks.sensitiveCategory('Birthdate', 'Birthdate'));
        Assert.areEqual('vulnerability', AIR_AutomatedChecks.sensitiveCategory('Safeguarding flag', 'SafeguardingFlag__c'));
        Assert.isNull(AIR_AutomatedChecks.sensitiveCategory('Grace Period', 'Grace_Period__c'));
        Assert.isNull(AIR_AutomatedChecks.sensitiveCategory('Email', 'Email'));

        System.runAs(adminWithAccess()) {
            insert new Contact(LastName = 'Young supporter', Birthdate = Date.today().addYears(-10));
            AIR_Use_Case__c uc = new AIR_Use_Case__c(
                Name = 'Sensitive scope test',
                Grounding_Fields__c = 'Contact.Birthdate\nContact.Email'
            );
            insert uc;
            Test.startTest();
            AIR_CheckOutcome scope = AIR_ScanService.evaluate('SensitiveInScope', new AIR_CheckContext(uc));
            AIR_CheckOutcome org = AIR_ScanService.evaluate('SpecialCategoryFields', new AIR_CheckContext());
            Test.stopTest();
            Assert.areEqual(AIR_Catalogue.ATTENTION, scope.status, scope.evidence);
            Assert.isTrue(scope.evidence.contains('Contact.Birthdate'), scope.evidence);
            Assert.areNotEqual(AIR_Catalogue.NOT_CHECKED, org.status, org.evidence);
            Assert.isTrue(org.evidence.contains('under 18'), org.evidence);
            Assert.areEqual(
                AIR_Catalogue.NOT_CHECKED,
                AIR_ScanService.evaluate('SensitiveInScope', new AIR_CheckContext()).status
            );
        }
    }

    @IsTest
    static void standardUserWithPermissionSetCanUseTheApp() {
        User member = newUser('Standard User', 'airmembr');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert member;
            insert new PermissionSetAssignment(
                AssigneeId = member.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'AIR_Admin'].Id
            );
        }
        System.runAs(member) {
            Test.startTest();
            AIR_ScanService.runOrgScan();
            AIR_Controller.saveChecklist(
                AIR_Catalogue.LEVEL_COMPANY,
                null,
                answersJson(AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_COMPANY, AIR_Catalogue.TYPE_MANUAL), 'Yes'),
                null
            );
            AIR_Controller.DashboardDTO dash = AIR_Controller.getDashboard();
            Test.stopTest();
            Assert.isTrue(dash.hasScan);
            List<String> failures = new List<String>();
            for (AIR_Assessment_Result__c r : [SELECT Check_Code__c, Evidence__c FROM AIR_Assessment_Result__c]) {
                if (r.Evidence__c != null && r.Evidence__c.startsWith('Could not be evaluated')) {
                    failures.add(r.Check_Code__c + ': ' + r.Evidence__c);
                }
            }
            Assert.isTrue(failures.isEmpty(), 'Failed for a non-admin: ' + String.join(failures, ' || '));
        }
    }

    @IsTest
    static void scoringFollowsTheModel() {
        AIR_ScoreService.Summary s = new AIR_ScoreService.Summary();
        for (Integer i = 0; i < 8; i++) {
            s.add(AIR_Catalogue.PASSED, false);
        }
        for (Integer i = 0; i < 5; i++) {
            s.add(AIR_Catalogue.ATTENTION, false);
        }
        for (Integer i = 0; i < 20; i++) {
            s.add(AIR_Catalogue.NOT_CHECKED, true);
        }
        s.finish();
        // Same numbers as the mockup: 8 passed, 5 need attention, 20 not checked.
        Assert.isTrue(s.score == 24.2, 'score = passed / all, got ' + s.score);
        Assert.isTrue(s.coverage == 39.4, 'coverage = (passed + attention) / all, got ' + s.coverage);
        Assert.areEqual(AIR_ScoreService.HEALTH_ATTENTION, s.health);

        AIR_ScoreService.Summary empty = new AIR_ScoreService.Summary().finish();
        Assert.areEqual(AIR_ScoreService.HEALTH_NOT_CHECKED, empty.health);
        Assert.isTrue(empty.score == 0);

        AIR_ScoreService.Summary unanswered = new AIR_ScoreService.Summary();
        unanswered.add(AIR_Catalogue.NOT_CHECKED, false);
        Assert.areEqual(AIR_ScoreService.HEALTH_NOT_CHECKED, unanswered.finish().health);

        AIR_ScoreService.Summary blocked = new AIR_ScoreService.Summary();
        blocked.add(AIR_Catalogue.PASSED, false);
        blocked.add(AIR_Catalogue.ATTENTION, true);
        Assert.areEqual(AIR_ScoreService.HEALTH_BLOCKED, blocked.finish().health);
        Assert.areEqual(1, blocked.criticalFailures);

        AIR_ScoreService.Summary ready = new AIR_ScoreService.Summary();
        for (Integer i = 0; i < 4; i++) {
            ready.add(AIR_Catalogue.PASSED, true);
        }
        ready.add(AIR_Catalogue.ATTENTION, false);
        Assert.areEqual(AIR_ScoreService.HEALTH_READY, ready.finish().health);
        Assert.isTrue(ready.score == 80);
    }

    @IsTest
    static void answersMapToStatuses() {
        Assert.areEqual(AIR_Catalogue.PASSED, AIR_Catalogue.statusForAnswer('Yes'));
        Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_Catalogue.statusForAnswer('Partially'));
        Assert.areEqual(AIR_Catalogue.ATTENTION, AIR_Catalogue.statusForAnswer('No'));
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_Catalogue.statusForAnswer('Not sure'));
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_Catalogue.statusForAnswer(null));
        Assert.areEqual('Data quality', AIR_Catalogue.categoryLabel('DQ'));
        Assert.areEqual('XYZ', AIR_Catalogue.categoryLabel('XYZ'));
    }

    @IsTest
    static void parsesResourcesAndGroundingFields() {
        List<AIR_Catalogue.Resource> resources = AIR_Catalogue.parseResources('A|https://example.com\nB|TBD\n\nC');
        Assert.areEqual(3, resources.size());
        Assert.areEqual('https://example.com', resources[0].url);
        Assert.isNull(resources[1].url);
        Assert.isNull(resources[2].url);

        List<String> entries = AIR_CheckContext.parse('Contact.Email\nContact.Email, Account.Name; Bogus');
        Assert.areEqual(3, entries.size());

        AIR_CheckContext ctx = new AIR_CheckContext();
        ctx.groundingEntries = new List<String>{
            'Contact.Email',
            'Contact.NoSuchField__x',
            'NoSuchObject__x.Name',
            'Bogus'
        };
        List<String> invalid = new List<String>();
        List<AIR_CheckContext.FieldRef> refs = ctx.resolveFields(invalid);
        Assert.areEqual(1, refs.size());
        Assert.areEqual('Contact.Email', refs[0].label());
        Assert.areEqual(3, invalid.size());
        Assert.areEqual(new List<String>{ 'Contact' }, ctx.groundingObjects());
    }

    @IsTest
    static void helpersFormatValues() {
        Assert.areEqual('', AIR_AutomatedChecks.joinLimited(new List<String>(), 3));
        Assert.areEqual('a, b and 1 more', AIR_AutomatedChecks.joinLimited(new List<String>{ 'a', 'b', 'c' }, 2));
        Assert.areEqual('40%', AIR_AutomatedChecks.fmtPct(40.0));
        Assert.areEqual('38.5%', AIR_AutomatedChecks.fmtPct(38.5));
        Assert.areEqual('never', AIR_AutomatedChecks.fmtDate(null));
        Assert.isTrue(AIR_AutomatedChecks.pct(1, 0) == 0);
        Assert.isTrue(AIR_AutomatedChecks.hasObject('Contact'));
        Assert.isNotNull(AIR_AutomatedChecks.isoDaysAgo(1));
    }

    @IsTest
    static void unknownHandlersAreNotChecked() {
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('DoesNotExist', null).status);
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate(null, null).status);
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('NO_SCOPE', null).status);
        // An inner class that isn't a check.
        Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('UserAccess', null).status);
    }

    @IsTest
    static void unknownCategoriesAreKeptAndFieldListIsCapped() {
        AIR_Controller.ResultDTO odd = new AIR_Controller.ResultDTO();
        odd.category = 'OTHER';
        odd.status = AIR_Catalogue.PASSED;
        List<AIR_Controller.CategoryDTO> groups = AIR_Controller.groupByCategory(
            new List<AIR_Controller.ResultDTO>{ odd },
            true
        );
        Assert.areEqual(1, groups.size());
        Assert.areEqual('OTHER', groups[0].code);

        List<String> entries = new List<String>();
        for (String fieldName : Schema.SObjectType.Contact.fields.getMap().keySet()) {
            if (entries.size() < 31) {
                entries.add('Contact.' + fieldName);
            }
        }
        AIR_CheckContext ctx = new AIR_CheckContext(
            new AIR_Use_Case__c(Grounding_Fields__c = String.join(entries, '\n'))
        );
        List<String> invalid = new List<String>();
        ctx.resolveFields(invalid);
        Assert.isFalse(invalid.isEmpty());
    }

    @IsTest
    static void everyAutomatedHandlerReturnsAResult() {
        User u = adminWithAccess();
        System.runAs(u) {
            createData();
            AIR_Use_Case__c uc = new AIR_Use_Case__c(
                Name = 'Handler test',
                Grounding_Fields__c = 'Contact.Email\nContact.LeadSource\nContact.Description\nAccount.Name'
            );
            insert uc;
            AIR_CheckContext ctx = new AIR_CheckContext(uc);
            ctx.agentUserId = UserInfo.getUserId();
            Set<String> valid = new Set<String>{
                AIR_Catalogue.PASSED,
                AIR_Catalogue.ATTENTION,
                AIR_Catalogue.NOT_CHECKED
            };
            Test.startTest();
            for (AIR_Check__mdt check : AIR_Catalogue.all()) {
                if (check.Check_Type__c != AIR_Catalogue.TYPE_AUTOMATED) {
                    continue;
                }
                AIR_CheckOutcome outcome = AIR_ScanService.evaluate(check.Handler__c, ctx);
                Assert.isTrue(valid.contains(outcome.status), check.DeveloperName + ' returned ' + outcome.status);
                Assert.isTrue(String.isNotBlank(outcome.evidence), check.DeveloperName + ' has no evidence');
                Assert.isFalse(
                    outcome.evidence.startsWith('Unavailable: unknown automated handler'),
                    check.DeveloperName + ' handler missing'
                );
            }
            // Implementation handlers without scope report Not checked.
            AIR_CheckContext noScope = new AIR_CheckContext();
            Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('FieldFillRate', noScope).status);
            Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('PicklistOther', noScope).status);
            Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('ScopeFreshness', noScope).status);
            Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('IntegrationUser', noScope).status);
            Assert.areEqual(AIR_Catalogue.NOT_CHECKED, AIR_ScanService.evaluate('UserApiOnly', noScope).status);
            Test.stopTest();
        }
    }

    @IsTest
    static void orgScanCreatesOneResultPerCheck() {
        User u = adminWithAccess();
        System.runAs(u) {
            createData();
            Test.startTest();
            Id first = AIR_Controller.runOrgScan();
            Test.stopTest();

            Integer expected = AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_ORG).size();
            Assert.areEqual(expected, [SELECT COUNT() FROM AIR_Assessment_Result__c WHERE Assessment__c = :first]);
            AIR_Assessment__c a = [
                SELECT
                    Score__c,
                    Coverage__c,
                    Health__c,
                    Passed_Count__c,
                    Attention_Count__c,
                    Not_Checked_Count__c
                FROM AIR_Assessment__c
                WHERE Id = :first
            ];
            Assert.isNotNull(a.Health__c);
            Assert.areEqual(expected, (a.Passed_Count__c + a.Attention_Count__c + a.Not_Checked_Count__c).intValue());

            // Answer the manual org checks; a second scan carries the answers over.
            AIR_Controller.saveChecklist(
                AIR_Catalogue.LEVEL_ORG,
                null,
                answersJson(AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_ORG, AIR_Catalogue.TYPE_MANUAL), 'Yes'),
                null
            );
            Id second = AIR_ScanService.runOrgScan();
            Assert.areNotEqual(first, second);
            for (AIR_Assessment_Result__c r : [
                SELECT Status__c, Answer__c
                FROM AIR_Assessment_Result__c
                WHERE Assessment__c = :second AND Check_Type__c = 'Manual'
            ]) {
                Assert.areEqual('Yes', r.Answer__c);
                Assert.areEqual(AIR_Catalogue.PASSED, r.Status__c);
            }

            AIR_Controller.AssessmentDTO detail = AIR_Controller.getAssessmentDetail(null);
            Assert.areEqual(second, detail.assessmentId);
            Assert.isFalse(detail.categories.isEmpty());
            Assert.areEqual(expected, detail.summary.total);
            AIR_Controller.AssessmentDTO byId = AIR_Controller.getAssessmentDetail(first);
            Assert.areEqual(first, byId.assessmentId);
        }
    }

    @IsTest
    static void companyChecklistSavesAnswersAndOwners() {
        User u = adminWithAccess();
        System.runAs(u) {
            List<AIR_Check__mdt> manual = AIR_Catalogue.forLevel(
                AIR_Catalogue.LEVEL_COMPANY,
                AIR_Catalogue.TYPE_MANUAL
            );
            AIR_Controller.ChecklistDTO before = AIR_Controller.getChecklist(AIR_Catalogue.LEVEL_COMPANY, null);
            Assert.isNull(before.assessmentId);
            Assert.areEqual(AIR_ScoreService.HEALTH_NOT_CHECKED, before.summary.health);

            Map<String, Object> owners = new Map<String, Object>{
                'dpoName' => 'Dana DPO',
                'securityOwner' => 'Sam Security',
                'adminOwner' => 'Alex Admin',
                'stakeholders' => 'Board'
            };
            Test.startTest();
            AIR_Controller.ChecklistDTO after = AIR_Controller.saveChecklist(
                AIR_Catalogue.LEVEL_COMPANY,
                null,
                answersJson(manual, 'No'),
                JSON.serialize(owners)
            );
            Test.stopTest();

            Assert.isNotNull(after.assessmentId);
            Assert.areEqual('Dana DPO', after.owners.dpoName);
            Assert.areEqual('Board', after.owners.stakeholders);
            Assert.areEqual(manual.size(), after.summary.attention);
            Assert.areEqual(AIR_ScoreService.HEALTH_BLOCKED, after.summary.health);
            AIR_Assessment__c saved = [
                SELECT Health__c, Critical_Failures__c
                FROM AIR_Assessment__c
                WHERE Id = :after.assessmentId
            ];
            Assert.areEqual(AIR_ScoreService.HEALTH_BLOCKED, saved.Health__c);
            Assert.isTrue(saved.Critical_Failures__c > 0);

            AIR_Controller.DashboardDTO dash = AIR_Controller.getDashboard();
            Assert.isFalse(dash.hasScan);
            Assert.isTrue(dash.companyAnswered);
            Assert.areEqual(4, dash.categories.size());
            Assert.isFalse(dash.criticalFailures.isEmpty());
            Integer expectedTotal =
                AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_COMPANY).size() +
                AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_ORG).size();
            Assert.areEqual(expectedTotal, dash.overall.total);
        }
    }

    @IsTest
    static void dashboardAfterScan() {
        User u = adminWithAccess();
        System.runAs(u) {
            createData();
            AIR_ScanService.runOrgScan();
            Test.startTest();
            AIR_Controller.DashboardDTO dash = AIR_Controller.getDashboard();
            Test.stopTest();
            Assert.isTrue(dash.hasScan);
            Assert.isFalse(dash.scanStale);
            Assert.isNotNull(dash.lastScanDate);
            Assert.areEqual('Data quality', dash.categories[0].label);
            Assert.areEqual('Privacy and erasure', dash.categories[3].label);
        }
    }

    @IsTest
    static void implementationAssessmentPerUseCase() {
        User u = adminWithAccess();
        System.runAs(u) {
            createData();
            AIR_Use_Case__c uc = new AIR_Use_Case__c(
                Name = 'Donor FAQ agent',
                Status__c = 'Approved',
                Business_Owner__c = 'Fundraising lead',
                Grounding_Fields__c = 'Contact.Email\nContact.LeadSource'
            );
            insert uc;

            List<AIR_Check__mdt> manual = AIR_Catalogue.forLevel(
                AIR_Catalogue.LEVEL_IMPLEMENTATION,
                AIR_Catalogue.TYPE_MANUAL
            );
            Test.startTest();
            AIR_Controller.ChecklistDTO result = AIR_Controller.saveChecklist(
                AIR_Catalogue.LEVEL_IMPLEMENTATION,
                uc.Id,
                answersJson(manual, 'Yes'),
                null
            );
            AIR_Controller.ChecklistDTO rerun = AIR_Controller.runUseCaseChecks(uc.Id);
            Test.stopTest();

            Assert.areEqual('Donor FAQ agent', result.useCaseName);
            Assert.areEqual(manual.size(), result.summary.passed - countPassed(result.automated));
            Assert.isFalse(rerun.automated.isEmpty());
            for (AIR_Controller.ResultDTO r : rerun.automated) {
                Assert.areNotEqual('Not run yet.', r.evidence, r.code + ' was not run');
            }

            // Register the AI integration user by username; using your own account needs attention.
            AIR_Controller.ChecklistDTO withUser = AIR_Controller.setAgentUser(
                uc.Id,
                [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()].Username
            );
            Assert.isNotNull(withUser.agentUser);
            Assert.areEqual(UserInfo.getUserId(), withUser.agentUser.id);
            for (AIR_Controller.ResultDTO r : withUser.automated) {
                if (r.code == 'U01_IntegrationUser') {
                    Assert.areEqual(AIR_Catalogue.ATTENTION, r.status, r.evidence);
                }
            }
            Boolean badUser = false;
            try {
                AIR_Controller.setAgentUser(uc.Id, 'nobody@nowhere.invalid');
            } catch (AuraHandledException e) {
                badUser = true;
            }
            Assert.isTrue(badUser, 'Unknown usernames must fail');

            List<AIR_Controller.UseCaseDTO> useCases = AIR_Controller.getUseCases();
            Assert.areEqual(1, useCases.size());
            Assert.isNotNull(useCases[0].assessmentId);
            Assert.isNotNull(useCases[0].health);

            Boolean threw = false;
            try {
                AIR_Controller.saveChecklist(AIR_Catalogue.LEVEL_IMPLEMENTATION, null, '[]', null);
            } catch (AuraHandledException e) {
                threw = true;
            }
            Assert.isTrue(threw, 'Implementation without a use case must fail');
        }
    }

    @IsTest
    static void useCaseWithoutAssessmentIsNotChecked() {
        User u = adminWithAccess();
        System.runAs(u) {
            insert new AIR_Use_Case__c(Name = 'Idea only', Status__c = 'Idea');
            List<AIR_Controller.UseCaseDTO> useCases = AIR_Controller.getUseCases();
            Assert.areEqual(AIR_ScoreService.HEALTH_NOT_CHECKED, useCases[0].health);
            AIR_Controller.AssessmentDTO detail = AIR_Controller.getAssessmentDetail(null);
            Assert.isNull(detail.assessmentId);
            Assert.isFalse(detail.categories.isEmpty());
        }
    }

    private static Integer countPassed(List<AIR_Controller.ResultDTO> dtos) {
        Integer n = 0;
        for (AIR_Controller.ResultDTO d : dtos) {
            if (d.status == AIR_Catalogue.PASSED) {
                n++;
            }
        }
        return n;
    }
}
