/**
 * Scoring model (see README, Scoring):
 *  score    = passed / all defined checks
 *  coverage = (passed + needs attention) / all defined checks
 *  health   = Not checked (coverage 0) > Blocked (critical failure) > Ready for pilot (score >= 80) > Needs attention
 */
public with sharing class AIR_ScoreService {
    public static final String HEALTH_NOT_CHECKED = 'Not checked';
    public static final String HEALTH_BLOCKED = 'Blocked';
    public static final String HEALTH_READY = 'Ready for pilot';
    public static final String HEALTH_ATTENTION = 'Needs attention';

    public class Summary {
        @AuraEnabled
        public Integer total = 0;
        @AuraEnabled
        public Integer passed = 0;
        @AuraEnabled
        public Integer attention = 0;
        @AuraEnabled
        public Integer notChecked = 0;
        @AuraEnabled
        public Integer criticalFailures = 0;
        @AuraEnabled
        public Decimal score = 0;
        @AuraEnabled
        public Decimal coverage = 0;
        @AuraEnabled
        public String health = HEALTH_NOT_CHECKED;

        public void add(String status, Boolean critical) {
            total++;
            if (status == AIR_Catalogue.PASSED) {
                passed++;
            } else if (status == AIR_Catalogue.ATTENTION) {
                attention++;
                if (critical == true) {
                    criticalFailures++;
                }
            } else {
                notChecked++;
            }
        }

        public Summary finish() {
            score = percent(passed, total);
            coverage = percent(passed + attention, total);
            health = healthFor(this);
            return this;
        }
    }

    /** Percentage with at most one decimal. */
    public static Decimal percent(Integer part, Integer total) {
        if (total == null || total == 0) {
            return 0;
        }
        return (Decimal.valueOf(part) * 100 / total).setScale(1, RoundingMode.HALF_UP);
    }

    public static String healthFor(Summary s) {
        if (s.total == 0 || s.passed + s.attention == 0) {
            return HEALTH_NOT_CHECKED;
        }
        if (s.criticalFailures > 0) {
            return HEALTH_BLOCKED;
        }
        if (s.score >= 80) {
            return HEALTH_READY;
        }
        return HEALTH_ATTENTION;
    }

    public static Summary summarize(List<AIR_Assessment_Result__c> results) {
        Summary s = new Summary();
        for (AIR_Assessment_Result__c r : results) {
            s.add(r.Status__c, r.Critical__c);
        }
        return s.finish();
    }

    /** Recomputes counts, score, coverage and health for the given assessments and saves them. */
    public static void recalculate(Set<Id> assessmentIds) {
        Map<Id, List<AIR_Assessment_Result__c>> byAssessment = new Map<Id, List<AIR_Assessment_Result__c>>();
        for (Id assessmentId : assessmentIds) {
            byAssessment.put(assessmentId, new List<AIR_Assessment_Result__c>());
        }
        for (AIR_Assessment_Result__c r : [
            SELECT Assessment__c, Status__c, Critical__c
            FROM AIR_Assessment_Result__c
            WHERE Assessment__c IN :assessmentIds
            WITH USER_MODE
        ]) {
            byAssessment.get(r.Assessment__c).add(r);
        }
        List<AIR_Assessment__c> updates = new List<AIR_Assessment__c>();
        for (Id assessmentId : byAssessment.keySet()) {
            Summary s = summarize(byAssessment.get(assessmentId));
            updates.add(
                new AIR_Assessment__c(
                    Id = assessmentId,
                    Score__c = s.score,
                    Coverage__c = s.coverage,
                    Passed_Count__c = s.passed,
                    Attention_Count__c = s.attention,
                    Not_Checked_Count__c = s.notChecked,
                    Critical_Failures__c = s.criticalFailures,
                    Health__c = s.health
                )
            );
        }
        Database.update(updates, AccessLevel.USER_MODE);
    }
}
