public with sharing class NonprofitAIReadiness {
    public class Request {
        @InvocableVariable(required=true label='Practice assessment' description='Use organization to assess accessible records, or poor, improving, pilot, blocked, unknown for practice.')
        public String scenario;
    }
    public class Response {
        @InvocableVariable(label='Assessment summary' description='Data readiness results only. Technical and staff readiness remain unknown.')
        public String output;
    }
    private static final Set<String> SCENARIOS = new Set<String>{'organization','poor','improving','pilot','blocked','unknown'};

    @InvocableMethod(label='Assess Nonprofit AI Readiness' description='Assess accessible organization records or fixed practice data with user permissions. Return aggregates only, suppress groups smaller than five, and never return personal values.')
    public static List<Response> assess(List<Request> requests) {
        List<Response> results = new List<Response>();
        Map<String, String> cache = new Map<String, String>();
        if (requests == null) return results;
        for (Request request : requests) {
            Response response = new Response();
            if (request == null || !SCENARIOS.contains(request.scenario)) {
                response.output = JSON.serialize(new Map<String,Object>{'error'=>'invalid_scenario'});
            } else {
                if (!cache.containsKey(request.scenario)) {
                    try {
                        cache.put(request.scenario, JSON.serialize(collect(request.scenario)));
                    } catch (Exception ignored) {
                        // Exception text may contain data or query details.
                        cache.put(request.scenario, JSON.serialize(new Map<String,Object>{'error'=>'assessment_unavailable'}));
                    }
                }
                response.output = cache.get(request.scenario);
            }
            results.add(response);
        }
        return results;
    }

    @AuraEnabled
    public static String assessScenario(String scenario) {
        Request request = new Request();
        request.scenario = scenario;
        return assess(new List<Request>{request})[0].output;
    }

    @AuraEnabled
    public static String createFollowUpTasks() {
        Savepoint writeBoundary;
        try {
            Map<String,Object> assessment = collect('organization');
            if (assessment.containsKey('error') ||
                (Boolean)((Map<String,Object>)assessment.get('privacy')).get('suppressed')) {
                return JSON.serialize(new Map<String,Object>{'error'=>'assessment_unavailable'});
            }
            Map<String,String> recommendations = new Map<String,String>();
            Map<String,String> severity = new Map<String,String>();
            Map<String,String> impacts = new Map<String,String>();
            Map<String,String> subjectByKey = recommendationSubjects();
            for (Map<String,String> item : (List<Map<String,String>>)assessment.get('priorities')) {
                String subject = subjectByKey.get(item.get('key'));
                recommendations.put(subject,item.get('recommendation'));
                severity.put(subject,item.get('priority'));
                impacts.put(subject,item.get('impact'));
            }
            Id ownerId = UserInfo.getUserId();
            Set<String> subjects = recommendations.keySet();
            // shortcut: concurrent sessions can race, use a unique follow-up key if shared execution is required.
            Set<String> existing = new Set<String>();
            List<Task> updates = new List<Task>();
            for (Task task : [SELECT Id,Subject,Priority,Description FROM Task WHERE OwnerId = :ownerId
                AND Subject IN :subjects AND IsClosed = false WITH USER_MODE]) {
                existing.add(task.Subject);
                String priority = taskPriority(severity.get(task.Subject));
                String description = 'Assessment priority: '+severity.get(task.Subject)+
                    '\nImpact: '+impacts.get(task.Subject)+'\nNext step: '+recommendations.get(task.Subject);
                if (task.Priority != priority || task.Description != description) {
                    updates.add(new Task(Id=task.Id,Priority=priority,Description=description));
                }
            }
            List<Task> tasks = new List<Task>();
            for (String subject : subjects) {
                if (!existing.contains(subject)) tasks.add(new Task(OwnerId=ownerId,Subject=subject,
                    Description='Assessment priority: '+severity.get(subject)+'\nImpact: '+impacts.get(subject)+
                        '\nNext step: '+recommendations.get(subject),Status='Not Started',
                    Priority=taskPriority(severity.get(subject))));
            }
            if (!tasks.isEmpty() || !updates.isEmpty()) {
                writeBoundary = Database.setSavepoint();
                if (!tasks.isEmpty()) insert as user tasks;
                if (!updates.isEmpty()) update as user updates;
            }
            return JSON.serialize(new Map<String,Object>{'created'=>tasks.size(),'reused'=>existing.size(),'updated'=>updates.size()});
        } catch (Exception ignored) {
            if (writeBoundary != null) Database.rollback(writeBoundary);
            return JSON.serialize(new Map<String,Object>{'error'=>'task_creation_unavailable'});
        }
    }

    private static Map<String,String> recommendationSubjects() {
        return new Map<String,String>{
            'controls'=>'AI Readiness: Review access and safeguards',
            'privacy'=>'AI Readiness: Review erasure request process',
            'staff'=>'AI Readiness: Complete staff readiness practice',
            'sufficient_data'=>'AI Readiness: Confirm representative assessment data',
            'email_completeness'=>'AI Readiness: Review missing contact emails',
            'account_linkage'=>'AI Readiness: Review unlinked contacts',
            'duplicate_indicator'=>'AI Readiness: Review possible duplicate contacts'
        };
    }

    private static List<Map<String,String>> assessmentPriorities(Map<String,String> checks, Map<String,Object> metrics) {
        Map<String,String> recommendations = new Map<String,String>{
            'AI Readiness: Review access and safeguards'=>
                'Verify least-privilege access, permitted actions, approvals, monitoring and stop controls before an AI pilot. Technical readiness remains unknown. https://trailhead.salesforce.com/content/learn/modules/data_security',
            'AI Readiness: Review erasure request process'=>
                'Privacy lead: verify deletion requests cover Salesforce and its Recycle Bin, backups, integrations, exports and AI logs, including applicable retention obligations. Soft deletion alone does not establish erasure or compliance. https://www.edpb.europa.eu/sme/be-compliant/respect-individuals-rights_en',
            'AI Readiness: Complete staff readiness practice'=>
                'Complete the seven staff scenarios covering sensitive data, untrusted content, human review and incident response. Staff readiness remains unknown. https://trailhead.salesforce.com/content/learn/modules/trusted-agentic-ai/discover-how-salesforce-builds-trusted-agentic-ai'
        };
        if (checks.get('sufficient_data') == 'fail') recommendations.put(
            'AI Readiness: Confirm representative assessment data',
            'Confirm the accessible Contacts represent the intended AI use case and provide sufficient test data. https://trailhead.salesforce.com/content/learn/trails/prepare-your-data-for-ai');
        if (checks.get('email_completeness') == 'fail') recommendations.put(
            'AI Readiness: Review missing contact emails',
            'Review missing contact emails against the approved contact-channel requirement. Do not invent values or assume email is universally required. https://trailhead.salesforce.com/content/learn/trails/prepare-your-data-for-ai');
        if (checks.get('account_linkage') == 'fail') recommendations.put(
            'AI Readiness: Review unlinked contacts',
            'Review Contacts without Account relationships and correct only verified relationships. https://trailhead.salesforce.com/content/learn/trails/prepare-your-data-for-ai');
        if (checks.get('duplicate_indicator') == 'fail') recommendations.put(
            'AI Readiness: Review possible duplicate contacts',
            'Review repeated populated emails as duplicate indicators; do not automatically merge people. https://trailhead.salesforce.com/content/learn/modules/sales_admin_duplicate_management/sales_admin_duplicate_management_unit_2');
        Integer contacts = metrics == null ? 0 : (Integer)metrics.get('contacts');
        Map<String,String> severity = new Map<String,String>{
            'AI Readiness: Review access and safeguards'=>'High',
            'AI Readiness: Review erasure request process'=>'High',
            'AI Readiness: Complete staff readiness practice'=>'Medium',
            'AI Readiness: Confirm representative assessment data'=>'Low',
            'AI Readiness: Review missing contact emails'=>
                contacts > 0 && (Integer)metrics.get('email_present') * 100 < contacts * 50 ? 'High' : 'Medium',
            'AI Readiness: Review unlinked contacts'=>
                contacts > 0 && (contacts-(Integer)metrics.get('linked_contacts')) * 100 > contacts * 20 ? 'High' : 'Medium',
            'AI Readiness: Review possible duplicate contacts'=>
                contacts > 0 && (Integer)metrics.get('repeated_email_rows') * 100 >= contacts * 10 ? 'High' : 'Medium'
        };
        Map<String,String> impacts = new Map<String,String>{
            'AI Readiness: Review access and safeguards'=>'Unverified controls could permit inappropriate access or consequential actions.',
            'AI Readiness: Review erasure request process'=>'Unverified deletion handling could retain personal data across connected systems.',
            'AI Readiness: Complete staff readiness practice'=>'Unverified staff practice can lead to unsafe handling or unsupported decisions.',
            'AI Readiness: Confirm representative assessment data'=>'A small accessible dataset limits confidence in the assessment.',
            'AI Readiness: Review missing contact emails'=>'Missing approved contact-channel data can limit useful donor summaries.',
            'AI Readiness: Review unlinked contacts'=>'Missing relationships can produce incomplete or misleading context.',
            'AI Readiness: Review possible duplicate contacts'=>'Repeated emails can cause ambiguous identity and misleading summaries.'
        };
        List<Map<String,String>> priorities = new List<Map<String,String>>();
        Map<String,String> subjects = recommendationSubjects();
        for (String priority : new List<String>{'Critical','High','Medium','Low'}) {
            for (String key : new List<String>{'controls','privacy','staff','email_completeness',
                'duplicate_indicator','account_linkage','sufficient_data'}) {
                String subject = subjects.get(key);
                if (recommendations.containsKey(subject) && severity.get(subject) == priority) {
                    priorities.add(new Map<String,String>{'key'=>key,'priority'=>priority,
                        'impact'=>impacts.get(subject),'recommendation'=>recommendations.get(subject)});
                }
            }
        }
        return priorities;
    }

    @TestVisible private static String taskPriority(String severity) {
        return severity == 'Critical' || severity == 'High' ? 'High' : (severity == 'Low' ? 'Low' : 'Normal');
    }

    @AuraEnabled
    public static String capabilityInventory() {
        List<Map<String,Object>> licenses = new List<Map<String,Object>>();
        Map<String,String> sections = new Map<String,String>();
        try {
            List<UserLicense> userLicenses = [SELECT Name,TotalLicenses,UsedLicenses FROM UserLicense
                WITH USER_MODE ORDER BY Name LIMIT 50];
            for (UserLicense license : userLicenses) {
                if (licenseRelevance(license.Name) != null) licenses.add(licenseRow(
                    license.Name,license.TotalLicenses,license.UsedLicenses,'user'));
            }
            sections.put('user_licenses',userLicenses.size() == 50 ? 'limited' : 'available');
        } catch (Exception ignored) {
            sections.put('user_licenses','unavailable');
        }
        try {
            List<PermissionSetLicense> permissionLicenses = [SELECT MasterLabel,TotalLicenses,UsedLicenses
                FROM PermissionSetLicense WITH USER_MODE ORDER BY MasterLabel LIMIT 100];
            for (PermissionSetLicense license : permissionLicenses) {
                if (licenseRelevance(license.MasterLabel) != null) licenses.add(licenseRow(
                    license.MasterLabel,license.TotalLicenses,license.UsedLicenses,'permission_set'));
            }
            sections.put('permission_set_licenses',permissionLicenses.size() == 100 ? 'limited' : 'available');
        } catch (Exception ignored) {
            sections.put('permission_set_licenses','unavailable');
        }
        List<Map<String,Object>> capabilities = new List<Map<String,Object>>();
        Map<String,String> objects = new Map<String,String>{'GiftTransaction'=>'Fundraising',
            'Case'=>'Service cases','KnowledgeArticleVersion'=>'Knowledge'};
        Map<String,Schema.SObjectType> schema = Schema.getGlobalDescribe();
        for (String objectName : objects.keySet()) {
            Map<String,Object> capability = new Map<String,Object>{'name'=>objects.get(objectName),
                'availability'=>'unknown','visibleRecords'=>null,'usage'=>'not_verified'};
            if (schema.containsKey(objectName) && schema.get(objectName).getDescribe().isAccessible()) {
                capability.put('availability','available');
                try {
                    Integer records = Database.countQuery('SELECT COUNT() FROM '+objectName,AccessLevel.USER_MODE);
                    if (records >= 5) capability.put('visibleRecords',records);
                } catch (Exception ignored) {
                    capability.put('availability','unknown');
                }
            }
            capabilities.add(capability);
        }
        return JSON.serialize(new Map<String,Object>{'licenses'=>licenses,'capabilities'=>capabilities,
            'sections'=>sections,'limitations'=>'AI-related license overview, not a complete licensing audit. License assignments do not prove activity; visible record counts are not usage. Record counts below five are withheld. Inventory is bounded and reflects current user access.'});
    }

    @TestVisible private static Map<String,Object> licenseRow(String name,Integer total,Integer assigned,String kind) {
        return new Map<String,Object>{'name'=>name,'total'=>total == null || total < 0 ? null : total,'assigned'=>assigned,
            'remaining'=>total == null || total < 0 || assigned == null ? null : Math.max(0,total-assigned),'kind'=>kind,'relevance'=>licenseRelevance(name)};
    }

    @TestVisible private static String licenseRelevance(String name) {
        if (name == null) return null;
        String label = name.toLowerCase();
        if (label == 'salesforce') return 'Core Salesforce access for assessment';
        if (label.contains('fundraising') && (label.contains('agent') || label.contains('einstein')))
            return 'Fundraising agent entitlement; assignment does not prove the feature is enabled';
        if (label.contains('data cloud') || label.contains('customer data platform'))
            return 'Data grounding option; not required for every AI use case';
        if (label.contains('agentforce') || label.contains('einstein') || label.contains('copilot') || label.contains('prompt'))
            return 'AI feature entitlement; verify setup and use-case requirements';
        if (label.contains('fundraising')) return 'Fundraising grounding; does not itself enable AI';
        return null;
    }

    private static Map<String,Object> collect(String scenario) {
        Boolean organization = scenario == 'organization';
        Id accountId;
        if (!organization) {
            String cohort = 'SYNTHETIC AI Readiness ' + scenario;
            List<Account> accounts = [SELECT Id FROM Account WHERE Name = :cohort WITH USER_MODE LIMIT 2];
            if (accounts.size() != 1) return new Map<String,Object>{'error'=>'cohort_unavailable'};
            accountId = accounts[0].Id;
        }
        AggregateResult counts;
        if (organization) {
            counts = [SELECT COUNT(Id) contacts, COUNT(Email) email_present,
                COUNT(AccountId) linked_contacts FROM Contact WITH USER_MODE];
        } else {
            counts = [SELECT COUNT(Id) contacts, COUNT(Email) email_present,
                COUNT(AccountId) linked_contacts FROM Contact WHERE AccountId = :accountId WITH USER_MODE];
        }
        Integer n = (Integer)counts.get('contacts');
        Integer populated = (Integer)counts.get('email_present');
        Integer linked = (Integer)counts.get('linked_contacts');
        Boolean suppressed = n < 5;
        Integer repeated = 0;
        if (!suppressed) {
            List<AggregateResult> duplicates;
            if (organization) {
                duplicates = [SELECT COUNT(Id) repeated_count FROM Contact
                    WHERE Email != null WITH USER_MODE GROUP BY Email HAVING COUNT(Id) > 1];
            } else {
                duplicates = [SELECT COUNT(Id) repeated_count FROM Contact
                    WHERE AccountId = :accountId AND Email != null WITH USER_MODE
                    GROUP BY Email HAVING COUNT(Id) > 1];
            }
            for (AggregateResult duplicate : duplicates) {
                repeated += (Integer)duplicate.get('repeated_count') - 1;
            }
        }
        Map<String,String> checks = new Map<String,String>{'sufficient_data'=>'unknown',
            'email_completeness'=>'unknown','account_linkage'=>'unknown','duplicate_indicator'=>'unknown'};
        Integer passed = 0;
        if (!suppressed) {
            checks.put('sufficient_data', n >= 10 ? 'pass' : 'fail');
            checks.put('email_completeness', populated * 100 >= n * 90 ? 'pass' : 'fail');
            checks.put('account_linkage', linked == n ? 'pass' : 'fail');
            checks.put('duplicate_indicator', repeated == 0 ? 'pass' : 'fail');
            for (String status : checks.values()) if (status == 'pass') passed++;
        }
        return new Map<String,Object>{
            'rubric_version'=>'donor-summary-demo-v1', 'evidence_mode'=>'live_aggregate',
            'scenario'=>scenario, 'scope'=>organization ? 'accessible_organization_records' : 'fixed_synthetic_demo_cohort',
            'coverage_note'=>'Only records accessible to the current user are assessed; this is not proof of complete organization visibility.',
            'metrics'=>suppressed ? null : new Map<String,Integer>{'contacts'=>n,'email_present'=>populated,
                'linked_contacts'=>linked,'repeated_email_rows'=>repeated},
            'data'=>new Map<String,Object>{'checks'=>checks,'passed'=>passed,'applicable'=>4,
                'score'=>suppressed ? null : passed * 25.0,'coverage'=>suppressed ? 0.0 : 100.0},
            'privacy'=>new Map<String,Object>{'mode'=>'aggregate_only','minimum_cohort'=>5,'suppressed'=>suppressed},
            'technical_and_staff'=>'unknown; not exercised','decision'=>'readiness_not_established',
            'priorities'=>assessmentPriorities(checks,suppressed ? null : new Map<String,Object>{
                'contacts'=>n,'email_present'=>populated,'linked_contacts'=>linked,'repeated_email_rows'=>repeated})
        };
    }
}
