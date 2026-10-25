/**
 * Result of one automated check: a status (see AIR_Catalogue) and the evidence shown to the admin.
 */
public with sharing class AIR_CheckOutcome {
    public String status;
    public String evidence;

    public AIR_CheckOutcome(String status, String evidence) {
        this.status = status;
        this.evidence = evidence == null ? null : evidence.left(32000);
    }

    public static AIR_CheckOutcome passed(String evidence) {
        return new AIR_CheckOutcome(AIR_Catalogue.PASSED, evidence);
    }

    public static AIR_CheckOutcome attention(String evidence) {
        return new AIR_CheckOutcome(AIR_Catalogue.ATTENTION, evidence);
    }

    public static AIR_CheckOutcome notChecked(String evidence) {
        return new AIR_CheckOutcome(AIR_Catalogue.NOT_CHECKED, evidence);
    }
}
