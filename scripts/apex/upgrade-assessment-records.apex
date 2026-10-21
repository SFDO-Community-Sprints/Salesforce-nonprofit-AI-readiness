// Run separately from post-deploy role assignment to avoid Salesforce mixed DML.
Integer updated = ReadinessWorkspace.hydrateAssessments();
System.debug('Existing owned assessment records populated from their original saved reports: ' + updated);
