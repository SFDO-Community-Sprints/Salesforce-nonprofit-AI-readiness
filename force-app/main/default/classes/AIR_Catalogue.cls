/**
 * Access to the check catalogue (AIR_Check__mdt) plus shared constants.
 * Question, advice and resource text live only in custom metadata.
 */
public with sharing class AIR_Catalogue {
    public static final String PASSED = 'Passed';
    public static final String ATTENTION = 'Needs attention';
    public static final String NOT_CHECKED = 'Not checked';

    public static final String LEVEL_COMPANY = 'Company';
    public static final String LEVEL_ORG = 'Org';
    public static final String LEVEL_IMPLEMENTATION = 'Implementation';

    public static final String TYPE_AUTOMATED = 'Automated';
    public static final String TYPE_MANUAL = 'Manual';

    /** Dashboard category order and labels (matches the mockup). */
    public static final List<String> CATEGORY_ORDER = new List<String>{ 'DQ', 'ACCESS', 'STAFF', 'PRIVACY' };
    public static final Map<String, String> CATEGORY_LABELS = new Map<String, String>{
        'DQ' => 'Data quality',
        'ACCESS' => 'Access and safeguards',
        'STAFF' => 'Staff readiness',
        'PRIVACY' => 'Privacy and erasure'
    };

    private static List<AIR_Check__mdt> cache;

    /** All active checks, sorted. SOQL (not getAll) so long text isn't truncated. */
    public static List<AIR_Check__mdt> all() {
        if (cache == null) {
            cache = [
                SELECT
                    DeveloperName,
                    MasterLabel,
                    Category__c,
                    Topic__c,
                    Level__c,
                    Check_Type__c,
                    Critical__c,
                    Question__c,
                    Pass_Criteria__c,
                    Advice__c,
                    Resources__c,
                    Handler__c,
                    Sort_Order__c
                FROM AIR_Check__mdt
                WHERE Active__c = TRUE
                ORDER BY Sort_Order__c, DeveloperName
            ];
        }
        return cache;
    }

    public static List<AIR_Check__mdt> forLevel(String level) {
        List<AIR_Check__mdt> checks = new List<AIR_Check__mdt>();
        for (AIR_Check__mdt c : all()) {
            if (c.Level__c == level) {
                checks.add(c);
            }
        }
        return checks;
    }

    public static List<AIR_Check__mdt> forLevel(String level, String checkType) {
        List<AIR_Check__mdt> checks = new List<AIR_Check__mdt>();
        for (AIR_Check__mdt c : forLevel(level)) {
            if (c.Check_Type__c == checkType) {
                checks.add(c);
            }
        }
        return checks;
    }

    public static Map<String, AIR_Check__mdt> byCode() {
        Map<String, AIR_Check__mdt> result = new Map<String, AIR_Check__mdt>();
        for (AIR_Check__mdt c : all()) {
            result.put(c.DeveloperName, c);
        }
        return result;
    }

    /** A blank result row for a check, with the catalogue fields copied for stable history. */
    public static AIR_Assessment_Result__c newResult(AIR_Check__mdt c, Id assessmentId) {
        return new AIR_Assessment_Result__c(
            Assessment__c = assessmentId,
            Check_Code__c = c.DeveloperName,
            Check_Title__c = c.MasterLabel,
            Category__c = c.Category__c,
            Topic__c = c.Topic__c,
            Critical__c = c.Critical__c,
            Check_Type__c = c.Check_Type__c,
            Status__c = NOT_CHECKED,
            Evidence__c = c.Check_Type__c == TYPE_MANUAL ? 'Not answered yet.' : 'Not run yet.'
        );
    }

    /** Manual answer to status: Yes = Passed, Partially/No = Needs attention, Not sure/blank = Not checked. */
    public static String statusForAnswer(String answer) {
        if (answer == 'Yes') {
            return PASSED;
        }
        if (answer == 'Partially' || answer == 'No') {
            return ATTENTION;
        }
        return NOT_CHECKED;
    }

    public static String categoryLabel(String code) {
        return CATEGORY_LABELS.containsKey(code) ? CATEGORY_LABELS.get(code) : code;
    }

    public class Resource {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String url;
    }

    /** Parses "Label|URL" lines. A URL of TBD (or missing) is returned as null. */
    public static List<Resource> parseResources(String text) {
        List<Resource> resources = new List<Resource>();
        if (String.isBlank(text)) {
            return resources;
        }
        for (String line : text.split('\\n')) {
            if (String.isBlank(line)) {
                continue;
            }
            Resource r = new Resource();
            List<String> parts = line.split('\\|', 2);
            r.label = parts[0].trim();
            String url = parts.size() > 1 ? parts[1].trim() : null;
            r.url = (String.isBlank(url) || url == 'TBD') ? null : url;
            resources.add(r);
        }
        return resources;
    }
}
