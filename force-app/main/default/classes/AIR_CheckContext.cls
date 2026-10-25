/**
 * Input for automated checks. Org-level checks ignore it; implementation-level
 * checks use the grounding fields listed on the AI use case ("Object.Field" per line).
 */
public with sharing class AIR_CheckContext {
    public Id useCaseId;
    /** The dedicated integration user the AI connects as (AIR_Use_Case__c.Agent_User__c). */
    public Id agentUserId;
    public List<String> groundingEntries = new List<String>();

    public AIR_CheckContext() {
    }

    public AIR_CheckContext(AIR_Use_Case__c useCase) {
        this.useCaseId = useCase.Id;
        this.agentUserId = useCase.Agent_User__c;
        this.groundingEntries = parse(useCase.Grounding_Fields__c);
    }

    /** One resolved grounding field. */
    public class FieldRef {
        public String objectName;
        public String fieldName;
        public Schema.DescribeFieldResult describe;

        public String label() {
            return objectName + '.' + fieldName;
        }

        public Boolean isFilterable() {
            return describe.isFilterable();
        }

        public Boolean isPicklist() {
            return describe.getType() == Schema.DisplayType.PICKLIST;
        }
    }

    /** Splits the free-text list into "Object.Field" entries (newline, comma or semicolon separated). */
    public static List<String> parse(String text) {
        List<String> entries = new List<String>();
        if (String.isBlank(text)) {
            return entries;
        }
        for (String part : text.split('[\\n\\r,;]+')) {
            String trimmed = part.trim();
            if (String.isNotBlank(trimmed) && !entries.contains(trimmed)) {
                entries.add(trimmed);
            }
        }
        return entries;
    }

    /**
     * Resolves entries against the schema. Unknown or inaccessible entries are added to `invalid`.
     * Limited to 30 fields to stay inside governor limits.
     */
    public List<FieldRef> resolveFields(List<String> invalid) {
        List<FieldRef> refs = new List<FieldRef>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String entry : groundingEntries) {
            if (refs.size() >= 30) {
                invalid.add(entry + ' (skipped: limit of 30 fields)');
                continue;
            }
            List<String> bits = entry.split('\\.');
            if (bits.size() != 2) {
                invalid.add(entry + ' (use Object.Field)');
                continue;
            }
            Schema.SObjectType objectType = globalDescribe.get(bits[0].trim().toLowerCase());
            if (objectType == null) {
                invalid.add(entry + ' (object not found)');
                continue;
            }
            Schema.SObjectField field = objectType.getDescribe().fields.getMap().get(bits[1].trim().toLowerCase());
            if (field == null) {
                invalid.add(entry + ' (field not found)');
                continue;
            }
            FieldRef ref = new FieldRef();
            ref.objectName = objectType.getDescribe().getName();
            ref.describe = field.getDescribe();
            ref.fieldName = ref.describe.getName();
            refs.add(ref);
        }
        return refs;
    }

    /** Distinct objects of the resolvable grounding fields, in the order they appear. */
    public List<String> groundingObjects() {
        List<String> objects = new List<String>();
        for (FieldRef ref : resolveFields(new List<String>())) {
            if (!objects.contains(ref.objectName)) {
                objects.add(ref.objectName);
            }
        }
        return objects;
    }
}
