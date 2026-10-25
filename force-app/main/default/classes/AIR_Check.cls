/**
 * An automated AI readiness check. Implementations live as inner classes of
 * AIR_AutomatedChecks and are referenced by name from AIR_Check__mdt.Handler__c.
 */
public interface AIR_Check {
    AIR_CheckOutcome evaluate(AIR_CheckContext ctx);
}
