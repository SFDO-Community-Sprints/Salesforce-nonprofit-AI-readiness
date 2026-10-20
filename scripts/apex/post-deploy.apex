// Run as the user who should open the assessment. No data or extra specialist roles are assigned.
Id currentUser = UserInfo.getUserId();
PermissionSet assessor = [SELECT Id FROM PermissionSet WHERE Name = 'Readiness_Assessor' LIMIT 1];
if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :currentUser AND PermissionSetId = :assessor.Id] == 0) {
    insert new PermissionSetAssignment(AssigneeId=currentUser, PermissionSetId=assessor.Id);
}
System.debug('Readiness Assessor access is assigned. Open /lightning/n/AI_Readiness');
