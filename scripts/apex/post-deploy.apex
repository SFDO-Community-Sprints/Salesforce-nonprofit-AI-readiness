// Assign the executing demo user the three focused roles needed for the complete walkthrough.
// No API-only/MCP, agent, follow-up Task, or delete permissions are assigned.
Id currentUser = UserInfo.getUserId();
Set<String> requiredRoles = new Set<String>{'Readiness_Assessor','Readiness_Staff_Reviewer','Readiness_Evidence_Reviewer'};
List<PermissionSet> roles = [SELECT Id,Name FROM PermissionSet WHERE Name IN :requiredRoles];
if (roles.size()!=requiredRoles.size()) {
    throw new IllegalArgumentException('Deploy the latest readiness metadata before running setup: assessor, staff reviewer and evidence reviewer roles are required.');
}
Set<Id> assigned = new Set<Id>();
for (PermissionSetAssignment row : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId=:currentUser]) assigned.add(row.PermissionSetId);
List<PermissionSetAssignment> additions = new List<PermissionSetAssignment>();
for (PermissionSet role : roles) if (!assigned.contains(role.Id)) additions.add(new PermissionSetAssignment(AssigneeId=currentUser,PermissionSetId=role.Id));
if (!additions.isEmpty()) insert additions;
System.debug('Assessor, staff reviewer and evidence reviewer roles ready. Refresh Salesforce and open /lightning/n/AI_Readiness');
