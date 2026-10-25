/**
 * Automated AI readiness checks. Each public inner class is one handler, referenced by
 * name from AIR_Check__mdt.Handler__c and instantiated by AIR_ScanService.
 *
 * All queries are dynamic so the class compiles in every org, including orgs without
 * Knowledge, Nonprofit Cloud, NPSP, Shield or Agentforce. AIR_ScanService catches any
 * exception and reports the check as "Not checked" with the reason.
 * Setup queries are read-only.
 */
public with sharing class AIR_AutomatedChecks {
    public static final Set<String> DONOR_OBJECTS = new Set<String>{
        'account',
        'contact',
        'opportunity',
        'case',
        'lead',
        'campaign',
        'npe01__opppayment__c',
        'npe03__recurring_donation__c',
        'gifttransaction',
        'giftcommitment'
    };

    public static final List<String> LLM_HOSTS = new List<String>{
        'openai.com',
        'anthropic.com',
        'generativelanguage.googleapis.com',
        'aiplatform.googleapis.com',
        'openai.azure.com',
        'cognitiveservices.azure.com',
        'bedrock',
        'mistral.ai',
        'cohere',
        'huggingface.co',
        'groq.com',
        'perplexity.ai'
    };

    // ------------------------------------------------------------------ helpers

    public static Integer countOf(String soql) {
        return Database.countQuery(soql, AccessLevel.SYSTEM_MODE);
    }

    public static List<SObject> rows(String soql) {
        return Database.query(soql, AccessLevel.SYSTEM_MODE);
    }

    public static List<SObject> rows(String soql, Map<String, Object> binds) {
        return Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE);
    }

    /** SOQL datetime literal for n days ago. */
    public static String isoDaysAgo(Integer days) {
        return Datetime.now().addDays(-days).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    public static Boolean hasObject(String name) {
        return Schema.getGlobalDescribe().containsKey(name.toLowerCase());
    }

    public static String joinLimited(List<String> items, Integer max) {
        if (items == null || items.isEmpty()) {
            return '';
        }
        List<String> shown = new List<String>();
        for (Integer i = 0; i < items.size() && i < max; i++) {
            shown.add(items[i]);
        }
        String text = String.join(shown, ', ');
        if (items.size() > max) {
            text += ' and ' + (items.size() - max) + ' more';
        }
        return text;
    }

    public static Decimal pct(Integer part, Integer total) {
        if (total == null || total == 0) {
            return 0;
        }
        return (Decimal.valueOf(part) * 100 / total).setScale(1, RoundingMode.HALF_UP);
    }

    public static String fmtPct(Decimal value) {
        return value.stripTrailingZeros().toPlainString() + '%';
    }

    public static String fmtDate(Datetime value) {
        return value == null ? 'never' : value.format('d MMM yyyy');
    }

    public static Object path(SObject record, String dottedPath) {
        List<String> parts = dottedPath.split('\\.');
        SObject current = record;
        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (current == null) {
                return null;
            }
            current = current.getSObject(parts[i]);
        }
        return current == null ? null : current.get(parts[parts.size() - 1]);
    }

    public static Map<String, SObject> entityDefinitions(List<String> objectNames) {
        Map<String, SObject> result = new Map<String, SObject>();
        for (
            SObject ed : rows(
                'SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition ' +
                'WHERE QualifiedApiName IN :names',
                new Map<String, Object>{ 'names' => objectNames }
            )
        ) {
            result.put((String) ed.get('QualifiedApiName'), ed);
        }
        return result;
    }

    // ------------------------------------------------------------------ T1 external interfaces

    public class StaleOAuthApps implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            // OauthToken is read through an internal callout, which fails after DML.
            if (Limits.getDmlStatements() > 0 && !Test.isRunningTest()) {
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: connected app tokens can only be read when the scan runs on its own. Run the org scan again.'
                );
            }
            List<SObject> tokens = rows('SELECT AppName, LastUsedDate FROM OauthToken LIMIT 5000');
            if (tokens.isEmpty()) {
                return AIR_CheckOutcome.passed('No connected apps hold OAuth tokens.');
            }
            Map<String, Datetime> lastUse = new Map<String, Datetime>();
            for (SObject t : tokens) {
                String app = (String) t.get('AppName');
                Datetime used = (Datetime) t.get('LastUsedDate');
                Datetime current = lastUse.get(app);
                if (!lastUse.containsKey(app) || (used != null && (current == null || used > current))) {
                    lastUse.put(app, used);
                }
            }
            Datetime cutoff = Datetime.now().addDays(-180);
            List<String> stale = new List<String>();
            for (String app : lastUse.keySet()) {
                Datetime used = lastUse.get(app);
                if (used == null || used < cutoff) {
                    stale.add(app + ' (last used ' + fmtDate(used) + ')');
                }
            }
            String evidence =
                lastUse.size() +
                ' connected app(s) hold OAuth tokens: ' +
                joinLimited(new List<String>(lastUse.keySet()), 10) +
                '.';
            if (stale.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence + ' All were used in the last 180 days.');
            }
            return AIR_CheckOutcome.attention(
                evidence + ' Unused for more than 180 days: ' + joinLimited(stale, 10) + '.'
            );
        }
    }

    public class InsecureEndpoints implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<SObject> creds = rows('SELECT DeveloperName, Endpoint FROM NamedCredential LIMIT 1000');
            List<String> insecure = new List<String>();
            for (SObject c : creds) {
                String endpoint = (String) c.get('Endpoint');
                if (endpoint != null && endpoint.toLowerCase().startsWith('http://')) {
                    insecure.add(c.get('DeveloperName') + ' (' + endpoint + ')');
                }
            }
            if (creds.isEmpty()) {
                return AIR_CheckOutcome.passed('No named credentials are configured.');
            }
            if (insecure.isEmpty()) {
                return AIR_CheckOutcome.passed(creds.size() + ' named credential(s) checked; none use http://.');
            }
            return AIR_CheckOutcome.attention('Unencrypted endpoints: ' + joinLimited(insecure, 10) + '.');
        }
    }

    public class GuestDonorAccess implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<SObject> perms = rows(
                'SELECT SobjectType, Parent.Profile.Name FROM ObjectPermissions ' +
                    'WHERE PermissionsRead = true AND Parent.IsOwnedByProfile = true ' +
                    'AND Parent.Profile.UserType = \'Guest\' LIMIT 5000'
            );
            List<String> exposed = new List<String>();
            for (SObject p : perms) {
                String objectName = (String) p.get('SobjectType');
                if (objectName != null && DONOR_OBJECTS.contains(objectName.toLowerCase())) {
                    exposed.add(path(p, 'Parent.Profile.Name') + ': ' + objectName);
                }
            }
            if (exposed.isEmpty()) {
                return AIR_CheckOutcome.passed('No guest user profile can read donor objects.');
            }
            return AIR_CheckOutcome.attention(
                'Guest profiles with read access to donor data: ' + joinLimited(exposed, 15) + '.'
            );
        }
    }

    public class ApiAccess implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<SObject> agg = rows(
                'SELECT COUNT_DISTINCT(AssigneeId) c FROM PermissionSetAssignment ' +
                    'WHERE PermissionSet.PermissionsApiEnabled = true AND Assignee.IsActive = true ' +
                    'AND Assignee.UserType = \'Standard\''
            );
            Integer apiUsers = agg.isEmpty() ? 0 : (Integer) agg[0].get('c');
            Integer active = countOf('SELECT COUNT() FROM User WHERE IsActive = true AND UserType = \'Standard\'');
            String evidence =
                apiUsers +
                ' of ' +
                active +
                ' active users (' +
                fmtPct(pct(apiUsers, active)) +
                ') have API Enabled.';
            if (apiUsers <= 5 || pct(apiUsers, active) <= 25) {
                return AIR_CheckOutcome.passed(evidence);
            }
            return AIR_CheckOutcome.attention(evidence);
        }
    }

    // ------------------------------------------------------------------ T2 sensitive data

    public class DataClassification implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> classified = new List<String>();
            for (String objectName : new List<String>{ 'Contact', 'Account', 'Lead', 'Opportunity' }) {
                for (
                    SObject fd : rows(
                        'SELECT QualifiedApiName, SecurityClassification FROM FieldDefinition ' +
                        'WHERE EntityDefinition.QualifiedApiName = :obj',
                        new Map<String, Object>{ 'obj' => objectName }
                    )
                ) {
                    if (fd.get('SecurityClassification') != null) {
                        classified.add(objectName + '.' + fd.get('QualifiedApiName'));
                    }
                }
            }
            if (classified.size() >= 5) {
                return AIR_CheckOutcome.passed(
                    classified.size() +
                        ' field(s) have a data sensitivity level, for example ' +
                        joinLimited(classified, 5) +
                        '.'
                );
            }
            if (classified.isEmpty()) {
                return AIR_CheckOutcome.attention(
                    'No fields on Contact, Account, Lead or Opportunity have a data sensitivity level.'
                );
            }
            return AIR_CheckOutcome.attention(
                'Only ' +
                    classified.size() +
                    ' field(s) have a data sensitivity level: ' +
                    joinLimited(classified, 5) +
                    '.'
            );
        }
    }

    public class SharingDefaults implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Set<String> open = new Set<String>{ 'ReadWrite', 'ReadWriteTransfer', 'FullAccess' };
            List<String> names = new List<String>{ 'Account', 'Contact', 'Opportunity', 'Case', 'Lead' };
            Map<String, SObject> defs = entityDefinitions(names);
            List<String> tooOpen = new List<String>();
            List<String> readOnly = new List<String>();
            List<String> summary = new List<String>();
            for (String name : names) {
                SObject ed = defs.get(name);
                if (ed == null) {
                    continue;
                }
                String model = (String) ed.get('InternalSharingModel');
                summary.add(name + ': ' + model);
                if (open.contains(model)) {
                    tooOpen.add(name);
                } else if (model == 'Read') {
                    readOnly.add(name);
                }
            }
            String evidence = 'Internal sharing defaults: ' + String.join(summary, ', ') + '.';
            if (!tooOpen.isEmpty()) {
                return AIR_CheckOutcome.attention(
                    evidence + ' Public read/write or wider: ' + String.join(tooOpen, ', ') + '.'
                );
            }
            if (!readOnly.isEmpty()) {
                evidence +=
                    ' Note: ' +
                    String.join(readOnly, ', ') +
                    ' are Public Read Only, so every user (and agent) can read them.';
            }
            return AIR_CheckOutcome.passed(evidence);
        }
    }

    public class ExternalSharing implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer externalUsers = countOf(
                'SELECT COUNT() FROM User WHERE IsActive = true AND UserType IN ' +
                '(\'PowerPartner\', \'CspLitePortal\', \'CustomerSuccess\', \'PowerCustomerSuccess\')'
            );
            if (externalUsers == 0) {
                return AIR_CheckOutcome.passed('There are no active external users.');
            }
            Map<String, SObject> defs = entityDefinitions(new List<String>{ 'Account', 'Contact' });
            List<String> open = new List<String>();
            for (String name : defs.keySet()) {
                String model = (String) defs.get(name).get('ExternalSharingModel');
                if (model != null && model != 'Private' && model != 'ControlledByParent') {
                    open.add(name + ': ' + model);
                }
            }
            String evidence = externalUsers + ' active external user(s).';
            if (open.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence + ' External sharing for Account and Contact is Private.');
            }
            return AIR_CheckOutcome.attention(
                evidence + ' External sharing is not Private for ' + String.join(open, ', ') + '.'
            );
        }
    }

    // ------------------------------------------------------------------ T3 protocols

    public class TempRestriction implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer sessionBased = countOf('SELECT COUNT() FROM PermissionSet WHERE HasActivationRequired = true');
            if (sessionBased > 0) {
                return AIR_CheckOutcome.passed(sessionBased + ' session-based permission set(s) exist.');
            }
            return AIR_CheckOutcome.attention('No session-based permission sets exist.');
        }
    }

    public class LoginCountries implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Set<String> countries = new Set<String>();
            List<SObject> logins;
            try {
                logins = rows('SELECT Country FROM LoginGeo WHERE LoginTime >= ' + isoDaysAgo(30) + ' LIMIT 5000');
            } catch (Exception e) {
                // LoginGeo needs the Manage Users permission, which AIR_Admin deliberately doesn't grant.
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: login locations can only be read by users with the Manage Users permission. Run the org scan as an administrator to include this check.'
                );
            }
            for (SObject g : logins) {
                String country = (String) g.get('Country');
                if (String.isNotBlank(country)) {
                    countries.add(country);
                }
            }
            if (countries.isEmpty()) {
                return AIR_CheckOutcome.passed('No login locations were recorded in the last 30 days.');
            }
            List<String> sorted = new List<String>(countries);
            sorted.sort();
            String evidence =
                'Logins in the last 30 days came from ' +
                countries.size() +
                ' countr' +
                (countries.size() == 1 ? 'y' : 'ies') +
                ': ' +
                joinLimited(sorted, 15) +
                '.';
            return countries.size() <= 3 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class TxnSecurity implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer enabled;
            try {
                enabled = countOf('SELECT COUNT() FROM TransactionSecurityPolicy WHERE State = \'Enabled\'');
            } catch (Exception e) {
                return AIR_CheckOutcome.notChecked('Unavailable: requires Event Monitoring / Shield.');
            }
            if (enabled > 0) {
                return AIR_CheckOutcome.passed(
                    enabled + ' transaction security polic' + (enabled == 1 ? 'y is' : 'ies are') + ' enabled.'
                );
            }
            return AIR_CheckOutcome.attention('No transaction security policies are enabled.');
        }
    }

    public class ConsentTracking implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer linked;
            try {
                linked = countOf('SELECT COUNT() FROM Contact WHERE IndividualId != null');
            } catch (Exception e) {
                return AIR_CheckOutcome.attention(
                    'Data Protection and Privacy (the Individual object) isn\'t enabled.'
                );
            }
            String evidence =
                linked +
                ' of ' +
                total +
                ' Contacts (' +
                fmtPct(pct(linked, total)) +
                ') are linked to an Individual record.';
            return pct(linked, total) >= 50 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    // ------------------------------------------------------------------ T4 agent rights

    public class ViewModifyAllData implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Map<Id, String> holders = new Map<Id, String>();
            for (
                SObject a : rows(
                    'SELECT AssigneeId, Assignee.Name FROM PermissionSetAssignment ' +
                        'WHERE (PermissionSet.PermissionsViewAllData = true OR PermissionSet.PermissionsModifyAllData = true) ' +
                        'AND Assignee.IsActive = true AND Assignee.UserType = \'Standard\' LIMIT 5000'
                )
            ) {
                holders.put((Id) a.get('AssigneeId'), (String) path(a, 'Assignee.Name'));
            }
            String evidence =
                holders.size() +
                ' active user(s) hold View All Data or Modify All Data' +
                (holders.isEmpty() ? '.' : ': ' + joinLimited(holders.values(), 10) + '.');
            return holders.size() <= 3 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class ObjectViewAll implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> grants = new List<String>();
            for (
                SObject p : rows(
                    'SELECT SobjectType, Parent.Label, PermissionsViewAllRecords, PermissionsModifyAllRecords ' +
                        'FROM ObjectPermissions WHERE (PermissionsViewAllRecords = true OR PermissionsModifyAllRecords = true) ' +
                        'AND Parent.IsOwnedByProfile = false AND Parent.IsCustom = true LIMIT 1000'
                )
            ) {
                String kind = (Boolean) p.get('PermissionsModifyAllRecords') ? 'Modify All' : 'View All';
                grants.add(path(p, 'Parent.Label') + ': ' + p.get('SobjectType') + ' (' + kind + ')');
            }
            if (grants.isEmpty()) {
                return AIR_CheckOutcome.passed('No custom permission set grants object-level View All or Modify All.');
            }
            return AIR_CheckOutcome.attention(
                grants.size() + ' object-level View All / Modify All grant(s): ' + joinLimited(grants, 10) + '.'
            );
        }
    }

    public class AgentLeastPrivilege implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Map<Id, String> agents = new Map<Id, String>();
            for (
                SObject u : rows(
                    'SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name LIKE \'%Agent%\' LIMIT 200'
                )
            ) {
                agents.put((Id) u.get('Id'), (String) u.get('Name'));
            }
            // Plus every integration user registered on an AI use case in this app.
            for (
                SObject uc : rows(
                    'SELECT Agent_User__c, Agent_User__r.Name FROM AIR_Use_Case__c WHERE Agent_User__c != null LIMIT 500'
                )
            ) {
                agents.put((Id) uc.get('Agent_User__c'), (String) path(uc, 'Agent_User__r.Name'));
            }
            if (agents.isEmpty()) {
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: no AI agent users found yet. Register the integration user of each AI connection on its use case.'
                );
            }
            List<String> issues = new List<String>();
            Map<Id, String> permSetLabels = new Map<Id, String>();
            for (
                SObject a : rows(
                    'SELECT AssigneeId, PermissionSetId, PermissionSet.Label, PermissionSet.PermissionsViewAllData, ' +
                    'PermissionSet.PermissionsModifyAllData FROM PermissionSetAssignment WHERE AssigneeId IN :ids',
                    new Map<String, Object>{ 'ids' => agents.keySet() }
                )
            ) {
                String agentName = agents.get((Id) a.get('AssigneeId'));
                permSetLabels.put((Id) a.get('PermissionSetId'), agentName);
                if (
                    path(a, 'PermissionSet.PermissionsViewAllData') == true ||
                    path(a, 'PermissionSet.PermissionsModifyAllData') == true
                ) {
                    issues.add(agentName + ': all-data permission via ' + path(a, 'PermissionSet.Label'));
                }
            }
            if (!permSetLabels.isEmpty()) {
                for (
                    SObject p : rows(
                        'SELECT ParentId, SobjectType FROM ObjectPermissions WHERE ParentId IN :ids ' +
                        'AND (PermissionsViewAllRecords = true OR PermissionsModifyAllRecords = true)',
                        new Map<String, Object>{ 'ids' => permSetLabels.keySet() }
                    )
                ) {
                    issues.add(
                        permSetLabels.get((Id) p.get('ParentId')) + ': View/Modify All on ' + p.get('SobjectType')
                    );
                }
            }
            String evidence = agents.size() + ' agent user(s): ' + joinLimited(agents.values(), 5) + '.';
            if (issues.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence + ' None hold all-data or object-level View All / Modify All.');
            }
            return AIR_CheckOutcome.attention(evidence + ' Too much access: ' + joinLimited(issues, 10) + '.');
        }
    }

    public class MutingInUse implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer muting = countOf('SELECT COUNT() FROM MutingPermissionSet');
            if (muting > 0) {
                return AIR_CheckOutcome.passed(muting + ' muting permission set(s) exist.');
            }
            return AIR_CheckOutcome.attention('No muting permission sets exist.');
        }
    }

    public class StaleContacts implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer stale = countOf('SELECT COUNT() FROM Contact WHERE LastModifiedDate < ' + isoDaysAgo(5 * 365));
            String evidence =
                stale +
                ' of ' +
                total +
                ' Contacts (' +
                fmtPct(pct(stale, total)) +
                ') were last modified more than 5 years ago.';
            return pct(stale, total) <= 20 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    // ------------------------------------------------------------------ T5 ownership

    public class AdminCount implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer admins = countOf(
                'SELECT COUNT() FROM User WHERE IsActive = true AND UserType = \'Standard\' ' +
                'AND Profile.PermissionsModifyAllData = true'
            );
            String evidence = admins + ' active user(s) are on an administrator profile.';
            return admins <= 3 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class InactiveAdmins implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> dormant = new List<String>();
            for (
                SObject u : rows(
                    'SELECT Name, LastLoginDate FROM User WHERE IsActive = true AND UserType = \'Standard\' ' +
                        'AND Profile.PermissionsModifyAllData = true AND (LastLoginDate = null OR LastLoginDate < ' +
                        isoDaysAgo(90) +
                        ') LIMIT 200'
                )
            ) {
                dormant.add(u.get('Name') + ' (last login ' + fmtDate((Datetime) u.get('LastLoginDate')) + ')');
            }
            if (dormant.isEmpty()) {
                return AIR_CheckOutcome.passed('Every active administrator logged in within the last 90 days.');
            }
            return AIR_CheckOutcome.attention('Dormant administrators: ' + joinLimited(dormant, 10) + '.');
        }
    }

    // ------------------------------------------------------------------ T6 LLM management

    public class LlmEndpoints implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> found = new List<String>();
            for (SObject c : rows('SELECT DeveloperName, Endpoint FROM NamedCredential LIMIT 1000')) {
                String endpoint = ((String) c.get('Endpoint'));
                if (endpoint == null) {
                    continue;
                }
                for (String host : LLM_HOSTS) {
                    if (endpoint.toLowerCase().contains(host)) {
                        found.add(c.get('DeveloperName') + ' (' + endpoint + ')');
                        break;
                    }
                }
            }
            if (found.isEmpty()) {
                return AIR_CheckOutcome.passed('No named credential points at a known LLM provider.');
            }
            return AIR_CheckOutcome.attention(
                'Direct LLM connections found: ' +
                    joinLimited(found, 10) +
                    '. Make sure each one is covered by your LLM policy and a DPA.'
            );
        }
    }

    public class AgentsHaveUseCase implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer bots;
            try {
                bots = countOf('SELECT COUNT() FROM BotDefinition');
            } catch (Exception e) {
                return AIR_CheckOutcome.notChecked('Unavailable: bots and agents aren\'t enabled in this org.');
            }
            if (bots == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: no bots or agents exist yet.');
            }
            Integer useCases = countOf(
                'SELECT COUNT() FROM AIR_Use_Case__c WHERE Status__c IN (\'Approved\', \'Live\')'
            );
            String evidence = bots + ' bot/agent definition(s) and ' + useCases + ' approved or live use case(s).';
            return bots <= useCases ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    // ------------------------------------------------------------------ T7 data quality

    public class KnowledgeFreshness implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            if (!hasObject('Knowledge__kav')) {
                return AIR_CheckOutcome.notChecked('Unavailable: Lightning Knowledge isn\'t enabled.');
            }
            Integer total = countOf('SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = \'Online\'');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no published Knowledge articles.');
            }
            Integer old = countOf(
                'SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = \'Online\' AND LastPublishedDate < ' +
                isoDaysAgo(365)
            );
            String evidence =
                old +
                ' of ' +
                total +
                ' published articles (' +
                fmtPct(pct(old, total)) +
                ') are older than a year.';
            return pct(old, total) <= 20 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class DuplicateRules implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Set<String> covered = new Set<String>();
            for (SObject r : rows('SELECT SobjectType FROM DuplicateRule WHERE IsActive = true LIMIT 500')) {
                covered.add(String.valueOf(r.get('SobjectType')));
            }
            List<String> missing = new List<String>();
            List<String> checked = new List<String>();
            for (String objectName : new List<String>{ 'Contact', 'Account', 'Lead' }) {
                if (countOf('SELECT COUNT() FROM ' + objectName + ' LIMIT 1') == 0) {
                    continue; // object not in use
                }
                checked.add(objectName);
                if (!covered.contains(objectName)) {
                    missing.add(objectName);
                }
            }
            String note = ' Review in Setup whether each rule blocks or only alerts.';
            if (checked.isEmpty()) {
                return AIR_CheckOutcome.notChecked('Unavailable: Contact, Account and Lead have no records yet.');
            }
            if (missing.isEmpty()) {
                return AIR_CheckOutcome.passed(
                    'Active duplicate rules exist for ' + String.join(checked, ', ') + '.' + note
                );
            }
            return AIR_CheckOutcome.attention(
                'No active duplicate rule for ' + String.join(missing, ', ') + '.' + note
            );
        }
    }

    public class ContactEmail implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer withEmail = countOf('SELECT COUNT() FROM Contact WHERE Email != null');
            String evidence =
                withEmail +
                ' of ' +
                total +
                ' Contacts (' +
                fmtPct(pct(withEmail, total)) +
                ') have an email address.';
            return pct(withEmail, total) >= 80
                ? AIR_CheckOutcome.passed(evidence)
                : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class OrphanedRecords implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer orphaned = countOf('SELECT COUNT() FROM Contact WHERE Owner.IsActive = false');
            String evidence =
                orphaned +
                ' of ' +
                total +
                ' Contacts (' +
                fmtPct(pct(orphaned, total)) +
                ') are owned by inactive users.';
            return pct(orphaned, total) <= 5 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class DuplicateRate implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer sameEmail = 0;
            for (
                SObject g : rows(
                    'SELECT Email, COUNT(Id) c FROM Contact WHERE Email != null GROUP BY Email HAVING COUNT(Id) > 1 LIMIT 2000'
                )
            ) {
                sameEmail += (Integer) g.get('c');
            }
            Integer sameNamePostal = 0;
            for (
                SObject g : rows(
                    'SELECT FirstName, LastName, MailingPostalCode, COUNT(Id) c FROM Contact ' +
                        'WHERE MailingPostalCode != null GROUP BY FirstName, LastName, MailingPostalCode ' +
                        'HAVING COUNT(Id) > 1 LIMIT 2000'
                )
            ) {
                sameNamePostal += (Integer) g.get('c');
            }
            Integer suspect = Math.min(total, Math.max(sameEmail, sameNamePostal));
            String evidence =
                'Estimated ' +
                fmtPct(pct(suspect, total)) +
                ' of ' +
                total +
                ' Contacts look like duplicates (' +
                sameEmail +
                ' share an email address, ' +
                sameNamePostal +
                ' share a name and postal code).';
            return pct(suspect, total) <= 5 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class OrphanContacts implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Contact');
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no Contacts yet.');
            }
            Integer orphans = countOf('SELECT COUNT() FROM Contact WHERE AccountId = null');
            String evidence =
                orphans +
                ' of ' +
                total +
                ' Contacts (' +
                fmtPct(pct(orphans, total)) +
                ') have no Account.';
            return pct(orphans, total) <= 5 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class OrphanGifts implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Integer total = countOf('SELECT COUNT() FROM Opportunity');
            Integer orphans = countOf('SELECT COUNT() FROM Opportunity WHERE AccountId = null');
            List<String> parts = new List<String>{ orphans + ' of ' + total + ' Opportunities have no Account' };
            if (hasObject('GiftTransaction')) {
                Integer gifts = countOf('SELECT COUNT() FROM GiftTransaction');
                Integer giftOrphans = countOf('SELECT COUNT() FROM GiftTransaction WHERE DonorId = null');
                parts.add(giftOrphans + ' of ' + gifts + ' Gift Transactions have no donor');
                total += gifts;
                orphans += giftOrphans;
            }
            if (total == 0) {
                return AIR_CheckOutcome.notChecked('Unavailable: there are no gifts or opportunities yet.');
            }
            String evidence = String.join(parts, '; ') + ' (' + fmtPct(pct(orphans, total)) + ' overall).';
            return pct(orphans, total) <= 1 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }


    // ------------------------------------------------------------------ special-category data

    public static final Set<String> SENSITIVE_LEVELS = new Set<String>{ 'Confidential', 'Restricted', 'MissionCritical' };

    /** Keyword patterns per GDPR Article 9 category (plus vulnerability and minors), matched on whole words. */
    private static final Map<String, Pattern> SENSITIVE_PATTERNS = new Map<String, Pattern>{
        'health' => Pattern.compile(
            '(?i).*\\b(health|medical|medication|diagnos\\w*|disabilit\\w*|disabled|illness|pregnan\\w*|allerg\\w*)\\b.*'
        ),
        'religion' => Pattern.compile('(?i).*\\b(religio\\w*|faith|church|mosque|synagogue|denomination)\\b.*'),
        'ethnicity' => Pattern.compile('(?i).*\\b(ethnic\\w*|race|racial)\\b.*'),
        'sexual orientation' => Pattern.compile('(?i).*\\b(sexual\\w*|orientation)\\b.*'),
        'vulnerability' => Pattern.compile('(?i).*\\b(vulnerab\\w*|safeguard\\w*|at risk)\\b.*'),
        'minors' => Pattern.compile('(?i).*\\b(minor|minors|child|children|guardian|birthdate|birth date|date of birth|dob)\\b.*'),
        'criminal records' => Pattern.compile('(?i).*\\b(criminal|conviction\\w*|offen[cs]e\\w*)\\b.*'),
        'biometric or genetic' => Pattern.compile('(?i).*\\b(biometric\\w*|genetic\\w*|dna)\\b.*'),
        'political or union' => Pattern.compile('(?i).*\\b(political|trade union|union member\\w*)\\b.*')
    };

    /** The special category a field seems to hold, judged by its label and API name, or null. */
    public static String sensitiveCategory(String label, String apiName) {
        String name = apiName == null ? '' : apiName.removeEnd('__c').replaceAll('^\\w+__', '');
        String text = (label == null ? '' : label) + ' ' + name.replace('_', ' ').replaceAll('([a-z])([A-Z])', '$1 $2');
        for (String category : SENSITIVE_PATTERNS.keySet()) {
            if (SENSITIVE_PATTERNS.get(category).matcher(text).matches()) {
                return category;
            }
        }
        return null;
    }

    /** Data sensitivity level per field API name for one object. */
    public static Map<String, String> classifications(String objectName) {
        Map<String, String> result = new Map<String, String>();
        for (
            SObject fd : rows(
                'SELECT QualifiedApiName, SecurityClassification FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :obj',
                new Map<String, Object>{ 'obj' => objectName }
            )
        ) {
            result.put((String) fd.get('QualifiedApiName'), (String) fd.get('SecurityClassification'));
        }
        return result;
    }

    public class SpecialCategoryFields implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            List<String> objectNames = new List<String>();
            for (String name : new List<String>{ 'Contact', 'Account', 'Lead', 'Opportunity', 'Case' }) {
                if (globalDescribe.containsKey(name.toLowerCase())) {
                    objectNames.add(name);
                }
            }
            Integer customObjects = 0;
            for (String key : globalDescribe.keySet()) {
                if (key.endsWith('__c') && !key.startsWith('air_') && customObjects < 100) {
                    objectNames.add(globalDescribe.get(key).getDescribe().getName());
                    customObjects++;
                }
            }
            // Candidates per object: field API name => category.
            Map<String, Map<String, String>> candidates = new Map<String, Map<String, String>>();
            for (String objectName : objectNames) {
                for (Schema.SObjectField f : globalDescribe.get(objectName.toLowerCase()).getDescribe().fields.getMap().values()) {
                    Schema.DescribeFieldResult d = f.getDescribe();
                    String category = sensitiveCategory(d.getLabel(), d.getName());
                    if (category != null) {
                        if (!candidates.containsKey(objectName)) {
                            candidates.put(objectName, new Map<String, String>());
                        }
                        candidates.get(objectName).put(d.getName(), category);
                    }
                }
            }
            String minorsNote = '';
            if (globalDescribe.get('contact').getDescribe().fields.getMap().containsKey('birthdate')) {
                Integer minors = countOf(
                    'SELECT COUNT() FROM Contact WHERE Birthdate > ' + String.valueOf(Date.today().addYears(-18))
                );
                if (minors > 0) {
                    minorsNote = ' ' + minors + ' Contact(s) are under 18.';
                }
            }
            if (candidates.isEmpty()) {
                return AIR_CheckOutcome.passed(
                    'No fields that look like special-category data were found on ' +
                        objectNames.size() +
                        ' object(s).' +
                        minorsNote +
                        ' Free-text fields and files aren\'t scanned.'
                );
            }
            List<String> unclassified = new List<String>();
            List<String> classified = new List<String>();
            List<String> notVerified = new List<String>();
            Integer queried = 0;
            for (String objectName : candidates.keySet()) {
                Map<String, String> fields = candidates.get(objectName);
                if (queried >= 15) {
                    for (String fieldName : fields.keySet()) {
                        notVerified.add(objectName + '.' + fieldName);
                    }
                    continue;
                }
                Map<String, String> levels = classifications(objectName);
                queried++;
                for (String fieldName : fields.keySet()) {
                    String label = objectName + '.' + fieldName + ' (' + fields.get(fieldName) + ')';
                    if (levels.get(fieldName) == null) {
                        unclassified.add(label);
                    } else {
                        classified.add(label);
                    }
                }
            }
            String evidence =
                (classified.size() + unclassified.size() + notVerified.size()) +
                ' field(s) look like special-category data.' +
                minorsNote +
                (classified.isEmpty() ? '' : ' Classified: ' + joinLimited(classified, 10) + '.') +
                (notVerified.isEmpty() ? '' : ' Not verified (too many objects): ' + joinLimited(notVerified, 5) + '.');
            if (unclassified.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence);
            }
            return AIR_CheckOutcome.attention(
                evidence + ' No data sensitivity level: ' + joinLimited(unclassified, 15) + '.'
            );
        }
    }

    // ------------------------------------------------------------------ Implementation level (grounding scope)

    public static final String NO_SCOPE = 'Unavailable: add grounding fields (Object.Field, one per line) to the use case.';

    public static String invalidNote(List<String> invalid) {
        return invalid.isEmpty() ? '' : ' Skipped: ' + joinLimited(invalid, 10) + '.';
    }

    public class FieldFillRate implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            Map<String, Integer> totals = new Map<String, Integer>();
            List<String> low = new List<String>();
            List<String> measured = new List<String>();
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (!ref.isFilterable()) {
                    invalid.add(ref.label() + ' (long text fields can\'t be measured)');
                    continue;
                }
                if (!totals.containsKey(ref.objectName)) {
                    totals.put(ref.objectName, countOf('SELECT COUNT() FROM ' + ref.objectName));
                }
                Integer total = totals.get(ref.objectName);
                if (total == 0) {
                    invalid.add(ref.label() + ' (no records)');
                    continue;
                }
                Integer filled = countOf(
                    'SELECT COUNT() FROM ' + ref.objectName + ' WHERE ' + ref.fieldName + ' != null'
                );
                Decimal rate = pct(filled, total);
                measured.add(ref.label() + ' ' + fmtPct(rate));
                if (rate < 80) {
                    low.add(ref.label() + ' ' + fmtPct(rate));
                }
            }
            if (measured.isEmpty()) {
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: none of the grounding fields could be measured.' + invalidNote(invalid)
                );
            }
            if (low.isEmpty()) {
                return AIR_CheckOutcome.passed('Fill rate: ' + joinLimited(measured, 15) + '.' + invalidNote(invalid));
            }
            return AIR_CheckOutcome.attention('Below 80%: ' + joinLimited(low, 15) + '.' + invalidNote(invalid));
        }
    }

    public class PicklistOther implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            List<String> measured = new List<String>();
            List<String> poor = new List<String>();
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (!ref.isPicklist()) {
                    continue;
                }
                Integer total = countOf('SELECT COUNT() FROM ' + ref.objectName);
                if (total == 0) {
                    continue;
                }
                Integer vague = countOf(
                    'SELECT COUNT() FROM ' +
                        ref.objectName +
                        ' WHERE ' +
                        ref.fieldName +
                        ' = null OR ' +
                        ref.fieldName +
                        ' = \'Other\''
                );
                Decimal rate = pct(vague, total);
                measured.add(ref.label() + ' ' + fmtPct(rate));
                if (rate > 20) {
                    poor.add(ref.label() + ' ' + fmtPct(rate));
                }
            }
            if (measured.isEmpty()) {
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: no picklist fields with records among the grounding fields.'
                );
            }
            if (poor.isEmpty()) {
                return AIR_CheckOutcome.passed('Blank or Other: ' + joinLimited(measured, 15) + '.');
            }
            return AIR_CheckOutcome.attention('Blank or Other above 20%: ' + joinLimited(poor, 15) + '.');
        }
    }

    public class ScopeFreshness implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> objects = ctx == null ? new List<String>() : ctx.groundingObjects();
            if (objects.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE);
            }
            List<String> measured = new List<String>();
            List<String> stale = new List<String>();
            for (String objectName : objects) {
                Integer total = countOf('SELECT COUNT() FROM ' + objectName);
                if (total == 0) {
                    continue;
                }
                Integer old = countOf(
                    'SELECT COUNT() FROM ' + objectName + ' WHERE LastModifiedDate < ' + isoDaysAgo(3 * 365)
                );
                Decimal rate = pct(old, total);
                measured.add(objectName + ' ' + fmtPct(rate));
                if (rate > 20) {
                    stale.add(objectName + ' ' + fmtPct(rate));
                }
            }
            if (measured.isEmpty()) {
                return AIR_CheckOutcome.notChecked('Unavailable: the grounding objects have no records yet.');
            }
            if (stale.isEmpty()) {
                return AIR_CheckOutcome.passed('Not modified in 3+ years: ' + joinLimited(measured, 10) + '.');
            }
            return AIR_CheckOutcome.attention(
                'More than 20% not modified in 3+ years: ' + joinLimited(stale, 10) + '.'
            );
        }
    }

    public class FreeTextVolume implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            List<String> freeText = new List<String>();
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (ref.describe.getType() == Schema.DisplayType.TEXTAREA) {
                    freeText.add(ref.label() + (ref.describe.isHtmlFormatted() ? ' (rich text)' : ''));
                }
            }
            Decimal share = pct(freeText.size(), refs.size());
            String evidence =
                freeText.size() +
                ' of ' +
                refs.size() +
                ' grounding fields (' +
                fmtPct(share) +
                ') are free text' +
                (freeText.isEmpty() ? '' : ': ' + joinLimited(freeText, 10)) +
                '.' +
                invalidNote(invalid);
            return share <= 30 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class TextShouldBePicklist implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            Pattern coded = Pattern.compile(
                '(?i).*(country|state|province|county|payment|method|currency|status|gender|salutation|language).*'
            );
            List<String> flagged = new List<String>();
            Boolean addressWithoutPicklists = false;
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (ref.describe.getType() != Schema.DisplayType.STRING) {
                    continue;
                }
                String name = ref.fieldName;
                if (!coded.matcher(name + ' ' + ref.describe.getLabel()).matches()) {
                    continue;
                }
                // With State and Country/Territory Picklists on, address text fields are backed by a *Code picklist.
                if (name.endsWith('Country') || name.endsWith('State')) {
                    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(ref.objectName.toLowerCase());
                    if (objectType.getDescribe().fields.getMap().containsKey((name + 'Code').toLowerCase())) {
                        continue;
                    }
                    addressWithoutPicklists = true;
                }
                flagged.add(ref.label());
            }
            String note = addressWithoutPicklists ? ' State and Country/Territory Picklists aren\'t enabled.' : '';
            if (flagged.isEmpty()) {
                return AIR_CheckOutcome.passed(
                    'No grounding text field holds coded values such as country, state or payment method.' +
                    invalidNote(invalid)
                );
            }
            return AIR_CheckOutcome.attention(
                'Text fields that look like they should be picklists: ' +
                    joinLimited(flagged, 10) +
                    '.' +
                    note +
                    invalidNote(invalid)
            );
        }
    }

    public class LookAlikeFields implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            Map<String, Map<String, List<String>>> labelsByObject = new Map<String, Map<String, List<String>>>();
            List<String> lookAlikes = new List<String>();
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (!labelsByObject.containsKey(ref.objectName)) {
                    Map<String, List<String>> byLabel = new Map<String, List<String>>();
                    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(ref.objectName.toLowerCase());
                    for (Schema.SObjectField f : objectType.getDescribe().fields.getMap().values()) {
                        Schema.DescribeFieldResult d = f.getDescribe();
                        String key = normalizeLabel(d.getLabel());
                        if (!byLabel.containsKey(key)) {
                            byLabel.put(key, new List<String>());
                        }
                        byLabel.get(key).add(d.getName());
                    }
                    labelsByObject.put(ref.objectName, byLabel);
                }
                List<String> others = new List<String>();
                for (String name : labelsByObject.get(ref.objectName).get(normalizeLabel(ref.describe.getLabel()))) {
                    if (name != ref.fieldName) {
                        others.add(ref.objectName + '.' + name);
                    }
                }
                if (!others.isEmpty()) {
                    lookAlikes.add(ref.label() + ' and ' + String.join(others, ', '));
                }
            }
            if (lookAlikes.isEmpty()) {
                return AIR_CheckOutcome.passed(
                    refs.size() + ' grounding field(s) checked; none share a label with another field.' + invalidNote(invalid)
                );
            }
            return AIR_CheckOutcome.attention(
                'Fields with the same label: ' + joinLimited(lookAlikes, 10) + '.' + invalidNote(invalid)
            );
        }
    }

    /** "Preferred e-mail", "Preferred Email" and "PreferredEmail" compare equal. */
    @TestVisible
    private static String normalizeLabel(String label) {
        return label == null ? '' : label.toLowerCase().replaceAll('e-mail', 'email').replaceAll('[^a-z0-9]', '');
    }

    public class FieldDescriptions implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            Map<String, List<AIR_CheckContext.FieldRef>> customByObject = new Map<String, List<AIR_CheckContext.FieldRef>>();
            Integer customCount = 0;
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (!ref.describe.isCustom()) {
                    continue;
                }
                if (!customByObject.containsKey(ref.objectName)) {
                    customByObject.put(ref.objectName, new List<AIR_CheckContext.FieldRef>());
                }
                customByObject.get(ref.objectName).add(ref);
                customCount++;
            }
            if (customCount == 0) {
                return AIR_CheckOutcome.passed(
                    'All grounding fields are standard fields, which Salesforce documents.' + invalidNote(invalid)
                );
            }
            List<String> missing = new List<String>();
            for (String objectName : customByObject.keySet()) {
                Map<String, String> descriptions = new Map<String, String>();
                for (
                    SObject fd : rows(
                        'SELECT QualifiedApiName, Description FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :obj',
                        new Map<String, Object>{ 'obj' => objectName }
                    )
                ) {
                    descriptions.put((String) fd.get('QualifiedApiName'), (String) fd.get('Description'));
                }
                for (AIR_CheckContext.FieldRef ref : customByObject.get(objectName)) {
                    if (
                        String.isBlank(descriptions.get(ref.fieldName)) && String.isBlank(ref.describe.getInlineHelpText())
                    ) {
                        missing.add(ref.label());
                    }
                }
            }
            Decimal described = pct(customCount - missing.size(), customCount);
            String evidence =
                (customCount - missing.size()) +
                ' of ' +
                customCount +
                ' custom grounding fields (' +
                fmtPct(described) +
                ') have a description or help text.' +
                (missing.isEmpty() ? '' : ' Missing: ' + joinLimited(missing, 10) + '.') +
                invalidNote(invalid);
            return described >= 80 ? AIR_CheckOutcome.passed(evidence) : AIR_CheckOutcome.attention(evidence);
        }
    }

    public class SensitiveInScope implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            List<String> invalid = new List<String>();
            List<AIR_CheckContext.FieldRef> refs = ctx == null
                ? new List<AIR_CheckContext.FieldRef>()
                : ctx.resolveFields(invalid);
            if (refs.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE + invalidNote(invalid));
            }
            Map<String, Map<String, String>> levelsByObject = new Map<String, Map<String, String>>();
            List<String> flagged = new List<String>();
            for (AIR_CheckContext.FieldRef ref : refs) {
                if (!levelsByObject.containsKey(ref.objectName)) {
                    levelsByObject.put(ref.objectName, classifications(ref.objectName));
                }
                String level = levelsByObject.get(ref.objectName).get(ref.fieldName);
                String category = sensitiveCategory(ref.describe.getLabel(), ref.fieldName);
                if (SENSITIVE_LEVELS.contains(level)) {
                    flagged.add(ref.label() + ' (classified ' + level + ')');
                } else if (category != null) {
                    flagged.add(ref.label() + ' (looks like ' + category + ')');
                }
            }
            if (flagged.isEmpty()) {
                return AIR_CheckOutcome.passed(
                    refs.size() + ' grounding field(s) checked; none is sensitive.' + invalidNote(invalid)
                );
            }
            return AIR_CheckOutcome.attention(
                'Sensitive fields in the agent\'s scope: ' + joinLimited(flagged, 15) + '.' + invalidNote(invalid)
            );
        }
    }

    // ------------------------------------------------------------------ Implementation level: AI integration user

    public static final String NO_AI_USER = 'Unavailable: enter the username of the integration user this AI connects as (on the use case or the first checklist step).';

    /** Effective access of one user: the permission sets behind its profile, permission sets and groups. */
    public class UserAccess {
        public SObject user;
        public Set<Id> permSetIds = new Set<Id>();
        public List<String> allDataSources = new List<String>();

        public String name() {
            return (String) user.get('Name') + ' (' + user.get('Username') + ')';
        }
    }

    public static UserAccess userAccess(Id userId) {
        if (userId == null) {
            return null;
        }
        List<SObject> users = rows(
            'SELECT Id, Name, Username, IsActive, Profile.Name, Profile.UserLicense.Name, Profile.PermissionsModifyAllData ' +
            'FROM User WHERE Id = :userId',
            new Map<String, Object>{ 'userId' => userId }
        );
        if (users.isEmpty()) {
            return null;
        }
        UserAccess access = new UserAccess();
        access.user = users[0];
        for (
            SObject a : rows(
                'SELECT PermissionSetId, PermissionSet.Label, PermissionSet.IsOwnedByProfile, PermissionSet.PermissionsViewAllData, ' +
                'PermissionSet.PermissionsModifyAllData FROM PermissionSetAssignment WHERE AssigneeId = :userId',
                new Map<String, Object>{ 'userId' => userId }
            )
        ) {
            access.permSetIds.add((Id) a.get('PermissionSetId'));
            if (
                path(a, 'PermissionSet.PermissionsViewAllData') == true ||
                path(a, 'PermissionSet.PermissionsModifyAllData') == true
            ) {
                String source = path(a, 'PermissionSet.IsOwnedByProfile') == true
                    ? 'profile ' + path(access.user, 'Profile.Name')
                    : 'permission set ' + path(a, 'PermissionSet.Label');
                access.allDataSources.add(source);
            }
        }
        return access;
    }

    /** Object permissions of the user, keyed by object API name. */
    public static Map<String, List<SObject>> objectPermissions(UserAccess access, String extraFilter) {
        Map<String, List<SObject>> byObject = new Map<String, List<SObject>>();
        if (access.permSetIds.isEmpty()) {
            return byObject;
        }
        for (
            SObject p : rows(
                'SELECT SobjectType, PermissionsRead, PermissionsEdit, PermissionsViewAllRecords, PermissionsModifyAllRecords, ' +
                    'Parent.Label FROM ObjectPermissions WHERE ParentId IN :ids' +
                    (extraFilter == null ? '' : ' AND ' + extraFilter),
                new Map<String, Object>{ 'ids' => access.permSetIds }
            )
        ) {
            String objectName = (String) p.get('SobjectType');
            if (!byObject.containsKey(objectName)) {
                byObject.put(objectName, new List<SObject>());
            }
            byObject.get(objectName).add(p);
        }
        return byObject;
    }

    public class IntegrationUser implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            SObject u = access.user;
            String profileName = String.valueOf(path(u, 'Profile.Name'));
            String licence = String.valueOf(path(u, 'Profile.UserLicense.Name'));
            String evidence = access.name() + ', profile ' + profileName + ', licence ' + licence + '.';
            if (u.get('IsActive') != true) {
                return AIR_CheckOutcome.attention(evidence + ' This user is inactive.');
            }
            if (u.get('Id') == UserInfo.getUserId()) {
                return AIR_CheckOutcome.attention(
                    evidence + ' This is your own account. Create a separate integration user for the AI.'
                );
            }
            if (path(u, 'Profile.PermissionsModifyAllData') == true) {
                return AIR_CheckOutcome.attention(
                    evidence +
                    ' This user is on an administrator profile. AI must not connect as a System Administrator.'
                );
            }
            String hints = (profileName + ' ' + licence + ' ' + u.get('Username')).toLowerCase();
            if (
                licence == 'Salesforce Integration' ||
                hints.contains('integration') ||
                hints.contains('agent') ||
                hints.contains('api')
            ) {
                return AIR_CheckOutcome.passed(evidence + ' Looks like a dedicated integration user.');
            }
            return AIR_CheckOutcome.attention(
                evidence +
                ' This looks like a regular user account. Use a dedicated integration user for each AI connection.'
            );
        }
    }

    public class UserNoAllData implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            if (access.allDataSources.isEmpty()) {
                return AIR_CheckOutcome.passed(access.name() + ' holds neither View All Data nor Modify All Data.');
            }
            return AIR_CheckOutcome.attention(
                access.name() + ' can see or change all data through ' + String.join(access.allDataSources, ', ') + '.'
            );
        }
    }

    public class UserNoObjectViewAll implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            Map<String, List<SObject>> perms = objectPermissions(
                access,
                '(PermissionsViewAllRecords = true OR PermissionsModifyAllRecords = true)'
            );
            if (perms.isEmpty()) {
                return AIR_CheckOutcome.passed(access.name() + ' has no object-level View All or Modify All.');
            }
            List<String> grants = new List<String>();
            for (String objectName : perms.keySet()) {
                for (SObject p : perms.get(objectName)) {
                    grants.add(objectName + ' via ' + path(p, 'Parent.Label'));
                }
            }
            return AIR_CheckOutcome.attention(
                access.name() + ' has View All / Modify All on: ' + joinLimited(grants, 10) + '.'
            );
        }
    }

    public class UserAccessMatchesScope implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            Set<String> scope = new Set<String>();
            for (String objectName : ctx.groundingObjects()) {
                scope.add(objectName.toLowerCase());
            }
            if (scope.isEmpty()) {
                return AIR_CheckOutcome.notChecked(NO_SCOPE);
            }
            Map<String, List<SObject>> perms = objectPermissions(access, 'PermissionsRead = true');
            List<String> readable = new List<String>();
            List<String> outside = new List<String>();
            for (String objectName : perms.keySet()) {
                if (!DONOR_OBJECTS.contains(objectName.toLowerCase())) {
                    continue;
                }
                Boolean canEdit = false;
                for (SObject p : perms.get(objectName)) {
                    canEdit = canEdit || p.get('PermissionsEdit') == true;
                }
                String label = objectName + (canEdit ? ' (read/edit)' : ' (read)');
                readable.add(label);
                if (!scope.contains(objectName.toLowerCase())) {
                    outside.add(label);
                }
            }
            readable.sort();
            String evidence =
                access.name() +
                ' can access donor objects: ' +
                (readable.isEmpty() ? 'none' : joinLimited(readable, 15)) +
                '.';
            if (outside.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence + ' All are within the grounding scope.');
            }
            outside.sort();
            return AIR_CheckOutcome.attention(
                evidence + ' Outside the grounding scope: ' + joinLimited(outside, 15) + '.'
            );
        }
    }

    public class UserSensitiveFields implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            List<String> objectNames = new List<String>{ 'Contact', 'Account', 'Lead', 'Opportunity', 'Case' };
            if (hasObject('GiftTransaction')) {
                objectNames.add('GiftTransaction');
            }
            Set<String> sensitive = new Set<String>();
            for (String objectName : objectNames) {
                for (
                    SObject fd : rows(
                        'SELECT QualifiedApiName, SecurityClassification FROM FieldDefinition ' +
                        'WHERE EntityDefinition.QualifiedApiName = :obj',
                        new Map<String, Object>{ 'obj' => objectName }
                    )
                ) {
                    if (SENSITIVE_LEVELS.contains(String.valueOf(fd.get('SecurityClassification')))) {
                        sensitive.add(objectName + '.' + fd.get('QualifiedApiName'));
                    }
                }
            }
            if (sensitive.isEmpty()) {
                return AIR_CheckOutcome.notChecked(
                    'Unavailable: no donor fields are classified as Confidential, Restricted or Mission Critical yet.'
                );
            }
            List<String> readable = new List<String>();
            if (!access.allDataSources.isEmpty()) {
                readable.addAll(sensitive);
            } else if (!access.permSetIds.isEmpty()) {
                Set<String> found = new Set<String>();
                for (
                    SObject fp : rows(
                        'SELECT Field FROM FieldPermissions WHERE ParentId IN :ids AND PermissionsRead = true AND Field IN :fields',
                        new Map<String, Object>{ 'ids' => access.permSetIds, 'fields' => sensitive }
                    )
                ) {
                    found.add((String) fp.get('Field'));
                }
                readable.addAll(found);
            }
            readable.sort();
            String evidence = sensitive.size() + ' sensitive field(s) checked.';
            if (readable.isEmpty()) {
                return AIR_CheckOutcome.passed(evidence + ' ' + access.name() + ' can read none of them.');
            }
            return AIR_CheckOutcome.attention(
                evidence + ' ' + access.name() + ' can read: ' + joinLimited(readable, 15) + '.'
            );
        }
    }

    public class UserApiOnly implements AIR_Check {
        public AIR_CheckOutcome evaluate(AIR_CheckContext ctx) {
            UserAccess access = userAccess(ctx == null ? null : ctx.agentUserId);
            if (access == null) {
                return AIR_CheckOutcome.notChecked(NO_AI_USER);
            }
            if (String.valueOf(path(access.user, 'Profile.UserLicense.Name')) == 'Salesforce Integration') {
                return AIR_CheckOutcome.passed(access.name() + ' has a Salesforce Integration licence (API only).');
            }
            Integer apiOnly = access.permSetIds.isEmpty()
                ? 0
                : Database.countQueryWithBinds(
                      'SELECT COUNT() FROM PermissionSet WHERE Id IN :ids AND PermissionsApiUserOnly = true',
                      new Map<String, Object>{ 'ids' => access.permSetIds },
                      AccessLevel.SYSTEM_MODE
                  );
            if (apiOnly > 0) {
                return AIR_CheckOutcome.passed(access.name() + ' has the API Only User permission.');
            }
            return AIR_CheckOutcome.attention(access.name() + ' can log in to the Salesforce user interface.');
        }
    }
}
