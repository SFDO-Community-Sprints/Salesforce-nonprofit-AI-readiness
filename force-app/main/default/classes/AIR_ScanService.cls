/**
 * Runs assessments and keeps their result rows in sync with the catalogue.
 *
 * Demo note: the org scan runs synchronously. The packaged version should run it as a
 * Queueable (one check per job if needed) and notify the page when it is done.
 */
public with sharing class AIR_ScanService {
    /** Runs one automated check by handler name. Never throws: failures become "Not checked". */
    public static AIR_CheckOutcome evaluate(String handler, AIR_CheckContext ctx) {
        try {
            if (String.isBlank(handler)) {
                return AIR_CheckOutcome.notChecked('Unavailable: no automated handler is configured.');
            }
            // Resolve relative to the class so it also works under a package namespace.
            Type handlerType = Type.forName(AIR_AutomatedChecks.class.getName() + '.' + handler);
            if (handlerType == null) {
                return AIR_CheckOutcome.notChecked('Unavailable: unknown automated handler "' + handler + '".');
            }
            Object instance = handlerType.newInstance();
            if (!(instance instanceof AIR_Check)) {
                return AIR_CheckOutcome.notChecked('Unavailable: "' + handler + '" is not an AIR check.');
            }
            AIR_CheckOutcome outcome = ((AIR_Check) instance).evaluate(ctx == null ? new AIR_CheckContext() : ctx);
            return outcome == null
                ? AIR_CheckOutcome.notChecked('Unavailable: the check returned no result.')
                : outcome;
        } catch (Exception e) {
            return AIR_CheckOutcome.notChecked('Could not be evaluated automatically: ' + e.getMessage());
        }
    }

    /** Latest assessment for a level (and use case for Implementation), or null. */
    public static AIR_Assessment__c latest(String level, Id useCaseId) {
        List<AIR_Assessment__c> found = [
            SELECT
                Id,
                Name,
                Level__c,
                Use_Case__c,
                Run_Date__c,
                CreatedBy.Name,
                LastModifiedBy.Name,
                Score__c,
                Coverage__c,
                Health__c,
                Critical_Failures__c,
                DPO_Name__c,
                Security_Owner__c,
                Admin_Owner__c,
                DPO_Not_Required_Reason__c,
                Stakeholders__c
            FROM AIR_Assessment__c
            WHERE Level__c = :level AND Use_Case__c = :useCaseId
            WITH USER_MODE
            ORDER BY Run_Date__c DESC NULLS LAST, CreatedDate DESC, Id DESC
            LIMIT 1
        ];
        return found.isEmpty() ? null : found[0];
    }

    public static List<AIR_Assessment_Result__c> results(Id assessmentId) {
        return [
            SELECT
                Id,
                Assessment__c,
                Check_Code__c,
                Check_Title__c,
                Category__c,
                Topic__c,
                Critical__c,
                Check_Type__c,
                Status__c,
                Evidence__c,
                Answer__c,
                Notes__c,
                Responsible__c,
                Due_Date__c
            FROM AIR_Assessment_Result__c
            WHERE Assessment__c = :assessmentId
            WITH USER_MODE
            ORDER BY Name
        ];
    }

    public static Map<String, AIR_Assessment_Result__c> resultsByCode(Id assessmentId) {
        Map<String, AIR_Assessment_Result__c> byCode = new Map<String, AIR_Assessment_Result__c>();
        if (assessmentId == null) {
            return byCode;
        }
        for (AIR_Assessment_Result__c r : results(assessmentId)) {
            byCode.put(r.Check_Code__c, r);
        }
        return byCode;
    }

    /**
     * Creates a new Org assessment: runs every automated Org check, carries over the answers
     * to manual Org checks from the previous Org assessment, and scores it.
     */
    public static Id runOrgScan() {
        AIR_Assessment__c previous = latest(AIR_Catalogue.LEVEL_ORG, null);
        Map<String, AIR_Assessment_Result__c> previousByCode = resultsByCode(previous == null ? null : previous.Id);

        AIR_Assessment__c assessment = new AIR_Assessment__c(
            Level__c = AIR_Catalogue.LEVEL_ORG,
            Run_Date__c = System.now()
        );

        // Evaluate before any DML: some setup objects (OauthToken) are served by an internal
        // callout, which fails once the transaction has uncommitted work.
        AIR_CheckContext ctx = new AIR_CheckContext();
        List<AIR_Check__mdt> checks = AIR_Catalogue.forLevel(AIR_Catalogue.LEVEL_ORG);
        Map<String, AIR_CheckOutcome> outcomes = new Map<String, AIR_CheckOutcome>();
        for (AIR_Check__mdt check : checks) {
            if (check.Check_Type__c == AIR_Catalogue.TYPE_AUTOMATED) {
                outcomes.put(check.DeveloperName, evaluate(check.Handler__c, ctx));
            }
        }
        Database.insert(assessment, AccessLevel.USER_MODE);

        List<AIR_Assessment_Result__c> rows = new List<AIR_Assessment_Result__c>();
        for (AIR_Check__mdt check : checks) {
            AIR_Assessment_Result__c row = AIR_Catalogue.newResult(check, assessment.Id);
            AIR_CheckOutcome outcome = outcomes.get(check.DeveloperName);
            if (outcome != null) {
                row.Status__c = outcome.status;
                row.Evidence__c = outcome.evidence;
            } else {
                copyAnswer(previousByCode.get(check.DeveloperName), row);
            }
            rows.add(row);
        }
        Database.insert(rows, AccessLevel.USER_MODE);
        AIR_ScoreService.recalculate(new Set<Id>{ assessment.Id });
        return assessment.Id;
    }

    /**
     * Returns the latest assessment for the level, creating it (with one row per check) when missing.
     * For Org, a missing assessment triggers a full scan.
     */
    public static AIR_Assessment__c ensureAssessment(String level, Id useCaseId) {
        AIR_Assessment__c existing = latest(level, useCaseId);
        if (existing != null) {
            addMissingRows(existing.Id, level);
            return existing;
        }
        if (level == AIR_Catalogue.LEVEL_ORG) {
            runOrgScan();
            return latest(level, null);
        }
        AIR_Assessment__c assessment = new AIR_Assessment__c(
            Level__c = level,
            Use_Case__c = level == AIR_Catalogue.LEVEL_IMPLEMENTATION ? useCaseId : null,
            Run_Date__c = System.now()
        );
        Database.insert(assessment, AccessLevel.USER_MODE);
        addMissingRows(assessment.Id, level);
        return latest(level, level == AIR_Catalogue.LEVEL_IMPLEMENTATION ? useCaseId : null);
    }

    /** Adds rows for checks added to the catalogue after the assessment was created. */
    public static void addMissingRows(Id assessmentId, String level) {
        Map<String, AIR_Assessment_Result__c> existing = resultsByCode(assessmentId);
        List<AIR_Assessment_Result__c> rows = new List<AIR_Assessment_Result__c>();
        for (AIR_Check__mdt check : AIR_Catalogue.forLevel(level)) {
            if (!existing.containsKey(check.DeveloperName)) {
                rows.add(AIR_Catalogue.newResult(check, assessmentId));
            }
        }
        if (!rows.isEmpty()) {
            Database.insert(rows, AccessLevel.USER_MODE);
        }
    }

    /** Runs the automated Implementation checks (scoped to the use case's grounding fields). */
    public static void runImplementationChecks(Id assessmentId, Id useCaseId) {
        List<AIR_Use_Case__c> useCases = [
            SELECT Id, Grounding_Fields__c, Agent_User__c
            FROM AIR_Use_Case__c
            WHERE Id = :useCaseId
            WITH USER_MODE
        ];
        AIR_CheckContext ctx = useCases.isEmpty() ? new AIR_CheckContext() : new AIR_CheckContext(useCases[0]);
        Map<String, AIR_Assessment_Result__c> byCode = resultsByCode(assessmentId);
        List<AIR_Assessment_Result__c> updates = new List<AIR_Assessment_Result__c>();
        for (
            AIR_Check__mdt check : AIR_Catalogue.forLevel(
                AIR_Catalogue.LEVEL_IMPLEMENTATION,
                AIR_Catalogue.TYPE_AUTOMATED
            )
        ) {
            AIR_Assessment_Result__c row = byCode.get(check.DeveloperName);
            if (row == null) {
                continue;
            }
            AIR_CheckOutcome outcome = evaluate(check.Handler__c, ctx);
            updates.add(
                new AIR_Assessment_Result__c(Id = row.Id, Status__c = outcome.status, Evidence__c = outcome.evidence)
            );
        }
        if (!updates.isEmpty()) {
            Database.update(updates, AccessLevel.USER_MODE);
        }
    }

    private static void copyAnswer(AIR_Assessment_Result__c source, AIR_Assessment_Result__c target) {
        if (source == null) {
            return;
        }
        target.Answer__c = source.Answer__c;
        target.Notes__c = source.Notes__c;
        target.Responsible__c = source.Responsible__c;
        target.Due_Date__c = source.Due_Date__c;
        target.Status__c = AIR_Catalogue.statusForAnswer(source.Answer__c);
        target.Evidence__c = source.Answer__c == null ? 'Not answered yet.' : 'Answered: ' + source.Answer__c + '.';
    }
}
